import 'package:flutter/material.dart';
import '../skeleton.dart';
import 'format_utils.dart';

class CallsTab extends StatelessWidget {
  final List<dynamic>? conversationRooms;

  /// Pass the current user's ID to correctly identify their personal chat
  final String? userMe;

  const CallsTab({super.key, this.conversationRooms, this.userMe});

  @override
  Widget build(BuildContext context) {
    if (conversationRooms == null) {
      return const ChatSkeleton();
    }

    if (conversationRooms!.isEmpty) {
      return const Center(
        child: Text(
          "No call history yet",
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    // Create a mutable copy and sort to ensure "Me" is at the top
    final List<dynamic> sortedRooms = List.from(conversationRooms!);

    // Find the index of the "Me" user
    final int meIndex = sortedRooms.indexWhere(
      (room) =>
          room['title']?.toString().toLowerCase() == 'me' ||
          (userMe != null && room['conversation_id']?.toString() == userMe),
    );

    if (meIndex != -1 && meIndex != 0) {
      final meRoom = sortedRooms.removeAt(meIndex);
      sortedRooms.insert(0, meRoom);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedRooms.length,
      itemBuilder: (context, index) {
        final room = sortedRooms[index];
        String title = room['title'] ?? 'No Title';

        if (title.length > 12) {
          title = '${title.substring(0, 12)}...';
        }

        // Fallbacks for common image keys
        final String imageUrl =
            (room['conv_img'] ?? room['img'] ?? room['image'] ?? '').toString();
        final String lastTimeStr = room['last_msg_time'] ?? '';
        String displayTime = lastTimeStr.split('T').first;

        return Card(
          color: Colors.green.withOpacity(
            0.1,
          ), // Green background for list items
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.green.withOpacity(0.2),
              backgroundImage: imageUrl.isNotEmpty
                  ? NetworkImage(imageUrl)
                  : null,
              child: imageUrl.isEmpty
                  ? const Icon(Icons.call, color: Colors.greenAccent)
                  : null,
            ),
            title: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ), // White text for visibility
            ),
            subtitle: Text(
              displayTime,
              style: const TextStyle(
                color: Colors.white70,
              ), // Lighter text for visibility
            ),
            trailing: const Icon(
              Icons.phone,
              color: Colors.white54,
            ), // Lighter icon for visibility
          ),
        );
      },
    );
  }
}
