import 'package:flutter/material.dart';
import 'package:freeli/controller/api/api_service.dart';
import '../AppColors.dart';

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
  bool isLoading = false;

  final String myId = "1";

  String conversationId = "";
  String roomTitle = "";

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

      if (args != null) {
        setState(() {
          conversationId = args['conversation_id']?.toString() ?? "";
          roomTitle = args['title']?.toString() ?? "Chat Room";
        });
        getMessages(conversationId);
      }
    });
  }

  List msgs = [];
  void getMessages(conversationId) async {
    var data = await ApiServer().fetchMessages(conversationId);
    setState(() {
      messages = data['msgs'] ?? [];
    });
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = AppColors.getBackgroundColor(widget.isDark);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: bgColor,

      appBar: AppBar(
        backgroundColor: const Color(0xff0B1736),
        titleSpacing: 0,

        title: Text(
          roomTitle,
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
      ),

      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xff0B1736), Color(0xff111827), Color(0xff0F172A)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),

        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                reverse: true,
                padding: const EdgeInsets.all(14),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final msg = messages.reversed.toList()[index];

                  final isMe = msg['sender'] == myId;

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
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,

      child: Container(
        margin: const EdgeInsets.only(bottom: 10),

        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),

        decoration: BoxDecoration(
          color: isMe
              ? const Color(0xff6C63FF)
              : Colors.white.withOpacity(0.08),

          borderRadius: BorderRadius.circular(14),
        ),

        child: Text(
          msg['msg_body'] ?? "",
          style: const TextStyle(color: Colors.white, fontSize: 15),
        ),
      ),
    );
  }

  Widget _inputBox() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),

      color: Colors.black.withOpacity(0.2),

      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                style: const TextStyle(color: Colors.white),

                decoration: InputDecoration(
                  hintText: "Type message...",
                  hintStyle: const TextStyle(color: Colors.white38),

                  filled: true,
                  fillColor: Colors.white.withOpacity(0.08),

                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),

            const SizedBox(width: 10),

            GestureDetector(
              onTap: () {
                final text = _messageController.text.trim();

                if (text.isEmpty) return;

                setState(() {
                  messages.insert(0, {
                    "sender": myId,
                    "sendername": "Me",
                    "msg_body": text,
                    "created_at": DateTime.now().toIso8601String(),
                  });
                });

                print("Conversation ID: $conversationId");
                print("Message: $text");

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
              },

              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: Color(0xff6C63FF),
                  shape: BoxShape.circle,
                ),

                child: const Icon(Icons.send, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
