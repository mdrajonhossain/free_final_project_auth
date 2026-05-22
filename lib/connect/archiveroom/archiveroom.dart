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

  // Dummy Data
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
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = widget.isDark;

    final backgroundColor = isDark
        ? const Color(0xFF0C1F5E)
        : const Color(0xFFF4F7FC);

    final cardColor = isDark ? const Color(0xFF162447) : Colors.white;

    final inputColor = isDark ? const Color(0xFF1B2C58) : Colors.white;

    final textColor = isDark ? Colors.white : const Color(0xFF1E293B);

    final subTextColor = isDark ? Colors.white70 : Colors.black54;

    final filteredChats = archivedChats.where((chat) {
      return chat["name"].toString().toLowerCase().contains(_searchQuery) ||
          chat["message"].toString().toLowerCase().contains(_searchQuery);
    }).toList();

    return Scaffold(
      backgroundColor: backgroundColor,

      // =========================
      // APP BAR
      // =========================
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,

        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),

        title: Text(
          "Archived Rooms",
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: textColor,
            fontSize: 22,
          ),
        ),

        actions: [
          IconButton(
            onPressed: () {
              widget.onThemeChange(!isDark);
            },
            icon: Icon(
              isDark ? Icons.wb_sunny_rounded : Icons.nightlight_round,
              color: isDark ? Colors.yellow : Colors.blueGrey,
            ),
          ),
        ],
      ),

      // =========================
      // BODY
      // =========================
      body: Column(
        children: [
          const SizedBox(height: 8),

          // =========================
          // SEARCH
          // =========================
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              height: 56,
              decoration: BoxDecoration(
                color: inputColor,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withOpacity(0.05)
                      : Colors.black.withOpacity(0.05),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.15 : 0.04),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                style: TextStyle(color: textColor),

                decoration: InputDecoration(
                  border: InputBorder.none,

                  hintText: "Search archived rooms...",

                  hintStyle: TextStyle(color: subTextColor),

                  prefixIcon: Icon(Icons.search_rounded, color: subTextColor),

                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ),

          const SizedBox(height: 18),

          // =========================
          // COUNT
          // =========================
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Row(
              children: [
                Text(
                  "${filteredChats.length} Archived Rooms",
                  style: TextStyle(
                    color: subTextColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // =========================
          // LIST
          // =========================
          Expanded(
            child: filteredChats.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.archive_outlined,
                          size: 72,
                          color: subTextColor.withOpacity(0.5),
                        ),

                        const SizedBox(height: 14),

                        Text(
                          "No Archived Rooms",
                          style: TextStyle(
                            color: textColor,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),

                        const SizedBox(height: 6),

                        Text(
                          "Archived conversations will appear here",
                          style: TextStyle(color: subTextColor, fontSize: 13),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
                    itemCount: filteredChats.length,

                    itemBuilder: (context, index) {
                      final chat = filteredChats[index];

                      return Container(
                        margin: const EdgeInsets.only(bottom: 14),

                        decoration: BoxDecoration(
                          color: cardColor,

                          borderRadius: BorderRadius.circular(22),

                          border: Border.all(
                            color: isDark
                                ? Colors.white.withOpacity(0.05)
                                : Colors.black.withOpacity(0.05),
                          ),

                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(
                                isDark ? 0.18 : 0.04,
                              ),
                              blurRadius: 16,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),

                        child: Material(
                          color: Colors.transparent,

                          child: InkWell(
                            borderRadius: BorderRadius.circular(22),

                            onTap: () {},

                            child: Padding(
                              padding: const EdgeInsets.all(16),

                              child: Row(
                                children: [
                                  // =========================
                                  // AVATAR
                                  // =========================
                                  Stack(
                                    children: [
                                      Container(
                                        height: 58,
                                        width: 58,

                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: [
                                              Color(0xFF4C8DFF),
                                              Color(0xFF6AA8FF),
                                            ],
                                          ),

                                          borderRadius: BorderRadius.circular(
                                            18,
                                          ),
                                        ),

                                        child: Center(
                                          child: chat["avatar"] == ""
                                              ? Text(
                                                  chat["name"][0].toUpperCase(),

                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 22,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                )
                                              : null,
                                        ),
                                      ),

                                      Positioned(
                                        bottom: -1,
                                        right: -1,
                                        child: Container(
                                          padding: const EdgeInsets.all(5),

                                          decoration: BoxDecoration(
                                            color: Colors.orange,
                                            shape: BoxShape.circle,

                                            border: Border.all(
                                              color: cardColor,
                                              width: 2,
                                            ),
                                          ),

                                          child: const Icon(
                                            Icons.archive_rounded,
                                            color: Colors.white,
                                            size: 12,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(width: 16),

                                  // =========================
                                  // TEXT
                                  // =========================
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,

                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                chat["name"],

                                                maxLines: 1,

                                                overflow: TextOverflow.ellipsis,

                                                style: TextStyle(
                                                  color: textColor,
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ),

                                            Text(
                                              chat["time"],

                                              style: TextStyle(
                                                color: subTextColor,
                                                fontSize: 11,
                                              ),
                                            ),
                                          ],
                                        ),

                                        const SizedBox(height: 8),

                                        Text(
                                          chat["message"],

                                          maxLines: 1,

                                          overflow: TextOverflow.ellipsis,

                                          style: TextStyle(
                                            color: subTextColor,
                                            fontSize: 13,
                                            height: 1.4,
                                          ),
                                        ),

                                        const SizedBox(height: 14),

                                        Row(
                                          children: [
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                    vertical: 5,
                                                  ),

                                              decoration: BoxDecoration(
                                                color: Colors.orange
                                                    .withOpacity(0.12),

                                                borderRadius:
                                                    BorderRadius.circular(30),
                                              ),

                                              child: const Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    Icons.archive_rounded,
                                                    color: Colors.orange,
                                                    size: 13,
                                                  ),

                                                  SizedBox(width: 4),

                                                  Text(
                                                    "Archived",
                                                    style: TextStyle(
                                                      color: Colors.orange,
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(width: 12),

                                  // =========================
                                  // UNARCHIVE BUTTON
                                  // =========================
                                  InkWell(
                                    borderRadius: BorderRadius.circular(14),

                                    onTap: () {
                                      // unarchive action
                                    },

                                    child: Container(
                                      height: 46,
                                      width: 46,

                                      decoration: BoxDecoration(
                                        color: Colors.blueAccent.withOpacity(
                                          0.12,
                                        ),

                                        borderRadius: BorderRadius.circular(14),
                                      ),

                                      child: const Icon(
                                        Icons.unarchive_rounded,
                                        color: Colors.blueAccent,
                                        size: 22,
                                      ),
                                    ),
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
