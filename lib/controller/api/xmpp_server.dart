import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:freeli/config/config.dart';
import 'package:freeli/controller/api/api_service.dart';
import 'package:freeli/model/modelScreema_quary.dart';

enum XmppConnectionState {
  disconnected,
  connecting,
  authenticating,
  authenticated,
  online,
  error,
}

class XmppService {
  final String server;

  XmppService({required this.server});

  WebSocket? _socket;

  late String _username;
  late String _domain;
  late String _jid;

  final String _password = 'a123456';

  bool _isConnected = false;
  bool _isAuthenticated = false;
  bool _saslDone = false;
  bool _isBound = false;

  final _stateController = StreamController<XmppConnectionState>.broadcast();
  final _messageController = StreamController<XmppMessage>.broadcast();

  Function(XmppMessage)? onMessageReceived;

  // ---------------- STREAMS ----------------

  Stream<XmppConnectionState> get connectionState => _stateController.stream;

  Stream<XmppMessage> get messages => _messageController.stream;

  bool get isOnline => _isConnected && _isAuthenticated && _isBound;

  void _setState(XmppConnectionState state) {
    print("🔄 STATE → $state");
    _stateController.add(state);
  }

  // ---------------- FAKE REGISTER (REPLACE WITH YOUR API LATER) ----------------

  Future<Map<String, dynamic>> registerUser({
    required String userId,
    required String token,
  }) async {
    try {
      final data = await ApiServer.call(
        xmppRegisterUserQuery,
        variables: {"user_id": userId, "token": token},
      );

      final result = data['xmpp_register_user'];
      if (result != null) {
        final bool isSuccess =
            result['status'] == "success" || result['status'] == true;
        return {
          "status": isSuccess,
          "xmpp_user": result['xmpp_user'],
          "xmpp_domain": result['xmpp_domain'],
        };
      }
      return {"status": false};
    } catch (e) {
      print("XMPP Registration Error: $e");
      return {"status": false};
    }
  }

  // ---------------- INIT ----------------

  Future<bool> initialize({
    required String userId,
    required String token,
  }) async {
    final res = await registerUser(userId: userId, token: token);

    if (res["status"] != true) return false;

    return connect(username: res["xmpp_user"], domain: res["xmpp_domain"]);
  }

  // ---------------- CONNECT ----------------

  Future<bool> connect({
    required String username,
    required String domain,
  }) async {
    try {
      _username = username;
      _domain = domain;
      _jid = "$username@$domain";

      _setState(XmppConnectionState.connecting);

      final wsUrl = _buildWsUrl(domain);

      print("🌐 CONNECT → $wsUrl");

      _socket = await WebSocket.connect(wsUrl);

      _isConnected = true;

      _socket!.listen(
        _handle,
        onDone: _disconnect,
        onError: (e) {
          print("❌ ERROR: $e");
          _reset();
          _setState(XmppConnectionState.error);
        },
      );

      _setState(XmppConnectionState.authenticating);

      _sendOpen();

      return true;
    } catch (e) {
      print("CONNECT ERROR: $e");
      _reset();
      _setState(XmppConnectionState.error);
      return false;
    }
  }

  // ---------------- BUILD WS URL ----------------

  String _buildWsUrl(String domain) {
    final String clean = domain
        .replaceAll("https://", "")
        .replaceAll("http://", "")
        .replaceAll("wss://", "")
        .replaceAll("ws://", "")
        .replaceAll(RegExp(r":\d+"), "");

    return "wss://$clean:5443/ws";
  }

  // ---------------- HANDLE STREAM ----------------

  void _handle(dynamic data) {
    final xml = data.toString();
    print("📥 RAW XMPP DATA: $xml"); // সব ধরণের ইনকামিং র-ডেটা প্রিন্ট হবে

    if (xml.contains("<stream:features")) {
      if (!_isAuthenticated && !_saslDone) {
        _sendSasl();
      } else if (_isAuthenticated && !_isBound) {
        _sendBind();
      }
      return;
    }

    if (xml.contains("<success")) {
      _isAuthenticated = true;
      _saslDone = true;

      _setState(XmppConnectionState.authenticated);
      _sendRestart();
      return;
    }

    if (xml.contains("<iq") && xml.contains("bind")) {
      _isBound = true;

      _setState(XmppConnectionState.online);
      _sendPresence();
      return;
    }

    if (xml.contains("<message")) {
      _parseMessage(xml);
    }
  }

  // ---------------- SASL ----------------

  void _sendSasl() {
    final raw = "\x00$_username\x00$_password";
    final encoded = base64Encode(utf8.encode(raw));

    _socket?.add(
      '<auth xmlns="urn:ietf:params:xml:ns:xmpp-sasl" mechanism="PLAIN">$encoded</auth>',
    );

    print("📤 SASL SENT");
  }

  // ---------------- FLOW ----------------

  void _sendOpen() {
    _socket?.add(
      '<open xmlns="urn:ietf:params:xml:ns:xmpp-framing" to="$_domain" version="1.0"/>',
    );
  }

  void _sendRestart() {
    _socket?.add(
      '<open xmlns="urn:ietf:params:xml:ns:xmpp-framing" to="$_domain" version="1.0"/>',
    );
  }

  void _sendBind() {
    final id = "bind_${DateTime.now().millisecondsSinceEpoch}";

    _socket?.add('''
<iq type='set' id='$id'>
  <bind xmlns='urn:ietf:params:xml:ns:xmpp-bind'>
    <resource>flutter</resource>
  </bind>
</iq>
''');
  }

  void _sendPresence() {
    _socket?.add("<presence/>");
  }

  // ---------------- MESSAGE PARSER ----------------

  void _parseMessage(String xml) {
    // Use dotAll: true to capture bodies that span multiple lines
    final body =
        RegExp(
          r"<body>(.*?)<\/body>",
          dotAll: true,
        ).firstMatch(xml)?.group(1) ??
        "";

    if (body.isEmpty) return;

    final decodedBody = _decode(body);
    dynamic structuredData;
    try {
      // Attempt to parse JSON for file/media metadata or structured text
      structuredData = jsonDecode(decodedBody);
    } catch (_) {
      structuredData = decodedBody;
    }

    final msg = XmppMessage(
      id: _getAttr(xml, "id"),
      from: _getAttr(xml, "from"),
      to: _getAttr(xml, "to"),
      body: decodedBody,
      data: structuredData,
      timestamp: DateTime.now(),
      type: _getAttr(xml, "type"),
    );

    print(
      '✅ Parsed XMPP Message: ${msg.data}',
    ); // পার্স করার পর ডেটা প্রিন্ট হবে

    _messageController.add(msg);
    onMessageReceived?.call(msg);
  }

  String _getAttr(String xml, String key) {
    final match = RegExp('$key=["\']([^"\']*)["\']').firstMatch(xml);
    return match?.group(1) ?? "";
  }

  String _decode(String input) {
    return input
        .replaceAll("&quot;", '"')
        .replaceAll("&amp;", "&")
        .replaceAll("&lt;", "<")
        .replaceAll("&gt;", ">")
        .replaceAll("&#39;", "'");
  }

  // ---------------- RESET ----------------

  void _disconnect() {
    _reset();
    _setState(XmppConnectionState.disconnected);
  }

  void _reset() {
    _isConnected = false;
    _isAuthenticated = false;
    _saslDone = false;
    _isBound = false;
  }

  Future<void> disconnect() async {
    await _socket?.close();
    _socket = null;
    _reset();
  }
}

// ---------------- MODEL ----------------

class XmppMessage {
  final String id;
  final String from;
  final String to;
  final String body;
  final dynamic data; // Support for text or file metadata
  final DateTime timestamp;
  final String type;

  XmppMessage({
    required this.id,
    required this.from,
    required this.to,
    required this.body,
    this.data,
    required this.timestamp,
    required this.type,
  });
}
