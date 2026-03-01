import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/events/presentation/events_view_model.dart';
import '../screens/settings_screen.dart';
import '../screens/recycle_bin_screen.dart';
import '../utils/snackbar_helpers.dart';

class MainDrawer extends ConsumerWidget {
  final int currentIndex;
  final Function(int) onDestinationSelected;

  const MainDrawer({
    super.key,
    required this.currentIndex,
    required this.onDestinationSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Drawer(
      width: MediaQuery.of(context).size.width * 0.85,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.only(
            topRight: Radius.circular(24),
            bottomRight: Radius.circular(24),
          ),
        ),
        child: Column(
          children: [
            // Top Bar with Settings
            Padding(
              padding: const EdgeInsets.only(top: 40, right: 16),
              child: Row(
                children: [
                  const Spacer(),
                  Stack(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.settings_outlined, size: 28),
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SettingsScreen(),
                            ),
                          );
                        },
                      ),
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const Divider(indent: 16, endIndent: 16),

            // View Options
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  _buildDrawerItem(
                    context: context,
                    icon: Icons.calendar_view_month_outlined,
                    label: 'Year',
                    index: 0,
                  ),
                  _buildDrawerItem(
                    context: context,
                    icon: Icons.calendar_month_outlined,
                    label: 'Month',
                    index: 1,
                  ),
                  _buildDrawerItem(
                    context: context,
                    icon: Icons.calendar_view_week_outlined,
                    label: 'Week',
                    index: 2,
                  ),
                  _buildDrawerItem(
                    context: context,
                    icon: Icons.calendar_view_day_outlined,
                    label: 'Day',
                    index: 3,
                  ),
                  _buildDrawerItem(
                    context: context,
                    icon: Icons.view_agenda_outlined,
                    label: 'Schedule',
                    index: 4,
                  ),

                  const Divider(indent: 8, endIndent: 8, height: 32),

                  // Device/Account Calendars
                  Consumer(
                    builder: (context, ref, child) {
                      return ref
                          .watch(deviceCalendarsProvider)
                          .when(
                            data: (calendars) {
                              if (calendars.isEmpty) {
                                return _buildAccountSection(
                                  context: context,
                                  title: 'My phone',
                                  icon: Icons.phone_android_outlined,
                                  children: [],
                                );
                              }

                              final Map<String, List<dynamic>> grouped = {};
                              for (var c in calendars) {
                                final key = c.accountName ?? 'Local';
                                if (grouped[key] == null) grouped[key] = [];
                                grouped[key]!.add(c);
                              }

                              return Column(
                                children: grouped.entries.map((entry) {
                                  final isGoogle =
                                      entry.key.toLowerCase().contains(
                                        'google',
                                      ) ||
                                      entry.key.toLowerCase().contains(
                                        '@gmail',
                                      );
                                  final isSamsung = entry.key
                                      .toLowerCase()
                                      .contains('samsung');

                                  return _buildAccountSection(
                                    context: context,
                                    title: isGoogle
                                        ? 'Google'
                                        : (isSamsung
                                              ? 'Samsung account'
                                              : entry.key),
                                    subtitle: isGoogle || isSamsung
                                        ? entry.key
                                        : null,
                                    icon: isGoogle
                                        ? Icons.account_circle
                                        : (isSamsung
                                              ? Icons.account_circle_outlined
                                              : Icons.phone_android_outlined),
                                    children: entry.value
                                        .map(
                                          (cal) => _buildCalendarItem(
                                            context: context,
                                            label: cal.name ?? 'Calendar',
                                            color: cal.color != null
                                                ? Color(cal.color!)
                                                : theme.colorScheme.primary,
                                          ),
                                        )
                                        .toList(),
                                  );
                                }).toList(),
                              );
                            },
                            loading: () => const Center(
                              child: Padding(
                                padding: EdgeInsets.all(8.0),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                            error: (e, __) => const SizedBox(),
                          );
                    },
                  ),

                  // Fixed sections like Birthdays/Holidays if needed
                  _buildCalendarItem(
                    context: context,
                    label: 'Birthdays',
                    color: Colors.blue,
                    icon: Icons.cake_outlined,
                    isCheckable: true,
                  ),
                  _buildCalendarItem(
                    context: context,
                    label: 'Holidays in India',
                    color: Colors.green,
                    icon: Icons.flag_outlined,
                    isCheckable: true,
                  ),

                  const Divider(indent: 8, endIndent: 8, height: 32),

                  // Management & Utilities
                  _buildDrawerItem(
                    context: context,
                    icon: Icons.delete_outline_outlined,
                    label: 'Trash',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const RecycleBinScreen(),
                        ),
                      );
                    },
                  ),
                  _buildDrawerItem(
                    context: context,
                    icon: Icons.sync,
                    label: 'Sync now',
                    onTap: () async {
                      SnackbarHelpers.showSuccess(context, 'Syncing...');
                      await ref
                          .read(eventsProvider.notifier)
                          .fetchDeviceEvents();
                    },
                  ),
                ],
              ),
            ),

            // Bottom Action Button
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark
                        ? Colors.grey[800]
                        : Colors.grey[200],
                    foregroundColor: theme.colorScheme.onSurface,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () {
                    // Navigate to calendar management
                  },
                  child: const Text(
                    'Manage calendars',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    int? index,
    VoidCallback? onTap,
  }) {
    final isSelected = index != null && currentIndex == index;
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        color: isSelected
            ? theme.colorScheme.primaryContainer.withValues(alpha: 0.5)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        onTap:
            onTap ??
            (index != null
                ? () {
                    Navigator.pop(context);
                    onDestinationSelected(index);
                  }
                : null),
        leading: Icon(
          icon,
          color: isSelected
              ? theme.colorScheme.primary
              : theme.colorScheme.onSurface.withValues(alpha: 0.7),
        ),
        title: Text(
          label,
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 15,
          ),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        dense: true,
      ),
    );
  }

  Widget _buildAccountSection({
    required BuildContext context,
    required String title,
    String? subtitle,
    required IconData icon,
    required List<Widget> children,
  }) {
    final theme = Theme.of(context);
    return ExpansionTile(
      leading: Icon(icon, color: theme.colorScheme.primary),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            )
          : null,
      shape: const Border(),
      childrenPadding: const EdgeInsets.only(left: 16),
      children: children,
    );
  }

  Widget _buildCalendarItem({
    required BuildContext context,
    required String label,
    required Color color,
    IconData? icon,
    bool isCheckable = false,
  }) {
    return ListTile(
      leading: icon != null
          ? Icon(icon, color: color, size: 20)
          : Container(
              margin: const EdgeInsets.only(left: 4),
              width: 12,
              height: 12,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
      title: Text(label, style: const TextStyle(fontSize: 14)),
      trailing: isCheckable ? const Icon(Icons.check, size: 18) : null,
      dense: true,
      onTap: () {},
    );
  }
}
