import 'package:flutter/material.dart';

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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),

      // ===== TOP BAR =====
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: const Text(
          "Task Details",
          style: TextStyle(color: Colors.black),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.copy)),
          IconButton(onPressed: () {}, icon: const Icon(Icons.delete)),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close),
          ),
        ],
      ),

      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ===== ROOM =====
                    Row(
                      children: const [
                        Icon(Icons.meeting_room, size: 18),
                        SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            "Room: Md. Mamun Or Rashid Rajon",
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // ===== TITLE =====
                    const Text(
                      "dfgsdfgasdf (Copy)",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 6),

                    const Text(
                      "Created by Md. Mamun Or Rashid Rajon, dated Jun 14, 2026",
                      style: TextStyle(color: Colors.grey),
                    ),

                    const SizedBox(height: 10),

                    // ===== PROJECT =====
                    Row(
                      children: [
                        const Text("Project: Not Defined"),
                        const SizedBox(width: 10),
                        TextButton(
                          onPressed: () {},
                          child: const Text("Add to project"),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // ===== KEYWORD =====
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton(
                          onPressed: () {},
                          child: const Text("+ Add keyword"),
                        ),
                      ],
                    ),

                    const SizedBox(height: 15),

                    // ===== STATUS + PROGRESS =====
                    Row(
                      children: [
                        Expanded(
                          child: _box(
                            "Status",
                            "Not Started",
                            Icons.arrow_forward_ios,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _box(
                            "Progress",
                            "Not Defined",
                            Icons.arrow_forward_ios,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 15),

                    // ===== DATES =====
                    Row(
                      children: [
                        Expanded(child: _inputBox("Start date")),
                        const SizedBox(width: 10),
                        Expanded(child: _inputBox("Due date")),
                        const SizedBox(width: 10),
                        Expanded(child: _inputBox("Due time")),
                      ],
                    ),

                    const SizedBox(height: 15),

                    // ===== ASSIGNED =====
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Assigned"),
                        TextButton(
                          onPressed: () {},
                          child: const Text("Add assignee"),
                        ),
                      ],
                    ),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Observers"),
                        TextButton(
                          onPressed: () {},
                          child: const Text("Add observers"),
                        ),
                      ],
                    ),

                    const SizedBox(height: 15),

                    // ===== TABS =====
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        children: [
                          TabBar(
                            controller: _tabController,
                            isScrollable: true,
                            labelColor: Colors.blue,
                            unselectedLabelColor: Colors.grey,
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
                            height: 180,
                            child: TabBarView(
                              controller: _tabController,
                              children: const [
                                Center(child: Text("Description content")),
                                Center(child: Text("Notes content")),
                                Center(child: Text("No files")),
                                Center(child: Text("0 checklist")),
                                Center(child: Text("Discussion")),
                                Center(child: Text("Notifications")),
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

          // ===== BOTTOM CHAT BAR =====
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey)),
            ),
            child: Row(
              children: [
                const Icon(Icons.mic),
                const SizedBox(width: 10),
                const Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: "Message...",
                      border: InputBorder.none,
                    ),
                  ),
                ),
                const Icon(Icons.emoji_emotions),
                const SizedBox(width: 10),
                ElevatedButton(onPressed: () {}, child: const Text("Send")),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _box(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: Colors.grey)),
              Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          Icon(icon, size: 16),
        ],
      ),
    );
  }

  Widget _inputBox(String hint) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: TextField(
        decoration: InputDecoration(hintText: hint, border: InputBorder.none),
      ),
    );
  }
}
