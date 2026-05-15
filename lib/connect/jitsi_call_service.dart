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
      if (userId != null && companyId != null) {
        jwt = await ApiServer().jitsiCallAccept_Call(
          userId,
          companyId,
          conversationId,
          ApiServer.token,
          conversation_type: conversationType,
        );

        // Mandatory JWT Check: Wait until data is received. If null, abort.
        if (jwt == null || jwt.isEmpty) {
          throw Exception(
            "Mandatory JWT token is missing. Call cannot be initiated.",
          );
        }
      }

      var options = JitsiMeetConferenceOptions(
        serverURL: serverUrl,
        room: conversationId,
        token: jwt,
        configOverrides: {
          "startWithAudioMuted": false,
          "startWithVideoMuted": !isVideo,
          "prejoinPageEnabled": false,
          "prejoinConfig.enabled": false,
          "requireDisplayName": false,
          "subject":
              roomTitle ?? "Meeting", // This shows the Room Name in the UI
        },
        featureFlags: {
          "add-people.enabled": true,
          "welcomepage.enabled": false,
          "prejoinpage.enabled": false,
          "chat.enabled": true,
          "invite.enabled": true,
          "raise-hand.enabled": true,
          "recording.enabled": true,
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
          conferenceJoined: (url) => onConferenceJoined?.call("local-user"),
          conferenceTerminated: (url, error) => onCallFinished?.call(),
        ),
      );
    } catch (error) {
      debugPrint("Jitsi Join Error: $error");
    }
  }
}
