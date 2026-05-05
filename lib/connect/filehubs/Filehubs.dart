import 'package:flutter/material.dart';
import 'package:freeli/controller/api/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../AppDrawer.dart';
import 'tags_page.dart';
import 'file_hub_page.dart';
import 'links_page.dart';

class Filehubs extends StatefulWidget {
  final bool isDark;
  final Function(bool) onThemeChange;

  const Filehubs({
    super.key,
    required this.isDark,
    required this.onThemeChange,
  });

  @override
  State<Filehubs> createState() => _FilehubsState();
}

class _FilehubsState extends State<Filehubs> {
  int _currentIndex = 1;
  Map<String, dynamic>? userData;
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
      setState(() {
        userData = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      debugPrint("Error fetching user data: $e");
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
    final List<Widget> pages = [
      TagsPage(isDark: widget.isDark),
      FileHubPage(isDark: widget.isDark),
      LinksPage(isDark: widget.isDark),
    ];

    final Color primaryColor = widget.isDark
        ? const Color(0xFF052874)
        : const Color(0xFF0A3BA8);
    final Color backgroundColor = widget.isDark
        ? const Color(0xFF030915)
        : Colors.grey[100]!;

    return Scaffold(
      backgroundColor: backgroundColor,
      endDrawer: AppDrawer(
        isDark: widget.isDark,
        onThemeChange: widget.onThemeChange,
        userData: userData,
        onLogout: _handleLogout,
      ),

      /// ================= APP BAR =================
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 12, 31, 94),
        elevation: 0,
        centerTitle: false,
        automaticallyImplyLeading: false,
        titleSpacing: 5,
        title: Image.asset('assets/logo.webp', height: 45),
        actions: [
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
      ),

      /// ================= BODY =================
      body: pages[_currentIndex],

      /// ================= BOTTOM NAV =================
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        backgroundColor: primaryColor,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white.withOpacity(0.5),
        elevation: 10,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
        unselectedLabelStyle: const TextStyle(fontSize: 12),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.sell_rounded), label: 'Tag'),
          BottomNavigationBarItem(
            icon: Icon(Icons.folder_copy_rounded),
            label: 'FileHub',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.link_rounded),
            label: 'Link',
          ),
        ],
      ),
    );
  }
}
