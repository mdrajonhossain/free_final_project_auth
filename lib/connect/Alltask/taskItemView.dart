import 'package:flutter/material.dart';
import 'package:freeli/theme/themeList.dart';
import 'package:freeli/controller/api/api_service.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';

class TaskDetailsPage extends StatefulWidget {
  final String taskId;
  final dynamic appTheme;
  final VoidCallback? onUpdate;

  const TaskDetailsPage(this.taskId, this.appTheme, {super.key, this.onUpdate});

  @override
  State<TaskDetailsPage> createState() => _TaskDetailsPageState();
}

class _TaskDetailsPageState extends State<TaskDetailsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  Map<String, dynamic>? _taskData;
  List<dynamic> _allRooms = [];
  List<Map<String, dynamic>> _users = [];
  String _myId = "";
  bool _isEditingTitle = false;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _msgController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _fetchTaskDetails();
  }

  Future<void> _fetchTaskDetails() async {
    try {
      setState(() => _isLoading = true);

      // 1. Get current user to fetch rooms later
      final me = await ApiServer().fetchMe();
      final companyId = me['company_id'] ?? "";
      _myId = (me['id'] ?? me['_id'] ?? "").toString();

      // 2. Fetch all rooms available to this user
      final roomsData = await ApiServer().fetchRooms(_myId);
      final users = await ApiServer().fetchAllUsers(companyId);

      final response = await ApiServer().fetchSingleTask(widget.taskId);
      if (mounted) {
        setState(() {
          _allRooms = roomsData['rooms'] ?? [];
          _users = users;
          _taskData = response;
          _titleController.text = response?['task_title'] ?? "";
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showRoomSelectionSheet(AppThemeModel appTheme, bool isDark) {
    String searchQuery = "";
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: appTheme.backgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setInternalState) {
            final filteredRooms = _allRooms.where((room) {
              final title = room['title']?.toString().toLowerCase() ?? "";
              return title.contains(searchQuery.toLowerCase());
            }).toList();

            return Container(
              height: MediaQuery.of(context).size.height * 0.7,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.black12,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  Text(
                    "Move Task to Room",
                    style: TextStyle(
                      color: appTheme.textColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    style: TextStyle(color: appTheme.textColor),
                    onChanged: (v) => setInternalState(() => searchQuery = v),
                    decoration: InputDecoration(
                      hintText: "Search Room...",
                      hintStyle: TextStyle(color: appTheme.subTextColor),
                      prefixIcon: Icon(
                        Icons.search,
                        color: appTheme.subTextColor,
                      ),
                      filled: true,
                      fillColor: isDark
                          ? Colors.white.withOpacity(0.05)
                          : Colors.black.withOpacity(0.03),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: filteredRooms.isEmpty
                        ? Center(
                            child: Text(
                              "No rooms found",
                              style: TextStyle(color: appTheme.subTextColor),
                            ),
                          )
                        : ListView.builder(
                            itemCount: filteredRooms.length,
                            itemBuilder: (context, index) {
                              final room = filteredRooms[index];
                              final bool isSelected =
                                  room['conversation_id'] ==
                                  _taskData?['conversation_id'];
                              return ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: CircleAvatar(
                                  backgroundColor: appTheme.accentColor
                                      .withOpacity(0.1),
                                  child: Icon(
                                    Icons.meeting_room,
                                    color: appTheme.accentColor,
                                    size: 20,
                                  ),
                                ),
                                title: Text(
                                  room['title'] ?? "Untitled Room",
                                  style: TextStyle(
                                    color: appTheme.textColor,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                                trailing: isSelected
                                    ? Icon(
                                        Icons.check_circle,
                                        color: appTheme.accentColor,
                                      )
                                    : null,
                                onTap: () {
                                  _updateTaskRoom(room);
                                  Navigator.pop(context);
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _updateTaskRoom(Map<String, dynamic> room) async {
    try {
      setState(() => _isLoading = true);
      final updatedTask = await ApiServer().updateSingleTask(
        taskId: widget.taskId,
        conversationId: room['conversation_id'],
        conversationName: room['title'],
        conversationImg: room['conv_img'] ?? room['img'] ?? "",
        participants: room['participants'] ?? [],
        saveType: "conversation",
      );

      if (updatedTask != null && mounted) {
        setState(() {
          _taskData?['conversation_id'] = updatedTask['conversation_id'];
          _taskData?['conversation_name'] = updatedTask['conversation_name'];
          _taskData?['conversation_img'] = updatedTask['conversation_img'];
        });
        widget.onUpdate?.call();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Task moved successfully")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error moving task: ${e.toString()}")),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateTaskTitle() async {
    final newTitle = _titleController.text.trim();
    if (newTitle.isEmpty) {
      setState(() {
        _titleController.text = _taskData?['task_title'] ?? "";
        _isEditingTitle = false;
      });
      return;
    }

    try {
      setState(() => _isLoading = true);
      final updated = await ApiServer().updateSingleTask(
        taskId: widget.taskId,
        title: newTitle,
        saveType: "task_title",
      );
      if (updated != null && mounted) {
        setState(() {
          _taskData?['task_title'] = updated['task_title'];
          _isEditingTitle = false;
        });
        widget.onUpdate?.call();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error updating title: $e")));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateTaskStatus(String? newStatus) async {
    if (newStatus == null || newStatus == _taskData?['status']) return;
    try {
      setState(() => _isLoading = true);
      final result = await ApiServer().updateSingleTask(
        taskId: widget.taskId,
        status: newStatus,
        saveType: "status",
      );
      if (result != null && mounted) {
        setState(() {
          _taskData?['status'] = result['status'];
        });
        widget.onUpdate?.call();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error updating status: $e")));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateTaskProgress(dynamic newProgress) async {
    if (newProgress == null || newProgress == _taskData?['progress']) return;
    try {
      setState(() => _isLoading = true);
      final result = await ApiServer().updateSingleTask(
        taskId: widget.taskId,
        progress: newProgress,
        saveType: "progress",
      );
      if (result != null && mounted) {
        setState(() {
          _taskData?['progress'] = result['progress'];
        });
        widget.onUpdate?.call();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error updating progress: $e")));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteTask() async {
    final appTheme = widget.appTheme;
    final bool confirm =
        await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: appTheme.backgroundColor,
            title: Text(
              "Delete Task",
              style: TextStyle(color: appTheme.textColor),
            ),
            content: Text(
              "Are you sure you want to delete this task?",
              style: TextStyle(color: appTheme.subTextColor),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  "Cancel",
                  style: TextStyle(color: appTheme.subTextColor),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  "Delete",
                  style: TextStyle(color: Colors.redAccent),
                ),
              ),
            ],
          ),
        ) ??
        false;

    if (confirm && mounted) {
      try {
        setState(() => _isLoading = true);
        final result = await ApiServer().deleteTask(widget.taskId);
        if (result != null && result['status'] == true) {
          widget.onUpdate?.call();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result['message'] ?? "Task deleted successfully"),
              ),
            );
          }
          Navigator.pop(context);
        }
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _msgController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appTheme = widget.appTheme;
    final bool isDark = appTheme.backgroundColor.computeLuminance() < 0.5;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: appTheme.backgroundColor,
        body: _buildSkeleton(appTheme, isDark),
      );
    }

    final data = _taskData ?? {};

    return Scaffold(
      backgroundColor: appTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: appTheme.backgroundColor,
        elevation: 0.5,
        shadowColor: isDark ? Colors.black54 : Colors.black12,
        centerTitle: true,
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
          IconButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: data['task_title'] ?? ""));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Task title copied")),
              );
            },
            icon: const Icon(Icons.copy_outlined, size: 20),
          ),
          IconButton(
            onPressed: _deleteTask,
            icon: const Icon(
              Icons.delete_outline,
              size: 20,
              color: Colors.redAccent,
            ),
          ),
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
                    InkWell(
                      onTap: () => _showRoomSelectionSheet(appTheme, isDark),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Icon(
                              Icons.meeting_room_outlined,
                              size: 18,
                              color: appTheme.accentColor,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                "Room: ${data['conversation_name'] ?? 'General'}",
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: appTheme.subTextColor,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.edit_outlined,
                              size: 14,
                              color: appTheme.accentColor,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _isEditingTitle
                        ? TextField(
                            controller: _titleController,
                            autofocus: true,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: appTheme.textColor,
                              letterSpacing: -0.5,
                            ),
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              suffixIcon: IconButton(
                                icon: const Icon(
                                  Icons.check,
                                  color: Colors.green,
                                ),
                                onPressed: _updateTaskTitle,
                              ),
                            ),
                            onSubmitted: (_) => _updateTaskTitle(),
                          )
                        : GestureDetector(
                            onTap: () => setState(() => _isEditingTitle = true),
                            child: Text(
                              data['task_title'] ?? "Untitled Task",
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: appTheme.textColor,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ),
                    const SizedBox(height: 6),
                    Builder(
                      builder: (context) {
                        final creator = _users.firstWhere(
                          (u) =>
                              (u['id'] ?? u['_id']).toString() ==
                              data['created_by'],
                          orElse: () => {},
                        );
                        final String name =
                            creator['firstname'] ??
                            creator['name'] ??
                            "Unknown";
                        final String date = data['created_at'] != null
                            ? DateFormat(
                                'MMM d, yyyy',
                              ).format(DateTime.parse(data['created_at']))
                            : 'N/A';
                        return Text(
                          "Created by $name at $date",
                          style: TextStyle(
                            color: appTheme.subTextColor,
                            fontSize: 12,
                          ),
                        );
                      },
                    ),
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
                          data['project_title'] ?? "Not Defined",
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
                          Icons.flag_outlined,
                          size: 22,
                          color: appTheme.subTextColor,
                        ),
                        const SizedBox(width: 8),
                        Wrap(
                          spacing: 8,
                          children: [
                            ...(data['key_words'] as List? ?? []).map(
                              (word) => _buildTag(appTheme, word, isDark),
                            ),
                            _buildMiniAction(appTheme, "+ Add a Keyword"),
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
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? appTheme.msgReceiverBubble
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isDark
                                    ? Colors.white10
                                    : Colors.black.withOpacity(0.05),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Status",
                                  style: TextStyle(
                                    color: appTheme.subTextColor,
                                    fontSize: 11,
                                  ),
                                ),
                                DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: data['status'] ?? "Not Started",
                                    isExpanded: true,
                                    isDense: true,
                                    icon: Icon(
                                      Icons.keyboard_arrow_down,
                                      size: 16,
                                      color: appTheme.accentColor,
                                    ),
                                    dropdownColor: appTheme.backgroundColor,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: appTheme.textColor,
                                      fontSize: 13,
                                    ),
                                    items:
                                        [
                                          "Not Started",
                                          "In Progress",
                                          "On Hold",
                                          "Completed",
                                          "Canceled",
                                        ].map((String value) {
                                          return DropdownMenuItem<String>(
                                            value: value,
                                            child: Text(value),
                                          );
                                        }).toList(),
                                    onChanged: _updateTaskStatus,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? appTheme.msgReceiverBubble
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isDark
                                    ? Colors.white10
                                    : Colors.black.withOpacity(0.05),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Progress",
                                  style: TextStyle(
                                    color: appTheme.subTextColor,
                                    fontSize: 11,
                                  ),
                                ),
                                DropdownButtonHideUnderline(
                                  child: DropdownButton<dynamic>(
                                    value:
                                        ([
                                          0,
                                          25,
                                          50,
                                          75,
                                          96,
                                          98,
                                          100,
                                        ].contains(data['progress']))
                                        ? data['progress']
                                        : 0,
                                    isExpanded: true,
                                    isDense: true,
                                    icon: Icon(
                                      Icons.keyboard_arrow_down,
                                      size: 16,
                                      color: appTheme.accentColor,
                                    ),
                                    dropdownColor: appTheme.backgroundColor,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: appTheme.textColor,
                                      fontSize: 13,
                                    ),
                                    items:
                                        {
                                          0: "Not Defined",
                                          25: "Stage 1",
                                          50: "Stage 2",
                                          75: "Stage 3",
                                          96: "Final Stage",
                                          98: "Penultimate Stage",
                                          100: "Ultimate Stage",
                                        }.entries.map((entry) {
                                          return DropdownMenuItem<dynamic>(
                                            value: entry.key,
                                            child: Text(entry.value),
                                          );
                                        }).toList(),
                                    onChanged: _updateTaskProgress,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _inputBox(
                            data['start_date'] != null
                                ? DateFormat(
                                    'MMM d, y',
                                  ).format(DateTime.parse(data['start_date']))
                                : "Start date",
                            Icons.calendar_today,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _inputBox(
                            data['end_date'] != null
                                ? DateFormat(
                                    'MMM d, y',
                                  ).format(DateTime.parse(data['end_date']))
                                : "Due date",
                            Icons.event,
                          ),
                        ),
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
                          data['assign_to']?.isNotEmpty == true
                              ? "Assigned"
                              : "Unassigned",
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
                          "${(data['observers'] as List? ?? []).length} observers",
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
                            tabs: [
                              Tab(text: "Description"),
                              Tab(text: "Notes"),
                              Tab(
                                text:
                                    "Files (${(data['files'] as List? ?? []).length})",
                              ),
                              Tab(
                                text:
                                    "Checklists (${(data['checklists'] as List? ?? []).length})",
                              ),
                              Tab(
                                text:
                                    "Discussion (${(data['discussion'] as List? ?? []).length})",
                              ),
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
                                  data['description']?.toString().isNotEmpty ==
                                          true
                                      ? data['description']
                                      : "No description provided.",
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

  Widget _buildSkeleton(AppThemeModel appTheme, bool isDark) {
    final Color skeletonColor = isDark
        ? Colors.white.withOpacity(0.08)
        : Colors.black.withOpacity(0.04);

    return Column(
      children: [
        const SizedBox(height: 8),
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
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Room row skeleton
                Row(
                  children: [
                    Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: skeletonColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      width: 140,
                      height: 14,
                      decoration: BoxDecoration(
                        color: skeletonColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Title skeleton
                Container(
                  height: 28,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: skeletonColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                // Created at skeleton
                Container(
                  height: 12,
                  width: 120,
                  decoration: BoxDecoration(
                    color: skeletonColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 30),
                // Overview header
                Container(
                  height: 10,
                  width: 70,
                  decoration: BoxDecoration(
                    color: skeletonColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                // Project row skeleton
                Row(
                  children: [
                    Container(width: 16, height: 16, color: skeletonColor),
                    const SizedBox(width: 8),
                    Container(
                      width: 100,
                      height: 14,
                      decoration: BoxDecoration(
                        color: skeletonColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Schedule header
                Container(
                  height: 10,
                  width: 100,
                  decoration: BoxDecoration(
                    color: skeletonColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                // Status/Progress boxes
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 55,
                        decoration: BoxDecoration(
                          color: skeletonColor,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Container(
                        height: 55,
                        decoration: BoxDecoration(
                          color: skeletonColor,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Date boxes
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 40,
                        decoration: BoxDecoration(
                          color: skeletonColor,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Container(
                        height: 40,
                        decoration: BoxDecoration(
                          color: skeletonColor,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                // People header
                Container(
                  height: 10,
                  width: 60,
                  decoration: BoxDecoration(
                    color: skeletonColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                // Assignee row
                Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: skeletonColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      width: 150,
                      height: 25,
                      decoration: BoxDecoration(
                        color: skeletonColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // TabBar skeleton
                Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: skeletonColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
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

  Color _getPriorityColor(String? priority) {
    final p = priority?.toLowerCase() ?? '';
    if (p == 'high' || p == 'urgent') return Colors.redAccent;
    if (p == 'medium') return Colors.orangeAccent;
    return Colors.blueAccent;
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
