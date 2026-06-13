import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freeli/connect/filehubs/Filehubs.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:freeli/connect/roomFilter.dart';
import 'package:freeli/controller/api/api_service.dart';
import 'package:freeli/controller/api/xmpp_server.dart';
import 'package:freeli/controller/stateBloc/message/chat_bloc.dart';
import 'package:freeli/config/config.dart';
import 'package:freeli/taskScreen.dart';
import 'connect/ChatsTab.dart';
import 'connect/CallsTab.dart';
import 'connect/jitsi_call_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'AppDrawer.dart';
import 'dart:ui';
import 'package:freeli/connect/crypto_utils.dart';
import 'dart:convert';
import 'IncomingCallPopup.dart';
import 'package:freeli/theme/themeList.dart';
import 'package:freeli/theme/ThemeCubit.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Map<String, dynamic>? userData;
  List<dynamic>? conversationRooms;
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
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
    _setupFirebaseMessaging(); // Call Firebase setup early
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
        _initFirebaseMessaging();
        _initXmpp(data['id'].toString());
      }
    } catch (e) {
      setState(() => isLoading = false);
      print("Error fetching user data: $e");
    }
  }

  /// Sets up Firebase Messaging listeners for foreground and background messages.
  void _setupFirebaseMessaging() {
    // Request permission for notifications
    _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    // Handle messages when the app is in the foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Got a message whilst in the foreground!');
      debugPrint('Message data: ${message.data}');

      // Check if the message is a call notification
      if (message.data['type'] == 'call' ||
          message.data['xmpp_type'] == 'jitsi_ring_calling') {
        _handleFirebaseCallMessage(message.data);
      }
    });

    // Handle messages when the user taps on a notification to open the app
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('A new onMessageOpenedApp event was published!');
      debugPrint('Message data: ${message.data}');

      // Check if the message is a call notification
      if (message.data['type'] == 'call' ||
          message.data['xmpp_type'] == 'jitsi_ring_calling') {
        _handleFirebaseCallMessage(message.data);
      }
    });

    // Handle initial message when the app is launched from a terminated state
    _firebaseMessaging.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        debugPrint('App launched from terminated state by a message!');
        debugPrint('Initial Message data: ${message.data}');
        if (message.data['type'] == 'call' ||
            message.data['xmpp_type'] == 'jitsi_ring_calling') {
          _handleFirebaseCallMessage(message.data);
        }
      }
    });
  }

  /// Initializes Firebase token and associates it with the user.
  /// This is called after user data is fetched.
  void _initFirebaseMessaging() {
    _firebaseMessaging.getToken().then((token) {
      if (token != null) {
        debugPrint("Firebase Messaging Token: $token");
        // Register this token with your backend to enable targeted push notifications
        ApiServer().registerFcmToken(
          userId: userData?['id']?.toString() ?? "",
          token: token,
        );
      }
    });
  }

  /// Parses Firebase message data and calls the existing _handleIncomingCall.
  void _handleFirebaseCallMessage(Map<String, dynamic> data) {
    debugPrint("FCM: Raw incoming message data: $data");

    // Normalize keys to handle both snake_case and camelCase from backend
    final Map<String, dynamic> formattedMsg = {
      'conversation_id':
          data['conversation_id']?.toString() ??
          data['conversationId']?.toString(),
      'user_fullname':
          data['caller_name'] ??
          data['callerName'] ??
          data['sendername'] ??
          "Unknown Caller",
      'sendername':
          data['caller_name'] ??
          data['callerName'] ??
          data['sendername'] ??
          "Unknown Caller",
      'senderimg':
          data['caller_image'] ??
          data['callerImage'] ??
          data['senderimg'] ??
          "",
      'msg_type':
          data['msg_type'] ?? data['call_type'] ?? data['callType'] ?? 'audio',
      'token': data['token'] ?? data['jitsi_token'] ?? data['jitsiToken'] ?? "",
      'xmpp_type':
          data['xmpp_type'] ??
          data['xmppType'] ??
          'jitsi_ring_calling', // Force ring type for Firebase calls
      'type': data['type'] ?? data['msg_type'] ?? 'call',
      'msg_body':
          data['msg_body'] ??
          data['msgBody'] ??
          '{"call_id": "fcm_call"}', // Ensure ring signal passes check
    };

    debugPrint("FCM: Formatted message for _handleIncomingCall: $formattedMsg");
    _handleIncomingCall(formattedMsg);
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

                  // Only increment unread count if the message is from someone else
                  if (sender != userId) {
                    int currentUnread =
                        int.tryParse(
                          updatedRoom['unread_count']?.toString() ?? '0',
                        ) ??
                        0;
                    updatedRoom['unread_count'] = (currentUnread + 1)
                        .toString();
                  }

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
    debugPrint("Handling incoming call signal. Message: $msg");

    final bool isRingSignal =
        msg['xmpp_type'] == 'jitsi_ring_calling' ||
        msg['xmpp_type'] == 'jitsi_ring_send' ||
        (msg['type'] == 'call' &&
            // Check for specific call identifier in msg_body
            msg['msg_body'].toString().contains('"call_id"')) ||
        msg['msg_body'].toString().contains('"participants_all"');

    if (!isRingSignal || _isCallPopupShowing || !mounted) return;

    final String convId = msg['conversation_id']?.toString() ?? "";
    // Prioritize user_fullname to ensure the caller's actual name is shown
    // Added more robust fallback for caller name
    final String callerName =
        msg['user_fullname'] ??
        msg['sendername'] ??
        msg['sender_name'] ??
        msg['caller_name'] ??
        msg['callerName'] ??
        "Someone";
    final String callerImage =
        msg['senderimg']?.toString() ?? msg['caller_image']?.toString() ?? "";
    final String callType = msg['msg_type']?.toString() ?? "audio";
    final String token = msg['token']?.toString() ?? "";

    if (convId.isEmpty) {
      debugPrint("FCM: Incoming call ignored, conversation_id is empty.");
      return;
    }
    debugPrint(
      "FCM: Showing IncomingCallPopup for $callerName (Type: $callType)",
    );
    setState(() => _isCallPopupShowing = true);

    // Use addPostFrameCallback to ensure the dialog opens safely
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => IncomingCallPopup(
          callerName: callerName,
          callerImage: callerImage,
          isVideoCall: callType == 'video' || callType == 'accept',
          onDecline: () {
            debugPrint("FCM: Call declined.");
            if (Navigator.of(context).canPop()) {
              Navigator.pop(context);
            }
            setState(() => _isCallPopupShowing = false);
            ApiServer().rejectCall(
              userId: userData?['id']?.toString() ?? "",
              conversationId: convId,
              token: token,
            );
          },
          onAccept: () async {
            debugPrint("FCM: Call accepted. Joining Jitsi call...");
            if (Navigator.of(context).canPop()) {
              Navigator.pop(context);
            }
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
    });
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
    return BlocBuilder<ThemeCubit, AppThemeModel>(
      builder: (context, appTheme) {
        final bool isDark = appTheme.backgroundColor.computeLuminance() < 0.5;

        if (isLoading || userData == null) {
          return Scaffold(
            backgroundColor: appTheme.backgroundColor,
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
          length: 4,
          child: Scaffold(
            backgroundColor: appTheme.backgroundColor,
            endDrawer: AppDrawer(
              archiveCount: archiveCount,
              isDark: isDark,
              onThemeChange: (val) {},
              userData: userData,
              onLogout: _handleLogout,
            ),
            appBar: AppBar(
              automaticallyImplyLeading: false,
              backgroundColor: appTheme.backgroundColor,
              elevation: 0,
              title: _isSearching
                  ? TextField(
                      controller: _searchController,
                      autofocus: true,
                      style: TextStyle(
                        color: appTheme.textColor,
                      ), // Already correct
                      decoration: InputDecoration(
                        // Already correct
                        hintText: "Search...",
                        hintStyle: TextStyle(
                          color: appTheme.subTextColor,
                        ), // Already correct
                        border: InputBorder.none,
                      ),
                      onChanged: (value) => setState(() {}),
                    )
                  : Image.asset('assets/logo.webp', height: 45),
              actions: [
                IconButton(
                  icon: Icon(
                    _isSearching ? Icons.close : Icons.search,
                    color: appTheme.textColor, // Already correct
                  ),
                  onPressed: () => setState(() {
                    _isSearching = !_isSearching;
                    if (!_isSearching) _searchController.clear();
                  }),
                ),
                Builder(
                  builder: (context) => IconButton(
                    icon: Icon(
                      Icons.menu,
                      color: appTheme.textColor,
                      size: 28,
                    ), // Already correct
                    onPressed: () => Scaffold.of(context).openEndDrawer(),
                  ),
                ),
              ],
              bottom: TabBar(
                indicatorColor: appTheme.accentColor,
                labelColor: appTheme.textColor,
                unselectedLabelColor: appTheme.subTextColor,
                dividerColor: Colors.transparent,
                indicator: UnderlineTabIndicator(
                  borderSide: BorderSide(
                    color: appTheme.accentColor, // Already correct
                    width: 2,
                  ),
                ),

                tabs: [
                  Tab(
                    icon: Badge(
                      backgroundColor: appTheme.accentColor, // Already correct
                      label: Text(
                        totalUnread.toString(),
                        style: TextStyle(
                          color: appTheme.backgroundColor,
                          fontSize: 10,
                        ), // Already correct
                      ),
                      isLabelVisible: totalUnread > 0,
                      child: const Icon(Icons.chat),
                    ),
                    text: "Chats",
                  ),
                  const Tab(icon: Icon(Icons.call), text: "Calls"),
                  const Tab(icon: Icon(Icons.dashboard), text: "Filehubs"),
                  const Tab(
                    icon: Icon(Icons.assignment_turned_in),
                    text: "Task",
                  ),
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
                  onRoomTap: _markRoomAsRead,
                ),
                CallsTab(
                  userId: userData?['id']?.toString(),
                  companyId: userData?['company_id']?.toString(),
                ),
                const Filehubs(),
                const TaskScreen(),
              ],
            ),
          ),
        );
      },
    );
  }
}
