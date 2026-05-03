import 'dart:convert';
import 'dart:typed_data';

import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter/material.dart';
import 'package:crypto/crypto.dart';

import '../AppColors.dart';
import '../controller/api/api_service.dart';

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

  /// SAME KEY AS BACKEND
  static const String _cryptoKey = "D1583ED51EEB8E58F2D3317F4839A";

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

  /// FETCH MESSAGES
  void getMessages(String conversationId) async {
    var data = await ApiServer().fetchMessages(conversationId);

    setState(() {
      messages = (data['msgs'] as List?)?.reversed.toList() ?? [];
    });
  }

  /// OPENSSL EVP BYTES TO KEY
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

  /// TRY JSON DECODE
  dynamic _tryDecodeJson(String value) {
    try {
      return jsonDecode(value);
    } catch (_) {
      return value;
    }
  }

  /// DECRYPT MESSAGE
  String _decryptMessage(dynamic encryptedText) {
    try {
      if (encryptedText == null) return "";

      final encrypted = encryptedText.toString();

      if (encrypted.isEmpty) return "";

      final encryptedBytes = base64.decode(encrypted);

      /// CHECK OPENSSL PREFIX
      final prefix = utf8.decode(encryptedBytes.sublist(0, 8));

      if (prefix != "Salted__") {
        return encrypted;
      }

      /// EXTRACT SALT
      final salt = encryptedBytes.sublist(8, 16);

      /// EXTRACT CIPHERTEXT
      final ciphertext = encryptedBytes.sublist(16);

      /// GENERATE KEY + IV
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

  /// STRIP HTML TAGS
  String _stripHtml(String text) {
    return text.replaceAll(RegExp(r'<[^>]*>|&[^;]+;'), '');
  }

  /// ENCRYPT MESSAGE (OpenSSL Compatible)
  String _encryptMessage(dynamic data) {
    try {
      final jsonString = data is String ? data : jsonEncode(data);

      // Generate a random 8-byte salt
      final salt = encrypt.IV.fromSecureRandom(8).bytes;

      // Derive Key and IV using the same logic as Decryption
      final keyIv = _evpBytesToKey(utf8.encode(_cryptoKey), salt, 32, 16);
      final key = encrypt.Key(keyIv['key']!);
      final iv = encrypt.IV(keyIv['iv']!);

      final encrypter = encrypt.Encrypter(
        encrypt.AES(key, mode: encrypt.AESMode.cbc),
      );
      final encrypted = encrypter.encrypt(jsonString, iv: iv);

      // Format: "Salted__" + salt + ciphertext
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
          cleanText,
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

                final encryptedText = _encryptMessage(text);

                setState(() {
                  messages.insert(0, {
                    "sender": myId,
                    "sendername": "Me",
                    "msg_body": encryptedText,
                    "created_at": DateTime.now().toIso8601String(),
                  });
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
