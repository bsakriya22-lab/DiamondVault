import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  bool _followSystemTheme = true;
  bool _isDarkMode = false;

  bool get followSystemTheme => _followSystemTheme;
  bool get isDarkMode => _followSystemTheme
      ? WidgetsBinding.instance.platformDispatcher.platformBrightness ==
          Brightness.dark
      : _isDarkMode;

  ThemeData get lightTheme => ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1A1A2E),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF5F5F0),
        cardColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1A1A2E),
          foregroundColor: Colors.white,
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Color(0xFF1A1A2E)),
          bodyMedium: TextStyle(color: Color(0xFF1A1A2E)),
          bodySmall: TextStyle(color: Color(0xFF666666)),
          headlineLarge: TextStyle(color: Color(0xFF1A1A2E)),
          headlineMedium: TextStyle(color: Color(0xFF1A1A2E)),
          headlineSmall: TextStyle(color: Color(0xFF1A1A2E)),
          titleLarge: TextStyle(color: Color(0xFF1A1A2E)),
          titleMedium: TextStyle(color: Color(0xFF1A1A2E)),
          titleSmall: TextStyle(color: Color(0xFF1A1A2E)),
          labelLarge: TextStyle(color: Color(0xFF1A1A2E)),
          labelMedium: TextStyle(color: Color(0xFF666666)),
          labelSmall: TextStyle(color: Color(0xFF666666)),
        ),
        inputDecorationTheme: const InputDecorationTheme(
          labelStyle: TextStyle(color: Color(0xFF666666)),
          hintStyle: TextStyle(color: Color(0xFF999999)),
        ),
      );

  ThemeData get darkTheme => ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1A1A2E),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF0F0F23),
        cardColor: const Color(0xFF1A1A2E),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0F0F23),
          foregroundColor: Colors.white,
        ),
        dialogBackgroundColor: const Color(0xFF1A1A2E),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Color(0xFF1A1A2E),
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.white70,
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.white),
          bodyMedium: TextStyle(color: Colors.white),
          bodySmall: TextStyle(color: Colors.white70),
          headlineLarge: TextStyle(color: Colors.white),
          headlineMedium: TextStyle(color: Colors.white),
          headlineSmall: TextStyle(color: Colors.white),
          titleLarge: TextStyle(color: Colors.white),
          titleMedium: TextStyle(color: Colors.white),
          titleSmall: TextStyle(color: Colors.white),
          labelLarge: TextStyle(color: Colors.white),
          labelMedium: TextStyle(color: Colors.white70),
          labelSmall: TextStyle(color: Colors.white60),
        ),
        inputDecorationTheme: const InputDecorationTheme(
          labelStyle: TextStyle(color: Colors.white70),
          hintStyle: TextStyle(color: Colors.white38),
        ),
      );

  ThemeData get currentTheme => isDarkMode ? darkTheme : lightTheme;

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _followSystemTheme = prefs.getBool('followSystemTheme') ?? true;
    _isDarkMode = prefs.getBool('isDarkMode') ?? false;
    notifyListeners();
  }

  Future<void> setFollowSystemTheme(bool value) async {
    _followSystemTheme = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('followSystemTheme', value);
    notifyListeners();
  }

  Future<void> setDarkMode(bool value) async {
    _isDarkMode = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', value);
    notifyListeners();
  }

  void updateSystemBrightness() {
    if (_followSystemTheme) {
      notifyListeners();
    }
  }
}
