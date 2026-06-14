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

class _UserManagementPageState extends State<UserManagementPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, AppThemeModel>(
      builder: (context, appTheme) {
        return DefaultTabController(
          length: 3,
          child: Scaffold(
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
                // Summary Header
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: appTheme.cardColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: appTheme.subTextColor.withOpacity(0.1),
                    ),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: appTheme.accentColor.withOpacity(0.1),
                        radius: 25,
                        child: Icon(
                          Icons.people_alt_outlined,
                          color: appTheme.accentColor,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Directory Overview",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: appTheme.textColor,
                            ),
                          ),
                          Text(
                            "Manage all system accounts",
                            style: TextStyle(
                              color: appTheme.subTextColor,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Search Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    controller: _searchController,
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
                const SizedBox(height: 12),

                // Tab Content
                Expanded(
                  child: TabBarView(
                    children: [
                      _buildUserList(appTheme, "Users"),
                      _buildUserList(appTheme, "Guests"),
                      _buildUserList(appTheme, "Contact Users"),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildUserList(AppThemeModel appTheme, String category) {
    // This is where you would call your API via FutureBuilder or Bloc
    // Example: ApiServer().getUsers(type: category)
    return FutureBuilder(
      future: Future.delayed(
        const Duration(milliseconds: 500),
      ), // Simulating API
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(color: appTheme.accentColor),
          );
        }

        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: [
            if (category == "Users") ...[
              UserCard(
                appTheme: appTheme,
                name: "John Smith",
                email: "john@example.com",
                role: "Admin",
                isActive: true,
              ),
              UserCard(
                appTheme: appTheme,
                name: "Sarah Johnson",
                email: "sarah@example.com",
                role: "Manager",
                isActive: true,
              ),
              UserCard(
                appTheme: appTheme,
                name: "Michael Brown",
                email: "michael@example.com",
                role: "Staff",
                isActive: false,
              ),
              UserCard(
                appTheme: appTheme,
                name: "Emma Wilson",
                email: "emma@example.com",
                role: "Staff",
                isActive: true,
              ),
            ],
          ],
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

  const UserCard({
    super.key,
    required this.appTheme,
    required this.name,
    required this.email,
    required this.role,
    required this.isActive,
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
          child: Text(
            name[0],
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: appTheme.accentColor,
            ),
          ),
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
                    : role == "Manager"
                    ? Colors.orange.shade100
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
