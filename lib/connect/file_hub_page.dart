import 'package:flutter/material.dart';
import 'package:freeli/controller/api/api_service.dart';
import 'package:url_launcher/url_launcher.dart';

import 'file_utils.dart'; // Updated path
import 'filehubs/FileHubSkeleton.dart'; // Import FileHubSkeleton
import 'PopUpFile/PublicTag.dart'; // Import PublicTag
import 'PopUpFile/ForwardMessageScreen.dart'; // Import ForwardMessageScreen
import 'FullImageViewer.dart'; // Updated path

class FileHubPage extends StatefulWidget {
  final bool isDark;
  final List<dynamic> files;
  final Map<String, dynamic>? userData;
  final Future<void> Function()? onRefresh;

  const FileHubPage({
    super.key,
    this.isDark = true,
    required this.files,
    this.userData,
    this.onRefresh,
  });

  @override
  State<FileHubPage> createState() => _FileHubPageState();
}

class _FileHubPageState extends State<FileHubPage> {
  int selectedCategory = 0;
  final TextEditingController _searchController = TextEditingController();
  String searchText = "";

  @override
  void initState() {
    super.initState();
  }

  @override
  void didUpdateWidget(covariant FileHubPage oldWidget) {
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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

  @override
  Widget build(BuildContext context) {
    final bool isDark = widget.isDark;

    final backgroundColor = isDark
        ? const Color(0xFF1A3470)
        : const Color(0xFFF4F7FC);

    final surfaceColor = isDark ? const Color(0xFF132850) : Colors.white;

    final cardColor = isDark ? const Color(0xFF1B2945) : Colors.white;

    final textColor = isDark ? Colors.white : const Color(0xFF1B1D28);

    final subTextColor = isDark ? Colors.white70 : Colors.black54;

    /// API FILES
    final List<dynamic> allFiles = widget.files;

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

    /// FILE ITEM BUILDER (Professional View)
    Widget buildFileItem(dynamic file) {
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
      final String date = createdAt.isNotEmpty && createdAt.contains("T")
          ? createdAt.split("T").first
          : "N/A";

      final String rawUrl = location.startsWith("http")
          ? location
          : "https://wfss001.freeli.io/$location";
      final String fullUrl = rawUrl.replaceAll(' ', '%20');

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

      final String? myId = widget.userData?['id']?.toString();
      final bool isStarred =
          myId != null &&
          (file['star'] is List &&
              (file['star'] as List).any((id) => id.toString() == myId));

      final List<dynamic> tagDetails = (file['tag_list_details'] is List)
          ? file['tag_list_details']
          : (file['tag_details'] is List ? file['tag_details'] : []);

      return GestureDetector(
        onLongPress: () {
          showModalBottomSheet(
            context: context,
            backgroundColor: isDark ? const Color(0xff1B2335) : Colors.white,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            builder: (context) {
              final itemColor = isDark ? Colors.white : const Color(0xFF1B1D28);
              return SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      leading: Icon(
                        Icons.open_in_new_rounded,
                        color: itemColor,
                      ),
                      title: Text("Open", style: TextStyle(color: itemColor)),
                      onTap: () async {
                        Navigator.pop(context);
                        final Uri? uri = Uri.tryParse(fullUrl);
                        if (uri != null) {
                          try {
                            await launchUrl(
                              uri,
                              mode: LaunchMode.externalApplication,
                            );
                          } catch (e) {
                            debugPrint('Error opening file: $e');
                          }
                        }
                      },
                    ),
                    ListTile(
                      leading: Icon(
                        isStarred
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        color: isStarred ? Colors.yellow : itemColor,
                      ),
                      title: Text(
                        isStarred ? "Unstar" : "Star",
                        style: TextStyle(
                          color: isStarred ? Colors.yellow : itemColor,
                        ),
                      ),
                      onTap: () async {
                        Navigator.pop(context);
                        try {
                          await ApiServer().toggleFileStar(
                            fileId: (file['id'] ?? file['file_id']).toString(),
                          );
                          if (widget.onRefresh != null)
                            await widget.onRefresh!();
                        } catch (e) {
                          debugPrint("Star error: $e");
                        }
                      },
                    ),
                    ListTile(
                      leading: Icon(Icons.share_rounded, color: itemColor),
                      title: Text("Share", style: TextStyle(color: itemColor)),
                      onTap: () => Navigator.pop(context),
                    ),
                    ListTile(
                      leading: Icon(
                        Icons.local_offer_rounded,
                        color: itemColor,
                      ),
                      title: Text(
                        "Add a tag", // Fix: Changed itemColor to color
                        style: TextStyle(color: itemColor),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.white,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(24),
                            ),
                          ),
                          builder: (ctx) => PublicTag(
                            tagList: {
                              'company_id': file['company_id'],
                              'tagList': file['tag_list'] ?? tagDetails,
                              'conversation_id': file['conversation_id'],
                              'file_id':
                                  (file['file_id'] ??
                                          file['id'] ??
                                          file['_id'] ??
                                          "")
                                      .toString(),
                              'msg_id': (file['msg_id'] ?? "").toString(),
                              'is_reply':
                                  (file['is_reply_msg'] == true ||
                                      file['is_reply_msg'] == 'yes')
                                  ? 'yes'
                                  : 'no',
                              'participants': (file['participants'] is List)
                                  ? file['participants']
                                  : (file['participants'] != null
                                        ? [file['participants']]
                                        : []),
                            },
                          ),
                        ).then((_) {
                          if (widget.onRefresh != null) widget.onRefresh!();
                        });
                      },
                    ),
                    ListTile(
                      leading: Icon(Icons.forward_rounded, color: itemColor),
                      title: Text(
                        "Forward",
                        style: TextStyle(color: itemColor),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.white,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(24),
                            ),
                          ),
                          builder: (ctx) => ForwardMessageScreen(
                            messageToForward: {
                              ...file,
                              'msg_id':
                                  file['msg_id'] ??
                                  file['id'] ??
                                  file['file_id'],
                              'user_id': myId,
                              'conversation_id': file['conversation_id'],
                              'is_reply_msg': file['is_reply_msg'] ?? 'no',
                            },
                          ),
                        );
                      },
                    ),
                    ListTile(
                      leading: const Icon(
                        Icons.delete_outline_rounded,
                        color: Colors.redAccent,
                      ),
                      title: const Text(
                        "Delete",
                        style: TextStyle(color: Colors.redAccent),
                      ),
                      onTap: () => Navigator.pop(context),
                    ),
                  ],
                ),
              );
            },
          );
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.05)
                  : Colors.grey.withOpacity(0.08),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
                blurRadius: 15,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: isImage
                    ? () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => FullImageViewer(imageUrl: fullUrl),
                          ),
                        );
                      }
                    : null,
                child: Container(
                  height: 48,
                  width: 48,
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withOpacity(0.08)
                        : const Color(0xFF4C8DFF).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: isImage
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: Image.network(
                            fullUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Icon(
                              Icons.broken_image_rounded,
                              color: subTextColor,
                            ),
                          ),
                        )
                      : Icon(
                          FileUtils.getFileIcon(location),
                          color: isDark
                              ? Colors.white70
                              : const Color(0xFF4C8DFF),
                          size: 24,
                        ),
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
                      "$fileSize • $date",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: subTextColor, fontSize: 12),
                    ),
                    Text(
                      file['uploaded_by'] ?? "Unknown",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: subTextColor, fontSize: 12),
                    ),
                    Text(
                      file['conversation_title'] ?? "Unknown",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: subTextColor, fontSize: 12),
                    ),
                    if (tagDetails.isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.white,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(24),
                              ),
                            ),
                            builder: (ctx) => PublicTag(
                              tagList: {
                                'company_id': file['company_id'],
                                'tagList': file['tag_list'] ?? tagDetails,
                                'conversation_id': file['conversation_id'],
                                'file_id':
                                    (file['file_id'] ??
                                            file['id'] ??
                                            file['_id'] ??
                                            "")
                                        .toString(),
                                'msg_id': (file['msg_id'] ?? "").toString(),
                                'is_reply':
                                    (file['is_reply_msg'] == true ||
                                        file['is_reply_msg'] == 'yes')
                                    ? 'yes'
                                    : 'no',
                                'participants': (file['participants'] is List)
                                    ? file['participants']
                                    : (file['participants'] != null
                                          ? [file['participants']]
                                          : []),
                              },
                            ),
                          ).then((_) {
                            if (widget.onRefresh != null) widget.onRefresh!();
                          });
                        },
                        child: Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            ...tagDetails
                                .take(2)
                                .map(
                                  (data) => Container(
                                    margin: const EdgeInsets.only(
                                      right: 6,
                                      top: 4,
                                    ),
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
                            if (tagDetails.length > 2)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  "+${tagDetails.length - 2}",
                                  style: TextStyle(
                                    color: subTextColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () async {
                      try {
                        await ApiServer().toggleFileStar(
                          fileId: (file['id'] ?? file['file_id']).toString(),
                        );
                        if (widget.onRefresh != null) await widget.onRefresh!();
                      } catch (e) {
                        debugPrint("Star error: $e");
                      }
                    },
                    child: Icon(
                      isStarred
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      color: isStarred
                          ? Colors.yellow
                          : subTextColor.withOpacity(0.8),
                      size: 22,
                    ),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () async {
                      final Uri? uri = Uri.tryParse(fullUrl);
                      if (uri != null) {
                        try {
                          await launchUrl(
                            uri,
                            mode: LaunchMode.externalApplication,
                          );
                        } catch (e) {
                          debugPrint('Download error: $e');
                        }
                      }
                    },
                    child: Icon(
                      Icons.download_rounded,
                      color: subTextColor.withOpacity(0.8),
                      size: 22,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

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
        child: widget.files.isEmpty && searchText.isEmpty
            ? Center(
                child: Text(
                  "No files available",
                  style: TextStyle(color: subTextColor),
                ),
              )
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
                      constraints: const BoxConstraints(minHeight: 58),
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
                          isDense: true,

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
                  filteredFiles.isEmpty
                      ? Center(
                          child: Text(
                            "No items found",
                            style: TextStyle(color: subTextColor, fontSize: 14),
                          ),
                        )
                      : Expanded(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                            child: ListView.builder(
                              physics: const BouncingScrollPhysics(),
                              itemCount: filteredFiles.length,
                              itemBuilder: (context, index) {
                                return buildFileItem(filteredFiles[index]);
                              },
                            ),
                          ),
                        ),
                ],
              ),
      ),
    );
  }
}
