import 'package:flutter/material.dart';
import 'package:freeli/controller/api/api_service.dart';
import '../AppColors.dart';

import 'user_selection_screen.dart'; // Import the new user selection screen

class CreateRoomScreen extends StatefulWidget {
  const CreateRoomScreen({super.key});

  @override
  State<CreateRoomScreen> createState() => _CreateRoomScreenState();
}

class _CreateRoomScreenState extends State<CreateRoomScreen> {
  final TextEditingController _roomNameController = TextEditingController();

  bool _isLoading = false;
  Map<String, dynamic>? _userData;

  // State variables matching React logic
  String? selectedCategory;
  String? selectedTeam;

  final List<String> categories = [];
  final List<String> teams = [];
  List<String> participants = [];
  List<String> participantsAdmin = [];
  List<dynamic> participantsGuest = [];
  List<dynamic> newParticipantsGuest = [];
  List<String> tagList = [];
  List<Map<String, dynamic>> _allUsers = [];

  String convImg = "";

  List<dynamic> _fullCategories = [];
  List<dynamic> _fullTeams = [];

  @override
  void initState() {
    super.initState();
    _fetchUser();
    getCatagory();
    getTeams();
  }

  Future<void> _fetchUser() async {
    try {
      final data = await ApiServer().fetchMe();
      setState(() {
        _userData = data;
        // Initialize participants with current user as per React logic
        participants = [data['id']?.toString() ?? ""];
        participantsAdmin = [data['id']?.toString() ?? ""];
      });
      _fetchUsers();
      debugPrint("User data fetched: ${_userData?['id']}");
    } catch (e) {
      debugPrint("Error fetching user: $e");
    }
  }

  Future<void> _fetchUsers() async {
    if (_userData == null) return;
    try {
      final users = await ApiServer().fetchAllUsers(_userData!['company_id']);
      setState(() => _allUsers = users);
    } catch (e) {
      debugPrint("Error fetching all users: $e");
    }
  }

  void getCatagory() {
    ApiServer()
        .get_Category()
        .then((response) {
          setState(() {
            _fullCategories = response['categories'] ?? [];
            categories.clear();
            categories.addAll(
              _fullCategories.map((e) => e['unit_name'].toString()).toList(),
            );
            debugPrint("Categories fetched: ${categories.length} items");
          });
        })
        .catchError((error) {
          debugPrint("Error fetching categories: $error");
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Failed to load categories: $error")),
            );
          }
        });
  }

  void getTeams() {
    ApiServer()
        .get_Teams()
        .then((response) {
          if (mounted) {
            setState(() {
              _fullTeams = response['teams'] ?? [];
              teams.clear();
              teams.addAll(
                _fullTeams.map((e) => e['team_title'].toString()).toList(),
              );
              debugPrint("Teams fetched: ${teams.length} items");
            });
          }
        })
        .catchError((error) {
          debugPrint("Error fetching teams: $error");
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Failed to load teams: $error")),
            );
          }
        });
  }

  void _makeAdmin(String type, String id) {
    setState(() {
      if (type == 'add') {
        if (!participantsAdmin.contains(id)) {
          participantsAdmin.add(id);
        }
      } else {
        participantsAdmin.remove(id);
      }
    });
  }

  void _removeParticipant(String id) {
    if (_userData != null && id == _userData!['id'].toString()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You cannot remove yourself.")),
      );
      return;
    }
    setState(() {
      participants.remove(id);
      participantsAdmin.remove(id);
    });
  }

  void _onTeamSelected(String? teamTitle) {
    if (teamTitle == null) return;
    final teamObj = _fullTeams.firstWhere(
      (e) => e['team_title'] == teamTitle,
      orElse: () => null,
    );

    if (teamObj != null) {
      setState(() {
        selectedTeam = teamTitle;
        final List<dynamic> teamParticipants = teamObj['participants'] ?? [];
        // When a team is selected, reset participants to only include the current user.
        // Other members will be added explicitly via the "Add members" button.
        participants = [_userData?['id']?.toString() ?? ""];

        final String myId = _userData?['id']?.toString() ?? "";
        if (myId.isNotEmpty && !participants.contains(myId)) {
          participants.add(myId);
        }
      });
    }
  }

  void _handleCreate() async {
    final String title = _roomNameController.text.trim();
    if (_userData == null) return;

    debugPrint(
      "Attempting to create room with title: $title, category: $selectedCategory, team: $selectedTeam",
    );
    // Validation matching React's isFormValid()
    if (title.isEmpty || selectedCategory == null || selectedTeam == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all required fields (*) ")),
      );
      debugPrint(
        "Validation failed: title=$title, category=$selectedCategory, team=$selectedTeam",
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final catObj = _fullCategories.firstWhere(
        (e) => e['unit_name'] == selectedCategory,
        orElse: () {
          debugPrint(
            "Selected category '$selectedCategory' not found in _fullCategories.",
          );
          throw Exception("Selected category not found.");
        },
      );
      final teamObj = _fullTeams.firstWhere(
        (e) => e['team_title'] == selectedTeam,
        orElse: () {
          debugPrint("Selected team '$selectedTeam' not found in _fullTeams.");
          throw Exception("Selected team not found.");
        },
      );

      final String teamId =
          teamObj['team_id']?.toString() ??
          teamObj['id']?.toString() ??
          teamObj['_id']?.toString() ??
          '';
      final String bUnitId =
          catObj['unit_id']?.toString() ??
          catObj['id']?.toString() ??
          catObj['_id']?.toString() ??
          '';

      if (teamId.isEmpty || bUnitId.isEmpty) {
        throw Exception(
          "Could not determine ID for selected team or category.",
        );
      }

      debugPrint("Resolved teamId: $teamId, bUnitId: $bUnitId");

      final input = {
        "title": title,
        "participants": participants,
        "participants_admin": participantsAdmin,
        "company_id": _userData!['company_id'],
        "group": "yes",
        "team_id": teamId,
        "b_unit_id": bUnitId,
        "conv_img": convImg,
        "tag_list": tagList,
        "participants_guest": participantsGuest,
        "new_participants_guest": newParticipantsGuest,
      };

      final response = await ApiServer().createRoom(input: input);

      if (response['status'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Room created successfully")),
          );

          // Navigate to the new room conversation, similar to React's navigate()
          final String? convId = response['data']?['conversation_id'];
          debugPrint("Room created, conversation_id: $convId");
          if (convId != null) {
            Navigator.pushReplacementNamed(context, '/home');
          } else {
            Navigator.pop(context);
          }
        }
      } else {
        final String errorMessage =
            response['message']?.toString() ?? "Unknown error";
        debugPrint("API error creating room: $errorMessage");
        throw errorMessage;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Failed to create room: $e")));
      }
      debugPrint("Exception during room creation: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _roomNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 35, 54, 114),

      /// APPBAR
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.white,
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
        ),
        title: const Text(
          "Create Room",
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

      /// BODY
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// DISPLAY PHOTO
              _sectionTitle("Display photo"),

              const SizedBox(height: 10),

              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.1),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    /// IMAGE
                    Container(
                      height: 64,
                      width: 64,
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.add_a_photo_rounded,
                        color: Colors.grey,
                        size: 28,
                      ),
                    ),

                    const SizedBox(width: 16),

                    /// UPLOAD BUTTON
                    Expanded(
                      child: Container(
                        height: 54,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: AppColors.accentColor.withOpacity(0.5),
                            width: 1.2,
                          ),
                          color: AppColors.accentColor.withOpacity(0.1),
                        ),
                        child: const Center(
                          child: Text(
                            "Upload",
                            style: TextStyle(
                              color: AppColors.accentColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              /// ROOM NAME
              _sectionTitle("Title of room*"),

              const SizedBox(height: 10),

              _buildTextField(
                controller: _roomNameController,
                hint: "Name of the room",
              ),

              const SizedBox(height: 22),

              /// CATEGORY
              _sectionTitle("Room category*"),

              const SizedBox(height: 10),

              _buildDropdown(
                value: selectedCategory,
                hint: "Select a room category",
                items: categories,
                onChanged: (v) {
                  setState(() {
                    selectedCategory = v;
                  });
                },
              ),

              const SizedBox(height: 22),

              /// TEAM
              _sectionTitle("Select team*"),

              const SizedBox(height: 10),

              _buildDropdown(
                value: selectedTeam,
                hint: "Select team",
                items: teams,
                onChanged: _onTeamSelected,
              ),

              const SizedBox(height: 22),

              /// TAGS
              _sectionTitle("Shared team tag[s]"),

              const SizedBox(height: 10),

              _buildAddBox(title: "Click to add"),

              const SizedBox(height: 22),

              /// ADD MEMBERS BUTTON
              _sectionTitle("Room member[s]"),

              const SizedBox(height: 10),

              _buildActionBox(title: "Add members"),

              const SizedBox(height: 12),

              /// DYNAMIC MEMBER LIST
              /// DYNAMIC MEMBER LIST
              ..._buildMemberList(),

              const SizedBox(height: 22),

              /// GUESTS
              _sectionTitle("Room guest[s]"),

              const SizedBox(height: 10),

              _buildActionBox(title: "Invite guest(s)"),

              const SizedBox(height: 40),

              /// BUTTONS
              Row(
                children: [
                  /// BACK
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white24),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text(
                        "Back",
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),

                  const SizedBox(width: 14),

                  /// CREATE BUTTON
                  Expanded(
                    child: Container(
                      height: 54,
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromARGB(
                            255,
                            10,
                            32,
                            100,
                          ),
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: _isLoading ? null : _handleCreate,
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                "Create",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildMemberList() {
    final List<Widget> list = [];
    for (final String id in participants) {
      final user = _allUsers.firstWhere(
        (u) => u['id'].toString() == id,
        orElse: () => {},
      );
      if (user.isEmpty) continue;

      final bool isMe = id == _userData?['id']?.toString();
      final bool isAdmin = participantsAdmin.contains(id);
      final String firstName = user['firstname']?.toString() ?? "";
      final String lastName = user['lastname']?.toString() ?? "";
      final String name = (firstName.isNotEmpty || lastName.isNotEmpty)
          ? "$firstName $lastName".trim()
          : (user['fnln']?.toString() ?? "");
      final String img = user['img'] ?? "";

      list.add(
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: Colors.white10,
                backgroundImage: img.isNotEmpty ? NetworkImage(img) : null,
                child: img.isEmpty
                    ? const Icon(Icons.person, color: Colors.grey)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      isMe ? 'Creator' : (isAdmin ? 'Admin' : 'Member'),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              ),
              if (!isMe && _userData != null) ...[
                // Only show actions for other users
                TextButton(
                  onPressed: () => _makeAdmin(isAdmin ? 'remove' : 'add', id),
                  child: Text(
                    isAdmin ? "Remove Admin" : "Make Admin",
                    style: const TextStyle(
                      color: AppColors.accentColor,
                      fontSize: 12,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.remove_circle_outline,
                    color: Colors.redAccent,
                    size: 20,
                  ),
                  onPressed: () => _removeParticipant(id),
                ),
              ],
              if (isMe)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const Text(
                    "Admin",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white70,
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    }

    if (list.isEmpty) {
      return [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 10),
          child: Text(
            "No members added yet.",
            style: TextStyle(color: Colors.white38, fontSize: 13),
          ),
        ),
      ];
    }
    return list;
  }

  /// SECTION TITLE
  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Colors.white70,
      ),
    );
  }

  /// TEXTFIELD
  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
  }) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white38),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: AppColors.accentColor,
            width: 1.4,
          ),
        ),
      ),
    );
  }

  /// DROPDOWN
  Widget _buildDropdown({
    required String? value,
    required String hint,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(hint, style: const TextStyle(color: Colors.white38)),
          dropdownColor: const Color(0xff1B2335),
          style: const TextStyle(color: Colors.white),
          isExpanded: true,
          borderRadius: BorderRadius.circular(14),
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Colors.white70,
          ),
          items: items.map((e) {
            return DropdownMenuItem(value: e, child: Text(e));
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  /// ADD BOX
  Widget _buildAddBox({required String title}) {
    return Container(
      height: 54,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      alignment: Alignment.centerLeft,
      child: Text(title, style: const TextStyle(color: Colors.white38)),
    );
  }

  /// ACTION BOX
  Widget _buildActionBox({required String title}) {
    return GestureDetector(
      onTap: () async {
        if (title == "Add members") {
          if (selectedTeam == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Please select a team first.")),
            );
            return;
          }

          final List<String>? result = await Navigator.push<List<String>>(
            context,
            MaterialPageRoute(
              builder: (context) => UserSelectionScreen(
                allUsers: _allUsers,
                initialSelectedUserIds: participants,
                currentUserId: _userData?['id']?.toString() ?? "",
              ),
            ),
          );

          if (result != null) {
            setState(() {
              participants = result;
              // Ensure the creator remains in the list and as an admin
              final String myId = _userData?['id']?.toString() ?? "";
              if (myId.isNotEmpty && !participants.contains(myId)) {
                participants.add(myId);
              }
              participantsAdmin.removeWhere((id) => !participants.contains(id));
              if (myId.isNotEmpty && !participantsAdmin.contains(myId)) {
                participantsAdmin.add(myId);
              }
            });
          }
        }
      },
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            Container(
              height: 28,
              width: 28,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 18),
            ),
          ],
        ),
      ),
    );
  }
}
