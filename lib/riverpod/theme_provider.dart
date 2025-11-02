import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:test_project/riverpod/favorites_provider.dart';


class ThemeNotifier extends Notifier<ThemeMode> {
  static const String _themeModeKey = 'theme_mode';

  @override
  ThemeMode build() {
    // Загружаем сохраненную тему из SharedPreferences
    final prefs = ref.watch(sharedPreferencesProvider);

    return prefs.when(
      data: (data) {
        final themeModeString = data.getString(_themeModeKey);
        if (themeModeString == null) {
          return ThemeMode.light; // По умолчанию светлая тема
        }

        switch (themeModeString) {
          case 'light':
            return ThemeMode.light;
          case 'dark':
            return ThemeMode.dark;
          case 'system':
            return ThemeMode.system;
          default:
            return ThemeMode.light;
        }
      },
      loading: () => ThemeMode.light,
      error: (_, __) => ThemeMode.light,
    );
  }

  /// Установить светлую тему
  Future<void> setLightTheme() async {
    await _saveThemeMode(ThemeMode.light);
    state = ThemeMode.light;
  }

  /// Установить темную тему
  Future<void> setDarkTheme() async {
    await _saveThemeMode(ThemeMode.dark);
    state = ThemeMode.dark;
  }

  /// Установить системную тему
  Future<void> setSystemTheme() async {
    await _saveThemeMode(ThemeMode.system);
    state = ThemeMode.system;
  }

  /// Переключить тему (светлая <-> темная)
  Future<void> toggleTheme() async {
    final newMode = state == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    await _saveThemeMode(newMode);
    state = newMode;
  }

  /// Сохранить выбор темы в SharedPreferences
  Future<void> _saveThemeMode(ThemeMode mode) async {
    final prefs = await ref.read(sharedPreferencesProvider.future);
    String modeString;

    switch (mode) {
      case ThemeMode.light:
        modeString = 'light';
        break;
      case ThemeMode.dark:
        modeString = 'dark';
        break;
      case ThemeMode.system:
        modeString = 'system';
        break;
    }

    await prefs.setString(_themeModeKey, modeString);
  }

  /// Проверить, используется ли темная тема
  bool get isDarkMode {
    if (state == ThemeMode.dark) return true;
    if (state == ThemeMode.light) return false;

    // Для system режима проверяем системную тему
    // (в runtime это будет определяться автоматически MaterialApp)
    return false;
  }
}

/// Provider для управления темой приложения
final themeProvider = NotifierProvider<ThemeNotifier, ThemeMode>(
  ThemeNotifier.new,
);

/// Provider для проверки, темная ли тема сейчас
final isDarkModeProvider = Provider<bool>((ref) {
  final themeMode = ref.watch(themeProvider);
  return themeMode == ThemeMode.dark;
});
