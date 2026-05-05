import 'package:flutter/material.dart';

class TagsPage extends StatefulWidget {
  final bool isDark;
  final List<dynamic> tags;

  const TagsPage({super.key, required this.isDark, this.tags = const []});

  @override
  State<TagsPage> createState() => _TagsPageState();
}

class _TagsPageState extends State<TagsPage> {
  late List<dynamic> _filteredTags;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filteredTags = widget.tags;
  }

  @override
  void didUpdateWidget(covariant TagsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tags != widget.tags) {
      _runFilter(_searchController.text);
    }
  }

  void _runFilter(String enteredKeyword) {
    List<dynamic> results = [];
    if (enteredKeyword.isEmpty) {
      results = widget.tags;
    } else {
      results = widget.tags
          .where(
            (tag) => (tag['title'] ?? '').toString().toLowerCase().contains(
              enteredKeyword.toLowerCase(),
            ),
          )
          .toList();
    }

    setState(() {
      _filteredTags = results;
    });
  }

  /// Helper to convert hex strings like "#032e84" to Flutter Color
  Color _parseHexColor(String? hexString) {
    if (hexString == null || hexString.isEmpty) return Colors.blue;
    try {
      final buffer = StringBuffer();
      if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
      buffer.write(hexString.replaceFirst('#', ''));
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (_) {
      return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color backgroundColor = widget.isDark
        ? const Color(0xFF030915)
        : const Color(0xFFF4F7FC);

    final Color surfaceColor = widget.isDark
        ? const Color(0xFF052874)
        : Colors.white;

    final Color cardColor = widget.isDark
        ? const Color(0xFF0A327F)
        : Colors.white;

    final Color primaryColor = const Color(0xFF4C8DFF);

    final Color textColor = widget.isDark
        ? Colors.white
        : const Color(0xFF1B1D28);

    final Color subTextColor = widget.isDark ? Colors.white70 : Colors.black54;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            /// HEADER
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Tags - Most recent",
                          style: TextStyle(
                            color: textColor,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Your latest and most active tags",
                          style: TextStyle(color: subTextColor, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            /// SEARCH
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                height: 58,
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(
                        widget.isDark ? 0.15 : 0.06,
                      ),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: _runFilter,
                  style: TextStyle(color: textColor, fontSize: 15),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: "Search tags...",
                    hintStyle: TextStyle(color: subTextColor),
                    prefixIcon: Icon(Icons.search_rounded, color: subTextColor),
                    suffixIcon: Icon(Icons.tune_rounded, color: subTextColor),
                    contentPadding: const EdgeInsets.symmetric(vertical: 18),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            /// TAG LIST
            Expanded(
              child: _filteredTags.isEmpty
                  ? Center(
                      child: Text(
                        "No tags found",
                        style: TextStyle(color: subTextColor),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: _filteredTags.length,
                      itemBuilder: (context, index) {
                        final tag = _filteredTags[index];
                        final String title = tag['title'] ?? 'Untitled';
                        final int count = tag['i_connected'] ?? 0;
                        final Color tagColor = _parseHexColor(tag['tag_color']);

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: widget.isDark
                                  ? Colors.white.withOpacity(0.05)
                                  : Colors.grey.withOpacity(0.08),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(
                                  widget.isDark ? 0.18 : 0.05,
                                ),
                                blurRadius: 18,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              const SizedBox(width: 10),

                              /// BULLET INDICATOR
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: tagColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 12),

                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "$title ($count)",
                                      style: TextStyle(
                                        color: textColor,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              /// ACTION BUTTON
                              Container(
                                height: 25,
                                width: 25,
                                decoration: BoxDecoration(
                                  color: widget.isDark
                                      ? Colors.white.withOpacity(0.08)
                                      : Colors.grey.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Icon(
                                  Icons.push_pin_rounded,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
