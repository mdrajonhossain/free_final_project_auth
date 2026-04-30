import 'package:flutter/material.dart';
import 'package:freeli/controller/api/api_service.dart';
import 'AppColors.dart';
import 'connect/ChatsTab.dart';
import 'connect/CallsTab.dart';
import 'connect/DashboardTab.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:ui';

class HomePage extends StatefulWidget {
  final bool isDark;
  final Function(bool) onThemeChange;

  const HomePage({
    super.key,
    required this.isDark,
    required this.onThemeChange,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Map<String, dynamic>? userData;
  List<dynamic>? conversationRooms;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    getMeData();
  }

  Future<void> getMeData() async {
    try {
      setState(() => isLoading = true);
      final data = await ApiServer().fetchMe();
      print(data);
      setState(() {
        userData = data;
        isLoading = false;
      });
      if (data['id'] != null) {
        getRooms(data['id']);
      }
    } catch (e) {
      setState(() => isLoading = false);
      print("Error fetching user data: $e");
    }
  }

  Future<void> getRooms(String userId) async {
    try {
      final data = await ApiServer().fetchRooms(userId);
      print("Rooms data fetched: $data");
      setState(() {
        conversationRooms = data['rooms'];
      });
    } catch (e) {
      print("Error fetching rooms: $e");
    }
  }

  Future<void> _handleLogout() async {
    await ApiServer.clearAuthToken();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, "/login", (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = AppColors.getBackgroundColor(widget.isDark);

    String displayName = "Loading...";
    String displayEmail = "...";

    if (userData != null) {
      displayName =
          "${userData!['firstname'] ?? ''} ${userData!['lastname'] ?? ''}"
              .trim();
      if (displayName.isEmpty) displayName = "User";
      displayEmail = userData!['email'] ?? "";
    } else if (!isLoading) {
      displayName = "Guest";
      displayEmail = "Not logged in";
    }

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: bgColor,
        endDrawer: AppDrawer(
          isDark: widget.isDark,
          onThemeChange: widget.onThemeChange,
          userData: userData,
          onLogout: _handleLogout,
        ),

        /// ================= APP BAR =================
        appBar: AppBar(
          backgroundColor: const Color.fromARGB(
            255,
            12,
            31,
            94,
          ), // Darker background for app bar
          elevation: 0,
          centerTitle: false,
          automaticallyImplyLeading: false,
          titleSpacing: 5,
          title: Image.asset('assets/logo.webp', height: 45),

          actions: [
            IconButton(
              constraints: const BoxConstraints(),
              padding: const EdgeInsets.symmetric(horizontal: 6),
              onPressed: () {},
              icon: const Icon(Icons.search, color: Colors.white),
              tooltip: 'Search',
            ),
            IconButton(
              constraints: const BoxConstraints(),
              padding: const EdgeInsets.symmetric(horizontal: 6),
              onPressed: () {},
              icon: const Icon(Icons.filter_alt_sharp, color: Colors.white),
              tooltip: 'Filter',
            ),
            Builder(
              builder: (context) {
                return IconButton(
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  onPressed: () => Scaffold.of(context).openEndDrawer(),
                  icon: const Icon(Icons.menu, color: Colors.white),
                  tooltip: 'Toggle menu',
                );
              },
            ),
            const SizedBox(width: 3),
          ],

          /// ================= TAB BAR =================
          bottom: const TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            dividerColor: Colors.transparent,
            indicator: UnderlineTabIndicator(
              borderSide: BorderSide(color: Colors.white, width: 2),
            ),

            tabs: [
              Tab(icon: Icon(Icons.chat), text: "Chats"),
              Tab(icon: Icon(Icons.call), text: "Calls"),
              Tab(icon: Icon(Icons.dashboard), text: "Dashboard"),
            ],
          ),
        ),

        /// ================= BODY =================
        body: TabBarView(
          children: [
            ChatsTab(conversationRooms: conversationRooms),
            const CallsTab(),
            const DashboardTab(),
          ],
        ),
      ),
    );
  }
}

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
