import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freeli/connect/filehubs/Filehubs.dart';
import 'package:freeli/connect/roomFilter.dart';
import 'package:freeli/controller/api/api_service.dart';
import 'package:freeli/controller/api/xmpp_server.dart';
import 'package:freeli/controller/stateBloc/message/chat_bloc.dart';
import 'AppColors.dart';
import 'package:freeli/config/config.dart';
import 'connect/ChatsTab.dart';
import 'connect/CallsTab.dart';
import 'connect/DashboardTab.dart';
import 'connect/jitsi_call_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'AppDrawer.dart';
import 'dart:ui';
import 'package:freeli/connect/crypto_utils.dart';
import 'dart:convert';
import 'IncomingCallPopup.dart';

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
  bool _isCallPopupShowing = false;
  String? _activeConversationId;
  int archiveCount = 0;

  @override
  void initState() {
    super.initState();
    getMeData();
    archiveCounter();
  }

  Future<void> archiveCounter() async {
    try {
      final data = await ApiServer().getArchiveCount();
      setState(() {
        archiveCount = data;
      });
    } catch (e) {
      debugPrint("Error: $e");
    }
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
                formattedMsg['msg_type'] = 'new_message';
              }
            }

            // Ensure basic routing fields exist before signal checks
            formattedMsg['conversation_id'] ??= cleanSenderId;
            formattedMsg['msg_body'] ??= formattedMsg['body'] ?? msg.body;
            formattedMsg['sender'] ??= cleanSenderId;

            // Normalize sender name and image for instant snippet update or call popups
            formattedMsg['sendername'] =
                formattedMsg['sendername'] ??
                formattedMsg['created_by_name'] ??
                formattedMsg['sender_name'] ??
                (formattedMsg['sender']?.toString().split('@').first) ??
                "User";
            formattedMsg['senderimg'] =
                formattedMsg['senderimg'] ??
                formattedMsg['created_by_img'] ??
                formattedMsg['sender_img'] ??
                "";

            // কল সিগন্যাল, টেকনিক্যাল ডেটা বা 'admin' মেসেজ আসলে লিস্ট আপডেট করব না
            final bool isCallSignal =
                formattedMsg['type'] == 'call' ||
                formattedMsg['xmpp_type'] == 'jitsi_ring_calling' ||
                formattedMsg['xmpp_type'] == 'jitsi_ring_send' ||
                formattedMsg['msg_body'].toString().contains('"call_id"');

            if (isCallSignal || formattedMsg['sender'] == 'admin') {
              _handleIncomingCall(formattedMsg);
              return;
            }

            // কল হ্যাংআপ বা রিজেক্ট সিগন্যাল আসলে পপআপ বন্ধ করে দেব
            if (formattedMsg['xmpp_type'] == 'jitsi_send_hangup' ||
                formattedMsg['xmpp_type'] == 'jitsi_call_reject') {
              if (_isCallPopupShowing && mounted) {
                Navigator.of(context, rootNavigator: true).pop();
                setState(() {
                  _isCallPopupShowing = false;
                });
              }
              return;
            }

            // Force 'new_message' internally for notification/list logic
            formattedMsg['type'] = 'new_message';

            print('🔔 XMPP Message Processed: ${formattedMsg['msg_id']}');
          } catch (e) {
            print('❌ Error parsing XMPP message: $e');
            return;
          }

          // Process readable body for instant Last Message snippet
          String displayBody = (formattedMsg['msg_body'] ?? "").toString();
          try {
            String decrypted = CryptoUtils.decryptMessage(displayBody);
            final String trimmed = decrypted.trim();
            if (trimmed.startsWith('{') || trimmed.startsWith('[')) {
              if (trimmed.contains('"sdp"') || trimmed.contains('"call_id"')) {
                displayBody = "📞 Voice/Video Call";
              } else {
                displayBody = "📁 Attachment";
              }
            } else {
              displayBody = decrypted;
            }
          } catch (_) {
            if (displayBody.trim().startsWith('{')) {
              displayBody = "📁 Attachment";
            }
          }

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
                  updatedRoom['last_msg'] =
                      displayBody; // Show readable text instantly
                  updatedRoom['last_msg_time'] =
                      chatBlocFormattedMsg['created_at']?.toString() ??
                      DateTime.now().toIso8601String();

                  // Increment unread count locally for instant UI update
                  int currentUnread =
                      int.tryParse(
                        updatedRoom['unread_count']?.toString() ?? '0',
                      ) ??
                      0;
                  updatedRoom['unread_count'] = (currentUnread + 1).toString();

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

  /// Marks a specific room as read locally and sets it as the active chat
  void _markRoomAsRead(String convId) {
    setState(() {
      _activeConversationId = convId.isEmpty ? null : convId;
      if (conversationRooms != null && convId.isNotEmpty) {
        final index = conversationRooms!.indexWhere(
          (room) => room['conversation_id']?.toString() == convId,
        );
        if (index != -1) {
          conversationRooms![index]['unread_count'] = '0';
        }
      }
    });
  }

  /// Handles incoming call signals by showing a popup dialog
  void _handleIncomingCall(Map<String, dynamic> msg) {
    // Only show popup for actual ringing signals, ignore candidates/SDP packets
    final bool isRingSignal =
        msg['xmpp_type'] == 'jitsi_ring_calling' ||
        msg['xmpp_type'] == 'jitsi_ring_send' ||
        (msg['type'] == 'call' &&
            msg['msg_body'].toString().contains('"call_id"')) ||
        msg['msg_body'].toString().contains('"participants_all"');

    if (!isRingSignal || _isCallPopupShowing || !mounted) return;

    final String convId = msg['conversation_id']?.toString() ?? "";
    // Prioritize user_fullname to ensure the caller's actual name is shown
    final String callerName =
        msg['user_fullname'] ??
        msg['sendername'] ??
        msg['sender_name'] ??
        "Someone";
    final String callerImage = msg['senderimg']?.toString() ?? "";
    final String callType = msg['msg_type'] ?? "audio";
    final String token = msg['token']?.toString() ?? "";

    if (convId.isEmpty) return;

    setState(() => _isCallPopupShowing = true);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => IncomingCallPopup(
        callerName: callerName,
        callerImage: callerImage,
        isVideoCall: callType == 'video' || callType == 'accept',
        onDecline: () {
          Navigator.pop(context);
          setState(() => _isCallPopupShowing = false);
          ApiServer().rejectCall(
            userId: userData?['id']?.toString() ?? "",
            conversationId: convId,
            token: token,
          );
        },
        onAccept: () async {
          Navigator.pop(context);
          setState(() => _isCallPopupShowing = false);

          await JitsiCallService.joinCall(
            context: context,
            userId: userData?['id']?.toString() ?? "",
            companyId: userData?['company_id']?.toString() ?? "",
            conversationId: convId,
            conversationType: callType,
            participants: [],
            roomTitle: callerName,
            userName: userData?['firstname'],
            userEmail: userData?['email'],
            userAvatar: userData?['img']?.toString(),
            isVideo: callType == 'video' || callType == 'accept',
          );
        },
      ),
    );
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

    // Data fetch না হওয়া পর্যন্ত লোডার দেখানো হচ্ছে যাতে null pointer error না হয়
    if (isLoading || userData == null) {
      return Scaffold(
        backgroundColor: bgColor,
        body: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

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

    // Calculate total unread messages from all conversation rooms
    int totalUnread = 0;
    if (conversationRooms != null) {
      for (var room in conversationRooms!) {
        final count = room['unread_count'];
        if (count != null) {
          totalUnread += int.tryParse(count.toString()) ?? 0;
        }
      }
    }

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: bgColor,
        endDrawer: AppDrawer(
          archiveCount: archiveCount,
          isDark: widget.isDark,
          onThemeChange: widget.onThemeChange,
          userData: userData,
          onLogout: _handleLogout,
        ),
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: const Color.fromARGB(255, 12, 31, 94),
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
              icon: Icon(
                _isSearching ? Icons.close : Icons.search,
                color: Colors.white,
              ),
              onPressed: () => setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) _searchController.clear();
              }),
            ),
            Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu, color: Colors.white, size: 28),
                onPressed: () => Scaffold.of(context).openEndDrawer(),
              ),
            ),
          ],
          bottom: TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            dividerColor: Colors.transparent,
            indicator: const UnderlineTabIndicator(
              borderSide: BorderSide(color: Colors.white, width: 2),
            ),

            tabs: [
              Tab(
                icon: Badge(
                  label: Text(totalUnread.toString()),
                  isLabelVisible: totalUnread > 0,
                  child: const Icon(Icons.chat),
                ),
                text: "Chats",
              ),
              const Tab(icon: Icon(Icons.call), text: "Calls"),
              const Tab(icon: Icon(Icons.dashboard), text: "Filehubs"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            ChatsTab(
              conversationRooms: filteredRooms,
              userMe: userData?['id']?.toString(),
              userId: userData?['id']?.toString(),
              companyId: userData?['company_id']?.toString(),
              isDark: widget.isDark,
              onRoomTap: _markRoomAsRead,
            ),
            CallsTab(
              userId: userData?['id']?.toString(),
              companyId: userData?['company_id']?.toString(),
              isDark: widget.isDark,
            ),
            Filehubs(
              isDark: widget.isDark,
              onThemeChange: widget.onThemeChange,
              userMe: userData,
            ),
          ],
        ),
      ),
    );
  }
}
