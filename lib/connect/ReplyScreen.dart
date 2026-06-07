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

  const ReplyScreen({super.key, required this.messageid, required this.msg});

  @override
  State<ReplyScreen> createState() => _ReplyScreenState();
}

class _ReplyScreenState extends State<ReplyScreen> {
  final TextEditingController _controller = TextEditingController();
  final ApiServer _apiServer = ApiServer();
  bool _isLoading = true;
  Map<String, dynamic>? _parentMsg;
  List<dynamic> _replies = [];
  List<MentionUser> _mentionableUsers = [];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      // Fetch specific message details using the message_id query
      final msgData = await _apiServer.fetchSingleMessage(widget.messageid);

      // Load conversation messages to filter for threaded replies
      final convId = msgData['conversation_id'];
      final chatData = await _apiServer.fetchMessages(convId);
      final List allMsgs = chatData['msgs'] ?? [];

      setState(() {
        _parentMsg = msgData;
        _replies = allMsgs
            .where((m) => m['reply_for_msgid']?.toString() == widget.messageid)
            .toList();
        _isLoading = false;
      });
      _fetchMentionableUsers();
    } catch (e) {
      debugPrint("Error fetching replies: $e");
      setState(() {
        _parentMsg = widget.msg;
        _isLoading = false;
      });
      _fetchMentionableUsers();
    }
  }

  Future<void> _fetchMentionableUsers() async {
    if (_parentMsg == null) return;
    final companyId = _parentMsg!['company_id']?.toString() ?? "";
    if (companyId.isEmpty) return;

    try {
      final List<Map<String, dynamic>> users = await _apiServer.fetchAllUsers(
        companyId,
      );
      final String myId = (await _apiServer.fetchMe())['id'].toString();
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

    final encryptedText = CryptoUtils.encryptMessage(text);
    final String myId = (await _apiServer.fetchMe())['id'].toString();

    try {
      final response = await _apiServer.sendMessage(
        msgBody: encryptedText,
        conversationId: _parentMsg!['conversation_id'],
        companyId: _parentMsg!['company_id'] ?? "",
        senderId: myId,
        participants:
            (_parentMsg!['participants'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
        replyForMsgId: widget.messageid,
        isReplyMsg: "yes",
      );

      setState(() {
        _replies.add(response);
        _controller.clear();
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
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 4,
                      height: 40,
                      decoration: BoxDecoration(
                        color: appTheme.accentColor,
                        borderRadius: BorderRadius.circular(50),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            parentName,
                            style: TextStyle(
                              color: appTheme.accentColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            parentBody,
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black87,
                              fontSize: 14,
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
                        itemCount: _replies.length,
                        itemBuilder: (context, index) {
                          final reply = _replies[index];
                          String replyBody = "";
                          try {
                            replyBody = CryptoUtils.decryptMessage(
                              reply['msg_body'] ?? "",
                            );
                          } catch (e) {
                            replyBody = (reply['msg_body'] ?? "").toString();
                          }
                          replyBody = FormatUtils.stripHtml(replyBody);

                          return Align(
                            alignment: Alignment.centerRight,
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(14),
                              constraints: const BoxConstraints(maxWidth: 280),
                              decoration: BoxDecoration(
                                color: appTheme.accentColor,
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(18),
                                  topRight: const Radius.circular(6),
                                  bottomLeft: const Radius.circular(18),
                                  bottomRight: const Radius.circular(18),
                                ),
                              ),
                              child: Text(
                                replyBody,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                              ),
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
