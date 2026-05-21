import 'package:flutter/material.dart';
import 'package:freeli/controller/api/api_service.dart';
import '../file_utils.dart';
import 'FileHubSkeleton.dart';

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

  // State for file view
  bool _isShowingFiles = false;
  List<dynamic> _tagFiles = [];
  List<dynamic> _filteredFiles = [];
  bool _isLoadingFiles = false;
  bool _isLoadingMore = false;
  int _filePage = 1;
  int _totalFilePages = 1;
  String _currentTagId = "";
  String _selectedTagName = "";
  int selectedCategory = 0;

  final TextEditingController _searchController = TextEditingController();
  final ScrollController _fileScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _filteredTags = widget.tags;
    _fileScrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (!_isShowingFiles || _isLoadingFiles || _isLoadingMore) return;

    // Trigger load more when user scrolls to within 200 pixels of the bottom
    if (_fileScrollController.position.pixels >=
        _fileScrollController.position.maxScrollExtent - 100) {
      if (_filePage < _totalFilePages) {
        _loadMoreFiles();
      }
    }
  }

  @override
  void didUpdateWidget(covariant TagsPage oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.tags != widget.tags) {
      _runFilter(_searchController.text);
    }
  }

  Future<void> get_tag_file(String tagId, String tagName) async {
    // Toggle view and set title immediately for responsiveness
    setState(() {
      _isShowingFiles = true;
      _selectedTagName = tagName;
      _currentTagId = tagId;
      _tagFiles = [];
      _filteredFiles = [];
      _isLoadingFiles = true;
      _filePage = 1;
      _totalFilePages = 1;
      selectedCategory = 0; // Reset category when opening a tag
    });

    try {
      final response = await ApiServer().getFilesByTag(
        tagId: _currentTagId,
        page: 1,
      );
      setState(() {
        _tagFiles = response?['files'] ?? [];
        _totalFilePages = response?['pagination']?['totalPages'] ?? 1;
        _filteredFiles = _tagFiles;
        _isLoadingFiles = false;
        _runFilter(_searchController.text);
      });
    } catch (e) {
      setState(() => _isLoadingFiles = false);
      debugPrint("Error fetching files: $e");
    }
  }

  Future<void> _loadMoreFiles() async {
    if (_isLoadingMore || _filePage >= _totalFilePages) return;

    setState(() => _isLoadingMore = true);

    try {
      final nextPage = _filePage + 1;

      final response = await ApiServer().getFilesByTag(
        tagId: _currentTagId,
        page: nextPage,
      );

      final newFiles = response?['files'] ?? [];

      setState(() {
        _filePage = nextPage;
        _totalFilePages = response?['pagination']?['totalPages'] ?? 1;

        _tagFiles.addAll(List<Map<String, dynamic>>.from(newFiles));

        _isLoadingMore = false;
      });

      _runFilter(_searchController.text);
    } catch (e) {
      setState(() => _isLoadingMore = false);

      debugPrint("Error loading more files: $e");
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _fileScrollController.dispose();
    super.dispose();
  }

  /// SEARCH FILTER
  void _runFilter(String enteredKeyword) {
    if (_isShowingFiles) {
      List<dynamic> results = _tagFiles.where((file) {
        final String category = (file['file_category'] ?? "")
            .toString()
            .toLowerCase();

        bool matchesCategory = true;
        switch (selectedCategory) {
          case 1:
            matchesCategory = category == "docs" || category == "other";
            break;
          case 2:
            matchesCategory = category == "image";
            break;
          case 3:
            matchesCategory = category == "voice";
            break;
          case 4:
            matchesCategory = category == "audio";
            break;
          case 5:
            matchesCategory = category == "video";
            break;
          default:
            matchesCategory = true;
        }

        final fileName = (file['name'] ?? file['originalname'] ?? '')
            .toString()
            .toLowerCase();
        bool matchesSearch =
            enteredKeyword.trim().isEmpty ||
            fileName.contains(enteredKeyword.toLowerCase());

        return matchesCategory && matchesSearch;
      }).toList();

      setState(() {
        _filteredFiles = results;
      });
    } else {
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

  /// CATEGORY CHIP
  Widget _buildCategoryChip(
    String label,
    int index,
    int count,
    Color surfaceColor,
    Color textColor,
    bool isDark,
  ) {
    final bool isSelected = selectedCategory == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedCategory = index;
          _runFilter(_searchController.text);
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
                      errorBuilder: (context, error, stackTrace) =>
                          Icon(Icons.broken_image_rounded, color: subTextColor),
                    ),
                  )
                : Icon(
                    FileUtils.getFileIcon(location),
                    color: isDark ? Colors.white70 : const Color(0xFF4C8DFF),
                    size: 24,
                  ),
          ),
          const SizedBox(width: 16),
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
                Text(
                  "$fileSize ${date.isNotEmpty ? '• $date' : ''}",
                  style: TextStyle(color: subTextColor, fontSize: 12),
                ),
                Text(
                  file['uploaded_by'] ?? "Unknown",
                  style: TextStyle(color: subTextColor, fontSize: 12),
                ),
                Text(
                  file['conversation_title'] ?? "Unknown",
                  style: TextStyle(color: subTextColor, fontSize: 12),
                ),
                if (file['tag_list_details'] is List &&
                    (file['tag_list_details'] as List).isNotEmpty)
                  Row(
                    children: [
                      ...(file['tag_list_details'] as List)
                          .take(2)
                          .map(
                            (data) => Container(
                              margin: const EdgeInsets.only(right: 6, top: 4),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: Colors.blue.withOpacity(0.3),
                                ),
                              ),
                              child: Text(
                                data['title'] ?? "",
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.blue,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                      if ((file['tag_list_details'] as List).length > 2)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            "+${(file['tag_list_details'] as List).length - 2}",
                            style: TextStyle(
                              color: subTextColor,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
              ],
            ),
          ),
          Icon(
            Icons.more_vert_rounded,
            color: subTextColor.withOpacity(0.8),
            size: 20,
          ),
        ],
      ),
    );
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

    /// COUNTS
    int allCount = 0;
    int docsCount = 0;
    int imageCount = 0;
    int voiceCount = 0;
    int audioCount = 0;
    int videoCount = 0;

    if (_isShowingFiles) {
      allCount = _tagFiles.length;
      docsCount = _tagFiles.where((file) {
        final String category = (file['file_category'] ?? "")
            .toString()
            .toLowerCase();
        return category == "docs" || category == "other";
      }).length;

      imageCount = _tagFiles.where((file) {
        return (file['file_category'] ?? "").toString().toLowerCase() ==
            "image";
      }).length;

      voiceCount = _tagFiles.where((file) {
        return (file['file_category'] ?? "").toString().toLowerCase() ==
            "voice";
      }).length;

      audioCount = _tagFiles.where((file) {
        return (file['file_category'] ?? "").toString().toLowerCase() ==
            "audio";
      }).length;

      videoCount = _tagFiles.where((file) {
        return (file['file_category'] ?? "").toString().toLowerCase() ==
            "video";
      }).length;
    }

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
                  if (_isShowingFiles)
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _isShowingFiles = false;
                          _runFilter(_searchController.text);
                        });
                      },
                      icon: Icon(
                        Icons.arrow_back_ios,
                        color: textColor,
                        size: 20,
                      ),
                    ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isShowingFiles ? _selectedTagName : "Tags",
                          style: TextStyle(
                            color: textColor,
                            fontSize: _isShowingFiles ? 24 : 28,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          _isShowingFiles
                              ? "Viewing files associated with this tag"
                              : "Manage all project tags professionally",
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
                      _isShowingFiles
                          ? "${_filteredFiles.length}"
                          : "${_filteredTags.length}",
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            /// CATEGORY
            if (_isShowingFiles)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    _buildCategoryChip(
                      "All file(s)",
                      0,
                      allCount,
                      surfaceColor,
                      textColor,
                      widget.isDark,
                    ),
                    _buildCategoryChip(
                      "Doc(s)",
                      1,
                      docsCount,
                      surfaceColor,
                      textColor,
                      widget.isDark,
                    ),
                    _buildCategoryChip(
                      "Image(s)",
                      2,
                      imageCount,
                      surfaceColor,
                      textColor,
                      widget.isDark,
                    ),
                    _buildCategoryChip(
                      "Voice(s)",
                      3,
                      voiceCount,
                      surfaceColor,
                      textColor,
                      widget.isDark,
                    ),
                    _buildCategoryChip(
                      "Audio(s)",
                      4,
                      audioCount,
                      surfaceColor,
                      textColor,
                      widget.isDark,
                    ),
                    _buildCategoryChip(
                      "Video(s)",
                      5,
                      videoCount,
                      surfaceColor,
                      textColor,
                      widget.isDark,
                    ),
                  ],
                ),
              ),

            if (_isShowingFiles) const SizedBox(height: 12),

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
                    hintText: _isShowingFiles
                        ? "Search files..."
                        : "Search tags...",
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
              child: _isLoadingFiles
                  ? FileHubSkeleton(
                      isDark: widget.isDark,
                      type: _isShowingFiles ? 'file' : 'tag',
                    )
                  : _isShowingFiles
                  ? ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      controller: _fileScrollController,
                      itemCount:
                          _filteredFiles.length +
                          (_filePage < _totalFilePages ? 1 : 0),
                      padding: const EdgeInsets.only(
                        left: 20,
                        right: 20,
                        bottom: 30,
                      ),
                      itemBuilder: (context, index) {
                        if (index == _filteredFiles.length) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            child: const Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          );
                        }
                        return _buildFileItem(
                          _filteredFiles[index],
                          widget.isDark,
                          textColor,
                          subTextColor,
                          cardColor,
                        );
                      },
                    )
                  : ListView.builder(
                      itemCount: _filteredTags.length,
                      itemBuilder: (context, index) {
                        final tag = _filteredTags[index];

                        final String title = tag['title'] ?? 'Untitled';
                        final String count = (tag['i_connected'] ?? 0)
                            .toString();
                        final Color tagColor = _parseHexColor(tag['tag_color']);
                        final String tagId = tag['tag_id'].toString();

                        return GestureDetector(
                          onTap: () {
                            get_tag_file(tagId, title);
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
