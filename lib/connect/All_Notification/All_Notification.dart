import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:freeli/controller/api/api_service.dart';
import 'package:intl/intl.dart';

class AllNotificationPage extends StatefulWidget {
  final bool isDark;
  final Function(bool) onThemeChange;

  const AllNotificationPage({
    super.key,
    required this.isDark,
    required this.onThemeChange,
  });

  @override
  State<AllNotificationPage> createState() => _AllNotificationPageState();
}

class _AllNotificationPageState extends State<AllNotificationPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<dynamic> unreadNotifications = [];
  List<dynamic> readNotifications = [];

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    loadNotifications();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// ================= LOAD API =================

  Future<void> loadNotifications() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Use the actual ApiServer method to fetch data
      final unreadResponse = await ApiServer().getNotifications(
        readStatus: "no",
      );
      final readResponse = await ApiServer().getNotifications(
        readStatus: "yes",
      );

      unreadNotifications = unreadResponse['notification'] ?? [];
      readNotifications = readResponse['notification'] ?? [];
    } catch (e) {
      debugPrint("Notification Error: $e");
    }

    setState(() {
      isLoading = false;
    });
  }

  /// ================= COLORS =================

  Color get bgColor =>
      widget.isDark ? const Color(0xFF08131F) : const Color(0xFFF4F7FC);

  Color get cardColor => widget.isDark ? const Color(0xFF132130) : Colors.white;

  Color get textColor => widget.isDark ? Colors.white : const Color(0xFF111827);

  Color get subText => widget.isDark ? Colors.white70 : Colors.grey.shade700;

  /// ================= ICON =================

  IconData getNotificationIcon(String type) {
    switch (type.toLowerCase()) {
      case "file":
        return Icons.insert_drive_file_rounded;

      case "conversation":
        return Icons.forum_rounded;

      default:
        return Icons.notifications_active_rounded;
    }
  }

  Color getNotificationColor(String type) {
    switch (type.toLowerCase()) {
      case "file":
        return Colors.blue;

      case "conversation":
        return Colors.orange;

      default:
        return Colors.purple;
    }
  }

  /// ================= FILE NAME =================

  String getFileName(String body) {
    try {
      final decoded = jsonDecode(body);

      if (decoded is List && decoded.isNotEmpty) {
        return decoded[0]['voriginalName'] ?? "Unknown file";
      }

      if (decoded is Map) {
        return decoded['title'] ?? "Conversation";
      }

      return "Unknown";
    } catch (e) {
      return "Conversation";
    }
  }

  /// ================= TIME =================

  String formatTime(String time) {
    try {
      DateTime date = DateTime.parse(time).toLocal();

      return DateFormat('dd MMM yyyy • hh:mm a').format(date);
    } catch (e) {
      return "";
    }
  }

  /// ================= BUILD =================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,

      /// ================= APP BAR =================
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        backgroundColor: bgColor,
        iconTheme: IconThemeData(color: textColor),

        title: Text(
          "Notifications",
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),

        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: widget.isDark
                    ? Colors.white.withOpacity(.06)
                    : Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(Icons.done_all_rounded, color: Colors.blue.shade400),
            ),
          ),
        ],

        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(72),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Container(
              height: 56,
              decoration: BoxDecoration(
                color: widget.isDark
                    ? Colors.white.withOpacity(.05)
                    : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(18),
              ),
              child: TabBar(
                controller: _tabController,
                dividerColor: Colors.transparent,
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: Colors.white,
                unselectedLabelColor: widget.isDark
                    ? Colors.white60
                    : Colors.black54,
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2563EB), Color(0xFF4F46E5)],
                  ),
                ),
                tabs: [
                  buildTab("Unread", unreadNotifications.length),

                  buildTab("Read", readNotifications.length),
                ],
              ),
            ),
          ),
        ),
      ),

      /// ================= BODY =================
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                buildNotificationList(unreadNotifications),
                buildNotificationList(readNotifications),
              ],
            ),
    );
  }

  /// ================= TAB =================

  Widget buildTab(String title, int count) {
    return Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),

          const SizedBox(width: 8),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.18),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Text(
              "$count",
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  /// ================= LIST =================

  Widget buildNotificationList(List<dynamic> notifications) {
    if (notifications.isEmpty) {
      return Center(
        child: Text(
          "No Notifications Found",
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: loadNotifications,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          final item = notifications[index];

          final type = item['type'] ?? "";
          final title = item['title'] ?? "";
          final image = item['created_by_img'] ?? "";
          final user = item['created_by_name'] ?? "";
          final fnln = item['fnln'] ?? "";
          final time = formatTime(item['created_at']);

          final icon = getNotificationIcon(type);
          final color = getNotificationColor(type);

          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: color.withOpacity(.15)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(.04),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: color.withOpacity(.12),
                      backgroundImage: image.toString().isNotEmpty
                          ? NetworkImage(image)
                          : null,
                      child: image.toString().isEmpty
                          ? Text(
                              fnln,
                              style: TextStyle(
                                color: color,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : null,
                    ),

                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(icon, color: Colors.white, size: 14),
                      ),
                    ),
                  ],
                ),

                const SizedBox(width: 14),

                /// ================= CONTENT =================
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      /// TITLE
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          height: 1.4,
                        ),
                      ),

                      const SizedBox(height: 8),

                      /// USER
                      Row(
                        children: [
                          Icon(Icons.person_rounded, size: 16, color: subText),

                          const SizedBox(width: 5),

                          Expanded(
                            child: Text(
                              user,
                              style: TextStyle(
                                color: subText,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      /// FILE
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: color.withOpacity(.08),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.attach_file_rounded,
                              size: 18,
                              color: color,
                            ),

                            const SizedBox(width: 8),

                            Expanded(
                              child: Text(
                                getFileName(item['body']),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: textColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      /// TIME + TYPE
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Icon(
                                  Icons.access_time_rounded,
                                  size: 16,
                                  color: subText,
                                ),

                                const SizedBox(width: 5),

                                Flexible(
                                  child: Text(
                                    time,
                                    style: TextStyle(
                                      color: subText,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: color.withOpacity(.12),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Text(
                              type.toUpperCase(),
                              style: TextStyle(
                                color: color,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// ================= DEMO DATA =================

final unreadNotificationData = {
  "data": {
    "get_notifications": {"notification": []},
  },
};

final readNotificationData = {
  "data": {
    "get_notifications": {"notification": []},
  },
};
