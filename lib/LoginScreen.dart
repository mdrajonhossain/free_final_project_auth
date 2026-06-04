import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:ui';

import 'package:freeli/controller/stateBloc/LoginBloc.dart';
import 'package:freeli/controller/stateBloc/LoginEven.dart';
import 'package:freeli/controller/stateBloc/LoginState.dart';
import 'package:freeli/theme/ProfessionalThemePage.dart';
import 'package:freeli/theme/themeList.dart';
import 'package:freeli/theme/ThemeCubit.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool obscurePassword = true;
  bool rememberMe = false;

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      rememberMe = prefs.getBool('remember_me') ?? false;
      if (rememberMe) {
        emailController.text = prefs.getString('saved_email') ?? '';
      }
    });
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Widget _input({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    Color? iconColor,
    TextInputType? keyboardType,
    bool isPassword = false,
  }) {
    final appTheme = context.read<ThemeCubit>().state; // Access current theme
    final bool isDark = appTheme.backgroundColor.computeLuminance() < 0.5;
    return Container(
      decoration: BoxDecoration(
        color: appTheme.cardColor.withOpacity(0.5), // Use appTheme.cardColor
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.15)
              : Colors.black.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword ? obscurePassword : false,
        keyboardType: keyboardType,
        style: TextStyle(
          // Use appTheme.textColor
          color: appTheme.textColor,
          fontSize: 15,
        ),
        decoration: InputDecoration(
          prefixIcon: Icon(
            icon,
            color:
                iconColor ?? appTheme.subTextColor, // Use appTheme.subTextColor
            size: 22,
          ),
          hintText: hint,
          hintStyle: TextStyle(
            // Use appTheme.subTextColor
            color: appTheme.subTextColor.withOpacity(0.7),
            fontSize: 15,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    obscurePassword ? Icons.visibility_off : Icons.visibility,
                    color: appTheme.subTextColor, // Use appTheme.subTextColor
                    size: 20,
                  ),
                  onPressed: () {
                    setState(() {
                      obscurePassword = !obscurePassword;
                    });
                  },
                )
              : null,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, AppThemeModel>(
      builder: (context, appTheme) {
        final bool isDark = appTheme.backgroundColor.computeLuminance() < 0.5;
        final bgColor = appTheme.backgroundColor; // Already correct
        final primaryTextColor = appTheme.textColor; // Already correct
        final secondaryTextColor = appTheme.subTextColor; // Already correct

        return BlocListener<LoginBloc, LoginState>(
          listener: (context, state) async {
            if (state is LoginSuccess) {
              final loginData = state.data;
              final email = emailController.text.trim();

              if (loginData['status'] == true) {
                final prefs = await SharedPreferences.getInstance();
                if (rememberMe) {
                  await prefs.setBool('remember_me', true);
                  await prefs.setString('saved_email', email);
                } else {
                  await prefs.setBool('remember_me', false);
                  await prefs.remove('saved_email');
                }

                if (loginData['next_step'] == "otp") {
                  Navigator.pushNamed(
                    context,
                    "/otp",
                    arguments: {
                      "email": email,
                      "session_token": loginData['session_token'],
                      "step": "otp",
                    },
                  );
                } else if (loginData['next_step'] == "company") {
                  Navigator.pushNamed(
                    context,
                    "/company",
                    arguments: {
                      "email": email,
                      "companies": loginData['companies'],
                      "session_token": loginData['session_token'],
                      "step": "company",
                    },
                  );
                }
              }
            } else if (state is LoginFailure) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.error),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },

          child: Scaffold(
            backgroundColor: bgColor,
            body: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 60),

                    Hero(
                      tag: 'logo',
                      child: Image.asset('assets/logo.webp', height: 60),
                    ),

                    const SizedBox(height: 50),

                    Column(
                      children: [
                        Text(
                          "Hello ! Welcome back",
                          style: TextStyle(
                            color: primaryTextColor,
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                        Text(
                          "Sign into your account here",
                          style: TextStyle(
                            color: secondaryTextColor,
                            fontSize: 15,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 45),

                    _input(
                      controller: emailController,
                      hint: "Email",
                      icon: Icons.email,
                      keyboardType: TextInputType.emailAddress,
                    ),

                    const SizedBox(height: 15),

                    _input(
                      controller: passwordController,
                      hint: "Password",
                      icon: Icons.lock_outline,
                      isPassword: true,
                    ),

                    const SizedBox(height: 12),

                    /// ================= REMEMBER ME & PASSWORD LINKS =================
                    Row(
                      children: [
                        SizedBox(
                          height: 24,
                          width: 24,
                          child: Checkbox(
                            value: rememberMe,
                            onChanged: (val) =>
                                setState(() => rememberMe = val ?? false),
                            side: BorderSide(
                              color: appTheme.subTextColor.withOpacity(
                                0.5,
                              ), // Use appTheme.subTextColor
                            ),
                            activeColor: appTheme.accentColor,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "Remember me ?",
                          style: TextStyle(
                            color: secondaryTextColor,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: () {}, // TODO: Implement OTP Login logic
                          child: Text(
                            "Sign in with otp",
                            style: TextStyle(
                              color: appTheme.accentColor,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed:
                              () {}, // TODO: Implement Forgot Password logic
                          child: Text(
                            "Forgot your password ?",
                            style: TextStyle(
                              color: secondaryTextColor,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: InkWell(
                        highlightColor: Colors.transparent,
                        splashColor: Colors.transparent,
                        onTap: () {
                          FocusScope.of(context).unfocus();
                          final state = context.read<LoginBloc>().state;
                          if (state is! LoginLoading) {
                            if (emailController.text.trim().isEmpty ||
                                passwordController.text.trim().isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    "Please enter both email and password",
                                  ),
                                ),
                              );
                              return;
                            }
                            context.read<LoginBloc>().add(
                              LoginSubmitted(
                                emailController.text.trim(),
                                passwordController.text.trim(),
                              ),
                            );
                          }
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: appTheme.accentColor,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 15,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Center(
                            child: BlocBuilder<LoginBloc, LoginState>(
                              builder: (context, state) {
                                if (state is LoginLoading) {
                                  return const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  );
                                }
                                return const Text(
                                  "Sign In",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),

                    /// ================= SIGN UP PROMPT =================
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Don't have an account ? ",
                          style: TextStyle(
                            color: secondaryTextColor,
                            fontSize: 14,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {}, // TODO: Navigate to Sign Up
                          child: Text(
                            "Sign up",
                            style: TextStyle(
                              color: appTheme
                                  .accentColor, // Use appTheme.accentColor
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton.icon(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ProfessionalThemePage(),
                            ),
                          ),
                          icon: const Icon(Icons.palette_outlined),
                          label: const Text("Select Professional Theme"),
                        ),
                      ],
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
