import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../graphql_config.dart';

class AppDrawer extends StatelessWidget {
  final bool isDark;
  final Function(bool) onThemeChange;

  const AppDrawer({
    super.key,
    required this.isDark,
    required this.onThemeChange,
  });

  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFF0C1F5E);
    const Color surfaceBlue = Color(0xFF152A6E);

    return Drawer(
      backgroundColor: primaryBlue,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          /// ================= HEADER =================
          Query(
            options: QueryOptions(
              document: gql(GraphQLSchema.getData),
              fetchPolicy: FetchPolicy.networkOnly,
            ),
            builder: (QueryResult result, {fetchMore, refetch}) {
              final data = result.data?['me'];

              return Container(
                padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
                decoration: const BoxDecoration(
                  color: surfaceBlue,
                  borderRadius: BorderRadius.only(
                    bottomRight: Radius.circular(30),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        CircleAvatar(
                          radius: 35,
                          backgroundColor: Colors.white24,
                          backgroundImage: data?['img'] != null
                              ? NetworkImage(data!['img'])
                              : null,
                          child: data?['img'] == null
                              ? const Icon(
                                  Icons.person,
                                  color: Colors.white,
                                  size: 40,
                                )
                              : null,
                        ),
                        Image.asset('assets/logo.webp', height: 30),
                      ],
                    ),
                    const SizedBox(height: 15),
                    Text(
                      data != null
                          ? "${data['firstname']} ${data['lastname']}"
                          : "Guest User",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      data?['email'] ?? "Sign in to sync your data",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 15),
                    Row(
                      children: [
                        _actionButton(Icons.settings, "Preferences", () {}),
                        const SizedBox(width: 10),
                        _themeSwitcher(),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),

          /// ================= MENU =================
          _drawerItem(Icons.task_alt, "Tasks", () {}),
          _drawerItem(Icons.folder_open_outlined, "FileHub", () {}),
          _drawerItem(Icons.analytics_outlined, "Daily Sales", () {}),

          const Divider(color: Colors.white12, indent: 20, endIndent: 20),

          _drawerItem(Icons.archive_outlined, "Archived rooms", () {}),
          _drawerItem(Icons.flag_outlined, "Flagged messages", () {}),
          _drawerItem(
            Icons.notifications_none_outlined,
            "All notifications",
            () {},
          ),
          _drawerItem(Icons.lock_outline, "Change password", () {}),
          _drawerItem(
            Icons.admin_panel_settings_outlined,
            "Admin settings",
            () {},
          ),

          const SizedBox(height: 20),

          /// ================= SIGN OUT =================
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _signOutButton(context),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  /// Drawer Item
  Widget _drawerItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.white70, size: 22),
      title: Text(
        title,
        style: const TextStyle(color: Colors.white, fontSize: 15),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 25, vertical: 0),
      visualDensity: const VisualDensity(vertical: -2),
    );
  }

  /// Action Button
  Widget _actionButton(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white10,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 14),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  /// Theme Switch
  Widget _themeSwitcher() {
    return InkWell(
      onTap: () => onThemeChange(!isDark),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isDark ? Colors.amber.withOpacity(0.2) : Colors.white10,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isDark ? Colors.amber : Colors.white24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isDark ? Icons.wb_sunny : Icons.nightlight_round,
              color: isDark ? Colors.amber : Colors.white,
              size: 14,
            ),
            const SizedBox(width: 6),
            Text(
              isDark ? "Light" : "Dark",
              style: TextStyle(
                color: isDark ? Colors.amber : Colors.white,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Sign Out Button
  Widget _signOutButton(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color.fromARGB(255, 145, 62, 62),
            Color.fromARGB(255, 145, 62, 62),
          ],
        ),
        borderRadius: BorderRadius.circular(15),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: () async {
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove('token');
          await prefs.remove('islogin');

          Navigator.pushNamedAndRemoveUntil(
            context,
            "/login",
            (route) => false,
          );
        },
        child: const Padding(
          padding: EdgeInsets.symmetric(vertical: 15),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.logout_rounded, color: Colors.white, size: 20),
              SizedBox(width: 10),
              Text(
                "Sign Out",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
