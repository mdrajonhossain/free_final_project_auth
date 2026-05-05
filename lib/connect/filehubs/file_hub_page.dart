import 'package:flutter/material.dart';

class FileHubPage extends StatelessWidget {
  final bool isDark;
  const FileHubPage({super.key, required this.isDark});

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

    final List<Map<String, dynamic>> files = [
      {
        'name': 'Project_UI.fig',
        'size': '12.5 MB',
        'date': 'Today',
        'icon': Icons.design_services_rounded,
      },
      {
        'name': 'Flutter_Source.zip',
        'size': '28.7 MB',
        'date': 'Yesterday',
        'icon': Icons.folder_zip_rounded,
      },
      {
        'name': 'Presentation.pptx',
        'size': '8.1 MB',
        'date': '2 days ago',
        'icon': Icons.slideshow_rounded,
      },
      {
        'name': 'Database.sql',
        'size': '5.4 MB',
        'date': 'Last week',
        'icon': Icons.storage_rounded,
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
                          "FileHub",
                          style: TextStyle(
                            color: textColor,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Access and manage your cloud files",
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
                      Icons.upload_file_rounded,
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
                    hintText: "Search files...",
                    hintStyle: TextStyle(color: subTextColor),
                    prefixIcon: Icon(Icons.search_rounded, color: subTextColor),
                    suffixIcon: Icon(Icons.tune_rounded, color: subTextColor),
                    contentPadding: const EdgeInsets.symmetric(vertical: 18),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 22),
            Expanded(
              child: ListView.builder(
                itemCount: files.length,
                itemBuilder: (context, index) {
                  final file = files[index];

                  return Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: !isDark
                          ? [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : null,
                    ),
                    child: Row(
                      children: [
                        Container(
                          height: 56,
                          width: 56,
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withOpacity(0.08)
                                : Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            file['icon'],
                            color: isDark
                                ? Colors.white70
                                : const Color(0xFF4C8DFF),
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                file['name'],
                                style: TextStyle(
                                  color: textColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Text(
                                    file['size'],
                                    style: TextStyle(
                                      color: subTextColor,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Container(
                                    width: 4,
                                    height: 4,
                                    decoration: BoxDecoration(
                                      color: subTextColor.withOpacity(0.5),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    file['date'],
                                    style: TextStyle(
                                      color: subTextColor,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
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
                            Icons.more_vert_rounded,
                            color: subTextColor.withOpacity(0.8),
                            size: 20,
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
