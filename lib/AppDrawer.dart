import 'package:flutter/material.dart';
import 'AppColors.dart';

class AppDrawer extends StatelessWidget {
  final bool isDark;
  final Function(bool) onThemeChange;
  final Map<String, dynamic>? userData;
  final VoidCallback onLogout;

  const AppDrawer({
    super.key,
    required this.isDark,
    required this.onThemeChange,
    this.userData,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final String name = (userData != null && userData!['firstname'] != null)
        ? "${userData!['firstname']} ${userData!['lastname'] ?? ''}".trim()
        : "Guest User";
    final String? email = userData?['email'];
    final String? teamName = userData?['company_name'];
    final String? imgUrl = userData?['img'];

    const Color primaryBlue = Color(0xFF0C1F5E);
    const Color surfaceBlue = Color(0xFF152A6E);

    return Drawer(
      backgroundColor: primaryBlue,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          /// ================= HEADER =================
          Container(
            padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
            decoration: const BoxDecoration(
              color: surfaceBlue,
              borderRadius: BorderRadius.only(bottomRight: Radius.circular(30)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Image.asset('assets/logo.webp', height: 30),
                    CircleAvatar(
                      radius: 35,
                      backgroundColor: Colors.white24,
                      backgroundImage: imgUrl != null
                          ? NetworkImage(imgUrl)
                          : null,
                      child: imgUrl == null
                          ? const Icon(
                              Icons.person,
                              color: Colors.white,
                              size: 40,
                            )
                          : null,
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                Text(
                  name,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (email != null)
                  Text(
                    email,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 13,
                    ),
                  ),
                Text(
                  teamName ??
                      (userData == null
                          ? "Sign in to sync your data"
                          : "No Team"),
                  style: TextStyle(
                    color: email != null
                        ? Colors.white.withOpacity(0.6)
                        : Colors.white.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          /// ================= PRIMARY MENU (2 COLUMN GRID) =================
          // Padding(
          //   padding: const EdgeInsets.fromLTRB(20, 10, 20, 5),
          //   child: GridView.count(
          //     shrinkWrap: true,
          //     padding: EdgeInsets.zero,
          //     physics: const NeverScrollableScrollPhysics(),
          //     crossAxisCount: 2,
          //     mainAxisSpacing: 5,
          //     crossAxisSpacing: 5,
          //     childAspectRatio: 2.6,
          //     children: [
          //       _gridItem(Icons.task_alt, "Tasks", () {}),
          //       _gridItem(Icons.folder_open_outlined, "FileHub", () {
          //         Navigator.pop(context);
          //         Navigator.pushNamed(context, '/filehuball');
          //       }),
          //       _gridItem(Icons.analytics_outlined, "Daily Sales", () {}),
          //     ],
          //   ),
          // ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 2),
            child: Divider(color: Colors.white12, indent: 20, endIndent: 20),
          ),

          /// ================= SECONDARY MENU =================
          _drawerItem(Icons.archive_outlined, "Archive rooms", () {
            Navigator.pop(context);
            Navigator.pushNamed(context, '/archiveroom');
          }),
          _drawerItem(Icons.flag_outlined, "Flagged messages", () {}),
          _drawerItem(
            Icons.notifications_none_outlined,
            "All notifications",
            () {},
          ),
          _drawerItem(Icons.lock_outline, "Change password", () {
            Navigator.pop(context);
            Navigator.pushNamed(context, '/changepassword');
          }),
          _drawerItem(
            Icons.admin_panel_settings_outlined,
            "Admin settings",
            () {},
          ),
          _drawerItem(
            Icons.theater_comedy,
            "Theme",
            () => onThemeChange(!isDark),
            trailing: Icon(
              isDark ? Icons.wb_sunny_rounded : Icons.nightlight_round,
              color: isDark ? Colors.yellow : Colors.white70,
              size: 20,
            ),
          ),

          const SizedBox(height: 30),

          /// ================= LOGOUT =================
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _signOutButton(),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  /// Helper to build Drawer Items
  Widget _drawerItem(
    IconData icon,
    String title,
    VoidCallback onTap, {
    Widget? trailing,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.white70, size: 22),
      title: Text(
        title,
        style: const TextStyle(color: Colors.white, fontSize: 15),
      ),
      trailing: trailing,
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 25),
      visualDensity: const VisualDensity(vertical: -1),
    );
  }

  /// Helper to build Grid Items
  Widget _gridItem(IconData icon, String title, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white70, size: 20),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Styled Sign Out Button
  Widget _signOutButton() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF913E3E),
        borderRadius: BorderRadius.circular(15),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: onLogout,
        child: const Padding(
          padding: EdgeInsets.symmetric(vertical: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.logout_rounded, color: Colors.white, size: 20),
              SizedBox(width: 10),
              Text(
                "Logout",
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
