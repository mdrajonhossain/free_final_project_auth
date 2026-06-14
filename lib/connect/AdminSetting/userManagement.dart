import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freeli/theme/themeList.dart';
import 'package:freeli/theme/ThemeCubit.dart';
import 'package:freeli/controller/api/api_service.dart'; // Assuming this is where ApiServer is

class UserManagementPage extends StatefulWidget {
  const UserManagementPage({super.key});

  @override
  State<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _allUsers = [];
  bool _isLoading = true;
  String? _companyId;
  String _selectedStatus = "Active";
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });
    _fetchInitialData();
  }

  Future<void> _fetchInitialData() async {
    try {
      final me = await ApiServer().fetchMe();
      _companyId = me['company_id']?.toString();
      if (_companyId != null) {
        final users = await ApiServer().fetchAllUsers(_companyId!);
        if (mounted) {
          setState(() {
            _allUsers = users;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching users: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, AppThemeModel>(
      builder: (context, appTheme) {
        return Scaffold(
          backgroundColor: appTheme.backgroundColor,
          appBar: AppBar(
            title: Text(
              "User Management",
              style: TextStyle(
                color: appTheme.textColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            centerTitle: true,
            backgroundColor: appTheme.backgroundColor,
            elevation: 0,
            iconTheme: IconThemeData(color: appTheme.textColor),
            bottom: TabBar(
              controller: _tabController,
              labelColor: appTheme.accentColor,
              unselectedLabelColor: appTheme.subTextColor,
              indicatorColor: appTheme.accentColor,
              indicatorWeight: 3,
              tabs: const [
                Tab(text: "Users"),
                Tab(text: "Guests"),
                Tab(text: "Contact Users"),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () {},
            backgroundColor: appTheme.accentColor,
            icon: Icon(Icons.person_add_alt_1, color: Colors.white),
            label: const Text(
              "Add User",
              style: TextStyle(color: Colors.white),
            ),
          ),
          body: Column(
            children: [
              // Search Bar
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) => setState(() {}),
                  style: TextStyle(color: appTheme.textColor),
                  decoration: InputDecoration(
                    hintText: "Search by name or email...",
                    hintStyle: TextStyle(color: appTheme.subTextColor),
                    prefixIcon: Icon(
                      Icons.search,
                      color: appTheme.subTextColor,
                    ),
                    filled: true,
                    fillColor: appTheme.cardColor,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide(
                        color: appTheme.subTextColor.withOpacity(0.3),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide(color: appTheme.accentColor),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (_tabController.index != 2) ...[
                _buildStatusFilterBar(appTheme),
                const SizedBox(height: 12),
                const Divider(height: 1, thickness: 0.5, color: Colors.white10),
                const SizedBox(height: 12),
              ],

              // Tab Content
              _isLoading
                  ? Expanded(
                      child: Center(
                        child: CircularProgressIndicator(
                          color: appTheme.accentColor,
                        ),
                      ),
                    )
                  : Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildUserList(appTheme, "Users"),
                          _buildUserList(appTheme, "Guests"),
                          _buildUserList(appTheme, "Contact Users"),
                        ],
                      ),
                    ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusFilterBar(AppThemeModel appTheme) {
    final List<String> statuses = ["Active", "Progress", "Deactive"];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: statuses.map((status) {
          final bool isSelected = _selectedStatus == status;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(status),
              selected: isSelected,
              onSelected: (bool selected) {
                if (selected) {
                  setState(() => _selectedStatus = status);
                }
              },
              selectedColor: appTheme.accentColor,
              backgroundColor: appTheme.cardColor,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : appTheme.subTextColor,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 13,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected
                      ? appTheme.accentColor
                      : appTheme.subTextColor.withOpacity(0.2),
                ),
              ),
              showCheckmark: false,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildUserList(AppThemeModel appTheme, String category) {
    final filteredUsers = _allUsers.where((user) {
      final role = user['role']?.toString() ?? "";
      final searchTerm = _searchController.text.toLowerCase();
      final name = "${user['firstname'] ?? ''} ${user['lastname'] ?? ''}"
          .toLowerCase();
      final email = (user['email'] ?? "").toString().toLowerCase();

      // 1. Filter by Tab Category
      bool matchesCategory = false;
      if (category == "Users") {
        matchesCategory = role != "Guest" && role != "Recipient";
      } else if (category == "Guests") {
        matchesCategory = role == "Guest";
      } else if (category == "Contact Users") {
        matchesCategory = role == "Recipient";
      }

      if (!matchesCategory) return false;

      // 2. Filter by Status chip
      bool matchesStatus = false;
      if (category == "Contact Users") {
        matchesStatus = true;
      } else {
        final bool isActive = user['is_active'] == 1;
        final String otp = user['email_otp']?.toString() ?? "";

        if (_selectedStatus == "Active") {
          matchesStatus = isActive && otp.isEmpty;
        } else if (_selectedStatus == "Progress") {
          matchesStatus = otp.isNotEmpty;
        } else if (_selectedStatus == "Deactive") {
          matchesStatus = !isActive;
        }
      }

      // 3. Filter by Search term
      return matchesStatus &&
          (name.contains(searchTerm) || email.contains(searchTerm));
    }).toList();

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: filteredUsers.length,
      itemBuilder: (context, index) {
        final user = filteredUsers[index];
        return UserCard(
          appTheme: appTheme,
          name: "${user['firstname'] ?? ''} ${user['lastname'] ?? ''}",
          email: user['email'] ?? "",
          role: user['role'] ?? "Member",
          isActive: user['is_active'] == 1,
          imageUrl: user['img'],
        );
      },
    );
  }
}

class UserCard extends StatelessWidget {
  final AppThemeModel appTheme;
  final String name;
  final String email;
  final String role;
  final bool isActive;
  final String? imageUrl;

  const UserCard({
    super.key,
    required this.appTheme,
    required this.name,
    required this.email,
    required this.role,
    required this.isActive,
    this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      color: appTheme.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: appTheme.subTextColor.withOpacity(0.1)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: CircleAvatar(
          radius: 26,
          backgroundColor: appTheme.accentColor.withOpacity(0.1),
          backgroundImage: (imageUrl != null && imageUrl!.isNotEmpty)
              ? NetworkImage(imageUrl!)
              : null,
          child: (imageUrl == null || imageUrl!.isEmpty)
              ? Text(
                  name.isNotEmpty ? name[0] : "?",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: appTheme.accentColor,
                  ),
                )
              : null,
        ),
        title: Text(
          name,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: appTheme.textColor,
          ),
        ),
        subtitle: Text(email, style: TextStyle(color: appTheme.subTextColor)),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: role == "Admin"
                    ? Colors.red.shade100
                    : (role == "Manager" || role == "Member")
                    ? Colors.orange.shade100
                    : (role == "Guest")
                    ? Colors.purple.shade100
                    : Colors.blue.shade100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                role,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.circle,
                  size: 10,
                  color: isActive ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 4),
                Text(
                  isActive ? "Active" : "Inactive",
                  style: TextStyle(fontSize: 11, color: appTheme.subTextColor),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
