import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'AppColors.dart';
import 'package:freeli/controller/api/api_service.dart'; // Import ApiServer
import 'package:freeli/controller/stateBloc/LoginBloc.dart';
import 'package:freeli/controller/stateBloc/LoginEven.dart';
import 'package:freeli/controller/stateBloc/LoginState.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CompanyListScreen extends StatefulWidget {
  final bool isDark;
  final Function(bool) onThemeChange;

  const CompanyListScreen({
    super.key,
    required this.isDark,
    required this.onThemeChange,
  });

  @override
  State<CompanyListScreen> createState() => _CompanyListScreenState();
}

class _CompanyListScreenState extends State<CompanyListScreen> {
  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> saveLoginData(Map<String, dynamic> loginData) async {
    try {
      final String? token = loginData['token'];
      if (token == null || token.isEmpty) {
        throw Exception("Auth token is missing.");
      }

      await ApiServer.setAuthToken(token); // Use ApiServer to set the token

      final prefs = await SharedPreferences.getInstance();
      // Only persist 'islogin' flag, token is handled by ApiServer
      await prefs.setBool("islogin", true);
    } catch (e) {
      debugPrint("Error saving session: $e");
      _showError("Failed to save your session. Please try again.");
    }
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ??
        {};

    final List<dynamic> companiesData = args['companies'] ?? [];
    final String? sessionToken = args['session_token'];
    final String email = args['email'] ?? '';

    final bgColor = AppColors.getBackgroundColor(widget.isDark);

    return BlocListener<LoginBloc, LoginState>(
      listener: (context, state) {
        if (state is LoginSuccess) {
          final loginData = state.data;

          if (loginData['status'] == true && loginData['token'] != null) {
            // Await the save operation before navigating to ensure data integrity
            saveLoginData(loginData).then((_) {
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, "/home");
              }
            });
          }
        }
      },
      child: Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          automaticallyImplyLeading: false,
        ),
        body: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 10),
              const Text(
                "Welcome back!",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Please select a business account to continue",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 20),

              /// ================= LIST =================
              Expanded(
                child: BlocBuilder<LoginBloc, LoginState>(
                  builder: (context, state) {
                    bool isLoading = state is LoginLoading;
                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: companiesData.length,
                      itemBuilder: (context, index) {
                        final company = companiesData[index];
                        final String companyName =
                            company['company_name'] ?? 'Unknown Company';
                        final String companyId = company['company_id'] ?? '';

                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          color: Colors.white.withOpacity(0.08),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            dense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            title: Text(
                              companyName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            trailing: isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(
                                    Icons.arrow_forward_ios,
                                    color: Colors.white54,
                                    size: 14,
                                  ),
                            onTap: isLoading
                                ? null
                                : () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          "Selecting $companyName...",
                                        ),
                                        duration: const Duration(
                                          milliseconds: 500,
                                        ),
                                      ),
                                    );
                                    context.read<LoginBloc>().add(
                                      LoginSelectCompany(
                                        email: email,
                                        companyId: companyId,
                                        sessionToken: sessionToken,
                                      ),
                                    );
                                  },
                          ),
                        );
                      },
                    );
                  },
                ),
              ),

              /// ================= THEME SWITCH =================
              Padding(
                padding: const EdgeInsets.only(bottom: 25, top: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: () => widget.onThemeChange(false),
                      icon: const Icon(Icons.wb_sunny, size: 28),
                      color: Colors.yellow,
                    ),
                    const SizedBox(width: 20),
                    IconButton(
                      onPressed: () => widget.onThemeChange(true),
                      icon: const Icon(Icons.nightlight_round, size: 28),
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
