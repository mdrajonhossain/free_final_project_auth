import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freeli/controller/api/api_service.dart'; // Import ApiServer
import 'package:freeli/controller/stateBloc/LoginBloc.dart';
import 'package:freeli/controller/stateBloc/LoginEven.dart';
import 'package:freeli/controller/stateBloc/LoginState.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:freeli/theme/themeList.dart';
import 'package:freeli/theme/ThemeCubit.dart';
import 'package:freeli/theme/ProfessionalThemePage.dart'; // Assuming this is the location

class CompanyListScreen extends StatefulWidget {
  const CompanyListScreen({super.key});

  @override
  State<CompanyListScreen> createState() => _CompanyListScreenState();
}

class _CompanyListScreenState extends State<CompanyListScreen> {
  String? _selectedCompanyId;

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
    return BlocBuilder<ThemeCubit, AppThemeModel>(
      builder: (context, appTheme) {
        final bgColor = appTheme.backgroundColor;
        final textColor = appTheme.textColor;
        final subTextColor = appTheme.subTextColor;
        final cardColor = appTheme.cardColor;
        final accentColor = appTheme.accentColor;

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
                  Text(
                    "Welcome back!",
                    style: TextStyle(
                      color: textColor,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Please select a business account to continue",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: subTextColor, fontSize: 14),
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
                            final String companyId =
                                company['company_id'] ?? '';

                            final bool isThisItemLoading =
                                isLoading && _selectedCompanyId == companyId;

                            return Card(
                              margin: const EdgeInsets.only(bottom: 10),
                              color: cardColor, // Use appTheme.cardColor
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
                                  style: TextStyle(
                                    color: textColor, // Use appTheme.textColor
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                trailing: isThisItemLoading
                                    ? SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          color:
                                              accentColor, // Use appTheme.accentColor
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Icon(
                                        Icons.arrow_forward_ios,
                                        color:
                                            subTextColor, // Use appTheme.subTextColor
                                        size: 14,
                                      ),
                                onTap: isLoading
                                    ? null
                                    : () {
                                        setState(() {
                                          _selectedCompanyId = companyId;
                                        });
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
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
                        TextButton.icon(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ProfessionalThemePage(),
                            ),
                          ),
                          icon: Icon(
                            Icons.palette_outlined,
                            color: accentColor,
                          ), // Use appTheme.accentColor
                          label: Text(
                            "Select Theme",
                            style: TextStyle(
                              color: accentColor,
                            ), // Use appTheme.accentColor
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
