import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freeli/connect/ChatInput.dart';
import 'package:freeli/controller/api/api_files_upload.dart';
import 'package:freeli/controller/stateBloc/message/chat_bloc.dart';
import 'package:freeli/controller/api/api_service.dart';
import 'package:freeli/theme/ThemeCubit.dart';
import 'package:freeli/theme/themeList.dart';

class PrivateMessagePopUp {
  static void show(
    BuildContext context, {
    required List<Map<String, dynamic>> users,
    required String companyId,
    required ChatBloc chatBloc,
    String? userEmail,
    Function(
      String title,
      List<String> recipientIds,
      List<Map<String, dynamic>> uploadedFiles,
      List<String> tags,
      String message,
    )?
    onCreate,
  }) {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController messageController = TextEditingController();
    final TextEditingController searchController = TextEditingController();
    final TextEditingController tagController = TextEditingController();
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    int currentStep = 1;
    List<String> selectedUserIds = [];
    List<PlatformFile> pickedFiles = [];
    List<Map<String, dynamic>> uploadedFilesMetadata = [];
    Map<String, double> uploadProgress = {};
    bool isUploading = false;
    List<String> tags = [];
    List<Map<String, dynamic>> publicTags = [];
    bool isLoadingTags = true;
    String searchQuery = "";

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (context) {
        return BlocBuilder<ThemeCubit, AppThemeModel>(
          builder: (context, appTheme) {
            final bool isDark =
                appTheme.backgroundColor.computeLuminance() < 0.5;
            final Color contentColor = isDark ? Colors.white : Colors.black;

            return Container(
              height: screenHeight * 0.9,
              decoration: BoxDecoration(
                color: appTheme.backgroundColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                child: Scaffold(
                  backgroundColor: Colors.transparent,
                  body: StatefulBuilder(
                    builder: (context, setState) {
                      // Fetch public tags when the dialog opens or moves to Step 3
                      if (isLoadingTags && currentStep == 3) {
                        ApiServer().fetch_Public_Tags(companyId).then((val) {
                          if (context.mounted) {
                            setState(() {
                              publicTags = val;
                              isLoadingTags = false;
                            });
                          }
                        });
                      }

                      return Column(
                        children: [
                          Expanded(
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _buildProgressIndicator(
                                    currentStep,
                                    appTheme,
                                    contentColor,
                                  ),
                                  const SizedBox(height: 20),
                                  if (currentStep == 1)
                                    _buildStep1(
                                      context,
                                      setState,
                                      users,
                                      titleController,
                                      searchController,
                                      selectedUserIds,
                                      searchQuery,
                                      screenWidth,
                                      appTheme,
                                      isDark,
                                      contentColor,
                                    ),
                                  if (currentStep == 2)
                                    _buildStep2(
                                      context,
                                      setState,
                                      pickedFiles,
                                      isUploading,
                                      uploadProgress,
                                      userEmail,
                                      uploadedFilesMetadata,
                                      (metadata) {
                                        uploadedFilesMetadata.addAll(metadata);
                                      },
                                      appTheme,
                                      isDark,
                                      contentColor,
                                    ),
                                  if (currentStep == 3)
                                    _buildStep3(
                                      context,
                                      setState,
                                      tags,
                                      tagController,
                                      publicTags,
                                      isLoadingTags,
                                      appTheme,
                                      isDark,
                                      contentColor,
                                    ),
                                  const SizedBox(height: 24),
                                  if (currentStep < 3)
                                    StatefulBuilder(
                                      builder: (context, _) {
                                        // Calculate if the next button should be active
                                        bool isNextActive = false;
                                        if (currentStep == 1) {
                                          isNextActive =
                                              selectedUserIds.isNotEmpty;
                                        } else if (currentStep == 2) {
                                          isNextActive =
                                              pickedFiles.isNotEmpty &&
                                              !isUploading;
                                        }

                                        return _buildActionButtons(
                                          context,
                                          setState,
                                          currentStep,
                                          isNextActive,
                                          () {
                                            if (currentStep == 1) {
                                              setState(() => currentStep = 2);
                                            } else if (currentStep == 2) {
                                              setState(() => currentStep = 3);
                                            }
                                          },
                                          () {
                                            if (currentStep > 1) {
                                              setState(() => currentStep--);
                                            } else {
                                              Navigator.pop(context);
                                            }
                                          },
                                          appTheme,
                                          contentColor,
                                        );
                                      },
                                    ),
                                ],
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.only(bottom: 5),
                            child: ChatInput(
                              controller: messageController,
                              companyId: companyId,
                              chatBloc: chatBloc,
                              userEmail: userEmail,
                              conversationId: "",
                              participants: selectedUserIds,
                              onAttachmentsPicked: (_) {},
                              onSend: () {
                                if (isUploading) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        "Please wait for files to finish uploading",
                                        style: TextStyle(color: Colors.white),
                                      ),
                                      backgroundColor: Colors.orangeAccent,
                                    ),
                                  );
                                  return;
                                }
                                if (selectedUserIds.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        "At least one recipient is required",
                                      ),
                                    ),
                                  );
                                  return;
                                }
                                if (messageController.text.trim().isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        "Please enter a message to send",
                                      ),
                                    ),
                                  );
                                  return;
                                }
                                Navigator.pop(context);
                                onCreate?.call(
                                  titleController.text.trim(),
                                  selectedUserIds,
                                  uploadedFilesMetadata,
                                  tags,
                                  messageController.text.trim(),
                                );
                              },
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  static Widget _buildProgressIndicator(
    int step,
    AppThemeModel appTheme,
    Color contentColor,
  ) {
    return Row(
      children: List.generate(3, (index) {
        bool isCompleted = step > index + 1;
        bool isActive = step == index + 1;
        return Expanded(
          child: Container(
            height: 4,
            margin: EdgeInsets.only(right: index == 2 ? 0 : 8),
            decoration: BoxDecoration(
              color: isActive || isCompleted
                  ? appTheme.accentColor
                  : contentColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }),
    );
  }

  static Widget _buildStep1(
    BuildContext context,
    StateSetter setState,
    List<Map<String, dynamic>> users,
    TextEditingController titleController,
    TextEditingController searchController,
    List<String> selectedUserIds,
    String searchQuery,
    double screenWidth,
    AppThemeModel appTheme,
    bool isDark,
    Color contentColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// HEADER
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: appTheme.accentColor.withOpacity(.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                // Use appTheme.accentColor
                Icons.people_outline_rounded,
                color: appTheme.accentColor,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Step 1: Recipients",
                    style: TextStyle(
                      color: contentColor, // Use contentColor
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    "Who should be in this room?",
                    style: TextStyle(
                      color: contentColor.withOpacity(0.6),
                      fontSize: 12,
                    ), // Use contentColor
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        /// SEARCH BAR
        TextField(
          controller: searchController,
          onChanged: (value) =>
              setState(() => searchQuery = value.toLowerCase()),
          style: TextStyle(color: contentColor, fontSize: 14),
          decoration: InputDecoration(
            hintText: "Search participants...",
            hintStyle: TextStyle(color: contentColor.withOpacity(0.38)),
            prefixIcon: Icon(
              Icons.search_rounded,
              color: contentColor.withOpacity(0.38),
              size: 20,
            ),
            filled: true,
            fillColor: contentColor.withOpacity(0.05),
            contentPadding: EdgeInsets.zero,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),

        const SizedBox(height: 20),

        /// PARTICIPANTS TITLE
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Participants",
              style: TextStyle(
                color: contentColor,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (selectedUserIds.isNotEmpty)
              Text(
                "${selectedUserIds.length} Selected",
                style: TextStyle(
                  color: appTheme.accentColor,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),

        const SizedBox(height: 12),

        /// USER LIST
        Container(
          width: double.infinity,
          constraints: BoxConstraints(maxHeight: screenWidth > 600 ? 300 : 180),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: contentColor.withOpacity(0.05), // Use contentColor
            borderRadius: BorderRadius.circular(16),
          ),
          child: Scrollbar(
            child: SingleChildScrollView(
              child: Column(
                children: users
                    .where(
                      (u) => (u['name'] ?? "")
                          .toString()
                          .toLowerCase()
                          .contains(searchQuery),
                    )
                    .map((user) {
                      final String uid = (user['id'] ?? "").toString();
                      final bool isSelected = selectedUserIds.contains(uid);
                      return InkWell(
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              selectedUserIds.remove(uid);
                            } else {
                              selectedUserIds.add(uid);
                            }
                          });
                        },
                        child: _userListItem(
                          name: user['name'] ?? '',
                          image: user['image'] ?? '',
                          isSelected: isSelected,
                          appTheme: appTheme,
                          isDark: isDark,
                          contentColor: contentColor,
                        ),
                      );
                    })
                    .toList(),
              ),
            ),
          ),
        ),

        const SizedBox(height: 20),

        /// ROOM TITLE
        Text(
          "Add a title for private message",
          style: TextStyle(
            color: contentColor, // Use contentColor
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),

        const SizedBox(height: 10),

        TextField(
          controller: titleController,
          style: TextStyle(color: contentColor),
          decoration: InputDecoration(
            hintText: "Enter private room title...",
            hintStyle: TextStyle(color: contentColor.withOpacity(0.38)),
            filled: true,
            fillColor: contentColor.withOpacity(0.05),
            contentPadding: const EdgeInsets.all(16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: appTheme.accentColor),
            ),
          ),
        ),
      ],
    );
  }

  static Widget _buildStep2(
    BuildContext context,
    StateSetter setState,
    List<PlatformFile> pickedFiles,
    bool isUploading,
    Map<String, double> uploadProgress,
    String? userEmail,
    List<Map<String, dynamic>> uploadedFilesMetadata,
    Function(List<Map<String, dynamic>>) onUploadComplete,
    AppThemeModel appTheme,
    bool isDark,
    Color contentColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Step 2: Attachments",
          style: TextStyle(
            color: contentColor,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Optional: Upload files to this room",
          style: TextStyle(color: contentColor.withOpacity(0.6), fontSize: 12),
        ),
        const SizedBox(height: 20),
        InkWell(
          onTap: isUploading
              ? null
              : () async {
                  final result = await FilePicker.platform.pickFiles(
                    allowMultiple: true,
                  );
                  if (result == null || result.files.isEmpty) return;

                  setState(() => isUploading = true);
                  setState(() => pickedFiles.addAll(result.files));
                  final email = userEmail ?? "default-user";
                  final bucketName = email.replaceAll(
                    RegExp(r'[^a-zA-Z0-9]'),
                    '-',
                  );

                  for (var file in result.files) {
                    // যদি আপলোড শুরু হওয়ার আগেই ইউজার ফাইলটি রিমুভ করে দেয়
                    if (!pickedFiles.any((f) => f.name == file.name)) continue;

                    if (file.path == null) continue;

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
                            uploadProgress[file.name] = total > 0
                                ? sent / total
                                : 0;
                          });
                        },
                      );

                      if (response != null &&
                          response['status'] == true &&
                          response['file_info'] != null) {
                        final metadata = List<Map<String, dynamic>>.from(
                          response['file_info'],
                        );
                        // Only add metadata if the user hasn't deleted the file while it was uploading
                        if (pickedFiles.any((f) => f.name == file.name)) {
                          onUploadComplete(metadata);
                        }
                      }
                    } catch (e) {
                      debugPrint("Error uploading ${file.name}: $e");
                    }
                  }
                  setState(() => isUploading = false);
                },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 30),
            decoration: BoxDecoration(
              color: contentColor.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: contentColor.withOpacity(0.1),
                style: BorderStyle.solid,
              ),
            ),
            child: Column(
              children: [
                if (isUploading)
                  CircularProgressIndicator(
                    color: appTheme.accentColor,
                    strokeWidth: 2,
                  )
                else
                  Icon(
                    Icons.cloud_upload_outlined,
                    color: appTheme.accentColor,
                    size: 40,
                  ),
                SizedBox(height: 12),
                Text(
                  "Tap to select files",
                  style: TextStyle(color: contentColor.withOpacity(0.7)),
                ),
              ],
            ),
          ),
        ),
        if (pickedFiles.isNotEmpty) ...[
          const SizedBox(height: 20),
          Text(
            "Selected Files",
            style: TextStyle(
              color: contentColor,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            constraints: const BoxConstraints(maxHeight: 150),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: pickedFiles.length,
              itemBuilder: (context, index) => ListTile(
                dense: true,
                leading: SizedBox(
                  width: 22,
                  height: 22,
                  child:
                      uploadProgress.containsKey(pickedFiles[index].name) &&
                          (uploadProgress[pickedFiles[index].name] ?? 0) < 1.0
                      ? CircularProgressIndicator(
                          strokeWidth: 2,
                          color:
                              appTheme.accentColor, // Use appTheme.accentColor
                        )
                      : Icon(
                          Icons.insert_drive_file_outlined,
                          color:
                              (uploadProgress[pickedFiles[index].name] ?? 0) >=
                                  1.0
                              ? Colors.greenAccent
                              : contentColor.withOpacity(
                                  0.38,
                                ), // Use contentColor
                          size: 18,
                        ),
                ),
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pickedFiles[index].name,
                      style: TextStyle(
                        // Use contentColor
                        color: contentColor.withOpacity(0.7),
                        fontSize: 13,
                      ),
                    ),
                    if (uploadProgress.containsKey(pickedFiles[index].name) &&
                        uploadProgress[pickedFiles[index].name]! < 1.0)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: LinearProgressIndicator(
                          value: uploadProgress[pickedFiles[index].name],
                          backgroundColor: contentColor.withOpacity(
                            0.1,
                          ), // Use contentColor
                          color: appTheme.accentColor,
                          minHeight: 2,
                        ),
                      ),
                  ],
                ),
                trailing: IconButton(
                  icon: const Icon(
                    Icons.close,
                    size: 18,
                    color: Colors.redAccent,
                  ),
                  onPressed: () {
                    setState(() {
                      final name = pickedFiles[index].name;
                      pickedFiles.removeAt(index);
                      uploadProgress.remove(name);

                      // আরও শক্তিশালী ফিল্টারিং যাতে মেটাডেটা লিস্ট থেকে ফাইলটি নিশ্চিতভাবে ডিলিট হয়
                      uploadedFilesMetadata.removeWhere(
                        (m) =>
                            (m['originalname'] ?? m['original_name']) == name ||
                            (m['voriginalName'] ?? m['voriginal_name']) == name,
                      );
                    });
                  },
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  static Widget _buildStep3(
    BuildContext context,
    StateSetter setState,
    List<String> tags,
    TextEditingController tagController,
    List<Map<String, dynamic>> publicTags,
    bool isLoading,
    AppThemeModel appTheme,
    bool isDark,
    Color contentColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Step 3: Tags",
          style: TextStyle(
            color: contentColor,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Add tags to categorize this private conversation",
          style: TextStyle(color: contentColor.withOpacity(0.6), fontSize: 12),
        ),
        const SizedBox(height: 20),

        /// TAG INPUT
        TextField(
          controller: tagController,
          style: TextStyle(color: contentColor),
          onSubmitted: (value) {
            if (value.trim().isNotEmpty) {
              setState(() {
                if (!tags.contains(value.trim())) tags.add(value.trim());
                tagController.clear();
              });
            }
          },
          decoration: InputDecoration(
            hintText: "Type tag and press enter...",
            hintStyle: TextStyle(color: contentColor.withOpacity(0.38)),
            filled: true,
            fillColor: contentColor.withOpacity(0.05),
            prefixIcon: Icon(
              Icons.tag_rounded,
              color: appTheme.accentColor,
              size: 20,
            ),
            suffixIcon: IconButton(
              icon: Icon(
                Icons.add_circle_outline_rounded,
                color: appTheme.accentColor,
              ),
              onPressed: () {
                if (tagController.text.trim().isNotEmpty) {
                  setState(() {
                    if (!tags.contains(tagController.text.trim()))
                      tags.add(tagController.text.trim());
                    tagController.clear();
                  });
                }
              },
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: appTheme.accentColor, width: 1),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          "Available Tags",
          style: TextStyle(
            color: contentColor.withOpacity(0.7),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxHeight: 180),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: contentColor.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
          ),
          child: isLoading
              ? const Center(
                  child: SizedBox(
                    height: 30,
                    width: 30,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : publicTags.isEmpty
              ? Text(
                  // Use contentColor
                  "No tags available",
                  style: TextStyle(
                    color: contentColor.withOpacity(0.24),
                    fontSize: 12,
                  ), // Use contentColor
                  textAlign: TextAlign.center,
                )
              : Scrollbar(
                  child: SingleChildScrollView(
                    child: Column(
                      children: publicTags.map((tag) {
                        final String title = (tag['title'] ?? "").toString();
                        final bool isSelected = tags.contains(title);
                        return InkWell(
                          onTap: () {
                            setState(() {
                              if (isSelected) {
                                tags.remove(title);
                              } else {
                                tags.add(title);
                              }
                            });
                          },
                          child: _tagListItem(
                            title: title,
                            isSelected: isSelected,
                            appTheme: appTheme,
                            isDark: isDark,
                            contentColor: contentColor,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
        ),

        if (tags.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text(
            "Selected Tags",
            style: TextStyle(
              color: contentColor.withOpacity(0.7),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: tags.map((tag) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: appTheme.accentColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: appTheme.accentColor.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.tag_rounded,
                      size: 14,
                      color: appTheme.accentColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      tag,
                      style: TextStyle(color: contentColor, fontSize: 13),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => setState(() => tags.remove(tag)),
                      child: Container(
                        padding: const EdgeInsets.all(1),
                        decoration: BoxDecoration(
                          color: contentColor.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  static Widget _buildActionButtons(
    BuildContext context,
    StateSetter setState,
    int step,
    bool isActive,
    VoidCallback onNext,
    VoidCallback onBack,
    AppThemeModel appTheme,
    Color contentColor,
  ) {
    return Row(
      children: [
        Expanded(
          child: TextButton(
            onPressed: onBack,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              foregroundColor: contentColor.withOpacity(
                0.6,
              ), // Use contentColor
            ),
            child: Text(step == 1 ? "Cancel" : "Back"),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: isActive ? onNext : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: isActive
                  ? appTheme.accentColor
                  : contentColor.withOpacity(0.05),
              disabledBackgroundColor: contentColor.withOpacity(0.05),
              foregroundColor: isActive
                  ? Colors.white
                  : contentColor.withOpacity(0.24),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(
              step == 3 ? "Create Room" : "Next",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  static Widget _userListItem({
    required String name,
    required String image,
    required bool isSelected,
    required AppThemeModel appTheme,
    required bool isDark,
    required Color contentColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected
            ? appTheme.accentColor.withOpacity(0.2)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: contentColor.withOpacity(0.1),
            backgroundImage: image.isNotEmpty ? NetworkImage(image) : null,
            child: image.isEmpty
                ? Icon(
                    Icons.person,
                    size: 18,
                    color: contentColor.withOpacity(0.7),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              style: TextStyle(
                color: isSelected
                    ? contentColor
                    : contentColor.withOpacity(0.7),
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
          if (isSelected)
            Icon(
              Icons.check_circle_rounded,
              color: appTheme.accentColor,
              size: 20,
            ),
        ],
      ),
    );
  }

  static Widget _tagListItem({
    required String title,
    required bool isSelected,
    required AppThemeModel appTheme,
    required bool isDark,
    required Color contentColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected
            ? appTheme.accentColor.withOpacity(0.2)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isSelected
                  ? appTheme.accentColor
                  : contentColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.tag_rounded,
              size: 14,
              color: isSelected ? Colors.white : contentColor.withOpacity(0.7),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: isSelected
                    ? contentColor
                    : contentColor.withOpacity(0.7),
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
          if (isSelected)
            Icon(
              Icons.check_circle_rounded,
              color: appTheme.accentColor,
              size: 20,
            ),
        ],
      ),
    );
  }
}
