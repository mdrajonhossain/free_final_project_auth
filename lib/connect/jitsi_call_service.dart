import 'package:jitsi_meet_flutter_sdk/jitsi_meet_flutter_sdk.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

class JitsiCallService {
  static const String serverUrl = "https://wfvs001.freeli.io/";

  static Future<void> joinCall({
    required String conversationId,
    String? jwtToken,
    String? userName,
    String? userEmail,
    String? userAvatar,
    bool isVideo = false,
    VoidCallback? onCallFinished,
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
      var options = JitsiMeetConferenceOptions(
        serverURL: serverUrl,
        room: conversationId,
        token: jwtToken,
        configOverrides: {
          "startWithAudioMuted": true,
          "startWithVideoMuted": !isVideo,
          "prejoinPageEnabled": false,
        },
        featureFlags: {
          "add-people.enabled": true,
          "welcomepage.enabled": false,
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
          conferenceTerminated: (url, error) => onCallFinished?.call(),
        ),
      );
    } catch (error) {
      debugPrint("Jitsi Join Error: $error");
    }
  }
}
