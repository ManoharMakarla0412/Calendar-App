import 'dart:io';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/event.dart';
import '../features/events/presentation/events_view_model.dart';
import '../providers/recycle_bin_provider.dart';
import '../theme/app_theme.dart';
import 'add_event_screen.dart';

class EventDetailScreen extends ConsumerWidget {
  final Event event;

  const EventDetailScreen({super.key, required this.event});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final mainTextColor = isDark ? Colors.white : Colors.black;
    final hintColor = isDark ? Colors.white60 : Colors.grey;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: mainTextColor),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.copy, color: mainTextColor, size: 20),
            onPressed: () {
              final newEvent = event.copyWith(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                recurrenceGroupId: null,
              );
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => Padding(
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top + 40,
                  ),
                  child: AddEventScreen(event: newEvent),
                ),
              );
            },
          ),
          TextButton(
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => Padding(
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top + 40,
                  ),
                  child: AddEventScreen(event: event),
                ),
              );
            },
            child: Text(
              'Edit',
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Basic Information
                  _buildSectionHeader('BASIC INFORMATION'),
                  _buildGroupedCard(
                    cardColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                    isDark: isDark,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              event.title,
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: mainTextColor,
                                letterSpacing: -0.5,
                              ),
                            ),
                            if (event.notes != null &&
                                event.notes!.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Text(
                                event.notes!,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: hintColor,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // 2. Date & Time
                  _buildSectionHeader('DATE & TIME'),
                  _buildGroupedCard(
                    cardColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                    isDark: isDark,
                    children: [
                      _buildDetailRow(
                        icon: Icons.access_time_rounded,
                        title: event.isAllDay ? 'All Day' : 'Time',
                        value: event.isAllDay
                            ? DateFormat('EEEE, MMM d').format(event.startTime)
                            : '${DateFormat('EEEE, MMM d').format(event.startTime)}\n${DateFormat('h:mm a').format(event.startTime)} - ${DateFormat('h:mm a').format(event.endTime)}',
                        isDark: isDark,
                        mainTextColor: mainTextColor,
                      ),
                      if (event.recurrence.isRecurring) ...[
                        _buildDivider(isDark),
                        _buildDetailRow(
                          icon: Icons.repeat_rounded,
                          title: 'Repeat',
                          value: event.recurrence.displayLabel,
                          isDark: isDark,
                          mainTextColor: mainTextColor,
                        ),
                      ],
                      if (event.reminders.isNotEmpty) ...[
                        _buildDivider(isDark),
                        _buildDetailRow(
                          icon: Icons.notifications_active_outlined,
                          title: 'Alert',
                          value: event.reminders
                              .map((r) => _formatReminder(r))
                              .join(', '),
                          isDark: isDark,
                          mainTextColor: mainTextColor,
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(height: 24),

                  // 3. Location & Online
                  if ((event.location != null && event.location!.isNotEmpty) ||
                      (event.url != null && event.url!.isNotEmpty)) ...[
                    _buildSectionHeader('LOCATION & ONLINE'),
                    _buildGroupedCard(
                      cardColor: isDark
                          ? const Color(0xFF1C1C1E)
                          : Colors.white,
                      isDark: isDark,
                      children: [
                        if (event.location != null &&
                            event.location!.isNotEmpty)
                          _buildDetailRow(
                            icon: Icons.location_on_outlined,
                            title: 'Location',
                            value: event.location!,
                            isDark: isDark,
                            mainTextColor: mainTextColor,
                            trailing: TextButton(
                              onPressed: () => _launchMaps(event.location!),
                              child: const Text(
                                'Maps',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        if (event.location != null &&
                            event.location!.isNotEmpty &&
                            event.url != null &&
                            event.url!.isNotEmpty)
                          _buildDivider(isDark),
                        if (event.url != null && event.url!.isNotEmpty)
                          _buildDetailRow(
                            icon: Icons.link_rounded,
                            title: 'Link',
                            value: event.url!,
                            isDark: isDark,
                            mainTextColor: mainTextColor,
                            trailing: TextButton(
                              onPressed: () => _launchUrl(event.url!),
                              child: const Text(
                                'Open',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],

                  // 4. Advanced Settings
                  _buildSectionHeader('ADVANCED SETTINGS'),
                  _buildGroupedCard(
                    cardColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                    isDark: isDark,
                    children: [
                      _buildDetailRow(
                        icon: Icons.circle,
                        title: 'Category',
                        value: event.color.label,
                        isDark: isDark,
                        mainTextColor: mainTextColor,
                        leadingColor: event.customColor ?? event.color.color,
                      ),
                    ],
                  ),

                  // 5. Attachment
                  if (event.photoPath != null) ...[
                    const SizedBox(height: 24),
                    _buildSectionHeader('ATTACHMENT'),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.file(
                        File(event.photoPath!),
                        width: double.infinity,
                        height: 220,
                        fit: BoxFit.cover,
                        errorBuilder: (ctx, err, stack) => Container(
                          height: 100,
                          color: Colors.grey.withValues(alpha: 0.1),
                          alignment: Alignment.center,
                          child: const Text(
                            'Image not found',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 40),

                  Center(
                    child: Text(
                      event.updatedAt != null
                          ? 'Updated ${DateFormat('MMM d, h:mm a').format(event.updatedAt!)}'
                          : 'Created ${DateFormat('MMM d, h:mm a').format(event.startTime)}',
                      style: TextStyle(
                        color: hintColor.withValues(alpha: 0.5),
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // Delete Button at bottom
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: TextButton(
                onPressed: () => _showDeleteDialog(context, ref),
                style: TextButton.styleFrom(
                  foregroundColor: theme.colorScheme.error,
                  backgroundColor: theme.colorScheme.error.withValues(
                    alpha: 0.1,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Delete Event',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- REUSABLE BUILDERS ---

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.grey[500],
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildGroupedCard({
    required Color cardColor,
    required bool isDark,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: isDark ? null : AppTheme.softShadows,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 16),
      child: Divider(
        height: 1,
        thickness: 0.5,
        color: isDark
            ? Colors.white.withValues(alpha: 0.1)
            : Colors.black.withValues(alpha: 0.05),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String title,
    required String value,
    required bool isDark,
    required Color mainTextColor,
    Color? leadingColor,
    Widget? trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: leadingColor ?? (isDark ? Colors.white54 : Colors.black54),
            size: 22,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white54 : Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(fontSize: 16, color: mainTextColor),
                ),
              ],
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  String _formatReminder(Duration duration) {
    if (duration.inMinutes == 0) return 'At time of event';
    if (duration.inMinutes < 60) return '${duration.inMinutes} mins before';
    if (duration.inHours < 24)
      return '${duration.inHours} hour${duration.inHours > 1 ? 's' : ''} before';
    return '${duration.inDays} day${duration.inDays > 1 ? 's' : ''} before';
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _launchMaps(String location) async {
    final query = Uri.encodeComponent(location);
    final googleMapsUrl =
        'https://www.google.com/maps/search/?api=1&query=$query';
    final appleMapsUrl = 'https://maps.apple.com/?q=$query';

    if (Platform.isIOS) {
      if (await canLaunchUrl(Uri.parse(appleMapsUrl))) {
        await launchUrl(Uri.parse(appleMapsUrl));
      } else {
        await launchUrl(Uri.parse(googleMapsUrl));
      }
    } else {
      if (await canLaunchUrl(Uri.parse(googleMapsUrl))) {
        await launchUrl(
          Uri.parse(googleMapsUrl),
          mode: LaunchMode.externalApplication,
        );
      }
    }
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Event?'),
        content: Text(
          event.recurrence.isRecurring
              ? 'This is a recurring event. Do you want to delete all instances?'
              : 'Are you sure you want to delete this event?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // 1. Close Dialog
              Navigator.pop(ctx);

              // 2. Perform Deletion (Move to Bin & Remove from List)
              final bool deleteAll = event.recurrence.isRecurring;
              ref.read(recycleBinProvider.notifier).moveToBin(event);
              ref
                  .read(eventsProvider.notifier)
                  .deleteEvent(event, deleteAllInGroup: deleteAll);

              // 3. Close Detail Screen
              Navigator.pop(context);

              // 4. Show Undo Snackbar
              ScaffoldMessenger.of(context).clearSnackBars();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Event deleted'),
                  duration: const Duration(seconds: 10),
                  action: SnackBarAction(
                    label: 'UNDO',
                    textColor: Colors.yellow,
                    onPressed: () {
                      // Undo Action: Restore from Bin & Add back to List
                      ref
                          .read(recycleBinProvider.notifier)
                          .restoreFromBin(event);
                      ref.read(eventsProvider.notifier).addEvent(event);
                    },
                  ),
                ),
              );
            },
            child: Text(
              event.recurrence.isRecurring ? 'Delete All' : 'Delete',
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
