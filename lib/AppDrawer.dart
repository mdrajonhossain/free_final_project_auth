import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'AppColors.dart';
import 'package:freeli/theme/ProfessionalThemePage.dart';
import 'package:freeli/theme/ThemeCubit.dart';
import 'package:freeli/theme/themeList.dart';

class AppDrawer extends StatelessWidget {
  final bool isDark;
  final Function(bool) onThemeChange;
  final Map<String, dynamic>? userData;
  final VoidCallback onLogout;
  final archiveCount;

  const AppDrawer({
    super.key,
    required this.isDark,
    required this.onThemeChange,
    this.userData,
    required this.onLogout,
    required this.archiveCount,
  });

  @override
  Widget build(BuildContext context) {
    final String name = (userData != null && userData!['firstname'] != null)
        ? "${userData!['firstname']} ${userData!['lastname'] ?? ''}".trim()
        : "Guest User";
    final String? email = userData?['email'];
    final String? teamName = userData?['company_name'];
    final String? imgUrl = userData?['img'];

    return BlocBuilder<ThemeCubit, AppThemeModel>(
      builder: (context, theme) {
        return Drawer(
          backgroundColor: theme.backgroundColor,
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              /// ================= HEADER =================
              Container(
                padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: const BorderRadius.only(
                    bottomRight: Radius.circular(30),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ================= TOP ROW =================
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Image.asset('assets/logo.webp', height: 30),
                        Row(
                          children: [
                            // 🔁 SWITCH COMPANY BUTTON
                            InkWell(
                              onTap: () {
                                Navigator.pushNamed(context, '/switchAccount');
                              },
                              borderRadius: BorderRadius.circular(30),
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: theme.textColor.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.swap_horiz_rounded,
                                  color: theme.textColor,
                                  size: 30,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            // PROFILE IMAGE
                            CircleAvatar(
                              radius: 35,
                              backgroundColor: theme.textColor.withOpacity(0.2),
                              backgroundImage: imgUrl != null
                                  ? NetworkImage(imgUrl)
                                  : null,
                              child: imgUrl == null
                                  ? Icon(
                                      Icons.person,
                                      color: theme.textColor,
                                      size: 40,
                                    )
                                  : null,
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    // ================= NAME =================
                    Text(
                      name,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: theme.textColor,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (email != null)
                      Text(
                        email,
                        style: TextStyle(
                          color: theme.subTextColor,
                          fontSize: 13,
                        ),
                      ),
                    Text(
                      teamName ??
                          (userData == null
                              ? "Sign in to sync your data"
                              : "No Team"),
                      style: TextStyle(
                        color: theme.subTextColor.withOpacity(0.7),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              const Padding(
                padding: EdgeInsets.symmetric(vertical: 2),
                child: Divider(
                  color: Colors.white12,
                  indent: 20,
                  endIndent: 20,
                ),
              ),

              /// ================= SECONDARY MENU =================
              _drawerItem(
                Icons.archive_outlined,
                "Archive rooms",
                () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/archiveroom');
                },
                theme: theme,
                trailing: archiveCount > 0
                    ? Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          archiveCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    : null,
              ),
              _drawerItem(Icons.flag_outlined, "Flagged messages", () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/allFlaggedMessage');
              }, theme: theme),
              _drawerItem(
                Icons.notifications_none_outlined,
                "All notifications",
                () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/allnotification');
                },
                theme: theme,
              ),
              _drawerItem(Icons.lock_outline, "Change password", () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/changepassword');
              }, theme: theme),
              _drawerItem(
                Icons.admin_panel_settings_outlined,
                "Admin settings",
                () {},
                theme: theme,
              ),
              _drawerItem(
                Icons.theater_comedy,
                "Cycle Theme",
                () => context.read<ThemeCubit>().toggleTheme(),
                theme: theme,
                trailing: Icon(
                  Icons.sync_rounded,
                  color: theme.accentColor,
                  size: 20,
                ),
              ),
              _drawerItem(Icons.palette_outlined, "Professional Themes", () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ProfessionalThemePage(),
                  ),
                );
              }, theme: theme),

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
      },
    );
  }

  /// Helper to build Drawer Items
  Widget _drawerItem(
    IconData icon,
    String title,
    VoidCallback onTap, {
    required AppThemeModel theme,
    Widget? trailing,
  }) {
    return ListTile(
      leading: Icon(icon, color: theme.subTextColor, size: 22),
      title: Text(
        title,
        style: TextStyle(color: theme.textColor, fontSize: 15),
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
