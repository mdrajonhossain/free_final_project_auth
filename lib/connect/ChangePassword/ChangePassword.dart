import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freeli/controller/api/api_service.dart';
import 'package:freeli/theme/ThemeCubit.dart';
import 'package:freeli/theme/themeList.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChangePassword extends StatefulWidget {
  const ChangePassword({super.key});

  @override
  State<ChangePassword> createState() => _ChangePasswordState();
}

class _ChangePasswordState extends State<ChangePassword> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController newPassController = TextEditingController();
  final TextEditingController confirmPassController = TextEditingController();

  bool isLoading = false;
  bool obscureNew = true;
  bool obscureConfirm = true;
  String? _userEmail;

  @override
  void initState() {
    super.initState();
    _fetchUser();
  }

  @override
  void dispose() {
    newPassController.dispose();
    confirmPassController.dispose();
    super.dispose();
  }

  Future<void> _fetchUser() async {
    try {
      final data = await ApiServer().fetchMe();
      setState(() {
        _userEmail = data['email']?.toString();
      });
    } catch (e) {
      debugPrint("Error fetching user email: $e");
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

  Future<void> changePassword() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_userEmail == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("User email not found. Please login again."),
        ),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final result = await ApiServer().setNewPassword(
        email: _userEmail!,
        password: newPassController.text.trim(),
        password2: confirmPassController.text.trim(),
      );
      if (!mounted) return;
      if (result['status'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? "Password changed successfully"),
            backgroundColor: Colors.green,
          ),
        );

        newPassController.clear();
        confirmPassController.clear();

        await Future.delayed(const Duration(milliseconds: 700));

        _handleLogout();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? "Something went wrong"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  InputDecoration inputDecoration(
    String hint,
    IconData icon,
    AppThemeModel theme, {
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: theme.cardColor,
      prefixIcon: Icon(icon, color: Colors.grey.shade700),
      suffixIcon: suffixIcon,
      hintStyle: TextStyle(color: Colors.grey.shade500),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: theme.accentColor, width: 1.2),
      ),

      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),

      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, AppThemeModel>(
      builder: (context, theme) {
        final textColor = theme.textColor;
        final backgroundColor = theme.backgroundColor;

        return Scaffold(
          backgroundColor: backgroundColor,
          appBar: AppBar(
            backgroundColor: backgroundColor,
            elevation: 0,
            centerTitle: false,
            title: Text(
              "Change Password",
              style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
            ),
            leading: IconButton(
              icon: Icon(Icons.arrow_back_rounded, color: textColor),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                onPressed: () => context.read<ThemeCubit>().toggleTheme(),
                icon: Icon(Icons.theater_comedy, color: theme.accentColor),
              ),
            ],
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),
                    Text(
                      "Create a new password",
                      style: TextStyle(
                        color: textColor,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Your new password must be different from previously used passwords.",
                      style: TextStyle(
                        color: theme.subTextColor,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 35),
                    Text(
                      "New Password",
                      style: TextStyle(
                        color: textColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: newPassController,
                      obscureText: obscureNew,
                      style: TextStyle(color: theme.textColor),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Enter new password";
                        }
                        if (value.length < 6) {
                          return "Password must be at least 6 characters";
                        }
                        return null;
                      },
                      decoration: inputDecoration(
                        "Enter new password",
                        Icons.lock_outline_rounded,
                        theme,
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscureNew
                                ? Icons.visibility_off_rounded
                                : Icons.visibility_rounded,
                            color: theme.subTextColor,
                          ),
                          onPressed: () {
                            setState(() {
                              obscureNew = !obscureNew;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    Text(
                      "Confirm Password",
                      style: TextStyle(
                        color: textColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: confirmPassController,
                      obscureText: obscureConfirm,
                      style: TextStyle(color: theme.textColor),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Confirm your password";
                        }
                        if (value != newPassController.text) {
                          return "Passwords do not match";
                        }
                        return null;
                      },
                      decoration: inputDecoration(
                        "Confirm new password",
                        Icons.lock_reset_rounded,
                        theme,
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscureConfirm
                                ? Icons.visibility_off_rounded
                                : Icons.visibility_rounded,
                            color: theme.subTextColor,
                          ),
                          onPressed: () {
                            setState(() {
                              obscureConfirm = !obscureConfirm;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 35),
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : changePassword,
                        style: ElevatedButton.styleFrom(
                          elevation: 0,
                          backgroundColor: theme.accentColor,
                          disabledBackgroundColor: theme.accentColor
                              .withOpacity(0.6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: isLoading
                            ? SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: theme.backgroundColor,
                                  strokeWidth: 2.2,
                                ),
                              )
                            : Text(
                                "Change Password",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: theme.msgSenderText,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
