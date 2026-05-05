import 'package:flutter/material.dart';

class LinksPage extends StatelessWidget {
  final bool isDark;
  const LinksPage({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final Color backgroundColor = isDark
        ? const Color(0xFF030915)
        : const Color(0xFFF4F7FC);

    final Color surfaceColor = isDark ? const Color(0xFF052874) : Colors.white;
    final Color cardColor = isDark ? const Color(0xFF0A327F) : Colors.white;
    final Color primaryColor = const Color(0xFF4C8DFF);

    final Color textColor = isDark ? Colors.white : const Color(0xFF1B1D28);
    final Color subTextColor = isDark ? Colors.white70 : Colors.black54;

    final List<Map<String, dynamic>> links = [
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
                  Container(
                    height: 48,
                    width: 48,
                    decoration: BoxDecoration(
                      color: primaryColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.add_link_rounded,
                      color: Colors.white,
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
                      color: Colors.black.withOpacity(isDark ? 0.15 : 0.06),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: TextField(
                  style: TextStyle(color: textColor, fontSize: 15),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: "Search links...",
                    hintStyle: TextStyle(color: subTextColor),
                    prefixIcon: Icon(Icons.search_rounded, color: subTextColor),
                    suffixIcon: Icon(Icons.tune_rounded, color: subTextColor),
                    contentPadding: const EdgeInsets.symmetric(vertical: 18),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            /// QUICK SHARE BANNER
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF052874)
                      : const Color(0xFF0A3BA8),
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF052874).withOpacity(0.15),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Quick Share',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Manage and access your important links instantly.',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 22),

            /// LINK LIST
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: links.length,
                itemBuilder: (context, index) {
                  final link = links[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withOpacity(0.05)
                            : Colors.grey.withOpacity(0.08),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(isDark ? 0.18 : 0.05),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          height: 50,
                          width: 50,
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withOpacity(0.08)
                                : Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            link['icon'],
                            color: isDark
                                ? Colors.white70
                                : const Color(0xFF4C8DFF),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                link['title'],
                                style: TextStyle(
                                  color: textColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                link['url'],
                                style: TextStyle(
                                  color: subTextColor,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          height: 32,
                          width: 32,
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
