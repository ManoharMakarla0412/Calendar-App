import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/event.dart';
import '../features/events/presentation/events_view_model.dart';
import '../providers/settings_provider.dart';
import '../theme/app_theme.dart';
import 'event_detail_screen.dart';
import 'add_event_screen.dart';
import '../widgets/premium_empty_state.dart';

enum AgendaFilter {
  today('Today'),
  tomorrow('Tomorrow'),
  next7Days('Next 7 Days'),
  thisMonth('This Month'),
  all('All Upcoming');

  final String label;
  const AgendaFilter(this.label);
}

class AgendaView extends ConsumerStatefulWidget {
  const AgendaView({super.key});

  @override
  ConsumerState<AgendaView> createState() => _AgendaViewState();
}

class _AgendaViewState extends ConsumerState<AgendaView> {
  AgendaFilter _selectedFilter = AgendaFilter.next7Days;

  // Helper to determine if a badge should render manually inline
  bool _shouldShowBadge(Event event, DateTime now) {
    if (event.isAllDay) return false;
    final start = event.startTime;
    final end = event.endTime;

    if ((now.isAfter(start) || now.isAtSameMomentAs(start)) &&
        now.isBefore(end)) {
      return true;
    }
    if (start.isAfter(now) && start.difference(now).inMinutes <= 60) {
      return true;
    }

    return false;
  }

  // Status Badge Logic
  Widget _buildStatusBadge(Event event, DateTime now, double fs) {
    if (event.isAllDay) return const SizedBox.shrink();

    final start = event.startTime;
    final end = event.endTime;

    // 1) In Progress (inclusive of start)
    if ((now.isAfter(start) || now.isAtSameMomentAs(start)) &&
        now.isBefore(end)) {
      return _Badge(text: 'Now', color: Colors.green, fs: fs);
    }
    // 2) Starting Soon (within 60 mins)
    else if (start.isAfter(now) && start.difference(now).inMinutes <= 60) {
      return _Badge(text: 'Soon', color: Colors.orange, fs: fs);
    }

    return const SizedBox.shrink();
  }

  // Duration Helper
  String _getDurationString(Event event) {
    if (event.isAllDay) return 'All Day';
    final duration = event.endTime.difference(event.startTime);
    if (duration.inHours > 0) {
      if (duration.inMinutes % 60 == 0) return '${duration.inHours}h';
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    }
    return '${duration.inMinutes}m';
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF000000) : const Color(0xFFF5F7FA);
    final cardColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final settings = ref.watch(settingsProvider);
    final double fs = settings.fontSize;

    final eventsMapRaw = ref.watch(filteredEventsProvider);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tmrw = today.add(const Duration(days: 1));
    final next7DaysLimit = today.add(const Duration(days: 7));

    // Optimized Single-Pass Filter & Count Logic
    final eventsMap = <DateTime, List<Event>>{};
    final filterCounts = <AgendaFilter, int>{
      for (var f in AgendaFilter.values) f: 0
    };

    eventsMapRaw.forEach((date, events) {
      if (events.isEmpty) return;

      final isToday = _isSameDay(date, today);
      final isTomorrow = _isSameDay(date, tmrw);
      final isNext7 = !date.isBefore(today) && date.isBefore(next7DaysLimit);
      final isThisMonth = date.month == today.month && date.year == today.year;
      final isUpcoming = !date.isBefore(today);

      // Update counts
      if (isToday) filterCounts[AgendaFilter.today] = (filterCounts[AgendaFilter.today] ?? 0) + events.length;
      if (isTomorrow) filterCounts[AgendaFilter.tomorrow] = (filterCounts[AgendaFilter.tomorrow] ?? 0) + events.length;
      if (isNext7) filterCounts[AgendaFilter.next7Days] = (filterCounts[AgendaFilter.next7Days] ?? 0) + events.length;
      if (isThisMonth) filterCounts[AgendaFilter.thisMonth] = (filterCounts[AgendaFilter.thisMonth] ?? 0) + events.length;
      if (isUpcoming) filterCounts[AgendaFilter.all] = (filterCounts[AgendaFilter.all] ?? 0) + events.length;

      // Filter for display based on selected filter
      bool include = false;
      switch (_selectedFilter) {
        case AgendaFilter.today: include = isToday; break;
        case AgendaFilter.tomorrow: include = isTomorrow; break;
        case AgendaFilter.next7Days: include = isNext7; break;
        case AgendaFilter.thisMonth: include = isThisMonth; break;
        case AgendaFilter.all: include = isUpcoming; break;
      }

      if (include) {
        eventsMap[date] = List<Event>.from(events)
          ..sort((a, b) {
            if (a.isAllDay != b.isAllDay) return a.isAllDay ? -1 : 1;
            return a.startTime.compareTo(b.startTime);
          });
      }
    });

    final sortedDates = eventsMap.keys.toList()..sort();

    return Scaffold(
      backgroundColor: bgColor,
      floatingActionButton: SizedBox(
        width: 48,
        height: 48,
        child: FloatingActionButton(
          heroTag: null,
          elevation: 4,
          highlightElevation: 8,
          backgroundColor: theme.colorScheme.primary,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddEventScreen()),
            );
          },
          child: const Icon(Icons.add, color: Colors.white, size: 24),
        ),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 2) Filter Chips (Slimmer)
            SizedBox(
              height: 28, // Ultra compact chip row
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 0,
                ),
                scrollDirection: Axis.horizontal,
                itemCount: AgendaFilter.values.length,
                separatorBuilder: (context, index) => const SizedBox(width: 4),
                itemBuilder: (context, index) {
                  final filter = AgendaFilter.values[index];
                  final isSelected = _selectedFilter == filter;
                  final count = filterCounts[filter] ?? 0;

                  return ChoiceChip(
                    label: Text(
                      count > 0 ? '${filter.label} $count' : filter.label,
                      style: TextStyle(
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w400,
                        fontSize:
                            10 * fs, // Even smaller text to accommodate counts
                        color: isSelected
                            ? Colors.white
                            : (isDark ? Colors.white70 : Colors.black87),
                      ),
                    ),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) setState(() => _selectedFilter = filter);
                    },
                    backgroundColor: isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.black.withValues(alpha: 0.05),
                    selectedColor: theme.colorScheme.primary,
                    showCheckmark: false,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide.none,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 0,
                    ), // Tight padding
                  );
                },
              ),
            ),

            const SizedBox(height: 8),

            // 3) Event List / Empty State
            Expanded(
              child: sortedDates.isEmpty
                  ? _buildEmptyState(isDark, theme, fs)
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(
                        16,
                        4,
                        16,
                        90,
                      ), // Bottom padding for FAB
                      itemCount: sortedDates.length,
                      itemBuilder: (context, dateIndex) {
                        final date = sortedDates[dateIndex];
                        final eventsForDate = eventsMap[date]!;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildDateHeader(date, fs, theme, isDark, today),
                            const SizedBox(height: 8),
                            ...eventsForDate.map((event) {
                              return RepaintBoundary(
                                child: _buildPremiumEventCard(
                                  context,
                                  event,
                                  fs,
                                  isDark,
                                  cardColor,
                                  now,
                                ),
                              );
                            }),
                            const SizedBox(height: 16),
                          ],
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateHeader(
    DateTime date,
    double fs,
    ThemeData theme,
    bool isDark,
    DateTime today,
  ) {
    final isToday = _isSameDay(date, today);
    final isTomorrow = _isSameDay(date, today.add(const Duration(days: 1)));

    String dateStr = DateFormat('MMM d, yyyy').format(date);
    String headerText = '';

    if (isToday) {
      headerText = 'Today – $dateStr';
    } else if (isTomorrow) {
      headerText = 'Tomorrow – $dateStr';
    } else {
      headerText = '${DateFormat('EEEE').format(date)} – $dateStr';
    }

    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        headerText,
        style: TextStyle(
          fontSize: 14 * fs,
          fontWeight: FontWeight.bold,
          color: isToday
              ? theme.colorScheme.primary
              : (isDark ? Colors.white70 : Colors.grey[800]),
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  Widget _buildPremiumEventCard(
    BuildContext context,
    Event event,
    double fs,
    bool isDark,
    Color cardColor,
    DateTime now,
  ) {
    final displayColor = event.customColor ?? event.color.color;

    // Fade out past/missed events slightly for visual priority
    final isPast = now.isAfter(event.endTime) && !event.isAllDay;

    // Distinct background for all-day events
    final Color effectiveCardColor = event.isAllDay
        ? displayColor.withValues(alpha: isDark ? 0.25 : 0.15)
        : cardColor;


    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Semantics(
        label:
            "Event: \${event.title}. \${event.isAllDay ? 'All Day' : DateFormat('h:mm a').format(event.startTime)}. \${event.location ?? ''}",
        button: true,
        child: InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => EventDetailScreen(event: event)),
          ),
          borderRadius: BorderRadius.circular(12),
          child: Opacity(
            opacity: isPast ? 0.6 : 1.0,
            child: Container(
              decoration: BoxDecoration(
                color: effectiveCardColor,
                borderRadius: BorderRadius.circular(12),
                border: event.isAllDay
                    ? Border.all(
                        color: displayColor.withValues(alpha: 0.3),
                        width: 1.5,
                      )
                    : null,
                boxShadow: isDark ? null : AppTheme.softShadows,
              ),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Left Colored Vertical Strip
                    Container(
                      width: 5,
                      decoration: BoxDecoration(
                        color: displayColor,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(12),
                          bottomLeft: Radius.circular(12),
                        ),
                      ),
                    ),

                    // Content
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header Row: Time/All-Day Info
                            Row(
                              children: [
                                if (event.isAllDay)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: displayColor,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'ALL DAY',
                                      style: TextStyle(
                                        fontSize: 9 * fs,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.white,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                  )
                                else
                                  Text(
                                    DateFormat(
                                      'h:mm a',
                                    ).format(event.startTime),
                                    style: TextStyle(
                                      fontSize: 13 * fs,
                                      fontWeight: FontWeight.w700,
                                      color: isDark
                                          ? Colors.white70
                                          : Colors.black87,
                                    ),
                                  ),

                                if (!event.isAllDay) ...[
                                  const SizedBox(width: 8),
                                  Text(
                                    _getDurationString(event),
                                    style: TextStyle(
                                      fontSize: 11 * fs,
                                      color: isDark
                                          ? Colors.white38
                                          : Colors.grey[500],
                                    ),
                                  ),
                                ],

                                const Spacer(),

                                if (event.recurrence.type !=
                                    RecurrenceType.none)
                                  Icon(
                                    Icons.repeat,
                                    size: 12,
                                    color: isDark
                                        ? Colors.white38
                                        : Colors.grey[400],
                                  ),

                                if (_shouldShowBadge(event, now)) ...[
                                  const SizedBox(width: 8),
                                  _buildStatusBadge(event, now, fs),
                                ],
                              ],
                            ),

                            const SizedBox(height: 6),

                            // Event Title
                            Text(
                              event.title,
                              style: TextStyle(
                                fontSize: 16 * fs,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.3,
                                color: isDark ? Colors.white : Colors.black,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),

                            // Location
                            if (event.location != null &&
                                event.location!.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Icon(
                                    Icons.location_on_rounded,
                                    size: 14 * fs,
                                    color: isDark
                                        ? Colors.white54
                                        : Colors.grey[600],
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      event.location!,
                                      style: TextStyle(
                                        fontSize: 12 * fs,
                                        color: isDark
                                            ? Colors.white54
                                            : Colors.grey[600],
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 7) Empty State
  // 7) Empty State
  Widget _buildEmptyState(bool isDark, ThemeData theme, double fs) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const PremiumEmptyState(
            icon: Icons.event_available_rounded,
            title: 'No upcoming events',
            message: 'Your schedule is clear. Add a new event to get started.',
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddEventScreen()),
              );
            },
            icon: const Icon(Icons.add, color: Colors.white),
            label: Text(
              'Create Event',
              style: TextStyle(
                fontSize: 16 * fs,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final Color color;
  final double fs;

  const _Badge({required this.text, required this.color, required this.fs});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.2 : 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: isDark ? 0.3 : 0.2)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 9 * fs, // Extremely compact
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}
