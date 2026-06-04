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
            title: Text(
              "Professional Themes",
              style: TextStyle(
                color: currentTheme.textColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: currentTheme.textColor),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: professionalThemes.length,
            itemBuilder: (context, index) {
              final theme = professionalThemes[index];
              final isSelected = currentTheme.name == theme.name;
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: isSelected
                      ? Border.all(color: theme.accentColor, width: 2)
                      : null,
                ),
                child: ListTile(
                  onTap: () => context.read<ThemeCubit>().changeTheme(index),
                  title: Text(
                    theme.name,
                    style: TextStyle(
                      color: theme.textColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  leading: CircleAvatar(backgroundColor: theme.backgroundColor),
                  trailing: isSelected
                      ? Icon(Icons.check_circle, color: theme.accentColor)
                      : null,
                ),
              );
            },
          ),
        );
      },
    );
  }
}
