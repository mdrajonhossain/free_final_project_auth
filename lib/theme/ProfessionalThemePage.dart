import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freeli/theme/themeList.dart';
import 'package:freeli/theme/ThemeCubit.dart';

class ProfessionalThemePage extends StatelessWidget {
  const ProfessionalThemePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, AppThemeModel>(
      builder: (context, currentTheme) {
        return Scaffold(
          backgroundColor: currentTheme.backgroundColor,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
            title: Text(
              "Professional Themes",
              style: TextStyle(
                color: currentTheme.textColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: currentTheme.textColor,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.85,
            ),
            itemCount: professionalThemes.length,
            itemBuilder: (context, index) {
              final theme = professionalThemes[index];
              final bool isSelected = theme.name == currentTheme.name;

              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: theme.accentColor.withOpacity(0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          ),
                        ]
                      : [],
                ),
                child: InkWell(
                  onTap: () {
                    context.read<ThemeCubit>().updateTheme(theme);
                  },
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: isSelected
                            ? theme.accentColor
                            : Colors.white.withOpacity(0.05),
                        width: isSelected ? 3 : 1,
                      ),
                    ),
                    child: Stack(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Palette Preview Dots
                              Row(
                                children: [
                                  _buildPaletteDot(theme.backgroundColor),
                                  _buildPaletteDot(theme.accentColor),
                                  _buildPaletteDot(theme.textColor),
                                ],
                              ),
                              const Spacer(),
                              Text(
                                theme.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: theme.textColor,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                isSelected ? "Active" : "Apply",
                                style: TextStyle(
                                  color: isSelected
                                      ? theme.accentColor
                                      : theme.subTextColor.withOpacity(0.6),
                                  fontSize: 11,
                                  fontWeight: isSelected
                                      ? FontWeight.w900
                                      : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          Positioned(
                            top: 12,
                            right: 12,
                            child: CircleAvatar(
                              radius: 10,
                              backgroundColor: theme.accentColor,
                              child: const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 12,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildPaletteDot(Color color) {
    return Container(
      margin: const EdgeInsets.only(right: 6),
      height: 12,
      width: 12,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white24, width: 0.5),
      ),
    );
  }
}
