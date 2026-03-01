import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ═══════════════════════════════════════════════════════════════════
// SETTINGS MODEL
// ═══════════════════════════════════════════════════════════════════
class AppSettings {
  final double fontSize;           // 1.0 = normal, 1.2 = large, 1.4 = extra large
  final bool highContrastMode;
  final bool reduceMotion;
  final ThemeMode themeMode;
  final int firstDayOfWeek;         // 1 = Monday, 6 = Saturday, 7 = Sunday

  final bool notificationsEnabled;
  final String? notificationSound; // null = default
  final bool vibrationEnabled;
  final bool alertInSilentMode;
  final bool trueBlackMode;
  final bool showPublicHolidays;
  final bool showReligiousHolidays;
  final bool showSchoolHolidays;
  final bool isOnboardingCompleted;
  final String holidayCountry;    // 'IN', 'US', 'GB', etc.

  const AppSettings({
    this.fontSize = 1.0,
    this.highContrastMode = false,
    this.reduceMotion = false,
    this.themeMode = ThemeMode.system,
    this.firstDayOfWeek = 1,
    this.notificationsEnabled = true,
    this.notificationSound,
    this.vibrationEnabled = true,
    this.alertInSilentMode = false,
    this.trueBlackMode = false,
    this.showPublicHolidays = true,
    this.showReligiousHolidays = false,
    this.showSchoolHolidays = false,
    this.isOnboardingCompleted = false,
    this.holidayCountry = 'IN',
  });

  AppSettings copyWith({
    double? fontSize,
    bool? highContrastMode,
    bool? reduceMotion,
    ThemeMode? themeMode,
    int? firstDayOfWeek,
    bool? notificationsEnabled,
    String? notificationSound,
    bool? vibrationEnabled,
    bool? alertInSilentMode,
    bool? trueBlackMode,
    bool? showPublicHolidays,
    bool? showReligiousHolidays,
    bool? showSchoolHolidays,
    bool? isOnboardingCompleted,
    String? holidayCountry,
  }) {
    return AppSettings(
      fontSize: fontSize ?? this.fontSize,
      highContrastMode: highContrastMode ?? this.highContrastMode,
      reduceMotion: reduceMotion ?? this.reduceMotion,
      themeMode: themeMode ?? this.themeMode,
      firstDayOfWeek: firstDayOfWeek ?? this.firstDayOfWeek,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      notificationSound: notificationSound ?? this.notificationSound,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      alertInSilentMode: alertInSilentMode ?? this.alertInSilentMode,
      trueBlackMode: trueBlackMode ?? this.trueBlackMode,
      showPublicHolidays: showPublicHolidays ?? this.showPublicHolidays,
      showReligiousHolidays: showReligiousHolidays ?? this.showReligiousHolidays,
      showSchoolHolidays: showSchoolHolidays ?? this.showSchoolHolidays,
      isOnboardingCompleted: isOnboardingCompleted ?? this.isOnboardingCompleted,
      holidayCountry: holidayCountry ?? this.holidayCountry,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// SETTINGS NOTIFIER
// ═══════════════════════════════════════════════════════════════════
class SettingsNotifier extends Notifier<AppSettings> {
  @override
  AppSettings build() {
    _loadSettings();
    return const AppSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    
    state = AppSettings(
      fontSize: prefs.getDouble('font_size') ?? 1.0,
      highContrastMode: prefs.getBool('high_contrast') ?? false,
      reduceMotion: prefs.getBool('reduce_motion') ?? false,
      themeMode: ThemeMode.values[prefs.getInt('theme_mode') ?? ThemeMode.system.index],
      firstDayOfWeek: prefs.getInt('first_day_of_week') ?? 1,
      notificationsEnabled: prefs.getBool('notifications_enabled') ?? true,
      notificationSound: prefs.getString('notification_sound'),
      vibrationEnabled: prefs.getBool('vibration_enabled') ?? true,
      alertInSilentMode: prefs.getBool('alert_silent_mode') ?? false,
      trueBlackMode: prefs.getBool('true_black_mode') ?? false,
      showPublicHolidays: prefs.getBool('show_public_holidays') ?? true,
      showReligiousHolidays: prefs.getBool('show_religious_holidays') ?? false,
      showSchoolHolidays: prefs.getBool('show_school_holidays') ?? false,
      isOnboardingCompleted: prefs.getBool('onboarding_completed') ?? false,
      holidayCountry: prefs.getString('holiday_country') ?? 'IN',
    );
  }

  Future<void> setFontSize(double size) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('font_size', size);
    state = state.copyWith(fontSize: size);
  }

  Future<void> setHighContrast(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('high_contrast', enabled);
    state = state.copyWith(highContrastMode: enabled);
  }

  Future<void> setReduceMotion(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('reduce_motion', enabled);
    state = state.copyWith(reduceMotion: enabled);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('theme_mode', mode.index);
    state = state.copyWith(themeMode: mode);
  }

  Future<void> setFirstDayOfWeek(int day) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('first_day_of_week', day);
    state = state.copyWith(firstDayOfWeek: day);
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', enabled);
    state = state.copyWith(notificationsEnabled: enabled);
  }

  Future<void> setNotificationSound(String? sound) async {
    final prefs = await SharedPreferences.getInstance();
    if (sound == null) {
      await prefs.remove('notification_sound');
    } else {
      await prefs.setString('notification_sound', sound);
    }
    state = state.copyWith(notificationSound: sound);
  }

  Future<void> setVibrationEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('vibration_enabled', enabled);
    state = state.copyWith(vibrationEnabled: enabled);
  }

  Future<void> setAlertInSilentMode(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('alert_silent_mode', enabled);
    state = state.copyWith(alertInSilentMode: enabled);
  }

  Future<void> setTrueBlackMode(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('true_black_mode', enabled);
    state = state.copyWith(trueBlackMode: enabled);
  }

  Future<void> setShowPublicHolidays(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('show_public_holidays', enabled);
    state = state.copyWith(showPublicHolidays: enabled);
  }

  Future<void> setShowReligiousHolidays(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('show_religious_holidays', enabled);
    state = state.copyWith(showReligiousHolidays: enabled);
  }

  Future<void> setShowSchoolHolidays(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('show_school_holidays', enabled);
    state = state.copyWith(showSchoolHolidays: enabled);
  }

  Future<void> setOnboardingCompleted(bool completed) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', completed);
    state = state.copyWith(isOnboardingCompleted: completed);
  }
  
  Future<void> setHolidayCountry(String country) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('holiday_country', country);
    state = state.copyWith(holidayCountry: country);
  }
}

// ═══════════════════════════════════════════════════════════════════
// PROVIDER
// ═══════════════════════════════════════════════════════════════════
final settingsProvider = NotifierProvider<SettingsNotifier, AppSettings>(
  () => SettingsNotifier(),
);
