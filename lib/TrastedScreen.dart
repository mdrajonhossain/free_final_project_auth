import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:freeli/theme/themeList.dart';
import 'package:freeli/theme/ThemeCubit.dart';
import 'package:freeli/theme/ProfessionalThemePage.dart';

class TrastedScreen extends StatefulWidget {
  const TrastedScreen({super.key});

  @override
  State<TrastedScreen> createState() => _TrastedScreenState();
}

class _TrastedScreenState extends State<TrastedScreen> {
  int selectedOption = 0;
  bool isLoading = false;

  Future<void> _handleContinue() async {
    if (selectedOption == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a security option")),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      // selectedOption 1 = Trust this device (true)
      // selectedOption 2 = Ask for OTP every time (false)
      await prefs.setBool('is_device_trusted', selectedOption == 1);
    } catch (e) {
      debugPrint("Error saving trust preference: $e");
    }

    // Professional navigation: Replace the screen so user can't go back to security options
    if (mounted) Navigator.pushReplacementNamed(context, "/home");
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, AppThemeModel>(
      builder: (context, appTheme) {
        final bgColor = appTheme.backgroundColor;
        final textColor = appTheme.textColor;
        final subTextColor = appTheme.subTextColor;

        return Scaffold(
          backgroundColor: bgColor,
          body: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 28,
                        vertical: 40,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 20),

                          Text(
                            "Security Preferences",
                            style: TextStyle(
                              color: textColor,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Text(
                              "Choose how you'd like to secure your account on this device for future sign-ins.",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: subTextColor,
                                fontSize: 15,
                                height: 1.4,
                              ),
                            ),
                          ),
                          const SizedBox(height: 48),

                          /// ✅ Option 1: Trusted Card
                          _buildOptionCard(
                            title: "Trust this device",
                            subtitle:
                                "You won't be asked for an OTP on this device again.",
                            option: 1,
                            appTheme: appTheme,
                          ),

                          const SizedBox(height: 16),

                          /// ✅ Option 2: Untrusted Card
                          _buildOptionCard(
                            title: "Ask every time",
                            subtitle:
                                "Recommended if this is a shared or public device.",
                            option: 2,
                            appTheme: appTheme,
                          ),

                          const SizedBox(height: 60),

                          /// ✅ Professional Gradient Button
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: appTheme.accentColor,
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(15),
                                  onTap: isLoading ? null : _handleContinue,
                                  child: Center(
                                    child: isLoading
                                        ? const SizedBox(
                                            height: 24,
                                            width: 24,
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : const Text(
                                            "Confirm & Continue",
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 16,
                                            ),
                                          ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 30),
                          _buildThemeToggles(appTheme),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildOptionCard({
    required String title,
    required String subtitle,
    required int option,
    required AppThemeModel appTheme,
  }) {
    final isSelected = selectedOption == option;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: InkWell(
        onTap: () => setState(() => selectedOption = option),
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected
                ? Colors.white.withOpacity(0.08)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? appTheme.accentColor
                  : appTheme.subTextColor.withOpacity(0.3),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: appTheme.textColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: appTheme.subTextColor,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 24,
                child: Radio<int>(
                  value: option,
                  groupValue: selectedOption,
                  onChanged: (val) => setState(() => selectedOption = val!),
                  activeColor: appTheme.accentColor,
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThemeToggles(AppThemeModel appTheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        TextButton.icon(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ProfessionalThemePage()),
          ),
          icon: Icon(Icons.palette_outlined, color: appTheme.accentColor),
          label: Text(
            "Select Professional Theme",
            style: TextStyle(color: appTheme.accentColor),
          ),
        ),
      ],
    );
  }
}
