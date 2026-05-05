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
    /// COLORS
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
                            letterSpacing: -.5,
                          ),
                        ),

                        const SizedBox(height: 5),

                        Text(
                          "Manage all project tags professionally",
                          style: TextStyle(
                            color: subTextColor,
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),

                  /// TOTAL COUNT
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

            /// SEARCH BOX
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                height: 58,

                decoration: BoxDecoration(
                  color: surfaceColor,

                  borderRadius: BorderRadius.circular(20),

                  border: Border.all(
                    color: widget.isDark
                        ? Colors.white.withOpacity(.05)
                        : Colors.black.withOpacity(.04),
                  ),

                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(.06),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
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

                    hintStyle: TextStyle(color: subTextColor, fontSize: 14),

                    prefixIcon: Icon(Icons.search_rounded, color: subTextColor),

                    suffixIcon: IconButton(
                      onPressed: () {
                        _searchController.clear();
                        _runFilter('');
                      },
                      icon: Icon(Icons.filter_alt_sharp, color: subTextColor),
                    ),

                    contentPadding: const EdgeInsets.symmetric(vertical: 18),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 18),

            /// TAG LIST
            Expanded(
              child: _filteredTags.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off_rounded,
                            size: 60,
                            color: subTextColor,
                          ),

                          const SizedBox(height: 12),

                          Text(
                            "No tags found",
                            style: TextStyle(
                              color: subTextColor,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      physics: const BouncingScrollPhysics(),

                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),

                      itemCount: _filteredTags.length,

                      itemBuilder: (context, index) {
                        final tag = _filteredTags[index];

                        final String title = tag['title'] ?? 'Untitled';

                        final int count = tag['i_connected'] ?? 0;

                        final Color tagColor = _parseHexColor(tag['tag_color']);

                        return Container(
                          margin: const EdgeInsets.only(bottom: 5),

                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 10,
                          ),

                          decoration: BoxDecoration(
                            color: cardColor,

                            borderRadius: BorderRadius.circular(24),

                            border: Border.all(
                              color: widget.isDark
                                  ? Colors.white.withOpacity(.04)
                                  : Colors.black.withOpacity(.03),
                            ),

                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(.08),

                                blurRadius: 24,

                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),

                          child: Row(
                            children: [
                              /// TAG COLOR
                              Container(
                                width: 14,
                                height: 14,

                                decoration: BoxDecoration(
                                  color: tagColor,
                                  shape: BoxShape.circle,

                                  boxShadow: [
                                    BoxShadow(
                                      color: tagColor.withOpacity(.45),
                                      blurRadius: 10,
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(width: 16),

                              /// TITLE
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

                                        fontSize: 15,

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

                              /// ACTION
                              Container(
                                height: 30,
                                width: 30,

                                decoration: BoxDecoration(
                                  color: widget.isDark
                                      ? Colors.white.withOpacity(.06)
                                      : Colors.blue.withOpacity(.08),

                                  borderRadius: BorderRadius.circular(14),
                                ),

                                child: Icon(
                                  Icons.push_pin_rounded,

                                  color: widget.isDark
                                      ? Colors.white70
                                      : Colors.blueGrey,

                                  size: 18,
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
