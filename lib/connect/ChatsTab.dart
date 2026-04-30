import 'package:flutter/material.dart';
import '../AppColors.dart';
import '../skeleton.dart'; // Import the skeleton loader

class ChatsTab extends StatelessWidget {
  final List<dynamic>? conversationRooms;

  const ChatsTab({super.key, this.conversationRooms});

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

    return ListView.builder(
      padding: const EdgeInsets.only(top: 16, bottom: 40, left: 16, right: 16),
      itemCount: conversationRooms!.length,
      itemBuilder: (context, index) {
        final room = conversationRooms![index];
        String title = room['title'] ?? 'No Title';

        if (title.length > 15) {
          title = '${title.substring(0, 15)}...';
        }

        final String lastMsg = room['last_msg'] ?? '';
        final String imageUrl = room['conv_img'] ?? '';
        final String lastTimeStr = room['last_msg_time'] ?? '';

        // Extracting date from ISO string: 2024-07-09T12... -> 2024-07-09
        String displayTime = lastTimeStr.split('T').first;

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
