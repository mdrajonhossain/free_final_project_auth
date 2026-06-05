import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:freeli/connect/ChatInput.dart';
import 'package:freeli/controller/stateBloc/message/chat_bloc.dart';
import 'package:freeli/controller/api/api_service.dart';

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
      List<PlatformFile> files,
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
        return Container(
          height: screenHeight * 0.9,
          decoration: const BoxDecoration(
            color: Color(0xFF1E293B),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
                              _buildProgressIndicator(currentStep),
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
                                ),
                              if (currentStep == 2)
                                _buildStep2(context, setState, pickedFiles),
                              if (currentStep == 3)
                                _buildStep3(
                                  context,
                                  setState,
                                  tags,
                                  tagController,
                                  publicTags,
                                  isLoadingTags,
                                ),
                              const SizedBox(height: 24),
                              if (currentStep < 3)
                                StatefulBuilder(
                                  builder: (context, _) {
                                    // Calculate if the next button should be active
                                    bool isNextActive = false;
                                    if (currentStep == 1) {
                                      isNextActive = selectedUserIds.isNotEmpty;
                                    } else if (currentStep == 2) {
                                      isNextActive = pickedFiles.isNotEmpty;
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
                              pickedFiles,
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
  }

  static Widget _buildProgressIndicator(int step) {
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
                  ? Colors.indigoAccent
                  : Colors.white10,
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
                color: Colors.indigo.withOpacity(.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.people_outline_rounded,
                color: Colors.indigoAccent,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Step 1: Recipients",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    "Who should be in this room?",
                    style: TextStyle(color: Colors.white60, fontSize: 12),
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
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            hintText: "Search participants...",
            hintStyle: const TextStyle(color: Colors.white38),
            prefixIcon: const Icon(
              Icons.search_rounded,
              color: Colors.white38,
              size: 20,
            ),
            filled: true,
            fillColor: const Color(0xFF334155).withOpacity(0.5),
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
            const Text(
              "Participants",
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (selectedUserIds.isNotEmpty)
              Text(
                "${selectedUserIds.length} Selected",
                style: const TextStyle(
                  color: Colors.indigoAccent,
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
            color: const Color(0xFF334155),
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
        const Text(
          "Add a title for private message",
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),

        const SizedBox(height: 10),

        TextField(
          controller: titleController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: "Enter private room title...",
            hintStyle: const TextStyle(color: Colors.white38),
            filled: true,
            fillColor: const Color(0xFF334155),
            contentPadding: const EdgeInsets.all(16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Colors.indigoAccent),
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
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Step 2: Attachments",
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          "Optional: Upload files to this room",
          style: TextStyle(color: Colors.white60, fontSize: 12),
        ),
        const SizedBox(height: 20),
        InkWell(
          onTap: () async {
            final result = await FilePicker.platform.pickFiles(
              allowMultiple: true,
            );
            if (result != null) {
              setState(() => pickedFiles.addAll(result.files));
            }
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 30),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white10,
                style: BorderStyle.solid,
              ),
            ),
            child: const Column(
              children: [
                Icon(
                  Icons.cloud_upload_outlined,
                  color: Colors.indigoAccent,
                  size: 40,
                ),
                SizedBox(height: 12),
                Text(
                  "Tap to select files",
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
        ),
        if (pickedFiles.isNotEmpty) ...[
          const SizedBox(height: 20),
          const Text(
            "Selected Files",
            style: TextStyle(
              color: Colors.white,
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
                leading: const Icon(
                  Icons.insert_drive_file_outlined,
                  color: Colors.white38,
                ),
                title: Text(
                  pickedFiles[index].name,
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
                trailing: IconButton(
                  icon: const Icon(
                    Icons.close,
                    size: 18,
                    color: Colors.redAccent,
                  ),
                  onPressed: () => setState(() => pickedFiles.removeAt(index)),
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
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Step 3: Tags",
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          "Add tags to categorize this private conversation",
          style: TextStyle(color: Colors.white60, fontSize: 12),
        ),
        const SizedBox(height: 20),

        /// TAG INPUT
        TextField(
          controller: tagController,
          style: const TextStyle(color: Colors.white),
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
            hintStyle: const TextStyle(color: Colors.white38),
            filled: true,
            fillColor: const Color(0xFF334155),
            prefixIcon: const Icon(
              Icons.tag_rounded,
              color: Colors.indigoAccent,
              size: 20,
            ),
            suffixIcon: IconButton(
              icon: const Icon(
                Icons.add_circle_outline_rounded,
                color: Colors.indigoAccent,
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
              borderSide: const BorderSide(
                color: Colors.indigoAccent,
                width: 1,
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          "Available Tags",
          style: TextStyle(
            color: Colors.white70,
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
            color: const Color(0xFF334155),
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
              ? const Text(
                  "No tags available",
                  style: TextStyle(color: Colors.white24, fontSize: 12),
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
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
        ),

        if (tags.isNotEmpty) ...[
          const SizedBox(height: 24),
          const Text(
            "Selected Tags",
            style: TextStyle(
              color: Colors.white70,
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
                  color: Colors.indigoAccent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.indigoAccent.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.tag_rounded,
                      size: 14,
                      color: Colors.indigoAccent,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      tag,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => setState(() => tags.remove(tag)),
                      child: Container(
                        padding: const EdgeInsets.all(1),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          size: 14,
                          color: Colors.white70,
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
  ) {
    return Row(
      children: [
        Expanded(
          child: TextButton(
            onPressed: onBack,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              foregroundColor: Colors.white60,
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
                  ? const Color(0xFF6366F1)
                  : Colors.white.withOpacity(0.05),
              disabledBackgroundColor: Colors.white.withOpacity(0.05),
              foregroundColor: isActive ? Colors.white : Colors.white24,
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
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected ? Colors.indigo.withOpacity(0.2) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: Colors.white10,
            backgroundImage: image.isNotEmpty ? NetworkImage(image) : null,
            child: image.isEmpty
                ? const Icon(Icons.person, size: 18, color: Colors.white70)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white70,
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
          if (isSelected)
            const Icon(
              Icons.check_circle_rounded,
              color: Colors.indigoAccent,
              size: 20,
            ),
        ],
      ),
    );
  }

  static Widget _tagListItem({
    required String title,
    required bool isSelected,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected ? Colors.indigo.withOpacity(0.2) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isSelected
                  ? Colors.indigoAccent
                  : Colors.white.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.tag_rounded,
              size: 14,
              color: isSelected ? Colors.white : Colors.white70,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white70,
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
          if (isSelected)
            const Icon(
              Icons.check_circle_rounded,
              color: Colors.indigoAccent,
              size: 20,
            ),
        ],
      ),
    );
  }
}
