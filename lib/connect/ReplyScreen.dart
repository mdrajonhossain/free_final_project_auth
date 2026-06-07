import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freeli/connect/crypto_utils.dart';
import 'package:freeli/connect/format_utils.dart';
import 'package:freeli/controller/api/api_service.dart';
import 'package:freeli/theme/ThemeCubit.dart';
import 'package:freeli/theme/themeList.dart';
import 'package:freeli/connect/ChatSkeleton.dart';
import 'package:freeli/connect/ChatInput.dart';
import 'package:freeli/connect/mention_input.dart';
import 'package:freeli/controller/stateBloc/message/chat_bloc.dart';

class ReplyScreen extends StatefulWidget {
  final String messageid;
  final dynamic msg;
  final String? companyId;
  final dynamic participants;

  const ReplyScreen({
    super.key,
    required this.messageid,
    required this.msg,
    this.companyId,
    this.participants,
  });

  @override
  State<ReplyScreen> createState() => _ReplyScreenState();
}

class _ReplyScreenState extends State<ReplyScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ApiServer _apiServer = ApiServer();
  bool _isLoading = true;
  Map<String, dynamic>? _parentMsg;
  List<dynamic> _replies = [];
  List<MentionUser> _mentionableUsers = [];

  @override
  void initState() {
    super.initState();
    // Safely cast widget.msg to Map<String, dynamic> to avoid type errors
    if (widget.msg != null && widget.msg is Map) {
      _parentMsg = Map<String, dynamic>.from(widget.msg);
    }
    _fetchData();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      // প্যারেন্ট মেসেজের তথ্য যদি ইনকমপ্লিট থাকে (যেমন conversation_id বা participants না থাকা),
      // তবে সেটি API এর মাধ্যমে ফেচ করে নেয়া।
      if (_parentMsg == null ||
          _parentMsg!['conversation_id'] == null ||
          _parentMsg!['company_id'] == null ||
          _parentMsg!['participants'] == null) {
        final fullMsg = await _apiServer.fetchSingleMessage(widget.messageid);
        if (mounted) {
          setState(() {
            _parentMsg = fullMsg;
          });
        }
      }

      // নির্দিষ্ট মেসেজের থ্রেডেড রিপ্লাইগুলো ফেচ করা
      final replyData = await _apiServer.fetchReplyMessages(widget.messageid);
      final List msgs = replyData['msgs'] ?? [];

      if (mounted) {
        setState(() {
          _replies = msgs;
          _scrollToBottom();
        });
      }
    } catch (e) {
      debugPrint("Error fetching replies: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
        _fetchMentionableUsers();
      }
    }
  }

  Future<void> _fetchMentionableUsers() async {
    if (_parentMsg == null || _parentMsg!['company_id'] == null) return;
    final companyId = _parentMsg!['company_id']?.toString() ?? "";
    if (companyId.isEmpty) return;

    try {
      final List<Map<String, dynamic>> users = await _apiServer.fetchAllUsers(
        companyId,
      );
      final String myId = context.read<ChatBloc>().state.myId;

      final List pList = _parentMsg!['participants'] is List
          ? _parentMsg!['participants']
          : [];
      final List<String> participantIds = pList
          .map((e) => e.toString())
          .toList();

      if (mounted) {
        setState(() {
          _mentionableUsers = users
              .where((u) {
                final uid = (u['id'] ?? u['_id'] ?? u['uid']).toString();
                return participantIds.contains(uid) && uid != myId;
              })
              .map(
                (u) => MentionUser(
                  id: (u['id'] ?? u['_id'] ?? u['uid']).toString(),
                  name: (u['firstname'] ?? u['name'] ?? 'User').toString(),
                  imageUrl: (u['img'] ?? u['image'])?.toString(),
                ),
              )
              .toList();

          if (_mentionableUsers.isNotEmpty) {
            final String everyoneIds = _mentionableUsers
                .map((e) => e.id)
                .join(',');
            _mentionableUsers.insert(
              0,
              MentionUser(id: everyoneIds, name: 'Everyone', imageUrl: null),
            );
          }
        });
      }
    } catch (e) {
      debugPrint("Error fetching mentions in ReplyScreen: $e");
    }
  }

  Future<void> _sendReply() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _parentMsg == null) return;

    final chatState = context.read<ChatBloc>().state;
    final String myId = chatState.myId;

    // Ensure we have the necessary conversation metadata
    final String cid = widget.companyId ?? _parentMsg?['company_id'] ?? "";

    List<String> partList = [];
    if (widget.participants != null) {
      if (widget.participants is List) {
        partList = List<String>.from(
          widget.participants.map((e) => e.toString()),
        );
      } else {
        partList = [widget.participants.toString()];
      }
    } else if (_parentMsg?['participants'] != null) {
      partList = List<String>.from(
        (_parentMsg!['participants'] as List).map((e) => e.toString()),
      );
    }

    if (cid.isEmpty || partList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error: Missing conversation metadata.")),
      );
      return;
    }

    final encryptedText = CryptoUtils.encryptMessage(text);

    try {
      final response = await _apiServer.sendMessage(
        msgBody: encryptedText,
        conversationId: _parentMsg?['conversation_id']?.toString() ?? "",
        companyId: cid,
        senderId: myId,
        participants: partList,
        replyms: "yes",
        replyForMsgId: widget.messageid,
        isReplyMsg: "yes",
        isSecret: false,
      );

      setState(() {
        // Enrich the response with local user info for immediate UI update
        final newReply = {
          ...response,
          'sender': myId,
          'sendername':
              "${chatState.userData?['firstname'] ?? ''} ${chatState.userData?['lastname'] ?? ''}"
                  .trim(),
          'senderimg': chatState.userData?['img'],
          'created_at': DateTime.now().toIso8601String(),
        };
        _replies.add(newReply);

        // Update parent message metadata locally for instant UI update in the header
        if (_parentMsg != null) {
          final int currentCount =
              int.tryParse(_parentMsg!['has_reply']?.toString() ?? '0') ?? 0;
          _parentMsg = {
            ..._parentMsg!,
            'has_reply': currentCount + 1,
            'last_reply_name':
                "${chatState.userData?['firstname'] ?? ''} ${chatState.userData?['lastname'] ?? ''}"
                    .trim(),
            'last_reply_time': DateTime.now().toIso8601String(),
          };
        }

        // Trigger Bloc update for ChatScreen to reflect the new reply count/info in the message list
        context.read<ChatBloc>().add(
          ChatParentMessageMetadataUpdated(
            msgId: widget.messageid,
            lastReplyName:
                "${chatState.userData?['firstname'] ?? ''} ${chatState.userData?['lastname'] ?? ''}"
                    .trim(),
            lastReplyTime: DateTime.now().toIso8601String(),
          ),
        );

        _controller.clear();
        _scrollToBottom();
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed to send reply: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, AppThemeModel>(
      builder: (context, appTheme) {
        final bool isDark = appTheme.backgroundColor.computeLuminance() < 0.5;

        if (_isLoading) {
          return Scaffold(
            backgroundColor: appTheme.msgBackgroundColor,
            appBar: AppBar(
              backgroundColor: appTheme.backgroundColor,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            body: const ChatSkeleton(),
          );
        }

        final String parentName = (_parentMsg?['sendername'] ?? 'User')
            .toString();
        final String parentImg = _parentMsg?['senderimg']?.toString() ?? "";
        String parentBody = "";
        try {
          parentBody = CryptoUtils.decryptMessage(
            _parentMsg?['msg_body'] ?? "",
          );
        } catch (e) {
          parentBody = (_parentMsg?['msg_body'] ?? "").toString();
        }
        parentBody = FormatUtils.stripHtml(parentBody);

        return Scaffold(
          backgroundColor: appTheme.msgBackgroundColor,
          appBar: AppBar(
            elevation: 0,
            backgroundColor: appTheme.backgroundColor,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text(
              "Reply message",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 18,
              ),
            ),
          ),
          body: Column(
            children: [
              /// Original Parent Message
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isDark
                        ? Colors.white12
                        : Colors.black.withOpacity(0.05),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: Colors.white12,
                      backgroundImage: parentImg.isNotEmpty
                          ? NetworkImage(parentImg)
                          : null,
                      child: parentImg.isEmpty
                          ? const Icon(Icons.person, color: Colors.white)
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                parentName,
                                style: TextStyle(
                                  color: appTheme.accentColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              Text(
                                FormatUtils.formatTime(
                                  _parentMsg?['created_at']?.toString(),
                                ),
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          Text(
                            parentBody,
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black87,
                              fontSize: 14,
                            ),
                          ),
                          if ((int.tryParse(
                                    _parentMsg?['has_reply']?.toString() ?? '0',
                                  ) ??
                                  0) >
                              0)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: appTheme.accentColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.forum_outlined,
                                      size: 14,
                                      color: appTheme.accentColor,
                                    ),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        "Threaded chat (${_parentMsg?['has_reply'] ?? 0}) • Last reply ${FormatUtils.formatTime(_parentMsg?['last_reply_time']?.toString())} from ${_parentMsg?['last_reply_name'] ?? 'Someone'}",
                                        style: TextStyle(
                                          color: isDark
                                              ? Colors.white70
                                              : Colors.black87,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              /// Threaded Replies
              Expanded(
                child: _replies.isEmpty
                    ? Center(
                        child: Text(
                          "No replies yet",
                          style: TextStyle(
                            color: isDark ? Colors.white54 : Colors.black38,
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        controller: _scrollController,
                        itemCount: _replies.length,
                        itemBuilder: (context, index) {
                          final reply = _replies[index];
                          final String myId = context
                              .read<ChatBloc>()
                              .state
                              .myId;
                          final bool isMe = reply['sender']?.toString() == myId;
                          final String senderImg =
                              reply['senderimg']?.toString() ?? "";

                          String replyBody = "";
                          try {
                            replyBody = CryptoUtils.decryptMessage(
                              reply['msg_body'] ?? "",
                            );
                          } catch (e) {
                            replyBody = (reply['msg_body'] ?? "").toString();
                          }
                          replyBody = FormatUtils.stripHtml(replyBody);

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              mainAxisAlignment: isMe
                                  ? MainAxisAlignment.end
                                  : MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (!isMe)
                                  CircleAvatar(
                                    radius: 14,
                                    backgroundColor: Colors.white12,
                                    backgroundImage: senderImg.isNotEmpty
                                        ? NetworkImage(senderImg)
                                        : null,
                                    child: senderImg.isEmpty
                                        ? const Icon(
                                            Icons.person,
                                            size: 14,
                                            color: Colors.white,
                                          )
                                        : null,
                                  ),
                                if (!isMe) const SizedBox(width: 8),
                                Flexible(
                                  child: Column(
                                    crossAxisAlignment: isMe
                                        ? CrossAxisAlignment.end
                                        : CrossAxisAlignment.start,
                                    children: [
                                      if (!isMe)
                                        Text(
                                          (reply['sendername'] ?? 'User')
                                              .toString(),
                                          style: const TextStyle(
                                            color: Colors.grey,
                                            fontSize: 10,
                                          ),
                                        ),
                                      Container(
                                        margin: const EdgeInsets.only(top: 4),
                                        padding: const EdgeInsets.all(12),
                                        constraints: const BoxConstraints(
                                          maxWidth: 260,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isMe
                                              ? appTheme.msgSenderBubble
                                              : appTheme.msgReceiverBubble,
                                          borderRadius: BorderRadius.only(
                                            topLeft: Radius.circular(
                                              isMe ? 18 : 4,
                                            ),
                                            topRight: Radius.circular(
                                              isMe ? 4 : 18,
                                            ),
                                            bottomLeft: const Radius.circular(
                                              18,
                                            ),
                                            bottomRight: const Radius.circular(
                                              18,
                                            ),
                                          ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              replyBody,
                                              style: TextStyle(
                                                color: isMe
                                                    ? appTheme.msgSenderText
                                                    : appTheme.msgReceiverText,
                                                fontSize: 13,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              FormatUtils.formatTime(
                                                reply['created_at']?.toString(),
                                              ),
                                              style: TextStyle(
                                                color: isMe
                                                    ? Colors.white70
                                                    : Colors.grey,
                                                fontSize: 9,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isMe) const SizedBox(width: 8),
                                if (isMe)
                                  CircleAvatar(
                                    radius: 14,
                                    backgroundColor: appTheme.accentColor
                                        .withOpacity(0.3),
                                    backgroundImage: senderImg.isNotEmpty
                                        ? NetworkImage(senderImg)
                                        : null,
                                    child: senderImg.isEmpty
                                        ? const Icon(
                                            Icons.person,
                                            size: 14,
                                            color: Colors.white,
                                          )
                                        : null,
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
              ),

              /// Reply Input
              ChatInput(
                controller: _controller,
                onSend: _sendReply,
                companyId: _parentMsg?['company_id']?.toString() ?? "",
                onAttachmentsPicked: (results) {},
                conversationId:
                    _parentMsg?['conversation_id']?.toString() ?? "",
                participants: _parentMsg?['participants'] ?? [],
                chatBloc: context.read<ChatBloc>(),
                group:
                    (_parentMsg?['participants'] as List?)?.length != null &&
                    (_parentMsg!['participants'] as List).length > 2,
                showLockIcon: false,
                userEmail: _parentMsg?['senderemail']?.toString(),
                mentionableUsers: _mentionableUsers,
              ),
            ],
          ),
        );
      },
    );
  }
}
