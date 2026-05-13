import 'package:flutter/material.dart';
import 'package:freeli/controller/api/api_service.dart';

// IMPORTANT: ensure this import exists in your project
// import 'api_server.dart';

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

  Future<void> get_tag_file(String tagId) async {
    print("99999999999999999999999 $tagId");
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// SEARCH FILTER
  void _runFilter(String enteredKeyword) {
    List<dynamic> results = [];

    if (enteredKeyword.trim().isEmpty) {
      results = widget.tags;
    } else {
      results = widget.tags.where((tag) {
        final title = (tag['title'] ?? '').toString().toLowerCase();
        return title.contains(enteredKeyword.toLowerCase());
      }).toList();
    }

    setState(() {
      _filteredTags = results;
    });
  }

  /// HEX COLOR PARSER
  Color _parseHexColor(String? hexString) {
    if (hexString == null || hexString.isEmpty) {
      return Colors.blue;
    }

    try {
      final buffer = StringBuffer();

      if (hexString.length == 6 || hexString.length == 7) {
        buffer.write('ff');
      }

      buffer.write(hexString.replaceFirst('#', ''));

      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (_) {
      return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = widget.isDark
        ? const Color(0xFF1A3470)
        : const Color(0xFFF4F7FC);

    final surfaceColor = widget.isDark ? const Color(0xFF132850) : Colors.white;

    final cardColor = widget.isDark ? const Color(0xFF102347) : Colors.white;

    final textColor = widget.isDark ? Colors.white : const Color(0xFF1B1D28);

    final subTextColor = widget.isDark ? Colors.white70 : Colors.black54;

    return Scaffold(
      backgroundColor: backgroundColor,

      body: SafeArea(
        child: Column(
          children: [
            /// HEADER
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 18, 22, 14),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Tags",
                          style: TextStyle(
                            color: textColor,
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          "Manage all project tags professionally",
                          style: TextStyle(color: subTextColor, fontSize: 13),
                        ),
                      ],
                    ),
                  ),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: widget.isDark
                          ? Colors.white.withOpacity(.06)
                          : Colors.blue.withOpacity(.08),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Text(
                      "${_filteredTags.length}",
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.bold,
                      ),
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
                  borderRadius: BorderRadius.circular(20),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: _runFilter,
                  style: TextStyle(color: textColor),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: "Search tags...",
                    hintStyle: TextStyle(color: subTextColor),
                    prefixIcon: Icon(Icons.search_rounded, color: subTextColor),
                    contentPadding: const EdgeInsets.symmetric(vertical: 18),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 18),

            /// LIST
            Expanded(
              child: ListView.builder(
                itemCount: _filteredTags.length,
                itemBuilder: (context, index) {
                  final tag = _filteredTags[index];

                  final String title = tag['title'] ?? 'Untitled';
                  final int count = tag['i_connected'] ?? 0;
                  final Color tagColor = _parseHexColor(tag['tag_color']);
                  final String tagId = tag['tag_id'].toString();

                  return GestureDetector(
                    onTap: () {
                      get_tag_file(tagId);
                    },
                    child: Container(
                      margin: const EdgeInsets.only(
                        bottom: 8,
                        left: 10,
                        right: 10,
                      ),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              color: tagColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 16),

                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: textColor,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  "$count connected files",
                                  style: TextStyle(
                                    color: subTextColor,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: subTextColor,
                          ),
                        ],
                      ),
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
