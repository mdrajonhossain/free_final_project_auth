import 'package:flutter/material.dart';
import 'package:freeli/controller/api/api_service.dart';

class SwitchAccount extends StatefulWidget {
  final bool isDark;
  final Function(bool) onThemeChange;

  const SwitchAccount({
    super.key,
    required this.isDark,
    required this.onThemeChange,
  });

  @override
  State<SwitchAccount> createState() => _SwitchAccountState();
}

class _SwitchAccountState extends State<SwitchAccount>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> companies = [];
  bool isLoading = true;
  String? _userEmail;

  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _initializeData();
  }

  Future<void> _initializeData() async {
    try {
      // 1. Fetch the user profile to get the email
      final userData = await ApiServer().fetchMe();
      final email = userData['email']?.toString();

      if (email != null) {
        _userEmail = email;
        // 2. Load companies using the fetched email
        await loadCompanies();
      } else {
        throw Exception("Email not found in user data");
      }
    } catch (e) {
      debugPrint("Error initializing data: $e");
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> loadCompanies() async {
    if (_userEmail == null) return;
    try {
      final data = await ApiServer().getCompanyList(email: _userEmail!);

      if (mounted) {
        setState(() {
          companies = data;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  // ================= SKELETON ITEM =================
  Widget buildSkeletonItem(bool isDark) {
    final baseColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;

    return FadeTransition(
      opacity: _controller,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF152B52) : Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            // IMAGE SKELETON
            Container(
              height: 50,
              width: 50,
              decoration: BoxDecoration(
                color: baseColor,
                borderRadius: BorderRadius.circular(12),
              ),
            ),

            const SizedBox(width: 12),

            // TEXT SKELETON
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 12,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: baseColor,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 10,
                    width: 120,
                    decoration: BoxDecoration(
                      color: baseColor,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ],
              ),
            ),

            // BUTTON SKELETON
            Container(
              height: 36,
              width: 70,
              decoration: BoxDecoration(
                color: baseColor,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildSkeletonList(bool isDark) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 6,
      itemBuilder: (context, index) {
        return buildSkeletonItem(isDark);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;

    final bg = isDark ? const Color(0xFF0B1B3A) : const Color(0xFFF5F7FB);
    final card = isDark ? const Color(0xFF152B52) : Colors.white;
    final text = isDark ? Colors.white : const Color(0xFF1E293B);
    final subText = isDark ? Colors.white70 : Colors.black54;

    return Scaffold(
      backgroundColor: bg,

      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF0C1F5E),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Switch Account",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),

      body: isLoading
          ? buildSkeletonList(isDark)
          : Column(
              children: [
                const SizedBox(height: 12),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Text(
                        "Company List (${companies.length})",
                        style: TextStyle(
                          color: text,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: companies.length,
                    itemBuilder: (context, index) {
                      final c = companies[index];

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: card,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.06),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              height: 50,
                              width: 50,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: Colors.blue.withOpacity(0.1),
                              ),
                              child:
                                  (c["company_img"] != null &&
                                      c["company_img"].toString().isNotEmpty)
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.network(
                                        c["company_img"],
                                        fit: BoxFit.cover,
                                        errorBuilder: (a, b, c) =>
                                            const Icon(Icons.business),
                                      ),
                                    )
                                  : const Icon(Icons.business),
                            ),

                            const SizedBox(width: 12),

                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    c["company_name"] ?? "No Name",
                                    style: TextStyle(
                                      color: text,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    c["role"] ?? "Member",
                                    style: TextStyle(
                                      color: subText,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              onPressed: () {
                                debugPrint("Switch to ${c["company_name"]}");
                              },
                              child: const Text(
                                "Switch",
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
