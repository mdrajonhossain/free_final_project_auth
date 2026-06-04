import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:freeli/theme/themeList.dart';

class ThemeCubit extends Cubit<AppThemeModel> {
  static const String _themeKey = 'professional_theme_index';

  ThemeCubit() : super(professionalThemes[0]) {
    _loadTheme();
  }

  void changeTheme(int index) async {
    if (index >= 0 && index < professionalThemes.length) {
      emit(professionalThemes[index]);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_themeKey, index);
    }
  }

  void updateTheme(AppThemeModel theme) {
    final index = professionalThemes.indexOf(theme);
    changeTheme(index);
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final index = prefs.getInt(_themeKey) ?? 0;
    if (index < professionalThemes.length) {
      emit(professionalThemes[index]);
    }
  }

  void toggleTheme() {
    int nextIndex = (currentIndex + 1) % professionalThemes.length;
    changeTheme(nextIndex);
  }

  int get currentIndex => professionalThemes.indexOf(state);
}
