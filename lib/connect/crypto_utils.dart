import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter/foundation.dart';

class CryptoUtils {
  static const String _cryptoKey = "D1583ED51EEB8E58F2D3317F4839A";

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

  static dynamic _tryDecodeJson(String value) {
    try {
      return jsonDecode(value);
    } catch (_) {
      return value;
    }
  }

  static String decryptMessage(dynamic encryptedText) {
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

  static String encryptMessage(dynamic data) {
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
}
