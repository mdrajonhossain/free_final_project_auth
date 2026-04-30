import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:freeli/controller/stateBloc/LoginBloc.dart';
import 'package:freeli/controller/stateBloc/LoginEven.dart';
import 'package:freeli/controller/stateBloc/LoginState.dart';
import 'AppColors.dart';

class LoginScreen extends StatefulWidget {
  final bool isDark;
  final Function(bool) onThemeChange;

  const LoginScreen({
    super.key,
    required this.isDark,
    required this.onThemeChange,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool obscurePassword = true;
  bool rememberMe = false;

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Widget _input({
    required TextEditingController controller,
    required String hint,
    required IconData icon, // Keep as required, as it's always provided
    Color? iconColor, // Added for custom icon color
    TextInputType? keyboardType,
    bool isPassword = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(
          0.1,
        ), // Professional glass effect: translucent background
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.white30,
          width: 1,
        ), // Subtle border for glass effect
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword ? obscurePassword : false,
        keyboardType: keyboardType,
        style: const TextStyle(
          color: Colors.white,
        ), // Text color for better visibility on dark translucent background
        decoration: InputDecoration(
          prefixIcon: Icon(
            icon,
            color: iconColor ?? Colors.white70,
          ), // Icon color for glass effect
          hintText: hint,
          hintStyle: const TextStyle(
            color: Colors.white54,
          ), // Hint text color for glass effect
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    obscurePassword ? Icons.visibility_off : Icons.visibility,
                    color: Colors.white70, // Suffix icon color for glass effect
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
    final bgColor = AppColors.getBackgroundColor(widget.isDark);

    return BlocListener<LoginBloc, LoginState>(
      listener: (context, state) {
        if (state is LoginSuccess) {
          final loginData = state.data;
          final email = emailController.text.trim();

          if (loginData['status'] == true) {
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
            SnackBar(content: Text(state.error), backgroundColor: Colors.red),
          );
        }
      },

      child: Scaffold(
        backgroundColor: bgColor,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 80),

                Image.asset('assets/logo.webp', height: 50),

                const SizedBox(height: 40),

                const Text(
                  "Hello! Welcome back",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 30),

                _input(
                  controller: emailController,
                  hint: "Email",
                  icon: Icons.email,
                  iconColor: Colors.white70, // Apply icon color
                  keyboardType: TextInputType.emailAddress,
                ),

                const SizedBox(height: 15),

                _input(
                  controller: passwordController,
                  hint: "Password",
                  icon: Icons.lock_outline,
                  iconColor: Colors.white70, // Apply icon color
                  isPassword: true,
                ),

                const SizedBox(height: 10),

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
                        side: const BorderSide(color: Colors.white70),
                        activeColor: AppColors.accentColor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      "Remember me ?",
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () {}, // TODO: Implement OTP Login logic
                      child: const Text(
                        "Sign in with otp",
                        style: TextStyle(
                          color: AppColors.accentColor,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {}, // TODO: Implement Forgot Password logic
                      child: const Text(
                        "Forgot your password ?",
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: InkWell(
                    highlightColor:
                        Colors.transparent, // Remove highlight border on tap
                    splashColor:
                        Colors.transparent, // Remove splash border on tap
                    onTap: () {
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
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(12),
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
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                /// ================= SIGN UP PROMPT =================
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Don't have an account ? ",
                      style: TextStyle(color: Colors.white70),
                    ),
                    GestureDetector(
                      onTap: () {}, // TODO: Navigate to Sign Up
                      child: const Text(
                        "Sign up",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: () => widget.onThemeChange(false),
                      icon: const Icon(Icons.wb_sunny),
                      color: Colors.yellow,
                    ),
                    IconButton(
                      onPressed: () => widget.onThemeChange(true),
                      icon: const Icon(Icons.nightlight_round),
                      color: Colors.white,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
