import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freeli/theme/ThemeCubit.dart';
import 'package:freeli/theme/themeList.dart';

class TaskScreen extends StatefulWidget {
  const TaskScreen({super.key});

  @override
  State<TaskScreen> createState() => _TaskScreenState();
}

class _TaskScreenState extends State<TaskScreen> {
  // Mock data for professional Kanban UI
  final List<Map<String, dynamic>> _columns = [
    {
      "title": "To Do",
      "color": Colors.blueAccent,
      "tasks": [
        {
          "title": "Design System Review",
          "priority": "High",
          "date": "Oct 28",
          "assignee": "JD",
        },
        {
          "title": "Backend API Docs",
          "priority": "Medium",
          "date": "Oct 30",
          "assignee": "AS",
        },
        {
          "title": "Security Audit",
          "priority": "Urgent",
          "date": "Nov 02",
          "assignee": "BK",
        },
      ],
    },
    {
      "title": "In Progress",
      "color": Colors.orangeAccent,
      "tasks": [
        {
          "title": "Kanban UI Implementation",
          "priority": "High",
          "date": "Oct 26",
          "assignee": "ME",
        },
        {
          "title": "Auth Middleware",
          "priority": "Medium",
          "date": "Oct 27",
          "assignee": "JD",
        },
      ],
    },
    {
      "title": "Review",
      "color": Colors.purpleAccent,
      "tasks": [
        {
          "title": "Filehub Integration",
          "priority": "Low",
          "date": "Oct 24",
          "assignee": "RT",
        },
      ],
    },
    {
      "title": "Done",
      "color": Colors.greenAccent,
      "tasks": [
        {
          "title": "Project Initialization",
          "priority": "Low",
          "date": "Oct 20",
          "assignee": "ME",
        },
        {
          "title": "Theme Management",
          "priority": "Medium",
          "date": "Oct 22",
          "assignee": "AS",
        },
      ],
    },
  ];

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, AppThemeModel>(
      builder: (context, appTheme) {
        return Scaffold(
          backgroundColor: appTheme.backgroundColor,
          body: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _columns.length,
              itemBuilder: (context, index) {
                return _buildKanbanColumn(_columns[index], appTheme);
              },
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

    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: isDark
            ? appTheme.msgBackgroundColor.withOpacity(0.6)
            : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
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
                  style: TextStyle(color: appTheme.subTextColor, fontSize: 13),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: (column['tasks'] as List).length,
              itemBuilder: (context, index) {
                final task = column['tasks'][index];
                return _buildTaskCard(task, appTheme, isDark);
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: InkWell(
              onTap: () {},
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add, size: 20, color: appTheme.accentColor),
                    const SizedBox(width: 4),
                    Text(
                      "Add Item",
                      style: TextStyle(
                        color: appTheme.accentColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
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
                task['date'],
                style: TextStyle(color: appTheme.subTextColor, fontSize: 11),
              ),
              const Spacer(),
              CircleAvatar(
                radius: 12,
                backgroundColor: appTheme.accentColor.withOpacity(0.1),
                child: Text(
                  task['assignee'],
                  style: TextStyle(
                    color: appTheme.accentColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPriorityBadge(String priority) {
    Color color = Colors.blueAccent;
    if (priority.toLowerCase() == 'high' || priority.toLowerCase() == 'urgent')
      color = Colors.redAccent;
    if (priority.toLowerCase() == 'medium') color = Colors.orangeAccent;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        priority,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
