import 'package:jitsi_meet_flutter_sdk/jitsi_meet_flutter_sdk.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import '../controller/api/api_service.dart';

class JitsiCallService {
  static const String serverUrl = "https://wfvs001.freeli.io/";

  static Future<void> joinCall({
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
    // Request necessary permissions before launching the call
    Map<Permission, PermissionStatus> statuses = await [
      Permission.camera,
      Permission.microphone,
    ].request();

    if (statuses[Permission.camera]!.isDenied ||
        statuses[Permission.microphone]!.isDenied) {
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

        callResponse = await ApiServer().jitsiCallAccept_Call(
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
        );

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
      debugPrint("Jitsi Join Error: $error");
    }
  }
}
