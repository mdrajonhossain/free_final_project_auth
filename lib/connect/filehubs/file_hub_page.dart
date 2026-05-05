import 'package:flutter/material.dart';

class FileHubPage extends StatefulWidget {
  final bool isDark;

  const FileHubPage({super.key, this.isDark = true});

  @override
  State<FileHubPage> createState() => _FileHubPageState();
}

class _FileHubPageState extends State<FileHubPage> {
  int selectedCategory = 1;

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

  @override
  Widget build(BuildContext context) {
    final bool isDark = widget.isDark;

    /// COLORS
    final backgroundColor = isDark
        ? const Color(0xFF0F172A)
        : const Color(0xFFF5F7FC);

    final surfaceColor = isDark ? const Color(0xFF16213E) : Colors.white;

    final cardColor = isDark ? const Color(0xFF1B2945) : Colors.white;

    final textColor = isDark ? Colors.white : const Color(0xFF1B1D28);

    final subTextColor = isDark ? Colors.white70 : Colors.black54;

    Widget buildCategoryChip(String label, int index) {
      final bool isSelected = selectedCategory == index;

      return GestureDetector(
        onTap: () {
          setState(() {
            selectedCategory = index;
          });
        },

        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),

          margin: const EdgeInsets.only(right: 10),

          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),

          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF4C8DFF) : surfaceColor,

            borderRadius: BorderRadius.circular(22),

            border: Border.all(
              color: isSelected
                  ? const Color(0xFF4C8DFF)
                  : isDark
                  ? Colors.white.withOpacity(.05)
                  : Colors.black.withOpacity(.05),
            ),

            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),

          child: Text(
            label,

            style: TextStyle(
              color: isSelected ? Colors.white : textColor,

              fontSize: 13,

              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF1A3470),

      body: SafeArea(
        child: Column(
          children: [
            /// HEADER
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),

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

                          style: TextStyle(color: subTextColor, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            /// CATEGORY SELECTOR
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,

              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),

              child: Row(
                children: [
                  buildCategoryChip("All Hubs", 0),

                  buildCategoryChip("Files", 1),

                  buildCategoryChip("Links", 2),

                  buildCategoryChip("Tags", 3),

                  buildCategoryChip("Media", 4),

                  buildCategoryChip("Docs", 5),
                ],
              ),
            ),

            const SizedBox(height: 10),

            /// SEARCH
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),

              child: Container(
                height: 58,

                decoration: BoxDecoration(
                  color: surfaceColor,

                  borderRadius: BorderRadius.circular(18),

                  border: Border.all(
                    color: isDark
                        ? Colors.white.withOpacity(.05)
                        : Colors.black.withOpacity(.04),
                  ),

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

            /// FILE LIST
            Expanded(
              child: ListView.builder(
                physics: const BouncingScrollPhysics(),

                padding: const EdgeInsets.symmetric(horizontal: 20),

                itemCount: files.length,

                itemBuilder: (context, index) {
                  final file = files[index];

                  return Container(
                    margin: const EdgeInsets.only(bottom: 14),

                    padding: const EdgeInsets.all(14),

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
                        /// FILE ICON
                        Container(
                          height: 56,
                          width: 56,

                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withOpacity(0.08)
                                : Colors.blue.withOpacity(0.1),

                            borderRadius: BorderRadius.circular(18),
                          ),

                          child: Icon(
                            file['icon'],

                            color: isDark
                                ? Colors.white70
                                : const Color(0xFF4C8DFF),

                            size: 28,
                          ),
                        ),

                        const SizedBox(width: 16),

                        /// FILE INFO
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,

                            children: [
                              Text(
                                file['name'],

                                maxLines: 1,

                                overflow: TextOverflow.ellipsis,

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

                        /// MENU BUTTON
                        Container(
                          height: 38,
                          width: 38,

                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withOpacity(0.05)
                                : Colors.grey.withOpacity(0.08),

                            borderRadius: BorderRadius.circular(12),
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
