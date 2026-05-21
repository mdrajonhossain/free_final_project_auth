import 'package:flutter/material.dart';

class ArchiveRoom extends StatefulWidget {
  final bool isDark;
  final Function(bool) onThemeChange;

  const ArchiveRoom({
    super.key,
    required this.isDark,
    required this.onThemeChange,
  });

  @override
  State<ArchiveRoom> createState() => _ArchiveRoomState();
}

class _ArchiveRoomState extends State<ArchiveRoom> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  // Dummy data (replace with API/GraphQL later)
  final List<Map<String, dynamic>> archivedChats = [
    {
      "name": "John Doe",
      "message": "Hey, are you available?",
      "time": "10:30 AM",
      "avatar": "",
    },
    {
      "name": "Flutter Devs",
      "message": "New update released 🚀",
      "time": "Yesterday",
      "avatar": "",
    },
    {
      "name": "Sarah Khan",
      "message": "Let’s meet tomorrow",
      "time": "Mon",
      "avatar": "",
    },
    {
      "name": "Project Team",
      "message": "Deadline is near!",
      "time": "Sun",
      "avatar": "",
    },
  ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = widget.isDark;
    final backgroundColor = isDark
        ? const Color(0xFF0F172A)
        : const Color(0xFFF4F7FC);
    final surfaceColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1E293B);
    final subTextColor = isDark ? Colors.white70 : Colors.black54;

    final filteredChats = archivedChats.where((chat) {
      return chat["name"].toString().toLowerCase().contains(_searchQuery) ||
          chat["message"].toString().toLowerCase().contains(_searchQuery);
    }).toList();

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        title: Text(
          "Archived Rooms",
          style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
        ),
        centerTitle: false,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            onPressed: () => widget.onThemeChange(!isDark),
            icon: Icon(
              isDark ? Icons.wb_sunny_rounded : Icons.nightlight_round,
              color: isDark ? Colors.yellow : Colors.blueGrey,
            ),
          ),
        ],
      ),

      body: Column(
        children: [
          // 🔍 Search Box
          Padding(
            padding: const EdgeInsets.all(12),
            child: Container(
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? Colors.white10 : Colors.black12,
                ),
              ),
              child: TextField(
                controller: _searchController,
                style: TextStyle(color: textColor),
                decoration: InputDecoration(
                  hintText: "Search archived chats...",
                  hintStyle: TextStyle(color: subTextColor),
                  prefixIcon: Icon(Icons.search, color: subTextColor),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(14),
                ),
              ),
            ),
          ),

          // 📜 Chat List
          Expanded(
            child: filteredChats.isEmpty
                ? Center(
                    child: Text(
                      "No archived rooms found",
                      style: TextStyle(color: subTextColor),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 12),
                    itemCount: filteredChats.length,
                    itemBuilder: (context, index) {
                      final chat = filteredChats[index];

                      return Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: surfaceColor,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(
                                isDark ? 0.2 : 0.05,
                              ),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                          border: Border.all(
                            color: isDark
                                ? Colors.white.withOpacity(0.05)
                                : Colors.black.withOpacity(0.05),
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: InkWell(
                            onTap: () {},
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Row(
                                children: [
                                  // Avatar
                                  CircleAvatar(
                                    radius: 26,
                                    backgroundColor: Colors.blueAccent,
                                    child: chat["avatar"] == ""
                                        ? Text(
                                            chat["name"][0],
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 18,
                                            ),
                                          )
                                        : null,
                                  ),

                                  const SizedBox(width: 14),

                                  // Name + Message
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          chat["name"],
                                          style: TextStyle(
                                            color: textColor,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          chat["message"],
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: subTextColor,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(width: 8),

                                  // Time + Action
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        chat["time"],
                                        style: TextStyle(
                                          color: subTextColor,
                                          fontSize: 11,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      IconButton(
                                        onPressed: () {
                                          // Action for unarchiving
                                        },
                                        icon: Icon(
                                          Icons.unarchive_rounded,
                                          color: Colors.blueAccent.withOpacity(
                                            0.9,
                                          ),
                                          size: 20,
                                        ),
                                        constraints: const BoxConstraints(),
                                        padding: EdgeInsets.zero,
                                        tooltip: "Unarchive",
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
