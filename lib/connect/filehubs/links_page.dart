import 'package:flutter/material.dart';
import 'package:freeli/controller/api/api_service.dart';

class LinksPage extends StatefulWidget {
  final bool isDark;

  const LinksPage({super.key, required this.isDark});

  @override
  State<LinksPage> createState() => _LinksPageState();
}

class _LinksPageState extends State<LinksPage> {
  bool isLoading = false;

  List<Map<String, dynamic>> links = [];

  final TextEditingController _searchController = TextEditingController();
  String _searchText = "";

  @override
  void initState() {
    super.initState();
    getLinkData();
  }

  Future<void> getLinkData() async {
    setState(() {
      isLoading = true;
    });

    try {
      final data = await ApiServer().fetchAllLink();

      print("LINK DATA: $data");

      /// যদি API null দেয় তাহলে fallback data দেখাবে
      if (data != null && data['items'] is List) {
        links = (data['items'] as List).map((e) {
          final map = Map<String, dynamic>.from(e as Map);
          return {
            'title': map['title'],
            'url': map['location'], // API returns 'location'
            'id': map['id'],
          };
        }).toList();
      } else {
        links = [
          {
            'title': 'GitHub Repository',
            'url': 'github.com/flutter/flutter',
            'icon': Icons.code_rounded,
          },
          {
            'title': 'Figma Design',
            'url': 'figma.com/community',
            'icon': Icons.design_services_rounded,
          },
          {
            'title': 'API Documentation',
            'url': 'docs.api.dev/v1',
            'icon': Icons.menu_book_rounded,
          },
          {
            'title': 'Drive Backup',
            'url': 'drive.google.com',
            'icon': Icons.cloud_rounded,
          },
        ];
      }
    } catch (e) {
      print("Error fetching link data: $e");

      /// Error হলে demo data
      links = [
        {
          'title': 'GitHub Repository',
          'url': 'github.com/flutter/flutter',
          'icon': Icons.code_rounded,
        },
        {
          'title': 'Figma Design',
          'url': 'figma.com/community',
          'icon': Icons.design_services_rounded,
        },
      ];
    }

    setState(() {
      isLoading = false;
    });
  }

  IconData _getLinkIcon(String? url) {
    if (url == null) return Icons.link_rounded;
    final String lowUrl = url.toLowerCase();
    if (lowUrl.contains('github.com')) return Icons.code_rounded;
    if (lowUrl.contains('figma.com')) return Icons.design_services_rounded;
    if (lowUrl.contains('drive.google.com')) return Icons.cloud_rounded;
    if (lowUrl.contains('docs.') || lowUrl.contains('/docs'))
      return Icons.menu_book_rounded;
    if (lowUrl.contains('youtube.com') || lowUrl.contains('vimeo.com'))
      return Icons.play_circle_outline_rounded;
    return Icons.link_rounded;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> filteredLinks = links.where((link) {
      final String title = (link['title'] ?? '').toString().toLowerCase();
      final String url = (link['url'] ?? '').toString().toLowerCase();
      return title.contains(_searchText.toLowerCase()) ||
          url.contains(_searchText.toLowerCase());
    }).toList();

    final Color backgroundColor = widget.isDark
        ? const Color(0xFF1A3470)
        : const Color(0xFFF4F7FC);

    final Color surfaceColor = widget.isDark
        ? const Color(0xFF16213E)
        : Colors.white;

    final Color cardColor = widget.isDark
        ? const Color(0xFF1B2945)
        : Colors.white;

    const Color primaryColor = Color(0xFF4C8DFF);

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
                          "Links",
                          style: TextStyle(
                            color: textColor,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Quickly share and access important URLs",
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
                  style: TextStyle(color: textColor, fontSize: 15),
                  onChanged: (value) {
                    setState(() {
                      _searchText = value;
                    });
                  },
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: "Search links...",
                    hintStyle: TextStyle(color: subTextColor),
                    prefixIcon: Icon(Icons.search_rounded, color: subTextColor),
                    suffixIcon: Icon(
                      Icons.filter_list_rounded,
                      color: subTextColor,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 18),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 22),

            /// LIST
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : filteredLinks.isEmpty
                  ? Center(
                      child: Text(
                        "No Links Found",
                        style: TextStyle(color: subTextColor, fontSize: 16),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
                      itemCount: filteredLinks.length,
                      itemBuilder: (context, index) {
                        final link = filteredLinks[index];

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(14),
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
                              /// ICON
                              Container(
                                height: 52,
                                width: 52,
                                decoration: BoxDecoration(
                                  color: widget.isDark
                                      ? Colors.white.withOpacity(0.08)
                                      : Colors.blue.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Icon(
                                  _getLinkIcon(link['url']),
                                  color: widget.isDark
                                      ? Colors.white70
                                      : primaryColor,
                                  size: 24,
                                ),
                              ),

                              const SizedBox(width: 16),

                              /// TEXT
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      link['title'] ?? '',
                                      style: TextStyle(
                                        color: textColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      link['url'] ?? '',
                                      style: TextStyle(
                                        color: subTextColor,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              /// OPEN BUTTON
                              Container(
                                height: 34,
                                width: 34,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  Icons.open_in_new_rounded,
                                  color: subTextColor.withOpacity(0.8),
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
