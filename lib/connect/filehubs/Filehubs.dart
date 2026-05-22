import 'package:flutter/material.dart';
import 'package:freeli/connect/filehubs/file_hub_page.dart';
import 'package:freeli/controller/api/api_service.dart';
import 'package:freeli/model/modelScreema_quary.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../AppDrawer.dart';
import 'tags_page.dart';
import 'links_page.dart';
import 'FileHubSkeleton.dart';

class Filehubs extends StatefulWidget {
  final bool isDark;
  final Function(bool) onThemeChange;

  const Filehubs({
    super.key,
    required this.isDark,
    required this.onThemeChange,
  });

  @override
  State<Filehubs> createState() => FilehubsState();
}

class FilehubsState extends State<Filehubs> {
  int _currentIndex = 0; // Default to Tags tab to show API data
  Map<String, dynamic>? userData;
  List<dynamic> tagsList = [];
  List<dynamic> filesList = [];
  List<dynamic> hubFiles = [];
  List<dynamic> linksList = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    // Coordinate both fetch operations to manage the loading state correctly
    await Future.wait([fetchFilehubData(), fetchFileList()]);
  }

  Future<void> fetchFileList() async {
    try {
      final dataFile = await ApiServer().get_file_gallery(
        conversationId: "all_files",
        fileName: "",
        fileSubType: "all",
        fileType: "all",
        from: null,
        page: 1,
        selectedFilters: "date_- Descending",
        tab: "file",
        tagId: null,
        uploadedBy: null,
        to: null,
      );

      debugPrint(
        "[API] fetchFileList Success: ${dataFile?['files']?.length ?? 0} files found",
      );
      setState(() {
        hubFiles = dataFile?['files'] ?? [];
      });
    } catch (e) {
      debugPrint("fetchFileList Error: $e");
    }
  }

  Future<void> fetchFilehubData() async {
    try {
      if (!mounted) return;
      setState(() {
        isLoading = true;
        errorMessage = null;
      });
      final results = await Future.wait([
        ApiServer().fetchMe(),
        ApiServer().get_tag_gallery(),
        ApiServer().fetchFilehubs_Link(),
      ]);

      if (!mounted) return;
      setState(() {
        userData = results[0] as Map<String, dynamic>?; // User data
        final galleryResult =
            results[1] as Map<String, dynamic>?; // Tags and files
        final linksResult = results[2] as List<Map<String, dynamic>>?; // Links

        tagsList = galleryResult?['tags'] ?? [];
        filesList = galleryResult?['files'] ?? [];
        linksList = linksResult ?? [];
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
        errorMessage = "Error fetching data: ${e.toString()}";
        debugPrint(errorMessage);
      });
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
    // Extract tags from galleryData
    final List<Widget> pages = [
      TagsPage(isDark: widget.isDark, tags: tagsList),
      FileHubPage(
        isDark: widget.isDark,
        files: hubFiles,
        userData: userData,
        onRefresh: fetchFileList,
      ), // Assuming FileHubPage takes files
      LinksPage(
        isDark: widget.isDark,
        links: linksList,
        onRefresh: fetchFilehubData,
      ), // Assuming LinksPage takes links
    ];

    final Color primaryColor = widget.isDark
        ? const Color(0xFF052874)
        : const Color(0xFF0A3BA8);
    final Color backgroundColor = widget.isDark
        ? const Color(0xFF1A3470)
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
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
      body: isLoading
          ? FileHubSkeleton(
              isDark: widget.isDark,
            ) // Show skeleton while loading
          : errorMessage != null
          ? Center(
              child: Text(
                errorMessage!,
                style: const TextStyle(color: Colors.redAccent),
                textAlign: TextAlign.center,
              ),
            )
          : pages[_currentIndex],

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
