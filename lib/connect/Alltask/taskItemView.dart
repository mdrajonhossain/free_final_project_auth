import 'package:flutter/material.dart';
import 'package:freeli/theme/themeList.dart';
import 'package:intl/intl.dart';

class TaskDetailsPage extends StatefulWidget {
  final String taskId;
  final dynamic appTheme;

  const TaskDetailsPage(this.taskId, this.appTheme, {super.key});

  @override
  State<TaskDetailsPage> createState() => _TaskDetailsPageState();
}

class _TaskDetailsPageState extends State<TaskDetailsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _msgController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
  }

  @override
  void dispose() {
    _msgController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppThemeModel appTheme = widget.appTheme;
    final bool isDark = appTheme.backgroundColor.computeLuminance() < 0.5;

    return Scaffold(
      backgroundColor: appTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: appTheme.backgroundColor,
        elevation: 0.5,
        shadowColor: isDark ? Colors.black54 : Colors.black12,
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close, size: 22),
        ),
        title: Text(
          "Task Details",
          style: TextStyle(
            color: appTheme.textColor,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        iconTheme: IconThemeData(color: appTheme.textColor),
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.more_horiz)),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Handle for the BottomSheet
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black12,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.meeting_room_outlined,
                          size: 18,
                          color: appTheme.accentColor,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            "Room: General Discussion",
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: appTheme.subTextColor,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "dfgsdfgasdf (Copy)",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: appTheme.textColor,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Created by Md. Mamun Or Rashid Rajon, dated Jun 14, 2026",
                      style: TextStyle(
                        color: appTheme.subTextColor,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildSectionHeader(appTheme, "Overview"),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          Icons.work_outline,
                          size: 16,
                          color: appTheme.subTextColor,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "Project: ",
                          style: TextStyle(
                            color: appTheme.subTextColor,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          "Not Defined",
                          style: TextStyle(
                            color: appTheme.textColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        const Spacer(),
                        _buildMiniAction(appTheme, "Change"),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          Icons.label_outline,
                          size: 16,
                          color: appTheme.subTextColor,
                        ),
                        const SizedBox(width: 8),
                        Wrap(
                          spacing: 8,
                          children: [
                            _buildTag(appTheme, "Internal", isDark),
                            _buildTag(
                              appTheme,
                              "Priority",
                              isDark,
                              color: Colors.orange,
                            ),
                            _buildMiniAction(appTheme, "+ Add"),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildSectionHeader(appTheme, "Schedule & Status"),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _box(
                            "Status",
                            "Not Started",
                            Icons.radio_button_unchecked,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _box(
                            "Progress",
                            "Not Defined",
                            Icons.trending_up,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _inputBox("Start date", Icons.calendar_today),
                        ),
                        const SizedBox(width: 10),
                        Expanded(child: _inputBox("Due date", Icons.event)),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildSectionHeader(appTheme, "People"),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildPersonRow(
                          appTheme,
                          "Assigned to",
                          "Md. Mamun Or Rashid",
                          "MR",
                        ),
                        _buildMiniAction(appTheme, "Edit"),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildPersonRow(
                          appTheme,
                          "Observers",
                          "No observers yet",
                          null,
                        ),
                        _buildMiniAction(appTheme, "Add"),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Container(
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        color: isDark
                            ? appTheme.msgReceiverBubble
                            : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isDark ? Colors.white10 : Colors.black12,
                        ),
                      ),
                      child: Column(
                        children: [
                          TabBar(
                            controller: _tabController,
                            isScrollable: true,
                            labelColor: appTheme.accentColor,
                            unselectedLabelColor: appTheme.subTextColor,
                            indicator: UnderlineTabIndicator(
                              borderSide: BorderSide(
                                width: 3.0,
                                color: appTheme.accentColor,
                              ),
                              insets: const EdgeInsets.symmetric(
                                horizontal: 16.0,
                              ),
                            ),
                            indicatorSize: TabBarIndicatorSize.label,
                            labelStyle: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                            unselectedLabelStyle: const TextStyle(
                              fontWeight: FontWeight.normal,
                              fontSize: 13,
                            ),
                            dividerColor: isDark
                                ? Colors.white12
                                : Colors.black12,
                            tabs: const [
                              Tab(text: "Description"),
                              Tab(text: "Notes"),
                              Tab(text: "Files (0)"),
                              Tab(text: "Checklists"),
                              Tab(text: "Discussion"),
                              Tab(text: "Notifications"),
                            ],
                          ),
                          SizedBox(
                            height: 220,
                            child: TabBarView(
                              controller: _tabController,
                              children: [
                                _buildTabEmptyState(
                                  appTheme,
                                  "No description provided for this task.",
                                ),
                                _buildTabEmptyState(
                                  appTheme,
                                  "Private notes can be added here.",
                                ),
                                _buildTabEmptyState(
                                  appTheme,
                                  "Attachments will be listed here.",
                                ),
                                _buildTabEmptyState(
                                  appTheme,
                                  "Create a checklist to track progress.",
                                ),
                                _buildTabEmptyState(
                                  appTheme,
                                  "No comments yet. Start the conversation!",
                                ),
                                _buildTabEmptyState(
                                  appTheme,
                                  "Activity logs will show up here.",
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? appTheme.msgReceiverBubble : Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
              border: Border(
                top: BorderSide(color: isDark ? Colors.white12 : Colors.grey),
              ),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  IconButton(
                    onPressed: () {},
                    icon: Icon(
                      Icons.add_circle_outline,
                      color: appTheme.accentColor,
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _msgController,
                      style: TextStyle(color: appTheme.textColor, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: "Write a message...",
                        hintStyle: TextStyle(
                          color: appTheme.subTextColor.withOpacity(0.6),
                          fontSize: 14,
                        ),
                        filled: true,
                        fillColor: isDark
                            ? Colors.white.withOpacity(0.05)
                            : Colors.black.withOpacity(0.03),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Material(
                    color: appTheme.accentColor,
                    shape: const CircleBorder(),
                    child: IconButton(
                      onPressed: () {},
                      icon: const Icon(
                        Icons.send,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(AppThemeModel appTheme, String title) {
    return Text(
      title.toUpperCase(),
      style: TextStyle(
        color: appTheme.subTextColor,
        fontSize: 11,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.1,
      ),
    );
  }

  Widget _buildMiniAction(AppThemeModel appTheme, String label) {
    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Text(
          label,
          style: TextStyle(
            color: appTheme.accentColor,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildTag(
    AppThemeModel appTheme,
    String text,
    bool isDark, {
    Color? color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: (color ?? appTheme.accentColor).withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color ?? appTheme.accentColor,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildPersonRow(
    AppThemeModel appTheme,
    String label,
    String name,
    String? initials,
  ) {
    return Row(
      children: [
        CircleAvatar(
          radius: 14,
          backgroundColor: initials != null
              ? appTheme.accentColor.withOpacity(0.2)
              : Colors.grey.withOpacity(0.1),
          child: Text(
            initials ?? "?",
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: appTheme.accentColor,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(color: appTheme.subTextColor, fontSize: 11),
            ),
            Text(
              name,
              style: TextStyle(
                color: appTheme.textColor,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTabEmptyState(AppThemeModel appTheme, String text) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(color: appTheme.subTextColor, fontSize: 13),
        ),
      ),
    );
  }

  Widget _box(String title, String value, IconData icon) {
    final appTheme = widget.appTheme;
    final bool isDark = appTheme.backgroundColor.computeLuminance() < 0.5;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? appTheme.msgReceiverBubble : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(color: appTheme.subTextColor, fontSize: 11),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  value,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: appTheme.textColor,
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(icon, size: 14, color: appTheme.accentColor),
            ],
          ),
        ],
      ),
    );
  }

  Widget _inputBox(String hint, IconData icon) {
    final appTheme = widget.appTheme;
    final bool isDark = appTheme.backgroundColor.computeLuminance() < 0.5;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? appTheme.msgReceiverBubble : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: appTheme.subTextColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              hint,
              style: TextStyle(color: appTheme.subTextColor, fontSize: 11),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
