import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freeli/connect/roomFilter.dart';
import 'package:freeli/controller/api/api_service.dart';
import 'package:freeli/controller/api/xmpp_server.dart';
import 'package:freeli/controller/stateBloc/message/chat_bloc.dart';
import 'AppColors.dart';
import 'package:freeli/config/config.dart';
import 'connect/ChatsTab.dart';
import 'connect/CallsTab.dart';
import 'connect/DashboardTab.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'AppDrawer.dart';
import 'dart:ui';
import 'package:freeli/connect/crypto_utils.dart';
import 'dart:convert';

class HomePage extends StatefulWidget {
  final bool isDark;
  final Function(bool) onThemeChange;

  const HomePage({
    super.key,
    required this.isDark,
    required this.onThemeChange,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Map<String, dynamic>? userData;
  List<dynamic>? conversationRooms;
  bool isLoading = true;
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    getMeData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> getMeData() async {
    try {
      setState(() => isLoading = true);
      final data = await ApiServer().fetchMe();
      print(data);
      setState(() {
        userData = data;
        isLoading = false;
      });
      if (data['id'] != null) {
        getRooms(data['id']);
        _initXmpp(data['id'].toString());
      }
    } catch (e) {
      setState(() => isLoading = false);
      print("Error fetching user data: $e");
    }
  }

  void _initXmpp(String userId) async {
    final xmpp = XmppService(server: AppConfig.xmppDomain);
    final token = ApiServer.token;

    if (token != null) {
      final success = await xmpp.initialize(userId: userId, token: token);
      if (success) {
        print('Jam server connected and registered successfully.');
        xmpp.messages.listen((msg) {
          Map<String, dynamic> formattedMsg;
          Map<String, dynamic> chatBlocFormattedMsg;
          bool hasPayloadConvId = false;

          // Normalize IDs: extract UUID from JID (handle user$$$token@domain format)
          String senderJid = msg.from.split('/').first;
          String cleanSenderId = _getCleanId(senderJid);

          try {
            // 1. Normalize formatting
            formattedMsg = _formatDefaultMessage(msg);
            if (formattedMsg['conversation_id'] != null) {
              hasPayloadConvId = true;
            }

            if (msg.data is Map) {
              final Map<String, dynamic> rawData = (msg.data['data'] is Map)
                  ? Map<String, dynamic>.from(msg.data['data'])
                  : Map<String, dynamic>.from(msg.data);

              if (rawData.containsKey('conversation_id') &&
                  rawData['conversation_id'] != null) {
                hasPayloadConvId = true;
              }

              rawData.forEach((key, value) {
                formattedMsg[key] = _cleanJsonValue(value);
              });

              final incomingType =
                  formattedMsg['fcm_type']?.toString() ??
                  formattedMsg['xmpp_type']?.toString() ??
                  msg.type;

              if (incomingType == 'chat' || incomingType == 'new_message') {
                formattedMsg['msg_type'] = 'chat';
              }
            }

            // Ensure basic routing fields exist
            formattedMsg['conversation_id'] ??= cleanSenderId;
            formattedMsg['msg_body'] ??= formattedMsg['body'] ?? msg.body;
            formattedMsg['sender'] ??= cleanSenderId;

            // Force 'new_message' internally for notification/list logic
            formattedMsg['type'] = 'new_message';

            print('🔔 XMPP Message Processed: ${formattedMsg['msg_id']}');
          } catch (e) {
            print('❌ Error parsing XMPP message: $e');
            return;
          }

          // For Bloc and List state, keep msg_body ENCRYPTED as it comes from XMPP.
          // Bubbles in ChatScreen and snippet in ChatsTab will handle decryption.
          chatBlocFormattedMsg = Map<String, dynamic>.from(formattedMsg);

          if (mounted) {
            context.read<ChatBloc>().add(
              ChatXmppMessageReceived(chatBlocFormattedMsg),
            );

            // Update the conversation list UI (Last Message & Reordering)
            setState(() {
              if (conversationRooms != null) {
                final String convId = chatBlocFormattedMsg['conversation_id']
                    .toString();
                final String sender = chatBlocFormattedMsg['sender'].toString();

                // Strict search for room list update.
                // 1. If payload has conversation_id, match strictly by ID.
                // 2. If not (Direct Message fallback), match non-group rooms by sender participant.
                final int index = conversationRooms!.indexWhere(
                  (room) =>
                      room['conversation_id']?.toString() == convId ||
                      room['id']?.toString() == convId ||
                      (!hasPayloadConvId &&
                          room['group'] != 'yes' &&
                          room['participants']?.toString().contains(sender) ==
                              true),
                );

                if (index != -1) {
                  final updatedRoom = Map<String, dynamic>.from(
                    conversationRooms![index],
                  );

                  // Update snippet
                  updatedRoom['last_msg'] = chatBlocFormattedMsg['msg_body'];
                  updatedRoom['last_msg_time'] =
                      chatBlocFormattedMsg['created_at']?.toString() ??
                      DateTime.now().toIso8601String();

                  // Remove and insert at top to show most recent first
                  conversationRooms!.removeAt(index);
                  conversationRooms!.insert(0, updatedRoom);
                }
              }
            });
          }
        });
      }
    }
  }

  String _getCleanId(String jid) {
    // Extract local part, then strip JWT if present (user$$$token@domain)
    String local = jid.split('@').first;
    return local.split('\$\$\$').first;
  }

  dynamic _cleanJsonValue(dynamic value) {
    // Handles cases where strings are double-encoded with quotes
    if (value is String && value.startsWith('"') && value.endsWith('"')) {
      try {
        return jsonDecode(value);
      } catch (_) {
        return value;
      }
    }
    return value;
  }

  Map<String, dynamic> _formatDefaultMessage(XmppMessage msg) {
    String? convId;
    if (msg.data is Map) {
      convId = msg.data['conversation_id']?.toString();
    }
    return {
      "msg_id": msg.id,
      "conversation_id": convId,
      "sender": msg.from.split('@').first,
      "msg_body": msg.body,
      "created_at": msg.timestamp.toIso8601String(),
      "msg_type": msg.type,
      "data": msg.data,
    };
  }

  Future<void> getRooms(String userId) async {
    try {
      final data = await ApiServer().fetchRooms(userId);
      setState(() {
        conversationRooms = data['rooms'];
      });
    } catch (e) {
      print("Error fetching rooms: $e");
    }
  }

  Future<void> _handleLogout() async {
    await ApiServer.clearAuthToken();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, "/login", (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = AppColors.getBackgroundColor(widget.isDark);

    List<dynamic>? filteredRooms = conversationRooms;

    // Category Filtering Logic
    if (_selectedFilter != 'all') {
      final myId = userData?['id']?.toString();
      filteredRooms = filteredRooms?.where((room) {
        final creatorId = room['created_by']?.toString();
        final isGroup = room['group'] == 'yes';

        switch (_selectedFilter) {
          case 'me':
            return creatorId == myId;
          case 'others':
            return creatorId != myId;
          case 'rooms':
            return isGroup;
          case 'direct':
            return !isGroup;
          default:
            return true;
        }
      }).toList();
    }

    // Search Filtering Logic
    if (_isSearching && _searchController.text.isNotEmpty) {
      filteredRooms = filteredRooms?.where((room) {
        final title = room['title']?.toString().toLowerCase() ?? "";
        return title.contains(_searchController.text.toLowerCase());
      }).toList();
    }

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: bgColor,
        endDrawer: AppDrawer(
          isDark: widget.isDark,
          onThemeChange: widget.onThemeChange,
          userData: userData,
          onLogout: _handleLogout,
        ),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0C1F5E),
          elevation: 0,
          title: _isSearching
              ? TextField(
                  controller: _searchController,
                  autofocus: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: "Search...",
                    hintStyle: TextStyle(color: Colors.white60),
                    border: InputBorder.none,
                  ),
                  onChanged: (value) => setState(() {}),
                )
              : Image.asset('assets/logo.webp', height: 45),
          actions: [
            IconButton(
              icon: Icon(_isSearching ? Icons.close : Icons.search),
              onPressed: () => setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) _searchController.clear();
              }),
            ),
            Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => Scaffold.of(context).openEndDrawer(),
              ),
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: "Chats"),
              Tab(text: "Calls"),
              Tab(text: "Dashboard"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            ChatsTab(
              conversationRooms: filteredRooms,
              userMe: userData?['id']?.toString(),
            ),
            CallsTab(
              conversationRooms: filteredRooms,
              userMe: userData?['id']?.toString(),
            ),
            DashboardTab(userMe: userData),
          ],
        ),
      ),
    );
  }
}
