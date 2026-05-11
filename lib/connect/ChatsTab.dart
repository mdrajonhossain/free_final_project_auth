import 'package:flutter/material.dart';
import '../AppColors.dart';
import '../skeleton.dart'; // Import the skeleton loader
import 'crypto_utils.dart';
import 'format_utils.dart';

class ChatsTab extends StatelessWidget {
  final List<dynamic>? conversationRooms;

  /// Pass the current user's ID to correctly identify their personal chat
  /// if it isn't explicitly named "Me".
  final String? userMe;

  const ChatsTab({super.key, this.conversationRooms, this.userMe});

  @override
  Widget build(BuildContext context) {
    if (conversationRooms == null) {
      return const ChatSkeleton(); // Show skeleton instead of loader
    }

    if (conversationRooms!.isEmpty) {
      return const Center(
        child: Text(
          "No conversations yet",
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    final List<dynamic> sortedRooms;
    if (conversationRooms!.length > 1) {
      sortedRooms = List.from(conversationRooms!);
      final int meIndex = sortedRooms.indexWhere(
        (room) =>
            room['title']?.toString().toLowerCase() == 'me' ||
            (userMe != null && room['conversation_id']?.toString() == userMe),
      );

      if (meIndex != -1 && meIndex != 0) {
        final meRoom = sortedRooms.removeAt(meIndex);
        sortedRooms.insert(0, meRoom);
      }
    } else {
      sortedRooms = conversationRooms!;
    }

    return ListView.builder(
      cacheExtent:
          500, // Keeps items in memory to avoid re-calculating/decrypting during scroll
      padding: const EdgeInsets.only(top: 16, bottom: 40, left: 16, right: 16),
      itemCount: sortedRooms.length,
      itemBuilder: (context, index) {
        final room = sortedRooms[index];
        String title = room['title'] ?? 'No Title';

        if (title.length > 12) {
          title = '${title.substring(0, 12)}...';
        }

        final String rawLastMsg = room['last_msg'] ?? '';
        final String decryptedLastMsg = CryptoUtils.decryptMessage(rawLastMsg);
        final String lastMsg = FormatUtils.stripHtml(decryptedLastMsg);

        // Fallbacks for common image keys
        final String imageUrl =
            (room['conv_img'] ?? room['img'] ?? room['image'] ?? '').toString();
        final String lastTimeStr = room['last_msg_time'] ?? '';

        // substring(0, 10) is significantly faster than split().first for ISO date strings
        final String displayTime = lastTimeStr.length >= 10
            ? lastTimeStr.substring(0, 10)
            : lastTimeStr;

        return Card(
          color: Colors.green.withOpacity(
            0.1,
          ), // Green background for list items
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            onTap: () {
              Navigator.pushNamed(
                context,
                '/chat',
                arguments: {
                  'conversation_id': room['conversation_id'],
                  'company_id': room['company_id'],
                  'participants': room['participants'],
                  'title': room['title'] ?? 'No Title',
                  'conv_img': room['conv_img'],
                },
              );
            },
            leading: CircleAvatar(
              backgroundColor: AppColors.accentColor,
              backgroundImage: imageUrl.isNotEmpty
                  ? NetworkImage(imageUrl)
                  : null,
              child: imageUrl.isEmpty
                  ? const Icon(Icons.person, color: Colors.white)
                  : null,
            ),
            title: Text(
              title,
              style: const TextStyle(
                color: Colors.white, // White text for visibility
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              lastMsg,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white70,
              ), // Lighter text for visibility
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  displayTime,
                  style: const TextStyle(color: Colors.white54, fontSize: 11),
                ),
                const SizedBox(height: 5),
                if (false) // Placeholder for unread count logic
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Colors.greenAccent,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '0', // Placeholder since unread count logic is not yet implemented
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
