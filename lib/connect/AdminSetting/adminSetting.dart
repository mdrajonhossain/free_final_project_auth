import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freeli/theme/themeList.dart';
import 'package:freeli/theme/ThemeCubit.dart';

class AdminSettingsPage extends StatelessWidget {
  const AdminSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, AppThemeModel>(
      builder: (context, appTheme) {
        return Scaffold(
          backgroundColor: appTheme.backgroundColor,
          appBar: AppBar(
            title: Text(
              "Admin Settings",
              style: TextStyle(color: appTheme.textColor),
            ),
            centerTitle: true,
            backgroundColor: appTheme.backgroundColor,
            elevation: 0,
            iconTheme: IconThemeData(color: appTheme.textColor),
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildSectionTitle("Management", appTheme),
              _buildMenuTile(
                context,
                appTheme: appTheme,
                title: "User Management",
                subtitle: "Manage users and permissions",
                icon: Icons.supervisor_account_outlined,
                onTap: () {
                  Navigator.pushNamed(context, '/usermanagement');
                },
              ),
              _buildMenuTile(
                context,
                appTheme: appTheme,
                title: "Account Settings",
                subtitle: "Configure account preferences",
                icon: Icons.manage_accounts_outlined,
                onTap: () {},
              ),
              _buildMenuTile(
                context,
                appTheme: appTheme,
                title: "Team Management",
                subtitle: "Manage teams and members",
                icon: Icons.groups_2_outlined,
                onTap: () {},
              ),
              _buildMenuTile(
                context,
                appTheme: appTheme,
                title: "Room Categories",
                subtitle: "Create and manage room categories",
                icon: Icons.category_outlined,
                onTap: () {},
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(String title, AppThemeModel appTheme) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 12, top: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: appTheme.textColor,
        ),
      ),
    );
  }

  Widget _buildMenuTile(
    BuildContext context, {
    required AppThemeModel appTheme,
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      color: appTheme.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: appTheme.subTextColor.withOpacity(0.1)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: appTheme.accentColor.withOpacity(0.1),
          child: Icon(icon, color: appTheme.accentColor),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: appTheme.textColor,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(color: appTheme.subTextColor),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 18,
          color: appTheme.subTextColor,
        ),
        onTap: onTap,
      ),
    );
  }
}
