import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freeli/theme/themeList.dart';
import 'package:freeli/theme/ThemeCubit.dart';

class UserManagementPage extends StatelessWidget {
  const UserManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, AppThemeModel>(
      builder: (context, appTheme) {
        return Scaffold(
          backgroundColor: appTheme.backgroundColor,
          appBar: AppBar(
            title: Text(
              "User Management",
              style: TextStyle(color: appTheme.textColor),
            ),
            centerTitle: true,
            backgroundColor: appTheme.backgroundColor,
            elevation: 0,
            iconTheme: IconThemeData(color: appTheme.textColor),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () {},
            backgroundColor: appTheme.accentColor,
            icon: Icon(Icons.person_add_alt_1, color: appTheme.textColor),
            label: Text(
              "Add User",
              style: TextStyle(color: appTheme.textColor),
            ),
          ),
          body: Column(
            children: [
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
                    Icon(
                      Icons.people_alt_outlined,
                      size: 40,
                      color: appTheme.accentColor,
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "125 Users",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: appTheme.textColor,
                          ),
                        ),
                        Text(
                          "Total registered users",
                          style: TextStyle(color: appTheme.subTextColor),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  style: TextStyle(color: appTheme.textColor),
                  decoration: InputDecoration(
                    hintText: "Search users...",
                    hintStyle: TextStyle(color: appTheme.subTextColor),
                    prefixIcon: Icon(
                      Icons.search,
                      color: appTheme.subTextColor,
                    ),
                    filled: true,
                    fillColor: appTheme.cardColor,
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
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
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
                ),
              ),
            ],
          ),
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
