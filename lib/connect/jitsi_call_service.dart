import 'package:jitsi_meet_flutter_sdk/jitsi_meet_flutter_sdk.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../controller/api/api_service.dart';
import 'dart:async';

class JitsiCallService {
  static const String serverUrl = "https://wfvs001.freeli.io/";

  static void _showConnectingLoader(
    BuildContext context,
    Completer<BuildContext> contextCompleter,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Color(0xff0B1180),
      builder: (dialogContext) {
        if (!contextCompleter.isCompleted)
          contextCompleter.complete(dialogContext);
        return WillPopScope(
          onWillPop: () async => false,
          child: Dialog(
            elevation: 0,
            backgroundColor: Color.fromARGB(255, 29, 43, 78),
            insetPadding: const EdgeInsets.symmetric(horizontal: 28),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF16213E),
                    Color(0xFF1E3A70),
                    Color(0xFF233B6E),
                  ],
                ),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.35),
                    blurRadius: 30,
                    offset: const Offset(0, 14),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  /// ANIMATED ICON
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        height: 90,
                        width: 90,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.05),
                        ),
                      ),

                      Container(
                        height: 68,
                        width: 68,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              Colors.blueAccent,
                              Colors.cyanAccent.withOpacity(0.9),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.cyanAccent.withOpacity(0.4),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.video_call_rounded,
                          color: Colors.white,
                          size: 36,
                        ),
                      ),

                      const SizedBox(
                        height: 105,
                        width: 105,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.cyanAccent,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),

                  /// TITLE
                  const Text(
                    "Connecting you to your Meeting",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.4,
                    ),
                  ),

                  const SizedBox(height: 10),

                  /// SUBTITLE
                  Text(
                    "Please wait while we establish\nsecure connection with server...",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.72),
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 24),

                  /// STATUS BOX
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white.withOpacity(0.05)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          height: 10,
                          width: 10,
                          decoration: const BoxDecoration(
                            color: Colors.greenAccent,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          "Securing connection...",
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  static Future<void> joinCall({
    required BuildContext context,
    String? userId,
    String? companyId,
    required String conversationId,
    String? conversationType,
    required List<dynamic> participants,
    String? roomTitle,
    String? userName,
    String? userEmail,
    String? userAvatar,
    bool isVideo = false,
    VoidCallback? onCallFinished,
    Function(String participantId)? onConferenceJoined,
  }) async {
    // Use a completer to get the dialog's own context for safe dismissal
    final Completer<BuildContext> loaderCompleter = Completer<BuildContext>();
    _showConnectingLoader(context, loaderCompleter);

    // Helper to dismiss the loader using the captured dialog context
    Future<void> dismissLoader() async {
      final dialogCtx = await loaderCompleter.future;
      if (dialogCtx.mounted) {
        Navigator.of(dialogCtx).pop();
      }
    }

    // Request necessary permissions before launching the call
    Map<Permission, PermissionStatus> statuses = await [
      Permission.camera,
      Permission.microphone,
    ].request();

    if (statuses[Permission.camera]!.isDenied ||
        statuses[Permission.microphone]!.isDenied) {
      await dismissLoader();
      debugPrint("Call permissions denied by user.");
      return;
    }

    try {
      // Fetch JWT Token internally if user/company IDs are provided
      String? jwt;
      String? serverRoomName;
      Map<String, dynamic>? callResponse;
      String signalingToken = "";

      if (userId != null && companyId != null) {
        // Construct payload similar to React.js initiation logic
        final int expireUnix = DateTime.now().millisecondsSinceEpoch + 60000;
        final String callLink = "https://work.freeli.io/call/$conversationId";

        // Use a persistent signaling token instead of the full JWT to match web client signaling
        signalingToken = await ApiServer.getSignalingToken();

        callResponse = await ApiServer()
            .jitsiCallAccept_Call(
              userId,
              companyId,
              conversationId,
              signalingToken,
              conversation_type: conversationType,
              participantsAll: participants,
              participantsAdmin: [userId], // Pass current user as admin
              arrParticipants: participants, // Ring all group members
              convname: roomTitle ?? "Meeting",
              callLink: callLink,
              expireUnix: expireUnix,
            )
            .timeout(const Duration(seconds: 20));

        // If initiation fails (status: false), fallback to fetching existing session JWT via query
        if (callResponse?['status'] != true) {
          debugPrint("Initiation status false. Fetching existing session...");
          final queryResponse = await ApiServer().jitsi_ring_users(
            userId: userId,
            conversationId: conversationId,
            token: signalingToken,
          );
          if (queryResponse != null && queryResponse['status'] == true) {
            jwt = queryResponse['jwt_token']?.toString();
            serverRoomName = queryResponse['voip_conv']?['room_name']
                ?.toString();
          }
        } else {
          jwt = callResponse?['jwt_token']?.toString();
          // IMPORTANT: Web (React.js) uses the room name assigned in the JWT.
          // We must use the room_name returned by the server.
          serverRoomName = callResponse?['room_name']?.toString();
        }

        // Mandatory JWT Check: Wait until data is received. If null, abort.
        if (jwt == null || jwt.isEmpty) {
          throw Exception(
            "Mandatory JWT token is missing. Call cannot be initiated.",
          );
        }
      }

      // If serverRoomName is available, use it. Otherwise, use conversationId.
      String finalRoomName =
          (serverRoomName != null && serverRoomName.isNotEmpty)
          ? serverRoomName
          : conversationId;

      // Sanitize room name to match React.js behavior (remove hyphens)
      finalRoomName = finalRoomName.replaceAll('-', '');

      // Ensure avatar URL is absolute (matches React.js behavior)
      String? finalAvatar = userAvatar;
      if (finalAvatar != null &&
          finalAvatar.isNotEmpty &&
          !finalAvatar.startsWith('http')) {
        finalAvatar =
            "https://wfss001.freeli.io/profile-pic/Photos/$finalAvatar";
      } else if (finalAvatar == null || finalAvatar.isEmpty) {
        finalAvatar = "https://wfss001.freeli.io/profile-pic/Photos/img.png";
      }

      var options = JitsiMeetConferenceOptions(
        serverURL: serverUrl,
        room: finalRoomName,
        configOverrides: {
          "startWithAudioMuted": false,
          "startWithVideoMuted": !isVideo,
          "prejoinPageEnabled": false,
          "prejoinConfig.enabled": false,
          "requireDisplayName": false,
          "subject": roomTitle ?? "Meeting",
          "p2p.enabled":
              false, // Bridge mode is REQUIRED for group calls and Tile View
          "disableTileView": false, // Ensure Tile View is not disabled
          "enableLayerSuspension": true,
          "tileViewRequired": true,
          "enableWelcomePage": false,
          "filmstrip.enabled": true,
          "filmstrip.disableResizable": true,
          "preferredLayout":
              "tile-view", // Matches React.js behavior to force Tile View
          "disableDeepLinking": true,
          "disableThirdPartyRequests": true,
          "enableNoAudioDetection": false,
          "enableNoisyMicDetection": false,
          "disableAudioLevels": true,
          "defaultBackground": "#19619c", // Professional deep blue background
        },
        token: jwt,
        featureFlags: {
          "add-people.enabled": true,
          "welcomepage.enabled": false,
          "prejoinpage.enabled": false,
          "chat.enabled": true,
          "invite.enabled": true,
          "raise-hand.enabled": true,
          "recording.enabled": true,
          "tile-view.enabled": true,
          "filmstrip.enabled": true,
          "conference-timer.enabled": true,
          "pip.enabled": true,
        },
        userInfo: JitsiMeetUserInfo(
          displayName: userName ?? "User",
          email: userEmail,
          avatar: finalAvatar,
        ),
      );

      var jitsiMeet = JitsiMeet();

      // Dismiss loader BEFORE joining the meeting as requested
      await dismissLoader();

      await jitsiMeet.join(
        options,
        JitsiMeetEventListener(
          conferenceJoined: (url) async {
            debugPrint("Conference Joined: $url");
            onConferenceJoined?.call("local-user");

            // Send Join Signal to bridge participants (matches React.js behavior)
            // IMPORTANT: Use the original UUID (conversationId) for the backend API signal
            if (userId != null && callResponse != null) {
              await ApiServer().jitsiCallJoin_Call(
                userId: userId,
                conversationId: conversationId,
                token: signalingToken,
              );
            }
          },
          conferenceTerminated: (url, error) => onCallFinished?.call(),
        ),
      );
    } catch (error) {
      await dismissLoader();
      debugPrint("Jitsi Join Error: $error");
    }
  }
}
