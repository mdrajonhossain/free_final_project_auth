import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/gestures.dart';
import 'package:freeli/connect/crypto_utils.dart';
import 'package:freeli/connect/format_utils.dart';
import 'package:freeli/connect/PopUpFile/UserProfilePopup.dart';
import 'package:freeli/controller/api/api_service.dart';
import 'package:freeli/theme/ThemeCubit.dart';
import 'package:freeli/theme/themeList.dart';
import 'package:freeli/connect/PopUpFile/PublicTag.dart';
import 'package:freeli/connect/file_utils.dart';
import 'package:freeli/connect/FullImageViewer.dart';
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
  List<Map<String, dynamic>> _selectedFiles = [];

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
          _mentionableUsers =
              (users
                      .where((u) {
                        final uid = (u['id'] ?? u['_id'] ?? u['uid'])
                            .toString();
                        return participantIds.contains(uid) && uid != myId;
                      })
                      .map<MentionUser>(
                        (u) => MentionUser(
                          id: (u['id'] ?? u['_id'] ?? u['uid']).toString(),
                          firstName: (u['firstname'] ?? u['name'] ?? 'User')
                              .toString(),
                          lastName: (u['lastname'] ?? '').toString(),
                          imageUrl: (u['img'] ?? u['image'])?.toString(),
                          email: u['email']?.toString(),
                        ),
                      ))
                  .toList();

          if (_mentionableUsers.isNotEmpty) {
            final String everyoneIds = _mentionableUsers
                .map((e) => e.id)
                .join(',');
            _mentionableUsers.insert(
              0,
              MentionUser(
                id: everyoneIds,
                firstName: 'Everyone',
                lastName: '',
                imageUrl: null,
                email: null,
              ),
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

    Map<String, dynamic>? attachFiles;
    List<Map<String, dynamic>>? allAttachment;

    if (_selectedFiles.isNotEmpty) {
      List<String> imgFiles = [];
      List<String> audioFiles = [];
      List<String> videoFiles = [];
      List<String> otherFiles = [];
      List<Map<String, dynamic>> sanitizedAllFiles = [];

      for (var file in _selectedFiles) {
        final String bucket = file['bucket'] ?? '';
        final String key = file['key'] ?? '';
        final String path = (bucket.isNotEmpty && key.isNotEmpty)
            ? "$bucket/$key"
            : "";
        String mimeType = file['mimetype'] ?? file['contentType'] ?? '';
        int fileSize = int.tryParse(file['size']?.toString() ?? '0') ?? 0;

        if (mimeType.startsWith('image/')) {
          imgFiles.add(path);
        } else if (mimeType.startsWith('audio/')) {
          audioFiles.add(path);
        } else if (mimeType.startsWith('video/')) {
          videoFiles.add(path);
        } else {
          otherFiles.add(path);
        }

        sanitizedAllFiles.add({
          "originalname": file['originalname'] ?? "",
          "mimetype": mimeType,
          "voriginalName":
              file['voriginalName'] ?? file['voriginal_name'] ?? "",
          "size": fileSize,
          "bucket": bucket,
          "key": key,
          "acl": file['acl'] ?? "public-read",
          "referenceId": "",
          "reference_type": "",
        });
      }

      attachFiles = {
        "imgfile": imgFiles,
        "audiofile": audioFiles,
        "videofile": videoFiles,
        "otherfile": otherFiles,
        "allfiles": sanitizedAllFiles,
      };

      allAttachment = sanitizedAllFiles
          .map((_) => {"tag_list": [], "has_tag": "N"})
          .toList();
    }

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
        attachFiles: attachFiles,
        allAttachment: allAttachment,
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
        _selectedFiles = [];
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
                          _buildMessageTextWithMentions(
                            parentBody,
                            isDark ? Colors.white : Colors.black87,
                            14,
                          ),
                          _AttachmentList(
                            // Calling the widget constructor
                            attachments: _parentMsg?['all_attachment'],
                            messageId: "parent-${widget.messageid}",
                            msg: _parentMsg,
                            company_id:
                                widget.companyId ??
                                (_parentMsg?['company_id']?.toString() ?? ""),
                            isDark: isDark,
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
                                            _buildMessageTextWithMentions(
                                              replyBody,
                                              isMe
                                                  ? appTheme.msgSenderText
                                                  : appTheme.msgReceiverText,
                                              13,
                                            ),
                                            _AttachmentList(
                                              // Calling the widget constructor
                                              attachments:
                                                  reply['all_attachment'],
                                              messageId: "reply-$index",
                                              msg: reply,
                                              company_id:
                                                  widget.companyId ??
                                                  (_parentMsg?['company_id']
                                                          ?.toString() ??
                                                      ""),
                                              isDark: isDark,
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

              if (_selectedFiles.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  color: isDark
                      ? Colors.white.withOpacity(0.05)
                      : Colors.black.withOpacity(0.05),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.attach_file,
                        color: Colors.blueAccent,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "${_selectedFiles.length} file(s) selected",
                          style: TextStyle(
                            color: isDark ? Colors.white70 : Colors.black87,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () => setState(() => _selectedFiles = []),
                      ),
                    ],
                  ),
                ),

              /// Reply Input
              ChatInput(
                controller: _controller,
                onSend: _sendReply,
                companyId: _parentMsg?['company_id']?.toString() ?? "",
                onAttachmentsPicked: (results) {
                  setState(() {
                    _selectedFiles = results;
                  });
                },
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
                onMessageSentFromPopup: (newReply) {
                  final chatState = context.read<ChatBloc>().state;
                  final String myId = chatState.myId;
                  setState(() {
                    // Enrich and add to local replies list
                    final enrichedReply = {
                      ...newReply,
                      'sender': myId,
                      'sendername':
                          "${chatState.userData?['firstname'] ?? ''} ${chatState.userData?['lastname'] ?? ''}"
                              .trim(),
                      'senderimg': chatState.userData?['img'],
                      'created_at': DateTime.now().toIso8601String(),
                    };
                    _replies.add(enrichedReply);

                    // Update local parent message metadata
                    if (_parentMsg != null) {
                      final int currentCount =
                          int.tryParse(
                            _parentMsg!['has_reply']?.toString() ?? '0',
                          ) ??
                          0;
                      _parentMsg = {
                        ..._parentMsg!,
                        'has_reply': currentCount + 1,
                        'last_reply_name':
                            "${chatState.userData?['firstname'] ?? ''} ${chatState.userData?['lastname'] ?? ''}"
                                .trim(),
                        'last_reply_time': DateTime.now().toIso8601String(),
                      };
                    }

                    // Notify the main ChatBloc about the metadata change
                    context.read<ChatBloc>().add(
                      ChatParentMessageMetadataUpdated(
                        msgId: widget.messageid,
                        lastReplyName:
                            "${chatState.userData?['firstname'] ?? ''} ${chatState.userData?['lastname'] ?? ''}"
                                .trim(),
                        lastReplyTime: DateTime.now().toIso8601String(),
                      ),
                    );

                    _scrollToBottom();
                  });
                },
                isReplyMsg: "yes",
                replyForMsgId: widget.messageid,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMessageTextWithMentions(
    String text,
    Color textColor,
    double fontSize,
  ) {
    if (_mentionableUsers.isEmpty || !text.contains('@')) {
      return Text(
        text,
        style: TextStyle(color: textColor, fontSize: fontSize),
      );
    }

    List<InlineSpan> spans = [];

    final interactiveUsers = _mentionableUsers
        .where((u) => u.firstName != 'Everyone')
        .toList();
    if (interactiveUsers.isEmpty)
      return Text(
        text,
        style: TextStyle(color: textColor, fontSize: fontSize),
      );

    interactiveUsers.sort(
      (a, b) => b.fullName.length.compareTo(a.fullName.length),
    );

    String pattern = interactiveUsers
        .map((u) => RegExp.escape('@${u.fullName}'))
        .join('|');
    RegExp regex = RegExp(pattern);

    int start = 0;
    regex.allMatches(text).forEach((match) {
      if (match.start > start) {
        spans.add(TextSpan(text: text.substring(start, match.start)));
      }

      final matchText = match.group(0)!;
      final user = interactiveUsers.firstWhere(
        (u) => "@${u.fullName}" == matchText,
      );

      spans.add(
        TextSpan(
          text: matchText,
          style: const TextStyle(
            color: Colors.blueAccent,
            fontWeight: FontWeight.bold,
          ),
          recognizer: TapGestureRecognizer()
            ..onTap = () {
              UserProfilePopup.show(
                context,
                name: user.fullName,
                email: user.email ?? "user@freeli.io",
                imageUrl: user.imageUrl ?? "",
              );
            },
        ),
      );
      start = match.end;
    });

    if (start < text.length) {
      spans.add(TextSpan(text: text.substring(start)));
    }

    return Text.rich(
      TextSpan(
        style: TextStyle(color: textColor, fontSize: fontSize),
        children: spans,
      ),
    );
  }
}

class _AttachmentList extends StatelessWidget {
  final dynamic attachments;
  final String messageId;
  final dynamic msg;
  final String company_id;
  final bool isDark;

  const _AttachmentList({
    required this.attachments,
    required this.messageId,
    required this.msg,
    required this.company_id,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    if (attachments == null || attachments is! List || attachments.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        ...attachments.asMap().entries.map((entry) {
          final int index = entry.key;
          final dynamic file = entry.value;
          final String originalName = file['originalname'] ?? "File";
          final String location = file['location'] ?? "";

          if (location.isEmpty || !location.contains('.')) {
            return const SizedBox.shrink();
          }

          final String extension = location
              .split('?')
              .first
              .split('.')
              .last
              .toLowerCase();

          final bool isImage = [
            'jpg',
            'jpeg',
            'png',
            'gif',
            'webp',
          ].contains(extension);
          final String fullUrl = location.startsWith('http')
              ? location
              : "https://wfss001.freeli.io/$location";

          if (isImage) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Column(
                  children: [
                    tagPopUpListUpdate(context, file, company_id, isDark),
                    const SizedBox(height: 8),
                    _buildIndexStar(context, file),
                  ],
                ),
                Flexible(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => FullImageViewer(imageUrl: fullUrl),
                        ),
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      constraints: const BoxConstraints(
                        maxHeight: 200,
                        maxWidth: 220,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Hero(
                          tag: "hero-$messageId-attachment-$index",
                          child: Image.network(
                            fullUrl,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                height: 150,
                                width: 200,
                                color: Colors.white.withOpacity(0.05),
                                child: const Center(
                                  child: SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                                  height: 100,
                                  width: 150,
                                  color: Colors.white.withOpacity(0.05),
                                  child: const Icon(
                                    Icons.broken_image,
                                    color: Colors.white24,
                                  ),
                                ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          } else {
            final IconData icon = FileUtils.getFileIcon(location);
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  tagPopUpListUpdate(context, file, company_id, isDark),
                  _buildIndexStar(context, file),
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.05),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(icon, color: Colors.white70, size: 20),
                          const SizedBox(width: 10),
                          Flexible(
                            child: Text(
                              originalName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w400,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }
        }).toList(),
      ],
    );
  }

  Widget tagPopUpListUpdate(
    BuildContext context,
    dynamic file,
    String companyId,
    bool isDark,
  ) {
    final String convId = msg['conversation_id']?.toString() ?? "";
    final String mId = (msg['msg_id'] ?? msg['id'])?.toString() ?? "";
    final String fId = file['id']?.toString() ?? "";
    final dynamic tagList = file['tag_list'];
    final String isReply = msg['is_reply_msg']?.toString() ?? "no";
    final dynamic participantsData = msg['participants'];

    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.white,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          builder: (ctx) => PublicTag(
            tagList: {
              'company_id': companyId,
              'tagList': tagList,
              'conversation_id': convId,
              'file_id': fId,
              'is_reply': isReply,
              'msg_id': mId,
              'participants': participantsData is List
                  ? participantsData
                  : [participantsData],
            },
            isDark: isDark,
          ),
        );
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white12),
            ),
            child: const Icon(
              Icons.local_offer_rounded,
              size: 18,
              color: Colors.white70,
            ),
          ),
          if (tagList is List && tagList.isNotEmpty)
            Positioned(
              top: -2,
              right: 4,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 245, 245, 247),
                  borderRadius: BorderRadius.circular(10),
                ),
                constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                child: Center(
                  child: Text(
                    tagList.length.toString(),
                    style: const TextStyle(
                      color: Color.fromARGB(255, 6, 3, 53),
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildIndexStar(BuildContext context, dynamic file) {
    final String fId = file['id']?.toString() ?? "";
    final dynamic starList = file['star'];
    final myId = context.read<ChatBloc>().state.myId;
    final bool isStarred =
        starList is List && starList.any((id) => id.toString() == myId);

    return GestureDetector(
      onTap: () async {
        try {
          final result = await ApiServer().toggleFileStar(fileId: fId);
          final String mId = (msg['msg_id'] ?? msg['id'])?.toString() ?? "";
          if (result.isNotEmpty && context.mounted) {
            context.read<ChatBloc>().add(
              ChatFileStarred(
                msgId: mId,
                fileId: fId,
                star: result['star'] ?? [],
              ),
            );
          }
        } catch (e) {
          debugPrint("Error toggling file star: $e");
        }
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white12),
        ),
        child: Icon(
          isStarred ? Icons.star_rounded : Icons.star_outline_rounded,
          size: 18,
          color: isStarred ? Colors.amber : Colors.white70,
        ),
      ),
    );
  }
}
