import 'package:flutter/material.dart';
import '../controller/api/api_service.dart';
import '../AppColors.dart';
import 'dart:ui';
import 'dart:convert';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart' as encrypt;

class ChatScreen extends StatefulWidget {
  final bool isDark;
  const ChatScreen({super.key, required this.isDark});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  List<dynamic> messages = [];
  bool isLoading = true;
  String? conversationId;
  String? title;
  final TextEditingController _messageController = TextEditingController();
  String? myId;

  @override
  void initState() {
    super.initState();
    _loadMyId();
  }

  Future<void> _loadMyId() async {
    try {
      final data = await ApiServer().fetchMe();
      setState(() {
        myId = data['id'];
      });
    } catch (e) {
      debugPrint("Error loading my ID: $e");
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null && conversationId == null) {
      conversationId = args['conversation_id'];
      title = args['title'];
      _loadMessages();
    }
  }

  /// Decrypts the message body.
  /// Currently returns the text if decryption fails or logic is pending.
  String _decryptMessage(String? encryptedText) {
    if (encryptedText == null || encryptedText.isEmpty) return "";

    try {
      // Ensure these keys are identical to the raw keys used in your React project.
      // If React uses a passphrase string, you must derive the key/iv using a KDF.
      final key = encrypt.Key.fromUtf8(
        'my32charssecretkeyfor-aes256-123',
      ); // 32 characters
      final iv = encrypt.IV.fromUtf8('1234567890123456'); // 16 characters

      final encrypter = encrypt.Encrypter(
        encrypt.AES(key, mode: encrypt.AESMode.cbc, padding: 'PKCS7'),
      );

      // Check if the text has the OpenSSL "Salted__" header (common with CryptoJS)
      if (encryptedText.startsWith("U2FsdGVkX1")) {
        final Uint8List encryptedBytes = base64.decode(encryptedText);

        // Standard OpenSSL format: "Salted__" (8 bytes) + Salt (8 bytes) = 16 bytes total header.
        // The actual encrypted data blocks start from index 16.
        final Uint8List ciphertextOnly = encryptedBytes.sublist(16);

        final decrypted = encrypter.decrypt(
          encrypt.Encrypted(ciphertextOnly),
          iv: iv,
        );
        return decrypted.trim();
      } else {
        // Fallback for standard base64 strings without the "Salted__" header
        final decrypted = encrypter.decrypt64(encryptedText, iv: iv);
        return decrypted.trim();
      }
    } catch (e) {
      debugPrint("Decryption error for message: $e");
      return encryptedText;
    }
  }

  Future<void> _loadMessages() async {
    if (conversationId == null) return;
    try {
      setState(() => isLoading = true);
      final data = await ApiServer().fetchMessages(conversationId!);
      setState(() {
        messages = data['msgs'] ?? [];
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      print("Error fetching messages: $e");
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || conversationId == null) return;

    // Optimistic UI update: add message locally
    final newMessage = {
      'sender': myId,
      'msg_body': text,
      'created_at': DateTime.now().toIso8601String(),
      'sendername': 'Me',
    };

    setState(() {
      messages.insert(0, newMessage); // Optimistic UI update
      _messageController.clear();
    });

    try {
      // TODO: Implement your mutation call here
      // await ApiServer().sendMessage(conversationId!, text);
    } catch (e) {
      debugPrint("Error sending message: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = AppColors.getBackgroundColor(widget.isDark);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 12, 31, 94),
        elevation: 0,
        title: Text(
          title ?? "Chat",
          style: const TextStyle(color: Colors.white, fontSize: 18),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.white24),
                  )
                : messages.isEmpty
                ? const Center(
                    child: Text(
                      "No messages yet",
                      style: TextStyle(color: Colors.white54),
                    ),
                  )
                : ListView.builder(
                    reverse: true, // Show latest messages at the bottom
                    padding: const EdgeInsets.all(16),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final msg = messages[index];
                      // Compare current sender ID with my loaded ID
                      final bool isMe = msg['sender'] == myId;

                      return _buildMessageBubble(msg, isMe);
                    },
                  ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(dynamic msg, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isMe
              ? AppColors.accentColor.withOpacity(0.8)
              : Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 0),
            bottomRight: Radius.circular(isMe ? 0 : 16),
          ),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isMe)
              Text(
                msg['sendername'] ?? "User",
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            const SizedBox(height: 2),
            Text(
              _decryptMessage(msg['msg_body']),
              style: const TextStyle(color: Colors.white, fontSize: 15),
            ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.bottomRight,
              child: Text(
                _formatTime(msg['created_at']),
                style: TextStyle(
                  color: isMe ? Colors.white70 : Colors.white38,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05))),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: TextField(
                  controller: _messageController,
                  style: const TextStyle(color: Colors.white, fontSize: 15),
                  decoration: const InputDecoration(
                    hintText: "Type a message...",
                    hintStyle: TextStyle(color: Colors.white38),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: const BoxDecoration(
                gradient: AppColors.primaryGradient,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.send, color: Colors.white, size: 20),
                onPressed: _sendMessage,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(String? isoString) {
    if (isoString == null) return "";
    try {
      DateTime dt = DateTime.parse(isoString);
      return "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
    } catch (e) {
      return "";
    }
  }
}
