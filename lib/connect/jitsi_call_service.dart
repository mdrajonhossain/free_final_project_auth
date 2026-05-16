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
    required List<Map<String, dynamic>> participants,
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

      if (userId != null && companyId != null) {
        callResponse = await ApiServer().jitsiCallAccept_Call(
          userId,
          companyId,
          conversationId,
          ApiServer.token,
          conversation_type: conversationType,
        );

        jwt = callResponse?['jwt_token']?.toString();

        // IMPORTANT: Web (React.js) uses the room name assigned in the JWT.
        // We must use the room_name returned by the server,
        // or fall back to conversationId if the server doesn't provide one.
        serverRoomName = callResponse?['room_name']?.toString();

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
          avatar: userAvatar,
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
            // IMPORTANT: Use finalRoomName so backend matches Rajon and Motaleb in the same session
            if (userId != null && callResponse != null) {
              await ApiServer().jitsiCallJoin_Call(
                userId: userId,
                conversationId: finalRoomName,
                token: ApiServer.token ?? "",
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
