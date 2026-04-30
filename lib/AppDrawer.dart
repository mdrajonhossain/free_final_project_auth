import 'package:flutter/material.dart';
import 'dart:ui';
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
    final String name =
        "${userData?['firstname'] ?? 'User'} ${userData?['lastname'] ?? ''}"
            .trim();
    final String email = userData?['email'] ?? "No email provided";
    final String? imgUrl = userData?['img'];

    return Drawer(
      backgroundColor: Colors.transparent,
      child: Stack(
        children: [
          // Glassmorphism effect background
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                color:
                    (isDark ? const Color(0xFF052874) : const Color(0xFF030915))
                        .withOpacity(0.85),
                border: Border(
                  left: BorderSide(color: Colors.white.withOpacity(0.1)),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // Profile Header
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: AppColors.accentColor.withOpacity(0.2),
                        backgroundImage: imgUrl != null
                            ? NetworkImage(imgUrl)
                            : null,
                        child: imgUrl == null
                            ? const Icon(
                                Icons.person,
                                size: 40,
                                color: Colors.white,
                              )
                            : null,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        email,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(
                  color: Colors.white10,
                  thickness: 1,
                  indent: 20,
                  endIndent: 20,
                ),

                // Menu Items
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    children: [
                      _drawerItem(Icons.person_outline, "My Profile", () {}),
                      _drawerItem(Icons.settings_outlined, "Settings", () {}),
                      _drawerItem(
                        Icons.notifications_none,
                        "Notifications",
                        () {},
                      ),
                      _drawerItem(
                        Icons.security_outlined,
                        "Privacy & Security",
                        () {},
                      ),
                      _drawerItem(Icons.help_outline, "Help & Support", () {}),
                    ],
                  ),
                ),

                // Footer Section
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      // Theme Switcher
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Dark Mode",
                              style: TextStyle(color: Colors.white70),
                            ),
                            Switch(
                              value: isDark,
                              onChanged: onThemeChange,
                              activeColor: AppColors.accentColor,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Logout Button
                      InkWell(
                        onTap: onLogout,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.redAccent.withOpacity(0.5),
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.logout,
                                color: Colors.redAccent,
                                size: 20,
                              ),
                              SizedBox(width: 10),
                              Text(
                                "Logout",
                                style: TextStyle(
                                  color: Colors.redAccent,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _drawerItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.white70, size: 22),
      title: Text(
        title,
        style: const TextStyle(color: Colors.white, fontSize: 15),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      onTap: onTap,
    );
  }
}
