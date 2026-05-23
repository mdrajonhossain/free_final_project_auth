import 'package:flutter/material.dart';
import 'package:freeli/connect/PopUpFile/MuteNotifications.dart';
import '../../controller/api/api_service.dart';

class ConversationRoomLongClick {
  static void show({
    required BuildContext context,
    required Map room,
    required String currentUserId,
    required Function(bool pinned) onPinToggle,
    required Function(bool muted) onMuteToggle,
    required Function(bool locked) onLockToggle,
    required Function(bool archived) onArchiveToggle,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),

      builder: (context) {
        final List pinList = room['pin'] ?? [];
        final List muteList = room['mute'] ?? [];
        final bool isArchived = room['archive'] == "yes";
        final bool isLocked = room['close_for'] == "yes";

        final bool isPinned = pinList.contains(currentUserId);
        final bool isMuted = muteList.contains(currentUserId);

        return Padding(
          padding: const EdgeInsets.only(
            top: 16,
            left: 16,
            right: 16,
            bottom: 26,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              /// TITLE
              Text(
                room['title'] ?? "Room Action",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              /// PIN / UNPIN
              ListTile(
                leading: Icon(
                  isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                  color: Colors.orange,
                ),
                title: Text(
                  isPinned ? "Unpin Room" : "Pin Room",
                  style: const TextStyle(color: Colors.white),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  final String action = isPinned ? "unpin" : "pin";
                  final String convId =
                      room['conversation_id']?.toString() ?? "";

                  try {
                    final result = await ApiServer().pinUnpinActionRoom(
                      conversation_id: convId,
                      action: action,
                    );

                    if (result['status'] == true) {
                      onPinToggle(!isPinned);
                    } else {
                      debugPrint(
                        "Server rejected pin action: ${result['message']}",
                      );
                    }
                  } catch (e) {
                    debugPrint("Pin API call failed: $e");
                  }
                },
              ),

              /// MUTE / UNMUTE
              ListTile(
                leading: Icon(
                  isMuted ? Icons.volume_off : Icons.volume_up,
                  color: Colors.blue,
                ),
                title: Text(
                  isMuted ? "Unmute Room" : "Mute Room",
                  style: const TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context);
                  MuteNotifications.show(
                    context,
                    alreadyMuted: isMuted,
                    onMuteChanged: onMuteToggle,
                  );
                },
              ),

              /// LOCK / UNLOCK
              ListTile(
                leading: const Icon(Icons.lock, color: Colors.red),
                title: Text(
                  isLocked ? "Unlock Room" : "Lock Room",
                  style: const TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context);
                  onLockToggle(!isLocked);
                },
              ),

              /// ARCHIVE / UNARCHIVE
              ListTile(
                leading: const Icon(Icons.archive, color: Colors.green),
                title: Text(
                  isArchived ? "Unarchive Room" : "Archive Room",
                  style: const TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context);
                  onArchiveToggle(!isArchived);
                },
              ),

              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }
}
