import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter/material.dart';
import '../AppColors.dart';
import '../controller/api/api_service.dart';
import 'ChatSkeleton.dart';

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
  final String myId = "1";
  static const String _cryptoKey = "D1583ED51EEB8E58F2D3317F4839A";
  String conversationId = "";
  String roomTitle = "Chat";
  bool isLoading = true;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null) {
        conversationId = args['conversation_id']?.toString() ?? "";
        roomTitle = args['title']?.toString() ?? "Chat";
        getMessages(conversationId);
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> getMessages(String conversationId) async {
    try {
      final data = await ApiServer().fetchMessages(conversationId);
      setState(() {
        messages = (data['msgs'] as List?)?.reversed.toList() ?? [];
        isLoading = false;
      });
    } catch (e) {
      debugPrint("FETCH ERROR: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  static Map<String, Uint8List> _evpBytesToKey(
    List<int> password,
    List<int> salt,
    int keyLen,
    int ivLen,
  ) {
    List<int> derivedBytes = [];
    List<int> block = [];

    while (derivedBytes.length < (keyLen + ivLen)) {
      final input = <int>[];

      if (block.isNotEmpty) {
        input.addAll(block);
      }

      input.addAll(password);
      input.addAll(salt);
      block = md5.convert(input).bytes;
      derivedBytes.addAll(block);
    }

    return {
      'key': Uint8List.fromList(derivedBytes.sublist(0, keyLen)),
      'iv': Uint8List.fromList(derivedBytes.sublist(keyLen, keyLen + ivLen)),
    };
  }

  dynamic _tryDecodeJson(String value) {
    try {
      return jsonDecode(value);
    } catch (_) {
      return value;
    }
  }

  String _decryptMessage(dynamic encryptedText) {
    try {
      if (encryptedText == null) {
        return "";
      }

      final encrypted = encryptedText.toString();
      if (encrypted.isEmpty) {
        return "";
      }

      final encryptedBytes = base64.decode(encrypted);
      if (encryptedBytes.length < 16) {
        return encrypted;
      }

      final prefix = utf8.decode(encryptedBytes.sublist(0, 8));
      if (prefix != "Salted__") {
        return encrypted;
      }

      final salt = encryptedBytes.sublist(8, 16);
      final ciphertext = encryptedBytes.sublist(16);
      final keyIv = _evpBytesToKey(utf8.encode(_cryptoKey), salt, 32, 16);
      final key = encrypt.Key(keyIv['key']!);
      final iv = encrypt.IV(keyIv['iv']!);
      final encrypter = encrypt.Encrypter(
        encrypt.AES(key, mode: encrypt.AESMode.cbc),
      );

      final decrypted = encrypter.decrypt(
        encrypt.Encrypted(Uint8List.fromList(ciphertext)),
        iv: iv,
      );

      final result = _tryDecodeJson(decrypted);
      return result.toString();
    } catch (e) {
      debugPrint("DECRYPT ERROR: $e");

      return encryptedText.toString();
    }
  }

  String _encryptMessage(dynamic data) {
    try {
      final jsonString = data is String ? data : jsonEncode(data);
      final salt = encrypt.IV.fromSecureRandom(8).bytes;
      final keyIv = _evpBytesToKey(utf8.encode(_cryptoKey), salt, 32, 16);
      final key = encrypt.Key(keyIv['key']!);
      final iv = encrypt.IV(keyIv['iv']!);
      final encrypter = encrypt.Encrypter(
        encrypt.AES(key, mode: encrypt.AESMode.cbc),
      );
      final encrypted = encrypter.encrypt(jsonString, iv: iv);
      final result = Uint8List.fromList([
        ...utf8.encode("Salted__"),
        ...salt,
        ...encrypted.bytes,
      ]);

      return base64.encode(result);
    } catch (e) {
      debugPrint("ENCRYPT ERROR: $e");

      return data.toString();
    }
  }

  String _stripHtml(String text) {
    return text.replaceAll(RegExp(r'<[^>]*>|&[^;]+;'), '');
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    final encryptedText = _encryptMessage(text);
    final newMessage = {
      "sender": myId,
      "sendername": "Me",
      "senderimg":
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

  String _formatTime(String? dateTime) {
    try {
      if (dateTime == null || dateTime.isEmpty) {
        return "";
      }

      final date = DateTime.parse(dateTime).toLocal();

      final hour = date.hour > 12
          ? date.hour - 12
          : date.hour == 0
          ? 12
          : date.hour;

      final minute = date.minute.toString().padLeft(2, '0');

      final amPm = date.hour >= 12 ? "PM" : "AM";

      return "$hour:$minute $amPm";
    } catch (e) {
      return "";
    }
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = AppColors.getBackgroundColor(widget.isDark);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xff111827),
        titleSpacing: 0,
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

              child: const Icon(Icons.forum_rounded, color: Colors.white),
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
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xff0B1120), Color(0xff111827), Color(0xff0F172A)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),

        child: Column(
          children: [
            Expanded(
              child: isLoading
                  ? const ChatSkeleton()
                  : messages.isEmpty
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

                      itemCount: messages.length,

                      itemBuilder: (context, index) {
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
    final decryptedText = _decryptMessage(msg['msg_body']);

    final cleanText = _stripHtml(decryptedText);

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
                            _formatTime(msg['created_at']?.toString()),
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
          color: const Color(0xff111827),
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
