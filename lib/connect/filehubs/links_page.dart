import 'package:flutter/material.dart';
import 'package:freeli/controller/api/api_service.dart';
import 'FileHubSkeleton.dart';
import 'package:url_launcher/url_launcher.dart'; // For opening links

class LinksPage extends StatefulWidget {
  final bool isDark;
  final List<dynamic> links; // New parameter
  final Future<void> Function() onRefresh;

  const LinksPage({
    super.key,
    required this.isDark,
    required this.links, // Mark as required
    required this.onRefresh,
  });

  @override
  State<LinksPage> createState() => _LinksPageState();
}

class _LinksPageState extends State<LinksPage> {
  bool isLoading = true;

  final TextEditingController _searchController = TextEditingController();
  String _searchText = "";

  @override
  void initState() {
    super.initState();
    // Data is now passed via widget.links, so no need to fetch again here.
    isLoading = false; // Assuming data is loaded by parent
  }

  @override
  void didUpdateWidget(covariant LinksPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.links != oldWidget.links) {
      // If the parent passes new links, update the state
      setState(() {
        isLoading = false; // Data is updated, so not loading
      });
    }
  }

  IconData _getLinkIcon(String? url) {
    if (url == null || url.isEmpty) return Icons.link_rounded;
    final lowUrl = url.toLowerCase();
    if (lowUrl.contains("youtube") || lowUrl.contains("youtu.be"))
      return Icons.play_circle_fill_rounded;
    if (lowUrl.contains("github")) return Icons.code_rounded;
    if (lowUrl.contains("google")) return Icons.travel_explore_rounded;
    if (lowUrl.contains("facebook")) return Icons.facebook_rounded;
    if (lowUrl.contains("linkedin")) return Icons.work_rounded;
    if (lowUrl.contains("figma")) return Icons.palette_rounded;
    if (lowUrl.contains("drive.google")) return Icons.cloud_circle_rounded;
    return Icons.link_rounded;
  }

  String _getTitle(Map<String, dynamic> link) {
    final title = (link['title'] ?? '').toString().trim();
    final url = (link['url'] ?? '').toString();

    /// যদি title empty হয় তাহলে URL hostname show করবে
    if (title.isEmpty) {
      try {
        return Uri.parse(url).host.replaceFirst("www.", "");
      } catch (e) {
        return "Unknown Link";
      }
    }

    return title;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<dynamic> filteredLinks = widget.links.where((link) {
      final String title = _getTitle(link).toLowerCase();

      final String url = (link['url'] ?? '').toString().toLowerCase();

      return title.contains(_searchText.toLowerCase()) ||
          url.contains(_searchText.toLowerCase());
    }).toList();

    final Color backgroundColor = widget.isDark
        ? const Color(0xFF1A3470)
        : const Color(0xFFF4F7FC);

    final Color cardColor = widget.isDark
        ? const Color(0xFF132850)
        : Colors.white;

    final Color textColor = widget.isDark
        ? Colors.white
        : const Color(0xFF1E293B);

    final Color subTextColor = widget.isDark ? Colors.white70 : Colors.black54;

    const Color primaryColor = Color(0xFF4C8DFF);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          // Keep RefreshIndicator for manual refresh
          onRefresh: () async {
            await widget.onRefresh();
          },
          color: primaryColor,
          backgroundColor: cardColor,
          child: Column(
            children: [
              /// HEADER
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 14),
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
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            "All shared links in one place",
                            style: TextStyle(color: subTextColor, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              /// SEARCH BOX
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  height: 56,
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(
                          widget.isDark ? 0.20 : 0.05,
                        ),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
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
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        color: subTextColor,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 18),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              /// TABLE HEADER
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: widget.isDark
                        ? Colors.white.withOpacity(0.05)
                        : Colors.grey.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Text(
                          "Title",
                          style: TextStyle(
                            color: textColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 5,
                        child: Text(
                          "URL",
                          style: TextStyle(
                            color: textColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 50,
                        child: Text(
                          "Open",
                          style: TextStyle(
                            color: textColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 10),

              /// TABLE BODY
              Expanded(
                child: isLoading
                    ? FileHubSkeleton(isDark: widget.isDark, type: 'link')
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

                          final String url = (link['url'] ?? '').toString();

                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: cardColor,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: widget.isDark
                                    ? Colors.white.withOpacity(0.05)
                                    : Colors.grey.withOpacity(0.08),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(
                                    widget.isDark ? 0.15 : 0.04,
                                  ),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                /// TITLE
                                Expanded(
                                  flex: 3,
                                  child: Row(
                                    children: [
                                      Container(
                                        height: 42,
                                        width: 42,
                                        decoration: BoxDecoration(
                                          color: widget.isDark
                                              ? Colors.white.withOpacity(0.06)
                                              : primaryColor.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Icon(
                                          _getLinkIcon(url),
                                          color: widget.isDark
                                              ? Colors.white70
                                              : primaryColor,
                                        ),
                                      ),

                                      const SizedBox(width: 12),

                                      Expanded(
                                        child: Text(
                                          _getTitle(link),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: textColor,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(width: 10),

                                /// URL
                                Expanded(
                                  flex: 5,
                                  child: Text(
                                    url,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: subTextColor,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),

                                const SizedBox(width: 10),

                                /// OPEN BUTTON
                                InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: () async {
                                    final Uri uri = Uri.parse(url);
                                    if (await canLaunchUrl(uri)) {
                                      await launchUrl(
                                        uri,
                                        mode: LaunchMode.externalApplication,
                                      );
                                    } else {
                                      debugPrint("Could not launch $url");
                                    }
                                  },
                                  child: Container(
                                    height: 42,
                                    width: 42,
                                    decoration: BoxDecoration(
                                      color: primaryColor.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.open_in_new_rounded,
                                      color: primaryColor,
                                      size: 20,
                                    ),
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
      ),
    );
  }
}
