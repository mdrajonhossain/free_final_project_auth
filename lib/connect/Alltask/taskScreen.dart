import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freeli/theme/ThemeCubit.dart';
import 'package:freeli/theme/themeList.dart';
import 'package:freeli/controller/api/api_service.dart';
import 'package:intl/intl.dart';
import 'taskItemView.dart';

class TaskScreen extends StatefulWidget {
  const TaskScreen({super.key});

  @override
  State<TaskScreen> createState() => _TaskScreenState();
}

class _TaskScreenState extends State<TaskScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _allTasks = [];
  List<Map<String, dynamic>> _users = [];
  final ScrollController _horizontalScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchTasks();
  }

  @override
  void dispose() {
    _horizontalScrollController.dispose();
    super.dispose();
  }

  void _handleAutoScroll(Offset globalPosition) {
    if (!_horizontalScrollController.hasClients) return;
    double screenWidth = MediaQuery.of(context).size.width;
    double edgeThreshold =
        80.0; // স্ক্রিনের সীমানা থেকে কত দূরে স্ক্রল শুরু হবে
    double scrollAmount = 12.0; // স্ক্রল স্পিড

    if (globalPosition.dx > screenWidth - edgeThreshold) {
      _horizontalScrollController.jumpTo(
        (_horizontalScrollController.offset + scrollAmount).clamp(
          0.0,
          _horizontalScrollController.position.maxScrollExtent,
        ),
      );
    } else if (globalPosition.dx < edgeThreshold) {
      _horizontalScrollController.jumpTo(
        (_horizontalScrollController.offset - scrollAmount).clamp(
          0.0,
          _horizontalScrollController.position.maxScrollExtent,
        ),
      );
    }
  }

  Future<void> _fetchTasks() async {
    try {
      if (!mounted) return;
      setState(() => _isLoading = true);
      final tasks = await ApiServer().fetchTasks();
      if (!mounted) return;
      debugPrint("DEBUG: Fetched ${tasks.length} tasks. Raw data: $tasks");
      setState(() {
        _allTasks = tasks;
        _isLoading = false;
      });

      // Pre-fetch users for the assignee dropdown in the Add Task sheet
      final me = await ApiServer().fetchMe();
      final companyUsers = await ApiServer().fetchAllUsers(
        me['company_id'] ?? "",
      );
      if (mounted) {
        setState(() {
          _users = companyUsers;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error loading tasks: $e")));
      }
    }
  }

  Future<void> _showAddTaskSheet(
    String initialStatus,
    AppThemeModel appTheme,
  ) async {
    final bool isDark = appTheme.backgroundColor.computeLuminance() < 0.5;
    final TextEditingController titleController = TextEditingController();
    String priority = "Medium";
    DateTime? selectedDate;
    String? selectedAssignee;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            left: 20,
            right: 20,
            top: 20,
          ),
          decoration: BoxDecoration(
            color: appTheme.backgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                "Quick Task - $initialStatus",
                style: TextStyle(
                  color: appTheme.textColor,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: titleController,
                autofocus: true,
                style: TextStyle(color: appTheme.textColor),
                decoration: InputDecoration(
                  hintText: "What needs to be done?",
                  hintStyle: TextStyle(color: appTheme.subTextColor),
                  filled: true,
                  fillColor: isDark
                      ? Colors.white.withOpacity(0.05)
                      : Colors.black.withOpacity(0.03),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: priority,
                      dropdownColor: appTheme.backgroundColor,
                      style: TextStyle(color: appTheme.textColor),
                      decoration: InputDecoration(
                        labelText: "Priority",
                        labelStyle: TextStyle(color: appTheme.subTextColor),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: ["Low", "Medium", "High", "Urgent"]
                          .map(
                            (p) => DropdownMenuItem(value: p, child: Text(p)),
                          )
                          .toList(),
                      onChanged: (v) => setSheetState(() => priority = v!),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(
                            const Duration(days: 365),
                          ),
                        );
                        if (date != null)
                          setSheetState(() => selectedDate = date);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: isDark ? Colors.white30 : Colors.black26,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          selectedDate == null
                              ? "Due Date"
                              : DateFormat('MMM d, y').format(selectedDate!),
                          style: TextStyle(
                            color: selectedDate == null
                                ? appTheme.subTextColor
                                : appTheme.textColor,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedAssignee,
                hint: Text(
                  "Assign to...",
                  style: TextStyle(color: appTheme.subTextColor),
                ),
                dropdownColor: appTheme.backgroundColor,
                style: TextStyle(color: appTheme.textColor),
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: _users.map((u) {
                  return DropdownMenuItem(
                    value: (u['id'] ?? u['_id']).toString(),
                    child: Text(u['firstname'] ?? u['name'] ?? "User"),
                  );
                }).toList(),
                onChanged: (v) => setSheetState(() => selectedAssignee = v),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () async {
                    if (titleController.text.isNotEmpty) {
                      final newTask = await ApiServer().createTask(
                        titleController.text,
                        initialStatus,
                        priority,
                        dueDate: selectedDate != null
                            ? DateFormat('yyyy-MM-dd').format(selectedDate!)
                            : null,
                        assignTo: selectedAssignee,
                      );
                      if (newTask != null) {
                        _fetchTasks();
                        if (context.mounted) Navigator.pop(context);
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: appTheme.accentColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    "Create Task",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _moveTask(
    String taskId,
    String newStatus, {
    int? newIndex,
  }) async {
    // Optimistic UI Update
    setState(() {
      final taskIndex = _allTasks.indexWhere((t) => t['id'] == taskId);
      if (taskIndex != -1) {
        final task = _allTasks.removeAt(taskIndex);
        task['status'] = newStatus;

        if (newIndex == null) {
          // Drop on empty space adds to the end
          _allTasks.add(task);
        } else {
          // Insertion logic: find the nth occurrence of this status in the global list
          int count = 0;
          int insertAtGlobal = _allTasks.length;
          for (int i = 0; i < _allTasks.length; i++) {
            if (_allTasks[i]['status'] == newStatus) {
              if (count == newIndex) {
                insertAtGlobal = i;
                break;
              }
              count++;
            }
          }
          _allTasks.insert(insertAtGlobal, task);
        }
      }
    });

    try {
      final result = await ApiServer().updateSingleTask(
        taskId: taskId,
        status: newStatus,
      );

      if (result == null) {
        throw Exception("Server returned an empty response.");
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to update task status: ${e.toString()}"),
          ),
        );
      }
      _fetchTasks(); // Rollback to server state
    }
  }

  List<Map<String, dynamic>> _getColumnsData() {
    return [
      {
        "title": "Not Started",
        "status": "Not Started",
        "color": Colors.blueAccent,
        "tasks": _allTasks.where((t) => t['status'] == 'Not Started').toList(),
      },
      {
        "title": "In Process",
        "status": "In Progress",
        "color": Colors.orangeAccent,
        "tasks": _allTasks.where((t) => t['status'] == 'In Progress').toList(),
      },
      {
        "title": "On Hold",
        "status": "On Hold",
        "color": Colors.amber,
        "tasks": _allTasks.where((t) => t['status'] == 'On Hold').toList(),
      },
      {
        "title": "Completed",
        "status": "Completed",
        "color": Colors.greenAccent,
        "tasks": _allTasks.where((t) => t['status'] == 'Completed').toList(),
      },
      {
        "title": "Canceled",
        "status": "Canceled",
        "color": Colors.redAccent,
        "tasks": _allTasks.where((t) => t['status'] == 'Canceled').toList(),
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    final columnsData = _getColumnsData();
    return BlocBuilder<ThemeCubit, AppThemeModel>(
      builder: (context, appTheme) {
        return Scaffold(
          backgroundColor: appTheme.backgroundColor,
          floatingActionButton: FloatingActionButton(
            onPressed: () => _showAddTaskSheet("Not Started", appTheme),
            backgroundColor: appTheme.accentColor,
            child: const Icon(Icons.add, color: Colors.white),
          ),
          body: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _fetchTasks,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 16, bottom: 85),
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: columnsData.length,
                      itemBuilder: (context, index) {
                        return _buildKanbanColumn(columnsData[index], appTheme);
                      },
                    ),
                  ),
                ),
        );
      },
    );
  }

  Widget _buildKanbanColumn(
    Map<String, dynamic> column,
    AppThemeModel appTheme,
  ) {
    final bool isDark = appTheme.backgroundColor.computeLuminance() < 0.5;

    return DragTarget<Map<String, dynamic>>(
      onWillAccept: (data) => true, // একই কলামে ড্রপ করার অনুমতি দেওয়া হলো
      onAccept: (task) => _moveTask(task['id'].toString(), column['status']),
      builder: (context, candidateData, rejectedData) {
        return Container(
          width: 280,
          margin: const EdgeInsets.only(right: 16),
          decoration: BoxDecoration(
            color: isDark
                ? (candidateData.isNotEmpty
                      ? appTheme.accentColor.withOpacity(0.15)
                      : appTheme.msgBackgroundColor.withOpacity(0.6))
                : Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: candidateData.isNotEmpty
                ? Border.all(color: appTheme.accentColor, width: 2)
                : null,
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: column['color'],
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      column['title'],
                      style: TextStyle(
                        color: appTheme.textColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      "${(column['tasks'] as List).length}",
                      style: TextStyle(
                        color: appTheme.subTextColor,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
                  itemCount: (column['tasks'] as List).length,
                  itemBuilder: (context, index) {
                    final task = column['tasks'][index];
                    return DragTarget<Map<String, dynamic>>(
                      onWillAccept: (data) => data?['id'] != task['id'],
                      onAccept: (draggedTask) => _moveTask(
                        draggedTask['id'].toString(),
                        column['status'],
                        newIndex: index,
                      ),
                      builder: (context, itemCandidateData, _) {
                        bool isHovered = itemCandidateData.isNotEmpty;
                        return Column(
                          children: [
                            if (isHovered)
                              Container(
                                height: 4,
                                margin: const EdgeInsets.only(bottom: 8),
                                decoration: BoxDecoration(
                                  color: appTheme.accentColor,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            LongPressDraggable<Map<String, dynamic>>(
                              data: task,
                              onDragUpdate: (details) {
                                _handleAutoScroll(details.globalPosition);
                              },
                              feedback: Material(
                                elevation: 12,
                                borderRadius: BorderRadius.circular(12),
                                color: Colors.transparent,
                                child: Transform.rotate(
                                  angle: 0.04,
                                  child: SizedBox(
                                    width: 220,
                                    child: Opacity(
                                      opacity: 0.9,
                                      child: _buildTaskCard(
                                        task,
                                        appTheme,
                                        isDark,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              childWhenDragging: Opacity(
                                opacity: 0.2, // Ghost original item
                                child: _buildTaskCard(task, appTheme, isDark),
                              ),
                              child: GestureDetector(
                                onTap: () {
                                  showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    useSafeArea: true,
                                    builder: (context) => TaskDetailsPage(
                                      task['id'].toString(),
                                      appTheme,
                                    ),
                                  );
                                },
                                child: _buildTaskCard(task, appTheme, isDark),
                              ),
                            ),
                          ],
                        );
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
  }

  Widget _buildTaskCard(
    Map<String, dynamic> task,
    AppThemeModel appTheme,
    bool isDark,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? appTheme.msgReceiverBubble : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.05)
              : Colors.black.withOpacity(0.05),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.4 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPriorityBadge(task['priority']),
          const SizedBox(height: 12),
          Text(
            task['title'],
            style: TextStyle(
              color: appTheme.textColor,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(
                Icons.calendar_today_outlined,
                size: 12,
                color: appTheme.subTextColor,
              ),
              const SizedBox(width: 6),
              Text(
                task['due_date'] ?? task['date'] ?? "No date",
                style: TextStyle(color: appTheme.subTextColor, fontSize: 11),
              ),
              const Spacer(),
              CircleAvatar(
                radius: 12,
                backgroundColor: appTheme.accentColor.withOpacity(0.1),
                child: Builder(
                  builder: (context) {
                    final List? assigneeIds = task['assignee_ids'];
                    final String? firstId = assigneeIds?.isNotEmpty == true
                        ? assigneeIds![0]?.toString()
                        : null;
                    final user = _users.firstWhere(
                      (u) => (u['id'] ?? u['_id']).toString() == firstId,
                      orElse: () => {},
                    );
                    final String name =
                        user['firstname'] ?? user['name'] ?? "?";
                    return Text(
                      name[0].toUpperCase(),
                      style: TextStyle(
                        color: appTheme.accentColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPriorityBadge(String? priority) {
    final String p = priority?.toLowerCase() ?? 'low';
    Color color = Colors.blueAccent;
    if (p == 'high' || p == 'urgent') color = Colors.redAccent;
    if (p == 'medium') color = Colors.orangeAccent;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        priority ?? 'Low',
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
