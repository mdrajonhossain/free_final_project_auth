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
    // Ensure the current user is always selected and cannot be deselected
    _selectedUserIds.addAll(widget.initialSelectedUserIds.toSet().toList());
    if (!_selectedUserIds.contains(widget.currentUserId)) {
      _selectedUserIds.add(widget.currentUserId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 35, 54, 114),
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.white,
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
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          color: Colors.white,
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
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

                if (userId.isEmpty) return const SizedBox.shrink();

                return Card(
                  color: Colors.white.withOpacity(0.05),
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.white10,
                      backgroundImage: img.isNotEmpty
                          ? NetworkImage(img)
                          : null,
                      child: img.isEmpty
                          ? const Icon(Icons.person, color: Colors.grey)
                          : null,
                    ),
                    title: Text(
                      name,
                      style: const TextStyle(color: Colors.white),
                    ),
                    subtitle: isCurrentUser
                        ? const Text(
                            'Creator',
                            style: TextStyle(color: Colors.white54),
                          )
                        : null, // Display 'Creator' for the current user
                    trailing: isCurrentUser
                        ? null
                        : Checkbox(
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
                          ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context, _selectedUserIds);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentColor,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                "Done",
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
