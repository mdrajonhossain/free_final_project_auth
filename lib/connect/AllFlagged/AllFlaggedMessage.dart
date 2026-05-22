import 'package:flutter/material.dart';
import 'package:freeli/controller/api/api_service.dart';

class AllFlaggedMessage extends StatefulWidget {
  final bool isDark;
  final Function(bool) onThemeChange;

  const AllFlaggedMessage({
    super.key,
    required this.isDark,
    required this.onThemeChange,
  });

  @override
  State<AllFlaggedMessage> createState() => _AllFlaggedMessageState();
}

class _AllFlaggedMessageState extends State<AllFlaggedMessage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;

  String _searchQuery = "";
  List<Map<String, dynamic>> flaggedItems = [];

  @override
  void initState() {
    super.initState();

    _tabController = TabController(length: 4, vsync: this);

    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });

    getFlaggedData();
  }

  void getFlaggedData() {
    ApiServer().getAll_ArchivedRoom().then((data) {
      setState(() {
        flaggedItems = List<Map<String, dynamic>>.from(data);
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _filterByTab(String type) {
    return flaggedItems.where((item) {
      final title = (item["title"] ?? item["name"] ?? "")
          .toString()
          .toLowerCase();

      final matchSearch = title.contains(_searchQuery);

      if (type == "all") return matchSearch;

      final itemType = (item["type"] ?? "").toString().toLowerCase();

      return matchSearch && itemType == type;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;

    final bg = isDark ? const Color(0xFF0C1F5E) : const Color(0xFFF5F7FB);
    final card = isDark ? const Color(0xFF152B52) : Colors.white;
    final text = isDark ? Colors.white : const Color(0xFF1E293B);
    final subText = isDark ? Colors.white70 : Colors.black54;
    final searchBg = isDark ? const Color(0xFF1A2F5A) : Colors.white;

    return Scaffold(
      backgroundColor: bg,

      // ================= APP BAR =================
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Flagged Messages",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),

      body: Column(
        children: [
          const SizedBox(height: 12),

          // ================= SEARCH =================
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              decoration: BoxDecoration(
                color: searchBg,
                borderRadius: BorderRadius.circular(14),
              ),
              child: TextField(
                controller: _searchController,
                style: TextStyle(color: text),
                decoration: InputDecoration(
                  hintText: "Search...",
                  hintStyle: TextStyle(color: subText),
                  prefixIcon: Icon(Icons.search_rounded, color: subText),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),

          const SizedBox(height: 14),

          // ================= CLEAN TAB BAR (FIXED) =================
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Container(
              height: 42,

              decoration: BoxDecoration(
                // LIGHT BACKGROUND (NO HEAVY BOX LOOK)
                color: isDark
                    ? const Color(0xFF12284D)
                    : const Color(0xFFEFF3FA),
                borderRadius: BorderRadius.circular(12),
              ),

              child: TabBar(
                controller: _tabController,

                // 👇 IMPORTANT FIX (REMOVED BOX FEEL)
                indicator: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(10),
                ),

                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,

                labelColor: Colors.white,
                unselectedLabelColor: subText,

                labelStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),

                unselectedLabelStyle: const TextStyle(fontSize: 13),

                tabs: const [
                  Tab(text: "All"),
                  Tab(text: "Messages"),
                  Tab(text: "Files"),
                  Tab(text: "Tasks"),
                ],
              ),
            ),
          ),

          const SizedBox(height: 10),

          // ================= LIST =================
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildList(_filterByTab("all"), card, text, subText),
                _buildList(_filterByTab("message"), card, text, subText),
                _buildList(_filterByTab("file"), card, text, subText),
                _buildList(_filterByTab("task"), card, text, subText),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(
    List<Map<String, dynamic>> items,
    Color card,
    Color text,
    Color subText,
  ) {
    if (items.isEmpty) {
      return Center(
        child: Text("No Data Found", style: TextStyle(color: subText)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final chat = items[index];

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: card,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.blue,
                child: Text(
                  (chat["title"] ?? "U")[0].toUpperCase(),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      chat["title"] ?? "Unknown",
                      style: TextStyle(
                        color: text,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      chat["status"] ?? "",
                      style: TextStyle(color: subText, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
