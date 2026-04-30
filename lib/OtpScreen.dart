import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'AppColors.dart';

import 'package:freeli/controller/stateBloc/LoginBloc.dart';
import 'package:freeli/controller/stateBloc/LoginEven.dart';
import 'package:freeli/controller/stateBloc/LoginState.dart';

class OtpScreen extends StatefulWidget {
  final bool isDark;
  final Function(bool) onThemeChange;

  const OtpScreen({
    super.key,
    required this.isDark,
    required this.onThemeChange,
  });

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final List<TextEditingController> controllers = List.generate(
    6,
    (index) => TextEditingController(),
  );

  final List<FocusNode> focusNodes = List.generate(6, (index) => FocusNode());

  String getOtp() => controllers.map((e) => e.text).join();

  void verifyOtp({
    required String email,
    String? sessionToken,
    required String step,
  }) async {
    final otpCode = getOtp();
    if (otpCode.length != 6) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Enter full 6 digit OTP")));
      return;
    }

    context.read<LoginBloc>().add(
      LoginVerifyOtp(
        otpCode,
        email: email,
        sessionToken: sessionToken,
        step: step,
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void resendOtp() {}

  Widget otpBox(int index, double boxSize) {
    return SizedBox(
      width: boxSize,
      height: boxSize + 5,
      child: TextField(
        controller: controllers[index],
        focusNode: focusNodes[index],
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 1,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
        decoration: InputDecoration(
          counterText: "",
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.zero,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
        ),
        onChanged: (value) {
          if (value.isNotEmpty && index < 5) {
            FocusScope.of(context).requestFocus(focusNodes[index + 1]);
          } else if (value.isEmpty && index > 0) {
            FocusScope.of(context).requestFocus(focusNodes[index - 1]);
          }
        },
      ),
    );
  }

  @override
  void dispose() {
    for (var controller in controllers) {
      controller.dispose();
    }
    for (var node in focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ??
        {};
    final String? sessionToken = args['session_token'];
    final String step = args['step'] ?? 'validate';
    final String email = args['email'] ?? '';

    final bgColor = AppColors.getBackgroundColor(widget.isDark);

    double screenWidth = MediaQuery.of(context).size.width;
    double boxSize = (screenWidth - 120) / 6; // perfect fit 6 boxes

    return BlocListener<LoginBloc, LoginState>(
      listener: (context, state) {
        if (state is LoginSuccess) {
          final loginData = state.data;
          print("8888888888888888: $loginData"); // Debug print
          if (loginData['status'] == true) {
            if (loginData['next_step'] == "company") {
              Navigator.pushNamed(
                context,
                "/company",
                arguments: {
                  "email": email,
                  "session_token": loginData['session_token'],
                  "code": getOtp(),
                  "step": "company",
                  "companies": loginData['companies'],
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
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.shield_outlined,
                          size: 80,
                          color: Colors.lightBlueAccent,
                        ),

                        const SizedBox(height: 30),

                        const Text(
                          "Verification Code",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 10),

                        const Text(
                          "A 6-digit code has been sent to your email.\nPlease enter it below to continue.",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),

                        const SizedBox(height: 40),

                        /// 🔢 FIXED OTP ROW
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(6, (i) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                              ),
                              child: otpBox(i, boxSize),
                            );
                          }),
                        ),

                        const SizedBox(height: 20),

                        /// 🔁 RESEND
                        TextButton(
                          onPressed: resendOtp,
                          child: const Text(
                            "Didn't receive the code? Resend OTP",
                            style: TextStyle(color: Colors.lightBlueAccent),
                          ),
                        ),

                        const SizedBox(height: 35),

                        /// 🔘 VERIFY BUTTON
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: AppColors.primaryGradient,
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(15),
                                onTap: () => verifyOtp(
                                  email: email,
                                  sessionToken: sessionToken,
                                  step: step,
                                ),
                                child: Center(
                                  child: BlocBuilder<LoginBloc, LoginState>(
                                    builder: (context, state) {
                                      if (state is LoginLoading) {
                                        return const SizedBox(
                                          height: 24,
                                          width: 24,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        );
                                      }
                                      return const Text(
                                        "Verify & Continue",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 16,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 30),

                        _buildThemeToggles(),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildThemeToggles() {
    return Row(
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
    );
  }
}
