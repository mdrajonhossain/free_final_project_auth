import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freeli/connect/ChatInput.dart';
import 'package:freeli/connect/chat_service.dart';
import 'package:freeli/controller/api/api_files_upload.dart';
import 'package:freeli/controller/api/api_service.dart';
import 'package:freeli/controller/stateBloc/message/chat_bloc.dart';
import 'package:freeli/theme/ThemeCubit.dart';
import 'package:freeli/theme/themeList.dart';

class AttachmentPopup {
  static Future<dynamic> show(
    BuildContext context, {
    String? userEmail,
    String? companyId,
    required String conversationId,
    required dynamic participants,
    required ChatBloc chatBloc,
    String isReplyMsg = "no",
    String? replyForMsgId,
  }) {
    return showModalBottomSheet<dynamic>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AttachmentSheet(
        userEmail: userEmail,
        companyId: companyId,
        conversationId: conversationId,
        participants: participants,
        chatBloc: chatBloc,
        isReplyMsg: isReplyMsg,
        replyForMsgId: replyForMsgId,
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
  final String isReplyMsg;
  final String? replyForMsgId;
  const AttachmentSheet({
    super.key,
    this.userEmail,
    this.companyId,
    required this.conversationId,
    required this.participants,
    required this.chatBloc,
    this.isReplyMsg = "no",
    this.replyForMsgId,
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

  Future<void> _sendMessage() async {
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

    final List<String> partList = widget.participants is List
        ? List<String>.from(widget.participants.map((e) => e.toString()))
        : [widget.participants.toString()];

    // Dynamically determine reply status based on parent ID or passed flag
    final String replyStatus =
        (widget.replyForMsgId != null || widget.isReplyMsg == "yes")
        ? "yes"
        : "no";

    // Using ApiServer directly because ChatService.sendMessage is missing
    // the named parameters 'isReplyMsg' and 'replyForMsgId'.
    final response = await ApiServer().sendMessage(
      msgBody: _messageController.text,
      conversationId: widget.conversationId,
      companyId: widget.companyId ?? "",
      senderId: widget.chatBloc.state.myId,
      participants: partList,
      attachFiles: attachFiles,
      tags: selectedTags.toList(),
      allAttachment: allAttachmentInput,
      replyms: replyStatus,
      isReplyMsg: replyStatus,
      replyForMsgId: widget.replyForMsgId,
    );

    if (mounted) Navigator.pop(context, response);
  }

  Future<void> _loadTags({
    Color? fallbackColor,
    AppThemeModel? appTheme,
  }) async {
    if (widget.companyId == null || widget.companyId!.isEmpty) {
      debugPrint("Tag Load Aborted: companyId is missing");
      return;
    }

    final Color fallback = fallbackColor ?? const Color(0xff7C5CFF);

    if (mounted) setState(() => isLoadingTags = true);
    try {
      final tags = await ApiServer().fetch_Public_Tags(widget.companyId);
      setState(() {
        availableTags = tags;
        isLoadingTags = false;
      });
    } catch (e) {
      debugPrint("Error in _loadTags: $e");
      if (mounted) setState(() => isLoadingTags = false);
    }
  }

  Color _parseColor(String? hexColor, Color fallback) {
    if (hexColor == null || hexColor.isEmpty) return fallback;
    try {
      return Color(int.parse(hexColor.replaceAll('#', '0xff')));
    } catch (e) {
      return fallback;
    }
  }

  Future<void> pickFiles(AppThemeModel appTheme) async {
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

  Widget _buildUploadBox(AppThemeModel appTheme, bool isDark) {
    return GestureDetector(
      onTap: isUploading ? null : () => pickFiles(appTheme),
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 10),
        height: 140,
        width: double.infinity,
        decoration: BoxDecoration(
          color: (isDark ? Colors.white : Colors.black).withOpacity(.03),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: (isDark ? Colors.white : Colors.black).withOpacity(.08),
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isUploading)
              CircularProgressIndicator(
                color: appTheme.accentColor,
                strokeWidth: 2,
              )
            else ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: appTheme.accentColor.withOpacity(.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.add_to_photos_rounded,
                  color: appTheme.accentColor,
                  size: 28,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "Click to upload files",
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "Support PDF, DOC, PNG, JPG, MP4...",
                style: TextStyle(
                  color: (isDark ? Colors.white : Colors.black).withOpacity(.4),
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, AppThemeModel>(
      builder: (context, appTheme) {
        final bool isDark = appTheme.backgroundColor.computeLuminance() < 0.5;
        final Color contentColor = isDark ? Colors.white : Colors.black;

        return Container(
          // Use padding to push the entire content up when the keyboard opens
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.88,
          ),
          decoration: BoxDecoration(
            color: appTheme.backgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
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
                    color: contentColor.withOpacity(.03),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(30),
                    ),
                    border: Border(
                      bottom: BorderSide(color: contentColor.withOpacity(.06)),
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 45,
                        height: 5,
                        decoration: BoxDecoration(
                          color: contentColor.withOpacity(.24),
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),

                      const SizedBox(height: 22),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            showingTags ? "Select Tags" : "Upload file(s)",
                            style: TextStyle(
                              color: contentColor,
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (showingTags)
                            TextButton(
                              onPressed: () =>
                                  setState(() => showingTags = false),
                              child: Text(
                                "Back",
                                style: TextStyle(
                                  color: contentColor.withOpacity(.7),
                                  fontSize: 16,
                                ),
                              ),
                            )
                          else if (uploaded_files.isNotEmpty)
                            TextButton(
                              onPressed: () =>
                                  setState(() => showingTags = true),
                              child: Text(
                                "Continue",
                                style: TextStyle(
                                  color: appTheme.accentColor,
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
                  child: showingTags
                      ? _buildTagSelection(appTheme, isDark)
                      : _buildFileSelection(appTheme, isDark),
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
                    showAttachmentIcon:
                        false, // Disable only the attachment icon
                    isReplyMsg:
                        (widget.replyForMsgId != null ||
                            widget.isReplyMsg == "yes")
                        ? "yes"
                        : "no",
                    replyForMsgId: widget.replyForMsgId,
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
      },
    );
  }

  Widget _buildFileSelection(AppThemeModel appTheme, bool isDark) {
    final Color contentColor = isDark
        ? Colors.white
        : Colors.black; // Define contentColor here
    return Column(
      children: [
        const SizedBox(height: 10),
        _buildUploadBox(appTheme, isDark), // Pass appTheme and isDark
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
                          color: contentColor.withOpacity(.04),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.cloud_upload_rounded,
                          color: contentColor.withOpacity(.4),
                          size: 42,
                        ),
                      ),

                      const SizedBox(height: 20),

                      Text(
                        "No files selected",
                        style: TextStyle(
                          color: contentColor.withOpacity(.7),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      const SizedBox(height: 6),

                      Text(
                        "Tap the upload box to add files",
                        style: TextStyle(
                          color: contentColor.withOpacity(.3),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
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
                        color: contentColor.withOpacity(.04),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: contentColor.withOpacity(.05),
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
                                    color: Colors
                                        .white, // File names usually look better in white over dark overlays
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
                                      color: appTheme.accentColor,
                                      minHeight: 2,
                                    ),
                                  ),

                                Text(
                                  formatBytes(size),
                                  style: TextStyle(
                                    color: contentColor.withOpacity(.6),
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          /// REMOVE
                          PopupMenuButton(
                            color: appTheme.cardColor,
                            icon: Icon(
                              Icons.more_vert_rounded,
                              color: contentColor.withOpacity(.5),
                            ),
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                value: "remove",
                                child: Text(
                                  "Remove",
                                  style: TextStyle(color: contentColor),
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

  Widget _buildTagSelection(AppThemeModel appTheme, bool isDark) {
    final Color contentColor = isDark ? Colors.white : Colors.black;
    if (isLoadingTags) {
      return Center(
        child: CircularProgressIndicator(color: appTheme.accentColor),
      );
    }

    final filteredTags = availableTags.where((tag) {
      final title = tag['title']?.toString().toLowerCase() ?? "";
      return title.contains(tagSearchQuery.toLowerCase());
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
          child: TextField(
            style: TextStyle(color: contentColor),
            onChanged: (v) => setState(() => tagSearchQuery = v),
            decoration:
                InputDecoration(
                  hintText: "Search tags...",
                  hintStyle: TextStyle(color: contentColor.withOpacity(.4)),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: contentColor.withOpacity(.4),
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
                      color: Color(0xff7C5CFF), // Replaced by accentColor below
                      width: 1.5,
                    ),
                  ),
                ).copyWith(
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide(
                      color: appTheme.accentColor,
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
                    final tagColor = _parseColor(
                      tag['tag_color']?.toString(),
                      appTheme.accentColor,
                    );

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? appTheme.accentColor.withOpacity(.08)
                            : contentColor.withOpacity(.02),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected
                              ? appTheme.accentColor.withOpacity(.3)
                              : contentColor.withOpacity(.04),
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
                          style: TextStyle(
                            color: contentColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        value: isSelected,
                        activeColor: appTheme.accentColor,
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
