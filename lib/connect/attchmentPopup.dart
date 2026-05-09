import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:freeli/connect/ChatInput.dart';
import 'package:freeli/connect/chat_service.dart';
import 'package:freeli/controller/api/api_files_upload.dart';
import 'package:freeli/controller/api/api_service.dart';
import 'package:freeli/controller/stateBloc/message/chat_bloc.dart';

class AttachmentPopup {
  static Future<List<Map<String, dynamic>>?> show(
    BuildContext context, {
    String? userEmail,
    String? companyId,
    required String conversationId,
    required dynamic participants,
    required ChatBloc chatBloc,
  }) {
    return showModalBottomSheet<List<Map<String, dynamic>>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AttachmentSheet(
        userEmail: userEmail,
        companyId: companyId,
        conversationId: conversationId,
        participants: participants,
        chatBloc: chatBloc,
      ),
    );
  }
}

class AttachmentSheet extends StatefulWidget {
  final String? userEmail;
  final String? companyId;
  final String conversationId;
  final dynamic participants;
  final ChatBloc chatBloc;
  const AttachmentSheet({
    super.key,
    this.userEmail,
    this.companyId,
    required this.conversationId,
    required this.participants,
    required this.chatBloc,
  });

  @override
  State<AttachmentSheet> createState() => _AttachmentSheetState();
}

class _AttachmentSheetState extends State<AttachmentSheet> {
  final TextEditingController _messageController = TextEditingController();
  final List<PlatformFile> files = [];
  final List<Map<String, dynamic>> uploaded_files = [];
  final Map<String, double> uploadProgress = {};
  final Set<String> completedFiles = {};
  final List<Map<String, dynamic>> uploadResults = [];
  bool isUploading = false;

  // Tag state management
  bool showingTags = false;
  String tagSearchQuery = "";
  final Set<String> selectedTags = {};
  List<Map<String, dynamic>> availableTags = [];
  bool isLoadingTags = false;

  @override
  void initState() {
    super.initState();
    _loadTags();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    List<String> imgFiles = [];
    List<String> audioFiles = [];
    List<String> videoFiles = [];
    List<String> otherFiles = [];
    List<Map<String, dynamic>> sanitizedAllFiles = [];

    for (var file in uploaded_files) {
      final String bucket = file['bucket'] ?? '';
      final String key = file['key'] ?? '';
      final String path = (bucket.isNotEmpty && key.isNotEmpty)
          ? "$bucket/$key"
          : "";

      // Robust extraction of mimetype and size from top-level or transforms
      String mimeType = file['mimetype'] ?? file['contentType'] ?? '';
      int fileSize = int.tryParse(file['size']?.toString() ?? '0') ?? 0;

      final transforms = file['transforms'] as List?;
      if (mimeType.isEmpty && transforms != null && transforms.isNotEmpty) {
        mimeType =
            transforms[0]['mimetype'] ??
            transforms[0]['contentType'] ??
            transforms[0]['content_type'] ??
            '';
      }
      if (fileSize == 0 && transforms != null && transforms.isNotEmpty) {
        fileSize = int.tryParse(transforms[0]['size']?.toString() ?? '0') ?? 0;
      }

      if (mimeType.startsWith('image/')) {
        imgFiles.add(path);
      } else if (mimeType.startsWith('audio/')) {
        audioFiles.add(path);
      } else if (mimeType.startsWith('video/')) {
        videoFiles.add(path);
      } else {
        otherFiles.add(path);
      }

      // Create a clean object that matches the server's expected AttachmentFileInfoInput
      sanitizedAllFiles.add({
        "originalname": file['originalname'] ?? "",
        "mimetype": mimeType,
        "voriginalName": file['voriginalName'] ?? file['voriginal_name'] ?? "",
        "size": fileSize,
        "bucket": bucket,
        "key": key,
        "acl": file['acl'] ?? "public-read",
        "referenceId": "",
        "reference_type": "",
      });
    }

    final List<Map<String, dynamic>> allAttachmentInput = sanitizedAllFiles
        .map(
          (_) => {
            "tag_list": selectedTags.toList(),
            "has_tag": selectedTags.isNotEmpty ? "Y" : "N",
          },
        )
        .toList();

    final Map<String, dynamic> attachFiles = {
      "imgfile": imgFiles,
      "audiofile": audioFiles,
      "videofile": videoFiles,
      "otherfile": otherFiles,
      "allfiles": sanitizedAllFiles,
    };

    ChatService.sendMessage(
      context: context,
      controller: _messageController,
      conversationId: widget.conversationId,
      companyId: widget.companyId ?? "",
      participants: widget.participants,
      chatBloc: widget.chatBloc,
      onScroll: () {},
      attachFiles: attachFiles,
      tags: selectedTags.toList(),
      allAttachment: allAttachmentInput,
    );

    if (mounted) Navigator.pop(context, sanitizedAllFiles);
  }

  Future<void> _loadTags() async {
    if (widget.companyId == null || widget.companyId!.isEmpty) {
      debugPrint("Tag Load Aborted: companyId is missing");
      return;
    }

    setState(() => isLoadingTags = true);
    try {
      final tags = await ApiServer().fetch_Public_Tags(widget.companyId);
      setState(() {
        availableTags = tags;
        isLoadingTags = false;
      });
    } catch (e) {
      debugPrint("Error in _loadTags: $e");
      setState(() => isLoadingTags = false);
    }
  }

  Color _parseColor(String? hexColor) {
    if (hexColor == null || hexColor.isEmpty) return const Color(0xff7C5CFF);
    try {
      return Color(int.parse(hexColor.replaceAll('#', '0xff')));
    } catch (e) {
      return const Color(0xff7C5CFF);
    }
  }

  Future<void> pickFiles() async {
    final FilePicker picker = FilePicker.platform;
    FilePickerResult? result = await picker.pickFiles(
      allowMultiple: true,
      withData: false,
    );

    if (result == null || result.files.isEmpty) return;

    final selectedFiles = result.files;
    setState(() {
      isUploading = true;
    });

    final email = widget.userEmail ?? "default-user";
    final bucketName = email.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '-');

    for (var file in selectedFiles) {
      if (file.path == null) continue;

      // Ensure every file gets a unique serial even in batch
      final sl =
          "${DateTime.now().microsecondsSinceEpoch}_${file.name.hashCode}";

      try {
        final response = await ApifilesServer().uploadFile(
          filePath: file.path!,
          fileName: file.name,
          bucketName: bucketName,
          sl: sl,
          onProgress: (int sent, int total) {
            setState(() {
              uploadProgress[file.name] = total > 0 ? sent / total : 0;
            });
          },
        );

        if (response != null &&
            response is Map &&
            response['status'] == true &&
            response['file_info'] != null) {
          setState(() {
            uploaded_files.addAll(
              List<Map<String, dynamic>>.from(response['file_info']),
            );
          });
          setState(() {
            completedFiles.add(file.name);
          });
          uploadResults.addAll(
            List<Map<String, dynamic>>.from(response['file_info']),
          );
        }
      } catch (e) {
        debugPrint("Error uploading ${file.name}: $e");
      }
    }

    setState(() => isUploading = false);

    // if (mounted && uploadResults.isNotEmpty) {
    //   Navigator.pop(context, uploadResults);
    // }
  }

  /// FORMAT FILE SIZE
  String formatBytes(int bytes) {
    double kb = bytes / 1024;
    double mb = kb / 1024;

    if (mb >= 1) {
      return "${mb.toStringAsFixed(1)} MB";
    }

    return "${kb.toStringAsFixed(1)} KB";
  }

  /// FILE ICON
  IconData getFileIcon(String name) {
    final ext = name.split('.').last.toLowerCase();

    switch (ext) {
      case 'pdf':
        return Icons.picture_as_pdf_rounded;

      case 'doc':
      case 'docx':
        return Icons.description_rounded;

      case 'png':
      case 'jpg':
      case 'jpeg':
        return Icons.image_rounded;

      case 'mp4':
      case 'mov':
        return Icons.video_file_rounded;

      case 'mp3':
        return Icons.audio_file_rounded;

      case 'zip':
      case 'rar':
        return Icons.folder_zip_rounded;

      default:
        return Icons.insert_drive_file_rounded;
    }
  }

  /// FILE COLOR
  Color getFileColor(String name) {
    final ext = name.split('.').last.toLowerCase();

    switch (ext) {
      case 'pdf':
        return Colors.redAccent;

      case 'doc':
      case 'docx':
        return Colors.blueAccent;

      case 'png':
      case 'jpg':
      case 'jpeg':
        return Colors.green;

      case 'mp4':
      case 'mov':
        return Colors.deepPurpleAccent;

      case 'mp3':
        return Colors.orange;

      case 'zip':
      case 'rar':
        return Colors.amber;

      default:
        return Colors.cyan;
    }
  }

  Widget _buildUploadBox() {
    return GestureDetector(
      onTap: isUploading ? null : pickFiles,
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 10),
        height: 140,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(.02),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(.08), width: 1.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isUploading)
              const CircularProgressIndicator(
                color: Color(0xff7C5CFF),
                strokeWidth: 2,
              )
            else ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xff7C5CFF).withOpacity(.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.add_to_photos_rounded,
                  color: Color(0xff7C5CFF),
                  size: 28,
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                "Click to upload files",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                "Support PDF, DOC, PNG, JPG, MP4...",
                style: TextStyle(color: Colors.white38, fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      // Use padding to push the entire content up when the keyboard opens
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: const BoxDecoration(
        color: Color.fromARGB(255, 67, 91, 153),
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: SafeArea(
        top: false,
        bottom: false, // We handle bottom padding manually with viewInsets
        child: Column(
          children: [
            /// HEADER
            Container(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(.03),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(30),
                ),
                border: Border(
                  bottom: BorderSide(color: Colors.white.withOpacity(.06)),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: 45,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),

                  const SizedBox(height: 22),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        showingTags ? "Select Tags" : "Upload file(s)",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (showingTags)
                        TextButton(
                          onPressed: () => setState(() => showingTags = false),
                          child: const Text(
                            "Back",
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                          ),
                        )
                      else if (uploaded_files.isNotEmpty)
                        TextButton(
                          onPressed: () => setState(() => showingTags = true),
                          child: const Text(
                            "Continue",
                            style: TextStyle(
                              color: Color.fromARGB(255, 241, 241, 241),
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),

            /// FILE LIST
            Expanded(
              child: showingTags ? _buildTagSelection() : _buildFileSelection(),
            ),

            if (uploaded_files.isNotEmpty && showingTags)
              ChatInput(
                controller: _messageController,
                onSend: _sendMessage,
                companyId: widget.companyId ?? "",
                userEmail: widget.userEmail,
                conversationId: widget.conversationId,
                participants: widget.participants,
                chatBloc: widget.chatBloc,
                showAttachmentIcon: false, // Disable only the attachment icon
                onAttachmentsPicked: (results) {
                  setState(() {
                    uploaded_files.addAll(results);
                  });
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileSelection() {
    return Column(
      children: [
        const SizedBox(height: 10),
        _buildUploadBox(),
        Expanded(
          child: uploaded_files.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        height: 95,
                        width: 95,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(.04),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.cloud_upload_rounded,
                          color: Colors.white38,
                          size: 42,
                        ),
                      ),

                      const SizedBox(height: 20),

                      const Text(
                        "No files selected",
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      const SizedBox(height: 6),

                      const Text(
                        "Tap the upload box to add files",
                        style: TextStyle(color: Colors.white38, fontSize: 13),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: uploaded_files.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 14),
                  itemBuilder: (context, index) {
                    final file = uploaded_files[index];
                    final fileName = file['originalname'] ?? "Unknown File";
                    final transforms = file['transforms'] as List?;
                    final size = transforms != null && transforms.isNotEmpty
                        ? (transforms[0]['size'] as int? ?? 0)
                        : 0;
                    final color = getFileColor(fileName);

                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(.04),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: Colors.white.withOpacity(.05),
                        ),
                      ),
                      child: Row(
                        children: [
                          /// FILE ICON
                          Container(
                            height: 58,
                            width: 58,
                            decoration: BoxDecoration(
                              color: color.withOpacity(.15),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(
                              getFileIcon(fileName),
                              color: color,
                              size: 30,
                            ),
                          ),

                          const SizedBox(width: 14),

                          /// FILE INFO
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  fileName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),

                                const SizedBox(height: 5),

                                if (uploadProgress.containsKey(fileName))
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      top: 4,
                                      bottom: 4,
                                    ),
                                    child: LinearProgressIndicator(
                                      value: uploadProgress[fileName],
                                      backgroundColor: Colors.white10,
                                      color: const Color(0xff7C5CFF),
                                      minHeight: 2,
                                    ),
                                  ),

                                Text(
                                  formatBytes(size),
                                  style: const TextStyle(
                                    color: Colors.white54,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          /// REMOVE
                          PopupMenuButton(
                            color: const Color(0xff1B2335),
                            icon: const Icon(
                              Icons.more_vert_rounded,
                              color: Colors.white54,
                            ),
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: "remove",
                                child: Text(
                                  "Remove",
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ],
                            onSelected: (value) {
                              if (value == "remove") {
                                setState(() {
                                  uploaded_files.removeAt(index);
                                });
                              }
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildTagSelection() {
    if (isLoadingTags) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xff7C5CFF)),
      );
    }

    final filteredTags = availableTags.where((tag) {
      final title = tag['title']?.toString().toLowerCase() ?? "";
      return title.contains(tagSearchQuery.toLowerCase());
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
          child: TextField(
            style: const TextStyle(color: Colors.white),
            onChanged: (v) => setState(() => tagSearchQuery = v),
            decoration: InputDecoration(
              hintText: "Search tags...",
              hintStyle: const TextStyle(color: Colors.white38),
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: Colors.white38,
              ),
              filled: true,
              fillColor: Colors.white.withOpacity(0.04),
              contentPadding: const EdgeInsets.symmetric(vertical: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: const BorderSide(
                  color: Color(0xff7C5CFF),
                  width: 1.5,
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: filteredTags.isEmpty
              ? const Center(
                  child: Text(
                    "No tags found.",
                    style: TextStyle(color: Colors.white54, fontSize: 16),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: filteredTags.length,
                  itemBuilder: (context, index) {
                    final tag = filteredTags[index];
                    final tagName = tag['title']?.toString() ?? "Unknown";
                    final tagId = tag['tag_id']?.toString() ?? "";
                    final isSelected = selectedTags.contains(tagId);
                    final tagColor = _parseColor(tag['tag_color']?.toString());

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xff7C5CFF).withOpacity(.08)
                            : Colors.white.withOpacity(.02),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xff7C5CFF).withOpacity(.3)
                              : Colors.white.withOpacity(.04),
                        ),
                      ),
                      child: CheckboxListTile(
                        secondary: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: tagColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        title: Text(
                          tagName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        value: isSelected,
                        activeColor: const Color(0xff7C5CFF),
                        checkColor: Colors.white,
                        onChanged: (val) {
                          setState(() {
                            if (val == true) {
                              selectedTags.add(tagId);
                            } else {
                              selectedTags.remove(tagId);
                            }
                          });
                        },
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
