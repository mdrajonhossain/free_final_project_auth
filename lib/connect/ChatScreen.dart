import 'package:flutter/material.dart';
import '../AppColors.dart';
import '../controller/api/api_service.dart';
import 'ChatSkeleton.dart';
import './crypto_utils.dart';
import './format_utils.dart';

class ChatScreen extends StatefulWidget {
  final bool isDark;
  const ChatScreen({super.key, required this.isDark});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<dynamic> messages = [];
  String myId = "";
  Map<String, dynamic>? userData;
  String conversationId = "";
  String roomTitle = "Chat";
  String convImg = "";
  bool isLoading = true;
  int _currentPage = 1;
  bool _isFetchingMore = false;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();

    _scrollController.addListener(_scrollListener);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null) {
        setState(() {
          conversationId = args['conversation_id']?.toString() ?? "";
          roomTitle = args['title']?.toString() ?? "Chat";
          // Added fallbacks for common keys in case 'conv_img' is null
          convImg =
              (args['conv_img'] ?? args['img'] ?? args['image'])?.toString() ??
              "";
        });
        getMessages(conversationId, page: 1);
      }
    });
  }

  void _scrollListener() {
    if (_scrollController.hasClients &&
        _scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 100 &&
        !_isFetchingMore &&
        _hasMore &&
        !isLoading) {
      if (conversationId.isNotEmpty) {
        _currentPage++;
        getMessages(conversationId, page: _currentPage);
      }
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> getMessages(String conversationId, {int page = 1}) async {
    if (page > 1) {
      setState(() => _isFetchingMore = true);
    }
    try {
      // Dynamically fetch current user info to distinguish 'Me' from others
      if (myId.isEmpty) {
        userData = await ApiServer().fetchMe();
        myId = userData?['id']?.toString() ?? "";
      }

      final data = await ApiServer().fetchMessages(conversationId, page: page);
      final List newMsgs = (data['msgs'] as List?)?.reversed.toList() ?? [];

      setState(() {
        if (page == 1) {
          messages = newMsgs;
        } else {
          messages.addAll(newMsgs);
        }
        if (newMsgs.isEmpty) {
          _hasMore = false;
        }
        isLoading = false;
        _isFetchingMore = false;
      });
    } catch (e) {
      debugPrint("FETCH ERROR: $e");
      setState(() {
        isLoading = false;
        _isFetchingMore = false;
      });
    }
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    final encryptedText = CryptoUtils.encryptMessage(text);
    final newMessage = {
      "sender": myId,
      "sendername":
          "${userData?['firstname'] ?? 'Me'} ${userData?['lastname'] ?? ''}"
              .trim(),
      "senderimg":
          userData?['img'] ??
          "https://wfss001.freeli.io/profile-pic/Photos/corporate-company-logo-png_seeklogo-425925@1764655943904.png",
      "msg_body": encryptedText,
      "created_at": DateTime.now().toIso8601String(),
    };

    setState(() {
      messages.insert(0, newMessage);
    });

    _messageController.clear();

    Future.delayed(const Duration(milliseconds: 100), () {
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
    final bgColor = AppColors.getBackgroundColor(widget.isDark);

    if (isLoading)
      return const Scaffold(
        backgroundColor: Color(0xff0B1120),
        body: ChatSkeleton(),
      );

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors
            .transparent, // Set to transparent to show the flexibleSpace gradient
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient:
                AppColors.primaryGradient, // Use the full primary gradient
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: -5,
        title: Row(
          children: [
            Container(
              height: 42,
              width: 42,

              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),

                gradient: const LinearGradient(
                  colors: [Color(0xff7C5CFF), Color(0xff5B4DFF)],
                ),
              ),

              child: convImg.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.network(
                        convImg,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(
                              Icons.forum_rounded,
                              color: Colors.white,
                            ),
                      ),
                    )
                  : const Icon(Icons.forum_rounded, color: Colors.white),
            ),

            const SizedBox(width: 12),

            Expanded(
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
                    "Secure conversation",
                    style: TextStyle(color: Colors.white54, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: AppColors
                .primaryGradient
                .colors, // Use primary gradient for body background
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),

        child: Column(
          children: [
            Expanded(
              child: messages.isEmpty
                  ? const Center(
                      child: Text(
                        "No messages found",
                        style: TextStyle(color: Colors.white54),
                      ),
                    )
                  : ListView.builder(
                      reverse: true,
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 16,
                      ),
                      itemCount: messages.length + (_isFetchingMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == messages.length) {
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
                        final msg = messages[index];
                        final isMe = msg['sender'].toString() == myId;
                        return _messageBubble(msg, isMe);
                      },
                    ),
            ),

            _inputBox(),
          ],
        ),
      ),
    );
  }

  Widget _messageBubble(dynamic msg, bool isMe) {
    final decryptedText = CryptoUtils.decryptMessage(msg['msg_body']);

    final cleanText = FormatUtils.stripHtml(decryptedText);

    final userImage = msg['senderimg']?.toString() ?? "";

    return Padding(
      padding: EdgeInsets.only(
        bottom: 18,
        right: isMe ? 10 : 0,
        left: isMe ? 0 : 10,
      ),

      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,

        mainAxisAlignment: isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,

        children: [
          /// LEFT SIDE USER
          if (!isMe) ...[
            CircleAvatar(
              radius: 18,

              backgroundColor: Colors.white12,

              backgroundImage: userImage.isNotEmpty
                  ? NetworkImage(userImage)
                  : null,

              child: userImage.isEmpty
                  ? const Icon(Icons.person, color: Colors.white, size: 18)
                  : null,
            ),
            const SizedBox(width: 10),
          ],

          Flexible(
            child: Column(
              crossAxisAlignment: isMe
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,

              children: [
                /// OTHER USER NAME
                if (!isMe)
                  Padding(
                    padding: const EdgeInsets.only(left: 6, bottom: 4),

                    child: Text(
                      msg['sendername']?.toString() ?? "User",

                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
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
                    gradient: isMe
                        ? const LinearGradient(
                            colors: [Color(0xff7C5CFF), Color(0xff5B4DFF)],
                          )
                        : null,
                    color: isMe ? null : Colors.white.withOpacity(0.07),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(22),
                      topRight: const Radius.circular(22),
                      bottomLeft: Radius.circular(isMe ? 22 : 6),
                      bottomRight: Radius.circular(isMe ? 6 : 22),
                    ),
                    border: Border.all(color: Colors.white.withOpacity(0.05)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.12),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cleanText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            FormatUtils.formatTime(
                              msg['created_at']?.toString(),
                            ),
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.65),
                              fontSize: 10,
                            ),
                          ),
                          if (isMe) ...[
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.done_all,
                              size: 14,
                              color: Colors.white70,
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
            CircleAvatar(
              radius: 18,
              backgroundColor: const Color(0xff6C63FF),

              backgroundImage: userImage.isNotEmpty
                  ? NetworkImage(userImage)
                  : null,

              child: userImage.isEmpty
                  ? const Icon(Icons.person, color: Colors.white, size: 18)
                  : null,
            ),
          ],
        ],
      ),
    );
  }

  Widget _inputBox() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
        decoration: BoxDecoration(
          color:
              AppColors.primaryGradient.colors[0], // Consistent with home page
          border: Border(
            top: BorderSide(color: Colors.white.withOpacity(0.05)),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.white.withOpacity(0.04)),
                ),
                child: TextField(
                  controller: _messageController,
                  style: const TextStyle(color: Colors.white, fontSize: 15),
                  minLines: 1,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    hintText: "Type message...",
                    hintStyle: TextStyle(color: Colors.white38),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 14,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(width: 12),
            GestureDetector(
              onTap: _sendMessage,
              child: Container(
                height: 54,
                width: 54,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: const LinearGradient(
                    colors: [Color(0xff7C5CFF), Color(0xff5B4DFF)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xff6C63FF).withOpacity(0.4),
                      blurRadius: 14,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.send_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
