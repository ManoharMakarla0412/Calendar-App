import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/settings_provider.dart';
import '../features/events/presentation/events_view_model.dart';
import '../models/event.dart';
import '../services/birthday_service.dart';
import 'recycle_bin_screen.dart';
import 'permissions_screen.dart';
import '../utils/snackbar_helpers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Explicitly handle Section Header Color
    final sectionHeaderColor = theme.primaryColor;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: theme.appBarTheme.backgroundColor,
        foregroundColor: theme.appBarTheme.titleTextStyle?.color,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        children: [
          _buildSectionHeader(
            context,
            'Display & Accessibility',
            sectionHeaderColor,
          ),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            color: theme.cardColor,
            child: Column(
              children: [
                ListTile(
                  leading: Icon(
                    Icons.text_fields,
                    color: isDark ? Colors.white : Colors.black54,
                  ),
                  title: const Text('Font Size'),
                  subtitle: Text(_getFontSizeLabel(settings.fontSize)),
                  onTap: () =>
                      _showFontSizeDialog(context, ref, settings.fontSize),
                ),
                Divider(
                  height: 1,
                  indent: 56,
                  color: theme.dividerColor.withValues(alpha: 0.1),
                ),
                SwitchListTile(
                  secondary: Icon(
                    Icons.contrast,
                    color: isDark ? Colors.white : Colors.black54,
                  ),
                  title: const Text('High Contrast Mode'),
                  subtitle: const Text('Increase color contrast'),
                  value: settings.highContrastMode,
                  activeThumbColor: theme.colorScheme.primary,
                  onChanged: (value) => ref
                      .read(settingsProvider.notifier)
                      .setHighContrast(value),
                ),
                Divider(
                  height: 1,
                  indent: 56,
                  color: theme.dividerColor.withValues(alpha: 0.1),
                ),
                SwitchListTile(
                  secondary: Icon(
                    Icons.dark_mode,
                    color: isDark ? Colors.white : Colors.black54,
                  ),
                  title: const Text('True Black Mode'),
                  subtitle: const Text('Pure black background in dark mode'),
                  value: settings.trueBlackMode,
                  activeThumbColor: theme.colorScheme.primary,
                  onChanged: (value) => ref
                      .read(settingsProvider.notifier)
                      .setTrueBlackMode(value),
                ),
                Divider(
                  height: 1,
                  indent: 56,
                  color: theme.dividerColor.withValues(alpha: 0.1),
                ),
                SwitchListTile(
                  secondary: Icon(
                    Icons.motion_photos_off,
                    color: isDark ? Colors.white : Colors.black54,
                  ),
                  title: const Text('Reduce Motion'),
                  subtitle: const Text('Minimize animations'),
                  value: settings.reduceMotion,
                  activeThumbColor: theme.colorScheme.primary,
                  onChanged: (value) => ref
                      .read(settingsProvider.notifier)
                      .setReduceMotion(value),
                ),
              ],
            ),
          ),

          _buildSectionHeader(context, 'Notifications', sectionHeaderColor),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            color: theme.cardColor,
            child: Column(
              children: [
                SwitchListTile(
                  secondary: Icon(
                    Icons.notifications_active,
                    color: isDark ? Colors.white : Colors.black54,
                  ),
                  title: const Text('Enable Notifications'),
                  value: settings.notificationsEnabled,
                  activeThumbColor: theme.colorScheme.primary,
                  onChanged: (value) => ref
                      .read(settingsProvider.notifier)
                      .setNotificationsEnabled(value),
                ),
                if (settings.notificationsEnabled) ...[
                  Divider(
                    height: 1,
                    indent: 56,
                    color: theme.dividerColor.withValues(alpha: 0.1),
                  ),
                  SwitchListTile(
                    secondary: Icon(
                      Icons.vibration,
                      color: isDark ? Colors.white : Colors.black54,
                    ),
                    title: const Text('Vibration'),
                    value: settings.vibrationEnabled,
                    activeThumbColor: theme.colorScheme.primary,
                    onChanged: (value) => ref
                        .read(settingsProvider.notifier)
                        .setVibrationEnabled(value),
                  ),
                  Divider(
                    height: 1,
                    indent: 56,
                    color: theme.dividerColor.withValues(alpha: 0.1),
                  ),
                  SwitchListTile(
                    secondary: Icon(
                      Icons.do_not_disturb_on,
                      color: isDark ? Colors.white : Colors.black54,
                    ),
                    title: const Text('Alert in Silent Mode'),
                    value: settings.alertInSilentMode,
                    activeThumbColor: theme.colorScheme.primary,
                    onChanged: (value) => ref
                        .read(settingsProvider.notifier)
                        .setAlertInSilentMode(value),
                  ),
                ],
              ],
            ),
          ),

          _buildSectionHeader(context, 'Calendar Settings', sectionHeaderColor),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            color: theme.cardColor,
            child: Column(
              children: [
                ListTile(
                  leading: Icon(
                    Icons.palette_outlined,
                    color: isDark ? Colors.white : Colors.black54,
                  ),
                  title: const Text('Theme'),
                  subtitle: Text(_getThemeLabel(settings.themeMode)),
                  onTap: () =>
                      _showThemeDialog(context, ref, settings.themeMode),
                ),
                ListTile(
                  leading: Icon(
                    Icons.calendar_today,
                    color: isDark ? Colors.white : Colors.black54,
                  ),
                  title: const Text('Start Week On'),
                  subtitle: Text(_getStartDayLabel(settings.firstDayOfWeek)),
                  onTap: () => _showStartDayDialog(
                    context,
                    ref,
                    settings.firstDayOfWeek,
                  ),
                ),
              ],
            ),
          ),

          _buildSectionHeader(
            context,
            'Holidays & Birthdays',
            sectionHeaderColor,
          ),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            color: theme.cardColor,
            child: Column(
              children: [
                SwitchListTile(
                  secondary: Icon(
                    Icons.event_available,
                    color: isDark ? Colors.white : Colors.black54,
                  ),
                  title: const Text('Public Holidays'),
                  value: settings.showPublicHolidays,
                  activeThumbColor: theme.colorScheme.primary,
                  onChanged: (value) => ref
                      .read(settingsProvider.notifier)
                      .setShowPublicHolidays(value),
                ),
                if (settings.showPublicHolidays) ...[
                  Divider(
                    height: 1,
                    indent: 56,
                    color: theme.dividerColor.withValues(alpha: 0.1),
                  ),
                  ListTile(
                    leading: const SizedBox(
                      width: 24,
                    ), // Offset to align with switch title
                    title: const Text('Holiday Country'),
                    subtitle: Text(_getCountryLabel(settings.holidayCountry)),
                    onTap: () => _showCountryDialog(
                      context,
                      ref,
                      settings.holidayCountry,
                    ),
                  ),
                ],
                Divider(
                  height: 1,
                  indent: 56,
                  color: theme.dividerColor.withValues(alpha: 0.1),
                ),
                SwitchListTile(
                  secondary: Icon(
                    Icons.temple_hindu,
                    color: isDark ? Colors.white : Colors.black54,
                  ),
                  title: const Text('Religious Holidays'),
                  value: settings.showReligiousHolidays,
                  activeThumbColor: theme.colorScheme.primary,
                  onChanged: (value) => ref
                      .read(settingsProvider.notifier)
                      .setShowReligiousHolidays(value),
                ),
                Divider(
                  height: 1,
                  indent: 56,
                  color: theme.dividerColor.withValues(alpha: 0.1),
                ),
                SwitchListTile(
                  secondary: Icon(
                    Icons.school,
                    color: isDark ? Colors.white : Colors.black54,
                  ),
                  title: const Text('School Holidays'),
                  value: settings.showSchoolHolidays,
                  activeThumbColor: theme.colorScheme.primary,
                  onChanged: (value) => ref
                      .read(settingsProvider.notifier)
                      .setShowSchoolHolidays(value),
                ),
                Divider(
                  height: 1,
                  indent: 56,
                  color: theme.dividerColor.withValues(alpha: 0.1),
                ),
                ListTile(
                  leading: Icon(
                    Icons.cake,
                    color: isDark ? Colors.white : Colors.black54,
                  ),
                  title: const Text('Sync Birthdays'),
                  subtitle: const Text('Fetch birthdays from contacts'),
                  onTap: () async {
                    SnackbarHelpers.showSuccess(
                      context,
                      'Syncing birthdays...',
                    );
                    final birthdayService = BirthdayService();
                    final List<Event> birthdays = await birthdayService
                        .fetchBirthdays();

                    if (birthdays.isNotEmpty) {
                      await ref
                          .read(eventsProvider.notifier)
                          .syncBirthdays(birthdays);
                      if (context.mounted) {
                        SnackbarHelpers.showSuccess(
                          context,
                          'Synced ${birthdays.length} birthdays',
                        );
                      }
                    } else {
                      if (context.mounted) {
                        SnackbarHelpers.showError(
                          context,
                          'No birthdays found or permission denied',
                        );
                      }
                    }
                  },
                ),
              ],
            ),
          ),

          _buildSectionHeader(context, 'Data Management', sectionHeaderColor),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            color: theme.cardColor,
            child: Column(
              children: [
                ListTile(
                  leading: Icon(
                    Icons.delete_sweep_outlined,
                    color: isDark ? Colors.white : Colors.black54,
                  ),
                  title: const Text('Recycle Bin'),
                  subtitle: const Text('Restore deleted events'),
                  trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const RecycleBinScreen(),
                    ),
                  ),
                ),
                Divider(
                  height: 1,
                  indent: 56,
                  color: theme.dividerColor.withValues(alpha: 0.1),
                ),
                ListTile(
                  leading: Icon(
                    Icons.help_outline,
                    color: isDark ? Colors.white : Colors.black54,
                  ),
                  title: const Text('Troubleshoot Sync'),
                  subtitle: const Text('Missing Google Events?'),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Sync Help'),
                        content: const Text(
                          'To sync Google Calendar, you must sign in via your device settings:\n\n'
                          '1. Open your device Settings.\n'
                          '2. Go to "Passwords & Accounts" or "Accounts".\n'
                          '3. Select "Add Account" if you are not signed in.\n'
                          '4. Select your Google account.\n'
                          '5. Ensure "Calendar" sync is switched ON.\n'
                          '6. Come back here and tap "Force Device Sync".',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Got it'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                Divider(
                  height: 1,
                  indent: 56,
                  color: theme.dividerColor.withValues(alpha: 0.1),
                ),
                ListTile(
                  leading: Icon(
                    Icons.sync,
                    color: isDark ? Colors.white : Colors.black54,
                  ),
                  title: const Text('Force Device Sync'),
                  onTap: () async {
                    SnackbarHelpers.showSuccess(context, 'Syncing events...');
                    final success = await ref
                        .read(eventsProvider.notifier)
                        .fetchDeviceEvents();
                    if (context.mounted) {
                      if (success) {
                        // Count events roughly
                        final count = ref
                            .read(eventsProvider)
                            .values
                            .fold(
                              0,
                              (previous, list) => previous + list.length,
                            );
                        SnackbarHelpers.showSuccess(
                          context,
                          'Sync completed. showing $count total events.',
                        );
                      } else {
                        SnackbarHelpers.showError(
                          context,
                          'Sync failed. Check permissions.',
                        );
                      }
                    }
                  },
                ),
              ],
            ),
          ),

          _buildSectionHeader(
            context,
            'Privacy & Security',
            sectionHeaderColor,
          ),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            color: theme.cardColor,
            child: Column(
              children: [
                ListTile(
                  leading: Icon(
                    Icons.security_outlined,
                    color: isDark ? Colors.white : Colors.black54,
                  ),
                  title: const Text('App Permissions'),
                  subtitle: const Text(
                    'Manage calendar, location, and other access',
                  ),
                  trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PermissionsScreen(),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
          Center(
            child: Text(
              'Version 1.0.0',
              style: TextStyle(color: theme.disabledColor, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: isDark
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.9)
              : color,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  String _getFontSizeLabel(double size) {
    if (size <= 1.0) return 'Normal';
    if (size <= 1.2) return 'Large';
    return 'Extra Large';
  }

  String _getThemeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
        return 'System Default';
    }
  }

  String _getStartDayLabel(int day) {
    switch (day) {
      case 1:
        return 'Monday';
      case 2:
        return 'Tuesday';
      case 3:
        return 'Wednesday';
      case 4:
        return 'Thursday';
      case 5:
        return 'Friday';
      case 6:
        return 'Saturday';
      case 7:
        return 'Sunday';
      default:
        return 'Monday';
    }
  }

  void _showFontSizeDialog(
    BuildContext context,
    WidgetRef ref,
    double currentSize,
  ) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Font Size'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<double>(
              title: const Text('Normal'),
              value: 1.0,
              groupValue: currentSize,
              activeColor: theme.colorScheme.primary,
              onChanged: (value) {
                if (value != null) {
                  ref.read(settingsProvider.notifier).setFontSize(value);
                  Navigator.pop(ctx);
                }
              },
            ),
            RadioListTile<double>(
              title: const Text('Large'),
              value: 1.2,
              groupValue: currentSize,
              activeColor: theme.colorScheme.primary,
              onChanged: (value) {
                if (value != null) {
                  ref.read(settingsProvider.notifier).setFontSize(value);
                  Navigator.pop(ctx);
                }
              },
            ),
            RadioListTile<double>(
              title: const Text('Extra Large'),
              value: 1.4,
              groupValue: currentSize,
              activeColor: theme.colorScheme.primary,
              onChanged: (value) {
                if (value != null) {
                  ref.read(settingsProvider.notifier).setFontSize(value);
                  Navigator.pop(ctx);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showThemeDialog(
    BuildContext context,
    WidgetRef ref,
    ThemeMode currentMode,
  ) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Theme'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<ThemeMode>(
              title: const Text('Light'),
              value: ThemeMode.light,
              groupValue: currentMode,
              activeColor: theme.colorScheme.primary,
              onChanged: (value) {
                if (value != null) {
                  ref.read(settingsProvider.notifier).setThemeMode(value);
                  Navigator.pop(ctx);
                }
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('Dark'),
              value: ThemeMode.dark,
              groupValue: currentMode,
              activeColor: theme.colorScheme.primary,
              onChanged: (value) {
                if (value != null) {
                  ref.read(settingsProvider.notifier).setThemeMode(value);
                  Navigator.pop(ctx);
                }
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('System Default'),
              value: ThemeMode.system,
              groupValue: currentMode,
              activeColor: theme.colorScheme.primary,
              onChanged: (value) {
                if (value != null) {
                  ref.read(settingsProvider.notifier).setThemeMode(value);
                  Navigator.pop(ctx);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  String _getCountryLabel(String code) {
    switch (code) {
      case 'IN':
        return 'India';
      case 'US':
        return 'United States';
      case 'GB':
        return 'United Kingdom';
      default:
        return code;
    }
  }

  void _showCountryDialog(
    BuildContext context,
    WidgetRef ref,
    String currentCode,
  ) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Holiday Country'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('India'),
              value: 'IN',
              groupValue: currentCode,
              activeColor: theme.colorScheme.primary,
              onChanged: (value) {
                if (value != null) {
                  ref.read(settingsProvider.notifier).setHolidayCountry(value);
                  Navigator.pop(ctx);
                }
              },
            ),
            RadioListTile<String>(
              title: const Text('United States'),
              value: 'US',
              groupValue: currentCode,
              activeColor: theme.colorScheme.primary,
              onChanged: (value) {
                if (value != null) {
                  ref.read(settingsProvider.notifier).setHolidayCountry(value);
                  Navigator.pop(ctx);
                }
              },
            ),
            RadioListTile<String>(
              title: const Text('United Kingdom'),
              value: 'GB',
              groupValue: currentCode,
              activeColor: theme.colorScheme.primary,
              onChanged: (value) {
                if (value != null) {
                  ref.read(settingsProvider.notifier).setHolidayCountry(value);
                  Navigator.pop(ctx);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showStartDayDialog(
    BuildContext context,
    WidgetRef ref,
    int currentDay,
  ) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Start Week On'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<int>(
              title: const Text('Monday'),
              value: 1,
              groupValue: currentDay,
              activeColor: theme.colorScheme.primary,
              onChanged: (value) {
                if (value != null) {
                  ref.read(settingsProvider.notifier).setFirstDayOfWeek(value);
                  Navigator.pop(ctx);
                }
              },
            ),
            RadioListTile<int>(
              title: const Text('Tuesday'),
              value: 2,
              groupValue: currentDay,
              activeColor: theme.colorScheme.primary,
              onChanged: (value) {
                if (value != null) {
                  ref.read(settingsProvider.notifier).setFirstDayOfWeek(value);
                  Navigator.pop(ctx);
                }
              },
            ),
            RadioListTile<int>(
              title: const Text('Wednesday'),
              value: 3,
              groupValue: currentDay,
              activeColor: theme.colorScheme.primary,
              onChanged: (value) {
                if (value != null) {
                  ref.read(settingsProvider.notifier).setFirstDayOfWeek(value);
                  Navigator.pop(ctx);
                }
              },
            ),
            RadioListTile<int>(
              title: const Text('Thursday'),
              value: 4,
              groupValue: currentDay,
              activeColor: theme.colorScheme.primary,
              onChanged: (value) {
                if (value != null) {
                  ref.read(settingsProvider.notifier).setFirstDayOfWeek(value);
                  Navigator.pop(ctx);
                }
              },
            ),
            RadioListTile<int>(
              title: const Text('Friday'),
              value: 5,
              groupValue: currentDay,
              activeColor: theme.colorScheme.primary,
              onChanged: (value) {
                if (value != null) {
                  ref.read(settingsProvider.notifier).setFirstDayOfWeek(value);
                  Navigator.pop(ctx);
                }
              },
            ),
            RadioListTile<int>(
              title: const Text('Saturday'),
              value: 6,
              groupValue: currentDay,
              activeColor: theme.colorScheme.primary,
              onChanged: (value) {
                if (value != null) {
                  ref.read(settingsProvider.notifier).setFirstDayOfWeek(value);
                  Navigator.pop(ctx);
                }
              },
            ),
            RadioListTile<int>(
              title: const Text('Sunday'),
              value: 7,
              groupValue: currentDay,
              activeColor: theme.colorScheme.primary,
              onChanged: (value) {
                if (value != null) {
                  ref.read(settingsProvider.notifier).setFirstDayOfWeek(value);
                  Navigator.pop(ctx);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
