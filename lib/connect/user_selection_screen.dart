import 'package:flutter/material.dart';
import '../AppColors.dart';

class UserSelectionScreen extends StatefulWidget {
  final List<Map<String, dynamic>> allUsers;
  final List<String> initialSelectedUserIds;
  final String currentUserId;

  const UserSelectionScreen({
    super.key,
    required this.allUsers,
    required this.initialSelectedUserIds,
    required this.currentUserId,
  });

  @override
  State<UserSelectionScreen> createState() => _UserSelectionScreenState();
}

class _UserSelectionScreenState extends State<UserSelectionScreen> {
  final List<String> _selectedUserIds = [];

  @override
  void initState() {
    super.initState();

    _selectedUserIds.addAll(widget.initialSelectedUserIds.toSet().toList());

    if (!_selectedUserIds.contains(widget.currentUserId)) {
      _selectedUserIds.add(widget.currentUserId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: const Color(0xFF16213E),

      // =========================
      // APPBAR
      // =========================
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
        ),
        title: const Text(
          "Select Members",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),

      // =========================
      // BODY
      // =========================
      body: Column(
        children: [
          const SizedBox(height: 10),

          // =========================
          // MEMBER COUNT
          // =========================
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Row(
              children: [
                Text(
                  "${_selectedUserIds.length} Members Selected",
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // =========================
          // USER LIST
          // =========================
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              itemCount: widget.allUsers.length,
              itemBuilder: (context, index) {
                final user = widget.allUsers[index];

                final String userId = user['id']?.toString() ?? '';

                final String firstName = user['firstname']?.toString() ?? "";

                final String lastName = user['lastname']?.toString() ?? "";

                final String name =
                    (firstName.isNotEmpty || lastName.isNotEmpty)
                    ? "$firstName $lastName".trim()
                    : (user['fnln']?.toString() ?? "");

                final String img = user['img'] ?? "";

                final bool isSelected = _selectedUserIds.contains(userId);

                final bool isCurrentUser = userId == widget.currentUserId;

                if (userId.isEmpty) {
                  return const SizedBox.shrink();
                }

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.white.withOpacity(0.08)
                        : Colors.white.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.accentColor.withOpacity(0.5)
                          : Colors.white.withOpacity(0.04),
                    ),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),

                    // =========================
                    // AVATAR
                    // =========================
                    leading: Stack(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: Colors.white10,
                          backgroundImage: img.isNotEmpty
                              ? NetworkImage(img)
                              : null,
                          child: img.isEmpty
                              ? const Icon(Icons.person, color: Colors.grey)
                              : null,
                        ),

                        if (isSelected)
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              height: 16,
                              width: 16,
                              decoration: BoxDecoration(
                                color: AppColors.accentColor,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFF16213E),
                                  width: 2,
                                ),
                              ),
                              child: const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 10,
                              ),
                            ),
                          ),
                      ],
                    ),

                    // =========================
                    // NAME
                    // =========================
                    title: Text(
                      name.isEmpty ? "Unknown User" : name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    subtitle: isCurrentUser
                        ? const Padding(
                            padding: EdgeInsets.only(top: 4),
                            child: Text(
                              "Creator",
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 12,
                              ),
                            ),
                          )
                        : null,

                    // =========================
                    // CHECKBOX
                    // =========================
                    trailing: isCurrentUser
                        ? Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.accentColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: const Text(
                              "You",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          )
                        : Transform.scale(
                            scale: 1.05,
                            child: Checkbox(
                              value: isSelected,
                              onChanged: (bool? value) {
                                setState(() {
                                  if (value == true) {
                                    _selectedUserIds.add(userId);
                                  } else {
                                    _selectedUserIds.remove(userId);
                                  }
                                });
                              },
                              activeColor: AppColors.accentColor,
                              checkColor: Colors.white,
                              side: BorderSide(
                                color: Colors.white.withOpacity(0.4),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(5),
                              ),
                            ),
                          ),

                    onTap: isCurrentUser
                        ? null
                        : () {
                            setState(() {
                              if (isSelected) {
                                _selectedUserIds.remove(userId);
                              } else {
                                _selectedUserIds.add(userId);
                              }
                            });
                          },
                  ),
                );
              },
            ),
          ),

          // =========================
          // DONE BUTTON
          // =========================
          Container(
            padding: EdgeInsets.fromLTRB(16, 8, 16, bottomPadding + 14),
            decoration: BoxDecoration(
              color: const Color(0xFF16213E),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 18,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context, _selectedUserIds);
                  },
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: AppColors.accentColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    "Done (${_selectedUserIds.length})",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
