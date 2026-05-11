import 'package:flutter/material.dart';
import 'package:freeli/controller/api/api_service.dart';
import 'AppColors.dart';
import 'connect/ChatsTab.dart';
import 'connect/CallsTab.dart';
import 'connect/DashboardTab.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'AppDrawer.dart';
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
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    getMeData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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

    List<dynamic>? filteredRooms = conversationRooms;
    if (_isSearching && _searchController.text.isNotEmpty) {
      filteredRooms = conversationRooms?.where((room) {
        final title = room['title']?.toString().toLowerCase() ?? "";
        return title.contains(_searchController.text.toLowerCase());
      }).toList();
    }

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
          title: _isSearching
              ? Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: TextField(
                    controller: _searchController,
                    autofocus: true,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                    cursorColor: Colors.white,
                    decoration: const InputDecoration(
                      hintText: "Search",
                      hintStyle: TextStyle(color: Colors.white60),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 8),
                    ),
                    onChanged: (value) {
                      setState(() {}); // Refresh UI to filter results
                    },
                  ),
                )
              : Image.asset('assets/logo.webp', height: 45),

          actions: [
            if (_isSearching)
              IconButton(
                onPressed: () {
                  setState(() {
                    _isSearching = false;
                    _searchController.clear();
                  });
                },
                icon: const Icon(Icons.close, color: Colors.white),
                tooltip: 'Close search',
              )
            else ...[
              IconButton(
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.symmetric(horizontal: 6),
                onPressed: () => setState(() => _isSearching = true),
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
            ChatsTab(
              conversationRooms: filteredRooms,
              userMe: userData?['id']?.toString(),
            ),
            CallsTab(
              conversationRooms: filteredRooms,
              userMe: userData?['id']?.toString(),
            ),
            DashboardTab(userMe: userData),
          ],
        ),
      ),
    );
  }
}
