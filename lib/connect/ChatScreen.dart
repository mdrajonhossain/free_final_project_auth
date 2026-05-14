import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freeli/controller/api/api_service.dart';
import '../controller/stateBloc/message/chat_bloc.dart';
import '../AppColors.dart';
import 'ChatSkeleton.dart';
import './crypto_utils.dart';
import './format_utils.dart';
import './file_utils.dart';
import './chat_service.dart';
import './attchmentPopup.dart';
import './ChatInput.dart';
import './chatMore_Screen.dart';
import './chatFilter_Screen.dart';
import './UserProfilePopup.dart';
import './FullImageViewer.dart';

class ChatScreen extends StatefulWidget {
  final bool isDark;
  const ChatScreen({super.key, required this.isDark});

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
  String roomTitle = "Chat";
  String convImg = "";

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
          company_id = args['company_id']?.toString() ?? "";
          participants = args['participants'];
          roomTitle = args['title']?.toString() ?? "Chat";
          // Added fallbacks for common keys in case 'conv_img' is null
          convImg =
              (args['conv_img'] ?? args['img'] ?? args['image'])?.toString() ??
              "";
          _chatBloc.add(ChatFetchRequested(conversationId));
        });
      }
    });
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
    final bgColor = AppColors.getBackgroundColor(widget.isDark);

    return BlocBuilder<ChatBloc, ChatState>(
      builder: (context, state) {
        if (state.isLoading) {
          return const Scaffold(
            backgroundColor: Color(0xff0B1120),
            body: ChatSkeleton(),
          );
        }

        return Scaffold(
          backgroundColor: bgColor,
          appBar: AppBar(
            elevation: 0,
            backgroundColor: Colors.transparent,
            flexibleSpace: Container(
              decoration: const BoxDecoration(
                gradient: AppColors.primaryGradient,
              ),
            ),
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
                  onTap: () {
                    print("Call button tapped");
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
                  onTap: () => ChatFilterScreen.show(context),
                  child: Container(
                    margin: const EdgeInsets.only(left: 8),
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.filter_alt_sharp,
                      size: 28,
                      color: Colors.white70,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => ChatMoreScreen.show(context),
                  child: Container(
                    margin: const EdgeInsets.only(left: 8),
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.more_vert,
                      size: 28,
                      color: Colors.white70,
                    ),
                  ),
                ),
              ],
            ),
          ),
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: AppColors.primaryGradient.colors,
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Column(
              children: [
                Expanded(
                  child: state.messages.isEmpty
                      ? _buildEmptyMessages()
                      : _buildMessageList(state),
                ),
                ChatInput(
                  controller: _messageController,
                  onSend: _sendMessage,
                  companyId: company_id,
                  userEmail: state.userData?['email'],
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
  }

  Widget _buildRoomImage() {
    return Container(
      height: 42,
      width: 42,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: const LinearGradient(
          colors: [
            Color.fromARGB(255, 6, 180, 157),
            Color.fromARGB(255, 6, 180, 157),
          ],
        ),
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
    return const Center(
      child: Text("No messages found", style: TextStyle(color: Colors.white54)),
    );
  }

  Widget _buildMessageList(ChatState state) {
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
          isMe: isMe,
        );
      },
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final dynamic msg;
  final bool isMe;

  const _MessageBubble({super.key, required this.msg, required this.isMe});

  @override
  Widget build(BuildContext context) {
    // Decryption and formatting happen only when this specific bubble builds
    String decryptedText = "";
    try {
      decryptedText = CryptoUtils.decryptMessage(msg['msg_body'] ?? '');
    } catch (e) {
      // Fallback if decryption fails (e.g. invalid base64 or plain text)
      decryptedText = (msg['msg_body'] ?? '').toString();
    }

    final String cleanText = FormatUtils.stripHtml(decryptedText);
    final String userImage = msg['senderimg']?.toString() ?? "";

    final screenWidth = MediaQuery.of(context).size.width;

    return Padding(
      padding: EdgeInsets.only(
        bottom: 18,
        right: isMe ? 10 : 0,
        left: isMe ? 0 : 10,
      ),

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
                      email: msg['senderemail']?.toString() ?? "user@freeli.io",
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
                        color: Colors.white60,
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
                    gradient: isMe
                        ? const LinearGradient(
                            colors: [
                              Color.fromARGB(42, 129, 138, 137),
                              Color.fromARGB(42, 129, 138, 137),
                            ],
                          )
                        : null,
                    color: isMe ? null : Colors.white.withOpacity(0.07),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(isMe ? 22 : 6),
                      topRight: Radius.circular(isMe ? 6 : 22),
                      bottomLeft: const Radius.circular(22),
                      bottomRight: const Radius.circular(22),
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
                      // Filter out technical JSON strings or object data indicators
                      if (cleanText.isNotEmpty &&
                          !cleanText.trim().startsWith('{') &&
                          !cleanText.trim().startsWith('[') &&
                          !cleanText.contains('"location"') &&
                          !cleanText.contains('"originalname"') &&
                          !cleanText.contains('[object Object]') &&
                          cleanText.toLowerCase() != "null")
                        Text(
                          cleanText,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            height: 1.5,
                          ),
                        ),
                      _AttachmentList(
                        attachments: msg['all_attachment'],
                        messageId:
                            msg['msg_id']?.toString() ??
                            msg['id']?.toString() ??
                            'unknown',
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
    );
  }
}

class _AttachmentList extends StatelessWidget {
  final dynamic attachments;
  final String messageId;

  const _AttachmentList({required this.attachments, required this.messageId});

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
                    _buildIndexTag(file['tag_list']),
                    const SizedBox(height: 8),
                    _buildIndexStar(index),
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
                          tag: "hero-$messageId-$index-$fullUrl",
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
                  _buildIndexStar(index),
                  _buildIndexTag(file['tag_list']),
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

  Widget _buildIndexTag(dynamic tagList) {
    return Stack(
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
                (tagList is List ? tagList.length : 0).toString(),
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
    );
  }

  Widget _buildIndexStar(int index) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Color.fromARGB(179, 38, 28, 134),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white12),
          ),
          child: const Icon(
            Icons.star_rounded,
            size: 20,
            color: Color.fromARGB(255, 245, 245, 247),
          ),
        ),
      ],
    );
  }
}
