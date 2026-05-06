import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:freeli/controller/api/api_files_upload.dart';

class AttachmentPopup {
  static Future<List<Map<String, dynamic>>?> show(
    BuildContext context, {
    String? userEmail,
  }) {
    return showModalBottomSheet<List<Map<String, dynamic>>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AttachmentSheet(userEmail: userEmail),
    );
  }
}

class AttachmentSheet extends StatefulWidget {
  final String? userEmail;
  const AttachmentSheet({super.key, this.userEmail});

  @override
  State<AttachmentSheet> createState() => _AttachmentSheetState();
}

class _AttachmentSheetState extends State<AttachmentSheet> {
  final List<PlatformFile> files = [];
  final List<Map<String, dynamic>> uploaded_files = [];
  final Map<String, double> uploadProgress = {};
  final Set<String> completedFiles = {};
  final List<Map<String, dynamic>> uploadResults = [];
  bool isUploading = false;

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

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * .88,
      decoration: const BoxDecoration(
        color: Color(0xff0B1120),
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: SafeArea(
        top: false,
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
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Upload file(s)",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),

                      ElevatedButton.icon(
                        onPressed: pickFiles,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xff7C5CFF),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        icon: const Icon(
                          Icons.upload_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                        label: const Text(
                          "Upload",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
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
                            "No files uploaded",
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),

                          const SizedBox(height: 6),

                          const Text(
                            "Tap upload button to add files",
                            style: TextStyle(
                              color: Colors.white38,
                              fontSize: 13,
                            ),
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

            if (uploaded_files.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 25),
                child: SizedBox(
                  width: double.infinity,
                  height: 58,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context, uploaded_files);

                      print(
                        "UPLOADED FILES*********************: ${uploaded_files}",
                      );

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: const Color(0xff7C5CFF),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          content: Text(
                            "${uploaded_files.length} file(s) attached",
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff7C5CFF),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: const Text(
                      "Send Attachments",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
