import 'package:flutter/material.dart';
import 'package:freeli/connect/PopUpFile/DirectMessagePopup.dart';
import '../AppColors.dart';
import '../skeleton.dart'; // Import the skeleton loader
import 'crypto_utils.dart';
import 'format_utils.dart';
import 'createRoom.dart';

class ChatsTab extends StatefulWidget {
  final List<dynamic>? conversationRooms;
  final String? userMe;
  final String? userId;
  final String? companyId;
  final bool isDark;
  final Function(String)? onRoomTap; // Callback to HomePage

  const ChatsTab({
    super.key,
    this.conversationRooms,
    this.userMe,
    this.userId,
    this.companyId,
    this.isDark = true,
    this.onRoomTap,
  });

  @override
  State<ChatsTab> createState() => _ChatsTabState();
}

class _ChatsTabState extends State<ChatsTab>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isMenuOpen = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleMenu() {
    _isMenuOpen = !_isMenuOpen;
    _isMenuOpen ? _controller.forward() : _controller.reverse();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.getBackgroundColor(widget.isDark),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(
          bottom: 80, // bottom space
          right: 8, // right space
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _buildMenuItem(
              label: "Direct message",
              icon: Icons.person_add_alt_1_rounded,
              onPressed: () {
                _toggleMenu();
                DirectMessagePopup.show(context, widget.conversationRooms);
              },
            ),
            const SizedBox(height: 16),
            _buildMenuItem(
              label: "Create room",
              icon: Icons.groups_rounded,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CreateRoomScreen(),
                  ),
                );
                _toggleMenu();
              },
            ),
            const SizedBox(height: 16),
            FloatingActionButton(
              onPressed: _toggleMenu,
              backgroundColor: AppColors.accentColor,
              child: RotationTransition(
                turns: Tween(begin: 0.0, end: 0.125).animate(_animation),
                child: const Icon(Icons.add, color: Colors.white, size: 40),
              ),
            ),
          ],
        ),
      ),
      body: _buildTabContent(context),
    );
  }

  Widget _buildMenuItem({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return ScaleTransition(
      scale: _animation,
      child: FadeTransition(
        opacity: _animation,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                label,
                style: const TextStyle(color: Colors.black, fontSize: 15),
              ),
            ),
            const SizedBox(width: 12),
            FloatingActionButton.small(
              onPressed: onPressed,
              backgroundColor: AppColors.accentColor,
              child: Icon(icon, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabContent(BuildContext context) {
    final cardColor = widget.isDark
        ? Colors.white.withOpacity(0.05)
        : Colors.black.withOpacity(0.05);

    if (widget.conversationRooms == null) {
      return const ChatSkeleton(); // Show skeleton instead of loader
    }

    if (widget.conversationRooms!.isEmpty) {
      return const Center(
        child: Text(
          "No conversations yet",
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    final List<dynamic> sortedRooms;
    if (widget.conversationRooms!.length > 1) {
      sortedRooms = List.from(widget.conversationRooms!);
      final int meIndex = sortedRooms.indexWhere(
        (room) =>
            room['title']?.toString().toLowerCase() == 'me' ||
            (widget.userMe != null &&
                room['conversation_id']?.toString() == widget.userMe),
      );

      if (meIndex != -1 && meIndex != 0) {
        final meRoom = sortedRooms.removeAt(meIndex);
        sortedRooms.insert(0, meRoom);
      }
    } else {
      sortedRooms = widget.conversationRooms!;
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

        final bool isGroup = room['group'] == 'yes';
        final bool roomIsOnline =
            !isGroup &&
            (room['is_online'] == true ||
                room['is_online'] == 'yes' ||
                room['online'] == true);

        final String rawLastMsg = room['last_msg'] ?? '';
        final String decryptedLastMsg = CryptoUtils.decryptMessage(rawLastMsg);
        String lastMsg = FormatUtils.stripHtml(decryptedLastMsg);

        // JSON ডেটা (ফাইল বা কল) শনাক্ত করে সুন্দর প্রিভিউ দেখানো
        final String trimmed = lastMsg.trim();
        if (trimmed.startsWith('{') || trimmed.startsWith('[')) {
          if (trimmed.contains('"sdp"') || trimmed.contains('"call_id"')) {
            lastMsg = "📞 Voice/Video Call";
          } else {
            lastMsg = "📎 Attachment";
          }
        }

        // Fallbacks for common image keys
        final String imageUrl =
            (room['conv_img'] ?? room['img'] ?? room['image'] ?? '').toString();
        final String lastTimeStr = room['last_msg_time'] ?? '';

        // substring(0, 10) is significantly faster than split().first for ISO date strings
        final String displayTime = lastTimeStr.length >= 10
            ? lastTimeStr.substring(0, 10)
            : lastTimeStr;

        final int unreadCount =
            int.tryParse(room['unread_count']?.toString() ?? '0') ?? 0;

        return Card(
          color: cardColor,
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            onTap: () async {
              final convId = room['conversation_id']?.toString() ?? "";
              if (widget.onRoomTap != null) {
                widget.onRoomTap!(convId); // Clear counter immediately
              }

              await Navigator.pushNamed(
                context,
                '/chat',
                arguments: {
                  'conversation_id': room['conversation_id'],
                  'company_id': room['company_id'] ?? widget.companyId,
                  'user_id': widget.userId ?? widget.userMe,
                  'participants': room['participants'],
                  'title': room['title'] ?? 'No Title',
                  'group': room['group'] == 'yes',
                  'conv_img': room['conv_img'],
                },
              );

              // Reset active chat status when returning
              if (widget.onRoomTap != null) {
                widget.onRoomTap!("");
              }
            },
            leading: Stack(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.accentColor,
                  backgroundImage: imageUrl.isNotEmpty
                      ? NetworkImage(imageUrl)
                      : null,
                  child: imageUrl.isEmpty
                      ? const Icon(Icons.person, color: Colors.white)
                      : null,
                ),

                // Online / Offline Indicator (Top Right)
                if (!isGroup)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: roomIsOnline ? Colors.green : Colors.grey,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
              ],
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
                /// DATE / TIME (TOP)
                Text(
                  displayTime,
                  style: const TextStyle(color: Colors.white54, fontSize: 11),
                ),

                const SizedBox(height: 6),

                /// BOTTOM ROW (3 ITEMS)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (unreadCount > 0)
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Colors.greenAccent,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          unreadCount.toString(),
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                    const SizedBox(width: 6),

                    /// 2nd badge (example icon)
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Colors.blueAccent,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.notifications,
                        size: 12,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Colors.orangeAccent,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.push_pin,
                        size: 12,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
