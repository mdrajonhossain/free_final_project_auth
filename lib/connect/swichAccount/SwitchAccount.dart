import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freeli/controller/api/api_service.dart';
import 'package:freeli/theme/ThemeCubit.dart';
import 'package:freeli/theme/themeList.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SwitchAccount extends StatefulWidget {
  const SwitchAccount({super.key});

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

  Future<void> switch_ChangeComapny(Map<String, dynamic> company) async {
    if (_userEmail == null) return;

    setState(() => isLoading = true);

    try {
      final result = await ApiServer().switchAccount(
        email: _userEmail!,
        company_id: company['company_id'],
        device_id: "android",
      );

      if (result['status'] == true && result['token'] != null) {
        final String token = result['token'];
        await ApiServer.setAuthToken(token);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool("islogin", true);

        if (!mounted) return;
        Navigator.pushNamedAndRemoveUntil(context, "/home", (route) => false);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? "Switch failed")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error switching company: ${e.toString()}")),
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  // ================= SKELETON ITEM =================
  Widget buildSkeletonItem(AppThemeModel theme) {
    final bool isDark = theme.backgroundColor.computeLuminance() < 0.5;
    final baseColor = isDark
        ? theme.textColor.withOpacity(0.1)
        : theme.subTextColor.withOpacity(0.2);

    return FadeTransition(
      opacity: _controller,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.cardColor,
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

  Widget buildSkeletonList(AppThemeModel theme) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 6,
      itemBuilder: (context, index) {
        return buildSkeletonItem(theme);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, AppThemeModel>(
      builder: (context, theme) {
        return Scaffold(
          backgroundColor: theme.backgroundColor,
          appBar: AppBar(
            elevation: 0,
            backgroundColor: theme.cardColor,
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: theme.textColor,
              ),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              "Switch Account",
              style: TextStyle(
                color: theme.textColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          body: isLoading
              ? buildSkeletonList(theme)
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
                              color: theme.textColor,
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
                              color: theme.cardColor,
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
                                    color: theme.accentColor.withOpacity(0.1),
                                  ),
                                  child:
                                      (c["company_img"] != null &&
                                          c["company_img"]
                                              .toString()
                                              .isNotEmpty)
                                      ? ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          child: Image.network(
                                            c["company_img"],
                                            fit: BoxFit.cover,
                                            errorBuilder: (a, b, c) =>
                                                const Icon(Icons.business),
                                          ),
                                        )
                                      : Icon(
                                          Icons.business,
                                          color: theme.subTextColor,
                                        ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        c["company_name"] ?? "No Name",
                                        style: TextStyle(
                                          color: theme.textColor,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        c["role"] ?? "Member",
                                        style: TextStyle(
                                          color: theme.subTextColor,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: theme.accentColor,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  onPressed: () {
                                    switch_ChangeComapny(c);
                                  },
                                  child: Text(
                                    "Switch",
                                    style: TextStyle(
                                      color: theme.msgSenderText,
                                    ),
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
      },
    );
  }
}
