import 'package:flutter/material.dart';
import 'package:freeli/controller/api/api_service.dart';
import '../file_utils.dart';
import 'FileHubSkeleton.dart';

class FileHubPage extends StatefulWidget {
  final bool isDark;

  const FileHubPage({super.key, this.isDark = true});

  @override
  State<FileHubPage> createState() => _FileHubPageState();
}

class _FileHubPageState extends State<FileHubPage> {
  int selectedCategory = 0;

  Map<String, dynamic>? userData;
  Map<String, dynamic>? galleryData;

  bool isLoading = true;

  final TextEditingController _searchController = TextEditingController();

  String searchText = "";

  @override
  void initState() {
    super.initState();
    get_fileData();
  }

  Future<void> get_fileData() async {
    try {
      if (!mounted) return;

      setState(() => isLoading = true);

      final results = await Future.wait([
        ApiServer().fetchMe(),
        ApiServer().get_file_gallery(),
      ]);

      if (!mounted) return;

      setState(() {
        userData = results[0] as Map<String, dynamic>?;
        galleryData = results[1] as Map<String, dynamic>?;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => isLoading = false);

      debugPrint("Error fetching data: $e");
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// FORMAT FILE SIZE
  String formatFileSize(dynamic bytes) {
    if (bytes == null) return "0 B";

    final int size = int.tryParse(bytes.toString()) ?? 0;

    if (size >= 1024 * 1024 * 1024) {
      return "${(size / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB";
    } else if (size >= 1024 * 1024) {
      return "${(size / (1024 * 1024)).toStringAsFixed(1)} MB";
    } else if (size >= 1024) {
      return "${(size / 1024).toStringAsFixed(1)} KB";
    }

    return "$size B";
  }

  /// FILE ITEM
  Widget _buildFileItem(
    dynamic file,
    bool isDark,
    Color textColor,
    Color subTextColor,
    Color cardColor,
  ) {
    final String originalName =
        file['originalname'] ??
        file['original_name'] ??
        file['name'] ??
        "Unknown File";

    final String location = file['location'] ?? "";

    final String fileSize = formatFileSize(
      file['file_size'] ?? file['filesize'] ?? 0,
    );

    final String createdAt = file['created_at'] ?? "";

    String date = "";

    if (createdAt.isNotEmpty && createdAt.contains("T")) {
      date = createdAt.split("T").first;
    }

    final String extension = location.contains(".")
        ? location.split('.').last.split('?').first.toLowerCase()
        : "";

    final bool isImage = [
      "jpg",
      "jpeg",
      "png",
      "gif",
      "webp",
    ].contains(extension);

    final String fullUrl = location.startsWith("http")
        ? location
        : "https://wfss001.freeli.io/$location";

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
          /// FILE IMAGE / ICON
          Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(0.08)
                  : const Color(0xFF4C8DFF).withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),

            child: isImage
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.network(
                      fullUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          Icons.broken_image_rounded,
                          color: subTextColor,
                        );
                      },
                    ),
                  )
                : Icon(
                    FileUtils.getFileIcon(location),
                    color: isDark ? Colors.white70 : const Color(0xFF4C8DFF),
                    size: 24,
                  ),
          ),

          const SizedBox(width: 16),

          /// FILE INFO
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  originalName,
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
                      fileSize,
                      style: TextStyle(color: subTextColor, fontSize: 12),
                    ),

                    if (date.isNotEmpty) ...[
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

                      Expanded(
                        child: Text(
                          date,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: subTextColor, fontSize: 12),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 10),

          /// MENU
          Container(
            height: 32,
            width: 32,
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
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = widget.isDark;

    final backgroundColor = isDark
        ? const Color(0xFF1A3470)
        : const Color(0xFFF4F7FC);

    final surfaceColor = isDark ? const Color(0xFF16213E) : Colors.white;

    final cardColor = isDark ? const Color(0xFF1B2945) : Colors.white;

    final textColor = isDark ? Colors.white : const Color(0xFF1B1D28);

    final subTextColor = isDark ? Colors.white70 : Colors.black54;

    /// API FILES
    final List<dynamic> allFiles = galleryData?['files'] ?? [];

    /// FILTER CATEGORY
    List<dynamic> filteredFiles = allFiles.where((file) {
      final String category = (file['file_category'] ?? "")
          .toString()
          .toLowerCase();

      switch (selectedCategory) {
        case 1:
          return category == "docs" || category == "other";

        case 2:
          return category == "image";

        case 3:
          return category == "voice";

        case 4:
          return category == "audio";

        case 5:
          return category == "video";

        default:
          return true;
      }
    }).toList();

    /// SEARCH FILTER
    if (searchText.isNotEmpty) {
      filteredFiles = filteredFiles.where((file) {
        final String name =
            (file['originalname'] ??
                    file['original_name'] ??
                    file['name'] ??
                    "")
                .toString()
                .toLowerCase();

        return name.contains(searchText.toLowerCase());
      }).toList();
    }

    /// COUNTS
    final int allCount = allFiles.length;

    final int docsCount = allFiles.where((file) {
      final String category = (file['file_category'] ?? "")
          .toString()
          .toLowerCase();

      return category == "docs" || category == "other";
    }).length;

    final int imageCount = allFiles.where((file) {
      return (file['file_category'] ?? "").toString().toLowerCase() == "image";
    }).length;

    final int voiceCount = allFiles.where((file) {
      return (file['file_category'] ?? "").toString().toLowerCase() == "voice";
    }).length;

    final int audioCount = allFiles.where((file) {
      return (file['file_category'] ?? "").toString().toLowerCase() == "audio";
    }).length;

    final int videoCount = allFiles.where((file) {
      return (file['file_category'] ?? "").toString().toLowerCase() == "video";
    }).length;

    Widget buildCategoryChip(String label, int index, int count) {
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
          ),

          child: Text(
            "$label ($count)",
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
      backgroundColor: backgroundColor,

      body: SafeArea(
        child: isLoading
            ? FileHubSkeleton(isDark: isDark)
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// HEADER
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "FileHub",
                          style: TextStyle(
                            color: textColor,
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.6,
                          ),
                        ),

                        const SizedBox(height: 4),

                        Text(
                          "Access and manage your cloud files professionally",
                          style: TextStyle(color: subTextColor, fontSize: 13),
                        ),
                      ],
                    ),
                  ),

                  /// CATEGORY
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,

                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),

                    child: Row(
                      children: [
                        buildCategoryChip("All file(s)", 0, allCount),

                        buildCategoryChip("Doc(s)", 1, docsCount),

                        buildCategoryChip("Image(s)", 2, imageCount),

                        buildCategoryChip("Voice(s)", 3, voiceCount),

                        buildCategoryChip("Audio(s)", 4, audioCount),

                        buildCategoryChip("Video(s)", 5, videoCount),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  /// SEARCH
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 4,
                    ),

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
                            color: Colors.black.withOpacity(
                              isDark ? 0.15 : 0.05,
                            ),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),

                      child: TextField(
                        controller: _searchController,

                        onChanged: (value) {
                          setState(() {
                            searchText = value;
                          });
                        },

                        style: TextStyle(color: textColor, fontSize: 15),

                        decoration: InputDecoration(
                          border: InputBorder.none,

                          hintText: "Search files...",

                          hintStyle: TextStyle(color: subTextColor),

                          prefixIcon: Icon(
                            Icons.search_rounded,
                            color: subTextColor,
                          ),

                          suffixIcon: searchText.isNotEmpty
                              ? IconButton(
                                  onPressed: () {
                                    _searchController.clear();

                                    setState(() {
                                      searchText = "";
                                    });
                                  },
                                  icon: Icon(
                                    Icons.close_rounded,
                                    color: subTextColor,
                                  ),
                                )
                              : Icon(
                                  Icons.filter_list_rounded,
                                  color: subTextColor,
                                ),

                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 18,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  /// FILE LIST
                  Expanded(
                    child: filteredFiles.isEmpty
                        ? Center(
                            child: Text(
                              "No items found",
                              style: TextStyle(
                                color: subTextColor,
                                fontSize: 14,
                              ),
                            ),
                          )
                        : ListView.builder(
                            physics: const BouncingScrollPhysics(),

                            padding: const EdgeInsets.only(
                              left: 20,
                              right: 20,
                              bottom: 30,
                            ),

                            itemCount: filteredFiles.length,

                            itemBuilder: (context, index) {
                              return _buildFileItem(
                                filteredFiles[index],
                                isDark,
                                textColor,
                                subTextColor,
                                cardColor,
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
