import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freeli/connect/PopUpFile/ForwardMessageScreen.dart';
import 'package:freeli/connect/PopUpFile/UserProfilePopup.dart';
import 'package:freeli/theme/themeList.dart';
import 'package:freeli/theme/ThemeCubit.dart';
import 'package:freeli/connect/PopUpFile/PublicTag.dart';
import 'package:freeli/controller/api/api_service.dart';
import 'package:flutter/services.dart'; // Import for Clipboard
import '../controller/stateBloc/message/chat_bloc.dart';
import 'ChatSkeleton.dart';
import './mention_input.dart';
import 'dart:convert';
import './crypto_utils.dart';
import './format_utils.dart';
import './file_utils.dart';
import './chat_service.dart';
import './ChatInput.dart';
import './chatMore_Screen.dart';
import './chatFilter_Screen.dart';
import './FullImageViewer.dart';
import './jitsi_call_service.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late ChatBloc _chatBloc;

  String conversationId = "";
  String company_id = "";
  dynamic participants;
  String conversation_type = "private";
  String roomTitle = "Chat";
  String convImg = "";
  bool _isEditing = false;
  String? _editingMsgId;
  List<MentionUser> _mentionableUsers = [];

  @override
  void initState() {
    super.initState();
    _chatBloc = context.read<ChatBloc>();
    _scrollController.addListener(_scrollListener);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null) {
        setState(() {
          conversationId = args['conversation_id']?.toString() ?? "";
          conversation_type = args['group'] == true ? "group" : "private";
          company_id = args['company_id']?.toString() ?? "";
          participants = args['participants'];
          roomTitle = args['title']?.toString() ?? "Chat";
          // Added fallbacks for common keys in case 'conv_img' is null
          convImg =
              (args['conv_img'] ?? args['img'] ?? args['image'])?.toString() ??
              "";

          // Synchronize with server to mark messages as read
          ApiServer().markAsRead(conversationId);

          _chatBloc.add(ChatFetchRequested(conversationId));
          _fetchMentionableUsers();
        });
      }
    });
  }

  Future<void> _fetchMentionableUsers() async {
    // @mentions are only available for group conversations
    if (company_id.isEmpty || conversation_type != "group") {
      if (mounted) {
        setState(() {
          _mentionableUsers = [];
        });
      }
      return;
    }
    try {
      final List<Map<String, dynamic>> users = await ApiServer().fetchAllUsers(
        company_id,
      );

      // Ensure we have a valid myId for filtering, fetching if necessary
      String myId = _chatBloc.state.myId;
      if (myId.isEmpty) {
        try {
          final me = await ApiServer().fetchMe();
          myId = (me['id'] ?? me['_id'] ?? me['uid']).toString();
        } catch (e) {
          debugPrint("Could not fetch myId for filtering: $e");
        }
      }

      // participants লিস্টকে String লিস্টে রূপান্তর করা
      final List pList = participants is List ? participants : [];
      final List<String> participantIds = pList
          .map((e) => e.toString())
          .toList();

      if (mounted) {
        setState(() {
          final List<MentionUser> mentionList = users
              .where((u) {
                final uid = (u['id'] ?? u['_id'] ?? u['uid']).toString();
                // রুমের মেম্বার হতে হবে এবং নিজে হওয়া যাবে না
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

          // React এর মতো 'Everyone' অপশন যোগ করা (যদি মেম্বার থাকে)
          if (mentionList.isNotEmpty) {
            final String everyoneIds = mentionList.map((e) => e.id).join(',');
            mentionList.insert(
              0,
              MentionUser(id: everyoneIds, name: 'Everyone', imageUrl: null),
            );
          }
          _mentionableUsers = mentionList;
        });
      }
    } catch (e) {
      debugPrint("Error fetching company users for mentions: $e");
    }
  }

  void _scrollListener() {
    if (_scrollController.hasClients &&
        _scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 100) {
      if (conversationId.isNotEmpty) {
        _chatBloc.add(ChatLoadMoreRequested(conversationId));
      }
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    if (_isEditing && _editingMsgId != null) {
      final text = _messageController.text.trim();
      // Get the original message text for comparison
      final originalMessage = _chatBloc.state.messages.firstWhere(
        (m) => (m['msg_id'] ?? m['id']).toString() == _editingMsgId,
        orElse: () => null,
      );
      String originalText = '';
      if (originalMessage != null) {
        try {
          originalText = CryptoUtils.decryptMessage(
            originalMessage['msg_body'] ?? '',
          );
        } catch (e) {
          originalText = (originalMessage['msg_body'] ?? '').toString();
        }
        originalText = FormatUtils.stripHtml(originalText);
      }

      if (text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Message cannot be empty.")),
        );
      } else if (text == originalText) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("No changes detected.")));
      } else {
        _chatBloc.add(
          ChatMessageEdited(
            conversationId: conversationId,
            msgId: _editingMsgId!,
            newText: text,
            onSuccess: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Message edited successfully!")),
              );
            },
            onError: (error) {
              // Add error parameter to the callback
              final errorMessage =
                  error?.toString() ?? "Failed to edit message.";
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(errorMessage)));
            },
          ),
        );
        setState(() {
          _isEditing = false;
          _editingMsgId = null;
          _messageController.clear();
        });
      }
    } else {
      ChatService.sendMessage(
        context: context,
        controller: _messageController,
        conversationId: conversationId,
        companyId: company_id,
        participants: participants,
        chatBloc: _chatBloc,
        onScroll: _scrollToBottom,
      );
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, AppThemeModel>(
      builder: (context, appTheme) {
        final bool isDark = appTheme.backgroundColor.computeLuminance() < 0.5;

        return BlocBuilder<ChatBloc, ChatState>(
          builder: (context, state) {
            if (state.isLoading) {
              return Scaffold(
                backgroundColor: appTheme.msgBackgroundColor,
                body: const ChatSkeleton(),
              );
            }

            return Scaffold(
              backgroundColor: appTheme.msgBackgroundColor,
              appBar: AppBar(
                elevation: 0,
                backgroundColor: appTheme.backgroundColor,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                titleSpacing: -5,
                title: Row(
                  children: [
                    _buildRoomImage(),
                    const SizedBox(width: 12),
                    _buildRoomTitle(),
                    GestureDetector(
                      onTap: () async {
                        final args =
                            ModalRoute.of(context)?.settings.arguments as Map?;
                        final userId =
                            state.userData?['id']?.toString() ??
                            args?['user_id']?.toString();
                        final companyId = company_id.isNotEmpty
                            ? company_id
                            : (state.userData?['company_id']?.toString() ??
                                  args?['company_id']?.toString());

                        if (userId == null || companyId == null) return;

                        try {
                          print("""
userId: $userId
companyId: $companyId
conversationId: $conversationId
conversationType: $conversation_type
roomTitle: $roomTitle
userName: ${state.userData?['firstname'] ?? "User"}
userEmail: ${state.userData?['email']}
userAvatar: ${state.userData?['img']}
isVideo: false
participants: $participants
""");
                          await JitsiCallService.joinCall(
                            context: context,
                            userId: userId,
                            companyId: companyId,
                            conversationId: conversationId,
                            conversationType: conversation_type,
                            participants:
                                (participants as List?)?.toList() ?? [],
                            roomTitle: roomTitle,
                            userName: state.userData?['firstname'] ?? "User",
                            userEmail: state.userData?['email'],
                            userAvatar: state.userData?['img']?.toString(),
                            isVideo: false,
                          );
                        } catch (e) {
                          // Dismiss loading animation on error
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Call Error: $e")),
                            );
                          }
                        }
                      },
                      child: Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.call,
                          size: 28,
                          color: Colors.green,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.pushNamed(context, "/filehubRoom");
                      },
                      child: Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.folder_open_rounded,
                          size: 28,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                    SizedBox(width: 14),
                    // GestureDetector(
                    //   onTap: () => ChatMoreScreen.show(context),
                    //   child: Container(
                    //     margin: const EdgeInsets.only(left: 8),
                    //     padding: const EdgeInsets.all(6),
                    //     decoration: BoxDecoration(
                    //       borderRadius: BorderRadius.circular(10),
                    //     ),
                    //     child: const Icon(
                    //       Icons.more_vert,
                    //       size: 28,
                    //       color: Colors.white70,
                    //     ),
                    //   ),
                    // ),
                  ],
                ),
              ),
              body: SafeArea(
                child: Column(
                  children: [
                    Expanded(
                      child: state.messages.isEmpty
                          ? _buildEmptyMessages()
                          : _buildMessageList(state, appTheme),
                    ),
                    if (_isEditing)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        color: isDark
                            ? Colors.white.withOpacity(0.1)
                            : Colors.black.withOpacity(0.05),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.edit,
                              color: Colors.greenAccent,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                "Editing message",
                                style: TextStyle(
                                  color: isDark
                                      ? Colors.white70
                                      : Colors.black87,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.close,
                                color: isDark ? Colors.white70 : Colors.black54,
                                size: 18,
                              ),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () {
                                setState(() {
                                  _isEditing = false;
                                  _editingMsgId = null;
                                  _messageController.clear();
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ChatInput(
                      controller: _messageController,
                      onSend: _sendMessage,
                      // Ensure no mentions are possible if it's not a group room
                      mentionableUsers: conversation_type == "group"
                          ? _mentionableUsers
                          : [],
                      companyId: company_id,
                      group: conversation_type == "group",
                      userEmail: state.userData?['email']?.toString(),
                      conversationId: conversationId,
                      participants: participants,
                      chatBloc: _chatBloc,
                      onAttachmentsPicked: (results) {
                        // Handle picked attachments here
                        debugPrint("Picked ${results.length} attachments");
                        // You can add logic to send them or show a preview
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildRoomImage() {
    return Container(
      height: 42,
      width: 42,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: context.read<ThemeCubit>().state.accentColor,
      ),
      child: convImg.isNotEmpty
          ? ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.network(
                convImg,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.forum_rounded, color: Colors.white),
              ),
            )
          : const Icon(Icons.forum_rounded, color: Colors.white),
    );
  }

  Widget _buildRoomTitle() {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            roomTitle,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            "Online",
            style: TextStyle(color: Colors.white54, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyMessages() {
    return Center(
      child: Text(
        "No messages found",
        style: TextStyle(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white54
              : Colors.black38,
        ),
      ),
    );
  }

  Widget _buildMessageList(ChatState state, AppThemeModel appTheme) {
    return ListView.builder(
      reverse: true,
      controller: _scrollController,
      // Cache off-screen items to prevent re-decryption/re-building during scroll
      cacheExtent: 1000,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      itemCount: state.messages.length + (state.isFetchingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == state.messages.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Center(
              child: SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white70,
                ),
              ),
            ),
          );
        }
        final msg = state.messages[index];
        final isMe = msg['sender'].toString() == state.myId;

        // Using a dedicated widget instead of a method improves rebuild performance
        return _MessageBubble(
          key: ValueKey(msg['id'] ?? index),
          msg: msg,
          isDark: appTheme.backgroundColor.computeLuminance() < 0.5,
          isMe: isMe,
          index: index,
          conversationId: conversationId,
          company_id: company_id,
          appTheme: appTheme,
          onEdit: () {
            String decryptedText = "";
            try {
              decryptedText = CryptoUtils.decryptMessage(msg['msg_body'] ?? '');
            } catch (e) {
              decryptedText = (msg['msg_body'] ?? '').toString();
            }
            _messageController.text = FormatUtils.stripHtml(decryptedText);
            setState(() {
              _isEditing = true;
              _editingMsgId = msg['msg_id'] ?? msg['id'];
            });
          },
        );
      },
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final dynamic msg;
  final bool isDark;
  final bool isMe;
  final int index;
  final String conversationId;
  final String company_id;
  final AppThemeModel appTheme;
  final VoidCallback? onEdit;

  const _MessageBubble({
    super.key,
    required this.msg,
    required this.isDark,
    required this.isMe,
    required this.index,
    required this.conversationId,
    required this.company_id,
    required this.appTheme,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    // Ensure we check the normalized 'is_secret' key first
    final bool isSecret =
        msg['is_secret'] == true ||
        msg['is_secret']?.toString() == 'true' ||
        msg['is_secret']?.toString() == '1' ||
        msg['isSecret'] == true ||
        msg['isSecret']?.toString() == 'true';

    // Dynamic colors for bubble text and background
    final Color textColor = isMe
        ? appTheme.msgSenderText
        : appTheme.msgReceiverText;

    // Dynamic background for private messages
    final Color bubbleColor = isSecret
        ? (isDark ? const Color(0xff2D3748) : const Color(0xffEDF2F7))
        : (isMe ? appTheme.msgSenderBubble : appTheme.msgReceiverBubble);

    // Decryption and formatting happen only when this specific bubble builds
    String decryptedText = "";
    try {
      decryptedText = CryptoUtils.decryptMessage(msg['msg_body'] ?? '');
    } catch (e) {
      // Fallback if decryption fails (e.g. invalid base64 or plain text)
      decryptedText = (msg['msg_body'] ?? '').toString();
    }

    final String cleanText = FormatUtils.stripHtml(decryptedText);
    final String msgTitle = (msg['msg_title'] ?? '').toString();
    final String msgId = msg['msg_id'] ?? msg['id'];
    final String userImage = msg['senderimg']?.toString() ?? "";

    // Generate a unique ID for Hero tags.
    // Incorporating index ensures uniqueness even if the message object is duplicated in the list state.
    final String messageId =
        "${msg['msg_id'] ?? msg['id'] ?? 'msg'}-$index-${msg['created_at'] ?? DateTime.now().millisecondsSinceEpoch}-${msg.hashCode}";

    final screenWidth = MediaQuery.of(context).size.width;

    return Padding(
      padding: EdgeInsets.only(
        bottom: 18,
        right: isMe ? 10 : 0,
        left: isMe ? 0 : 10,
      ),

      child: GestureDetector(
        onLongPress: () {
          showModalBottomSheet(
            context: context,
            backgroundColor: isDark ? const Color(0xff1B2335) : Colors.white,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            builder: (context) {
              return SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isMe)
                      ListTile(
                        leading: const Icon(
                          Icons.edit,
                          color: Colors.greenAccent,
                        ),
                        title: Text(
                          "Edit",
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          onEdit?.call();
                        },
                      ),
                    // Copy functionality
                    ListTile(
                      leading: Icon(
                        Icons.copy,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                      title: Text(
                        "Copy",
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        Clipboard.setData(ClipboardData(text: cleanText));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Message copied!")),
                        );
                      },
                    ),
                    // Forward functionality
                    ListTile(
                      leading: Icon(
                        Icons.forward,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                      title: Text(
                        "Forward",
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.white,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(24),
                            ),
                          ),
                          builder: (ctx) => ForwardMessageScreen(
                            messageToForward: {
                              ...msg,
                              'conversation_id':
                                  msg['conversation_id'] ?? conversationId,
                            },
                          ),
                        );
                      },
                    ),
                    ListTile(
                      leading: const Icon(
                        Icons.delete,
                        color: Colors.redAccent,
                      ),
                      title: const Text(
                        "Delete",
                        style: TextStyle(color: Colors.redAccent),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        context.read<ChatBloc>().add(
                          ChatMessageDeleted(
                            conversationId: conversationId,
                            msgId: msgId,
                            onSuccess: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Message deleted!"),
                                ),
                              );
                            },
                            onError: (error) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Failed to delete message."),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: isMe
              ? MainAxisAlignment.end
              : MainAxisAlignment.start,

          children: [
            /// LEFT SIDE USER
            if (!isMe) ...[
              GestureDetector(
                onTap: () => UserProfilePopup.show(
                  context,
                  // Checking multiple keys for sender name to avoid showing "User"
                  name:
                      (msg['sendername'] ??
                              msg['name'] ??
                              msg['created_by_name'] ??
                              msg['sender_name'] ??
                              msg['username'] ??
                              "User")
                          .toString(),
                  email: msg['senderemail']?.toString() ?? "user@freeli.io",
                  imageUrl: userImage,
                ),
                child: CircleAvatar(
                  radius: 18,

                  backgroundColor: Colors.white12,

                  backgroundImage: userImage.isNotEmpty
                      ? NetworkImage(userImage)
                      : null,

                  child: userImage.isEmpty
                      ? const Icon(Icons.person, color: Colors.white, size: 18)
                      : null,
                ),
              ),
              const SizedBox(width: 10),
            ],

            Flexible(
              child: Column(
                crossAxisAlignment: isMe
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,

                children: [
                  /// USER NAME (Now for both sides)
                  Padding(
                    padding: EdgeInsets.only(
                      left: isMe ? 0 : 6,
                      right: isMe ? 6 : 0,
                      bottom: 4,
                    ),
                    child: GestureDetector(
                      onTap: () => UserProfilePopup.show(
                        context,
                        name: isMe
                            ? "You"
                            : (msg['sendername'] ??
                                      msg['name'] ??
                                      msg['created_by_name'] ??
                                      msg['sender_name'] ??
                                      msg['username'] ??
                                      "User")
                                  .toString(),
                        email:
                            msg['senderemail']?.toString() ?? "user@freeli.io",
                        imageUrl: userImage,
                      ),
                      child: Text(
                        isMe
                            ? "You"
                            : (msg['sendername'] ??
                                      msg['name'] ??
                                      msg['created_by_name'] ??
                                      msg['sender_name'] ??
                                      msg['username'] ??
                                      "User")
                                  .toString(),
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),

                  /// CHAT BUBBLE
                  Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.72,
                    ),

                    padding: const EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 12,
                    ),

                    decoration: BoxDecoration(
                      color: bubbleColor,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(isMe ? 22 : 6),
                        topRight: Radius.circular(isMe ? 6 : 22),
                        bottomLeft: const Radius.circular(22),
                        bottomRight: const Radius.circular(22),
                      ),
                      border: isSecret
                          ? Border.all(
                              color: Colors.orangeAccent.withOpacity(0.5),
                              width: 1.5,
                            )
                          : Border.all(
                              color: isMe
                                  ? Colors.white.withOpacity(0.05)
                                  : (isDark
                                        ? Colors.white.withOpacity(0.05)
                                        : Colors.black.withOpacity(0.05)),
                            ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (isSecret)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.lock_rounded,
                                  size: 14,
                                  color: Colors.orangeAccent,
                                ),
                              ],
                            ),
                          )
                        else if (msgTitle.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Text(
                              msgTitle,
                              style: TextStyle(
                                color: textColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        if (isSecret) ...[
                          const SizedBox(height: 8),
                          // Display title instead of message body for private messages
                          Text(
                            msgTitle.isNotEmpty ? msgTitle : "Private Message",
                            style: TextStyle(
                              color: textColor,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          // 1. User List (Who can see this secret)
                          if (msg['secret_users'] != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.people_outline,
                                    size: 14,
                                    color: Colors.orangeAccent,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: SizedBox(
                                      height: 24,
                                      child: ListView.separated(
                                        scrollDirection: Axis.horizontal,
                                        itemCount: (msg['secret_users'] is List)
                                            ? (msg['secret_users'] as List)
                                                  .length
                                            : 1,
                                        separatorBuilder: (_, __) =>
                                            const SizedBox(width: 4),
                                        itemBuilder: (context, i) =>
                                            CircleAvatar(
                                              radius: 11,
                                              backgroundColor: Colors.white24,
                                              child: const Icon(
                                                Icons.person,
                                                size: 14,
                                                color: Colors.white,
                                              ),
                                            ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          // 2. Action Buttons Panel
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _buildSecretAction(
                                icon: Icons.remove_red_eye_outlined,
                                label: "Quick view",
                                color: Colors.blueAccent,
                                onTap: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      backgroundColor: isDark
                                          ? const Color(0xff1B2335)
                                          : Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      title: Row(
                                        children: [
                                          const Icon(
                                            Icons.lock_outline,
                                            color: Colors.orangeAccent,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 10),
                                          Text(
                                            "Private Preview",
                                            style: TextStyle(
                                              color: isDark
                                                  ? Colors.white
                                                  : Colors.black87,
                                              fontSize: 18,
                                            ),
                                          ),
                                        ],
                                      ),
                                      content: SingleChildScrollView(
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                CircleAvatar(
                                                  radius: 16,
                                                  backgroundImage:
                                                      userImage.isNotEmpty
                                                      ? NetworkImage(userImage)
                                                      : null,
                                                  child: userImage.isEmpty
                                                      ? const Icon(
                                                          Icons.person,
                                                          size: 16,
                                                        )
                                                      : null,
                                                ),
                                                const SizedBox(width: 10),
                                                Text(
                                                  (msg['sendername'] ?? "User")
                                                      .toString(),
                                                  style: TextStyle(
                                                    color: isDark
                                                        ? Colors.white70
                                                        : Colors.black54,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const Divider(height: 24),
                                            // Display list of all users who can see this secret
                                            if (msg['secret_users'] != null ||
                                                msg['participants'] !=
                                                    null) ...[
                                              const Text(
                                                "Shared with:",
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                              const SizedBox(height: 10),
                                              SizedBox(
                                                height: 35,
                                                child: ListView.separated(
                                                  scrollDirection:
                                                      Axis.horizontal,
                                                  itemCount:
                                                      (msg['secret_users']
                                                          is List)
                                                      ? (msg['secret_users']
                                                                as List)
                                                            .length
                                                      : (msg['participants']
                                                                is List
                                                            ? (msg['participants']
                                                                      as List)
                                                                  .length
                                                            : 0),
                                                  separatorBuilder: (_, __) =>
                                                      const SizedBox(width: 8),
                                                  itemBuilder: (context, i) {
                                                    return Tooltip(
                                                      message:
                                                          "User ID: ${(msg['secret_users'] ?? msg['participants'])[i]}",
                                                      child: CircleAvatar(
                                                        radius: 16,
                                                        backgroundColor: Colors
                                                            .orangeAccent
                                                            .withOpacity(0.2),
                                                        child: const Icon(
                                                          Icons.person,
                                                          size: 18,
                                                          color: Colors
                                                              .orangeAccent,
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                ),
                                              ),
                                              const SizedBox(height: 16),
                                            ],
                                            if (cleanText.isNotEmpty &&
                                                cleanText.toLowerCase() !=
                                                    "null")
                                              Text(
                                                cleanText,
                                                style: TextStyle(
                                                  color: isDark
                                                      ? Colors.white
                                                      : Colors.black87,
                                                  fontSize: 15,
                                                ),
                                              ),
                                            const SizedBox(height: 16),
                                            _AttachmentList(
                                              attachments:
                                                  msg['all_attachment'],
                                              messageId: messageId,
                                              msg: msg,
                                              company_id: company_id,
                                              isDark: isDark,
                                            ),
                                          ],
                                        ),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context),
                                          child: const Text("Close"),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                              _buildSecretAction(
                                icon: Icons.reply_all_rounded,
                                label: "View & reply",
                                color: Colors.greenAccent,
                                onTap: () {},
                              ),
                              if (isMe) ...[
                                _buildSecretAction(
                                  icon: Icons.person_add_alt_1_outlined,
                                  label: "Add",
                                  color: Colors.orangeAccent,
                                  onTap: () {},
                                ),
                                _buildSecretAction(
                                  icon: Icons.edit_outlined,
                                  label: "Edit",
                                  color: Colors.cyanAccent,
                                  onTap: onEdit ?? () {},
                                ),
                                _buildSecretAction(
                                  icon: Icons.delete_outline,
                                  label: "Delete",
                                  color: Colors.redAccent,
                                  onTap: () {
                                    context.read<ChatBloc>().add(
                                      ChatMessageDeleted(
                                        conversationId: conversationId,
                                        msgId: msgId,
                                        onSuccess: () {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                "Secret message deleted",
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 8),
                        ] else ...[
                          // Regular message content (Text and Attachments)
                          if (cleanText.isNotEmpty &&
                              !cleanText.trim().startsWith('{') &&
                              !cleanText.trim().startsWith('[') &&
                              !cleanText.contains('"location"') &&
                              !cleanText.contains('"originalname"') &&
                              !cleanText.contains('[object Object]') &&
                              cleanText.toLowerCase() != "null")
                            Text(
                              cleanText,
                              style: TextStyle(
                                color: textColor,
                                fontSize: 15,
                                height: 1.5,
                              ),
                            ),
                          _AttachmentList(
                            attachments: msg['all_attachment'],
                            messageId: messageId,
                            msg: msg,
                            company_id: company_id,
                            isDark: isDark,
                          ),
                          if (!isSecret &&
                              (int.tryParse(
                                        msg['has_reply']?.toString() ?? '0',
                                      ) ??
                                      0) >
                                  0)
                            Padding(
                              padding: const EdgeInsets.only(top: 8, bottom: 2),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: isMe
                                      ? Colors.black.withOpacity(0.1)
                                      : Colors.white.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      Icons.forum_outlined,
                                      size: 16,
                                      color: textColor.withOpacity(0.7),
                                    ),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        "Threaded chat (${msg['has_reply']}) • Last reply ${FormatUtils.formatTime(msg['last_reply_time']?.toString())} from ${msg['last_reply_name'] ?? 'Someone'}",
                                        style: TextStyle(
                                          color: textColor.withOpacity(0.9),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          height: 1.4,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                        const SizedBox(height: 8),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (msg['edit_status'] == true)
                              GestureDetector(
                                onTap: () {
                                  if (msg['edit_history'] != null &&
                                      (msg['edit_history'] as List)
                                          .isNotEmpty) {
                                    showDialog(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        backgroundColor: const Color(
                                          0xff1B2335,
                                        ),
                                        title: const Text(
                                          "Edit History",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                          ),
                                        ),
                                        content: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children:
                                              (msg['edit_history'] as List)
                                                  .map(
                                                    (h) => ListTile(
                                                      title: Text(
                                                        h['msg_body'] ?? "",
                                                        style: const TextStyle(
                                                          color: Colors.white70,
                                                        ),
                                                      ),
                                                      subtitle: Text(
                                                        FormatUtils.formatTime(
                                                          h['updated_at']
                                                              ?.toString(),
                                                        ),
                                                        style: const TextStyle(
                                                          color: Colors.white38,
                                                          fontSize: 10,
                                                        ),
                                                      ),
                                                    ),
                                                  )
                                                  .toList(),
                                        ),
                                      ),
                                    );
                                  }
                                },
                                child: Padding(
                                  padding: const EdgeInsets.only(right: 4),
                                  child: Text(
                                    "Edited",
                                    style: TextStyle(
                                      color: Colors.greenAccent.withOpacity(
                                        0.6,
                                      ),
                                      fontSize: 9,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                              ),
                            Text(
                              FormatUtils.formatTime(
                                msg['created_at']?.toString(),
                              ),
                              style: TextStyle(
                                color: isMe
                                    ? Colors.white70
                                    : (isDark
                                          ? Colors.white60
                                          : Colors.black45),
                                fontSize: 10,
                              ),
                            ),
                            if (isMe) ...[
                              const SizedBox(width: 4),
                              Icon(
                                Icons.done_all,
                                size: 14,
                                color: appTheme.msgStatusIconColor,
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            /// RIGHT SIDE MY IMAGE
            if (isMe) ...[
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () => UserProfilePopup.show(
                  context,
                  name: "You",
                  email: msg['senderemail']?.toString() ?? "me@freeli.io",
                  imageUrl: userImage,
                ),
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: const Color(0xff6C63FF),

                  backgroundImage: userImage.isNotEmpty
                      ? NetworkImage(userImage)
                      : null,

                  child: userImage.isEmpty
                      ? const Icon(Icons.person, color: Colors.white, size: 18)
                      : null,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSecretAction({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.4), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
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

          // Only show files that have a proper location and extension (containing a dot)
          if (location.isEmpty || !location.contains('.'))
            return const SizedBox.shrink();

          // More efficient extension extraction
          final String extension = location
              .split('?')
              .first
              .split('.')
              .last
              .toLowerCase();

          // Identify if the file is an image
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
                // Tag Counter / Index Indicator
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
                          // Unique tag per message attachment
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
            // Non-image file card
            final IconData icon = FileUtils.getFileIcon(location);
            return Padding(
              padding: const EdgeInsets.only(
                bottom: 8,
              ), // Consistent bottom margin for each attachment item
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  tagPopUpListUpdate(context, file, company_id, isDark),
                  _buildIndexStar(context, file),
                  Flexible(
                    child: Container(
                      // Removed margin: const EdgeInsets.only(bottom: 6)
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

          /// Top Right Counter
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

    // Get my ID from the Bloc state
    final myId = context.read<ChatBloc>().state.myId;
    final bool isStarred =
        starList is List && starList.any((id) => id.toString() == myId);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        GestureDetector(
          onTap: () async {
            try {
              final result = await ApiServer().toggleFileStar(fileId: fId);
              final String mId = (msg['msg_id'] ?? msg['id'])?.toString() ?? "";

              if (result.isNotEmpty && context.mounted) {
                context.read<ChatBloc>().add(
                  ChatFileStarred(
                    fileId: fId,
                    msgId: mId,
                    star: result['star'] ?? [],
                  ),
                );
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(e.toString())));
              }
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
              size: 20,
              color: isStarred
                  ? Colors.red
                  : (msg['sender'].toString() ==
                            context.read<ChatBloc>().state.myId
                        ? Colors.white70
                        : context
                              .read<ThemeCubit>()
                              .state
                              .msgReceiverText
                              .withOpacity(0.5)),
            ),
          ),
        ),
      ],
    );
  }
}
