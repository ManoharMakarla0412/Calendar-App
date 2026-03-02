import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/event.dart';
import '../features/events/presentation/events_view_model.dart';
import '../providers/date_provider.dart';
import '../providers/settings_provider.dart';
import 'event_detail_screen.dart';

class MonthView extends ConsumerStatefulWidget {
  const MonthView({super.key});

  @override
  ConsumerState<MonthView> createState() => _MonthViewState();
}

class _MonthViewState extends ConsumerState<MonthView> {
  late DateTime _focusedDay;
  // Track the last month we synced to avoid redundant jumps
  DateTime _lastSyncedMonthYear = DateTime.now();

  @override
  void initState() {
    super.initState();
    _focusedDay = ref.read(selectedDateProvider);
    _lastSyncedMonthYear = DateTime(_focusedDay.year, _focusedDay.month);
  }

  List<Event> _getEventsForDay(
    DateTime day,
    Map<DateTime, List<Event>> events,
  ) {
    final key = DateTime(day.year, day.month, day.day);
    return events[key] ?? [];
  }

  void _showDayEventsBottomSheet(
    BuildContext context,
    DateTime day,
    List<Event> dayEvents,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final fs = ref.read(settingsProvider).fontSize;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.5,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    DateFormat('EEEE, MMM d').format(day).toUpperCase(),
                    style: TextStyle(
                      fontSize: 13 * fs,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                      color: theme.textTheme.bodySmall?.color?.withValues(
                        alpha: 0.6,
                      ),
                    ),
                  ),
                  Text(
                    '${dayEvents.length} EVENTS',
                    style: TextStyle(
                      fontSize: 11 * fs,
                      fontWeight: FontWeight.bold,
                      color: theme.primaryColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Divider(),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                itemCount: dayEvents.length,
                itemBuilder: (context, index) {
                  final event = dayEvents[index];
                  final color = event.customColor ?? event.color.color;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: InkWell(
                      onTap: () {
                        Navigator.pop(context); // Close sheet
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                EventDetailScreen(event: event),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: isDark ? 0.15 : 0.08),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: color.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 4,
                              height: 32,
                              decoration: BoxDecoration(
                                color: color,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    event.title,
                                    style: TextStyle(
                                      fontSize: 16 * fs,
                                      fontWeight: FontWeight.bold,
                                      color: theme.textTheme.titleLarge?.color,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    event.isAllDay
                                        ? 'All Day'
                                        : '${DateFormat('h:mm a').format(event.startTime)} - ${DateFormat('h:mm a').format(event.endTime)}',
                                    style: TextStyle(
                                      fontSize: 13 * fs,
                                      color: theme.textTheme.bodyMedium?.color
                                          ?.withValues(alpha: 0.7),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.chevron_right_rounded,
                              color: color.withValues(alpha: 0.5),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final events = ref.watch(filteredEventsProvider);
    final settings = ref.watch(settingsProvider);
    final double fs = settings.fontSize;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    // Watch the selected date and normalize it to midnight to ensure
    // consistent behavior across all views and date types.
    final rawSelectedDate = ref.watch(selectedDateProvider);
    final selectedDate = DateTime(
      rawSelectedDate.year,
      rawSelectedDate.month,
      rawSelectedDate.day,
    );

    // Sync focused day with selected date provider
    ref.listen(selectedDateProvider, (previous, next) {
      // Specifically avoid 'jumping' by only updating focused day if month/year changed
      // AND we are not already at that month (prevents feedback loops during swipes).
      if ((next.year != _focusedDay.year || next.month != _focusedDay.month) &&
          (next.year != _lastSyncedMonthYear.year ||
              next.month != _lastSyncedMonthYear.month)) {
        setState(() {
          _focusedDay = DateTime(next.year, next.month, next.day);
        });
      }
    });

    return Column(
      children: [
        Expanded(
          child: Container(
            color: theme.scaffoldBackgroundColor,
            child: RepaintBoundary(
              child: TableCalendar<Event>(
                firstDay: DateTime(2000, 1, 1),
                lastDay: DateTime(2050, 12, 31),
                focusedDay: _focusedDay,
                calendarFormat: CalendarFormat.month,
                shouldFillViewport: true,
                sixWeekMonthsEnforced:
                    true, // Keep stable height to avoid layout shift

                selectedDayPredicate: (day) => isSameDay(selectedDate, day),
                eventLoader: (day) => _getEventsForDay(day, events),
                startingDayOfWeek: () {
                  switch (settings.firstDayOfWeek) {
                    case 1: return StartingDayOfWeek.monday;
                    case 2: return StartingDayOfWeek.tuesday;
                    case 3: return StartingDayOfWeek.wednesday;
                    case 4: return StartingDayOfWeek.thursday;
                    case 5: return StartingDayOfWeek.friday;
                    case 6: return StartingDayOfWeek.saturday;
                    case 7: return StartingDayOfWeek.sunday;
                    default: return StartingDayOfWeek.monday;
                  }
                }(),

                headerVisible: false,
                daysOfWeekStyle: DaysOfWeekStyle(
                  weekdayStyle: TextStyle(
                    fontSize: 12 * fs,
                    fontWeight: FontWeight.w100,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                  weekendStyle: TextStyle(
                    fontSize: 12 * fs,
                    fontWeight: FontWeight.w100,
                    color: Colors.red.withValues(alpha: 0.8),
                  ),
                ),
                daysOfWeekHeight: 30 * fs,

                calendarStyle: CalendarStyle(
                  outsideDaysVisible: true,
                  outsideTextStyle: TextStyle(
                    color: Colors.grey.withValues(alpha: 0.5),
                  ),
                  cellMargin: EdgeInsets.zero,
                  // Disable all default markers and decorations to prevent 'ghost' highlights
                  selectedDecoration: const BoxDecoration(),
                  todayDecoration: const BoxDecoration(),
                  markerDecoration: const BoxDecoration(),
                  tableBorder: const TableBorder(),
                ),

                onDaySelected: (selectedDay, focusedDay) {
                  ref.read(selectedDateProvider.notifier).setDate(selectedDay);

                  final dayEvents = _getEventsForDay(selectedDay, events);
                  if (dayEvents.isNotEmpty) {
                    _showDayEventsBottomSheet(context, selectedDay, dayEvents);
                  }

                  // Only update focusedDay if month/year changed to keep TableCalendar stable
                  if (focusedDay.year != _focusedDay.year ||
                      focusedDay.month != _focusedDay.month) {
                    setState(() {
                      _focusedDay = focusedDay;
                    });
                  }
                },
                onPageChanged: (focusedDay) {
                  // Ensure time components are stripped to match provider format
                  final newFocusedDay = DateTime(
                    focusedDay.year,
                    focusedDay.month,
                    focusedDay.day,
                  );

                  // Set this first so the local state matches the upcoming provider update
                  _lastSyncedMonthYear = DateTime(
                    focusedDay.year,
                    focusedDay.month,
                  );

                  setState(() {
                    _focusedDay = newFocusedDay;
                  });

                  // Use a slight delay to allow TableCalendar to finish its animation
                  // before triggering a global state change that might cause a rebuild.
                  Future.delayed(const Duration(milliseconds: 50), () {
                    if (mounted) {
                      ref
                          .read(selectedDateProvider.notifier)
                          .setDate(newFocusedDay);
                    }
                  });
                },

                calendarBuilders: CalendarBuilders(
                  dowBuilder: (context, day) {
                    final text = DateFormat('E').format(day).substring(0, 1);
                    final isSunday = day.weekday == DateTime.sunday;

                    return Center(
                      child: MediaQuery.withNoTextScaling(
                        child: Text(
                          text,
                          style: TextStyle(
                            color: isSunday
                                ? Colors.red
                                : (theme.brightness == Brightness.dark
                                      ? Colors.white70
                                      : Colors.black87),
                            fontWeight: FontWeight.bold,
                            fontSize: 12 * fs,
                          ),
                        ),
                      ),
                    );
                  },
                  defaultBuilder: (context, day, focusedDay) {
                    return _buildCell(
                      context,
                      day,
                      events,
                      isSelected: false,
                      isToday: false,
                      fs: fs,
                      isExpanded: true,
                    );
                  },

                  selectedBuilder: (context, day, focusedDay) {
                    return _buildCell(
                      context,
                      day,
                      events,
                      isSelected: true,
                      isToday: isSameDay(day, DateTime.now()),
                      fs: fs,
                      isExpanded: true,
                    );
                  },
                  todayBuilder: (context, day, focusedDay) {
                    return _buildCell(
                      context,
                      day,
                      events,
                      isSelected: false,
                      isToday: true,
                      fs: fs,
                      isExpanded: true,
                    );
                  },
                  outsideBuilder: (context, day, focusedDay) {
                    return _buildCell(
                      context,
                      day,
                      events,
                      isSelected: false,
                      isToday: false,
                      fs: fs,
                      isOutside: true,
                      isExpanded: true,
                    );
                  },
                  disabledBuilder: (context, day, focusedDay) {
                    return _buildCell(
                      context,
                      day,
                      events,
                      isSelected: false,
                      isToday: false,
                      fs: fs,
                      isOutside: true,
                      isExpanded: true,
                    );
                  },
                  holidayBuilder: (context, day, focusedDay) {
                    return _buildCell(
                      context,
                      day,
                      events,
                      isSelected: false,
                      isToday: false,
                      fs: fs,
                      isExpanded: true,
                    );
                  },
                  markerBuilder: (context, day, events) =>
                      const SizedBox.shrink(),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCell(
    BuildContext context,
    DateTime day,
    Map<DateTime, List<Event>> allEvents, {
    required bool isSelected,
    required bool isToday,
    required double fs,
    bool isOutside = false,
    bool isExpanded = false,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final dayEvents = _getEventsForDay(day, allEvents);
    final isSunday = day.weekday == DateTime.sunday;
    final eventDescription = dayEvents.isEmpty
        ? 'No events'
        : '\${dayEvents.length} event\${dayEvents.length > 1 ? "s" : ""}';

    return Semantics(
      label: "Date: \${DateFormat('MMMM d').format(day)}. $eventDescription.",
      button: true,
      child: ClipRect(
        key: ValueKey(
          'cell_\${day.year}_\${day.month}_\${day.day}',
        ), // Unique key to prevent selection leakage
        child: Container(
          decoration: BoxDecoration(
            color: isSelected && !isExpanded
                ? (isDark
                      ? Colors.white.withValues(alpha: 0.12)
                      : theme.primaryColor.withValues(alpha: 0.04))
                : null,
            // Removed the permanent faint border that could be mistaken for a highlighter bug
            border: Border.all(color: Colors.transparent, width: 0),
          ),
          child: Column(
            children: [
              const SizedBox(height: 2),
              // Day Number Pill
              Container(
                height: 24 * fs,
                width: 24 * fs,
                alignment: Alignment.center,
                decoration: (isSelected || isToday)
                    ? BoxDecoration(
                        color: isSelected
                            ? theme.primaryColor
                            : Colors.transparent,
                        shape: BoxShape.circle,
                        border: isToday && !isSelected
                            ? Border.all(
                                color: isDark ? Colors.white : Colors.black,
                                width: 1.5,
                              )
                            : null,
                      )
                    : null,
                child: MediaQuery.withNoTextScaling(
                  child: Text(
                    '${day.day}',
                    style: TextStyle(
                      fontSize:
                          13 * fs, // Standardized and responsive font size
                      fontWeight: (isSelected || isToday)
                          ? FontWeight.bold
                          : FontWeight.w500,
                      color: isSelected
                          ? Colors.white
                          : isToday
                          ? (isDark ? Colors.white : Colors.black)
                          : isOutside
                          ? Colors.grey.withValues(alpha: 0.3)
                          : isSunday
                          ? Colors.red
                          : (isDark ? Colors.white : Colors.black),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              // Event indicators
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Builder(
                    builder: (context) {
                      // Sort events: All-day and Holidays first
                      final sortedEvents = List<Event>.from(dayEvents)
                        ..sort((a, b) {
                          final aIsHoliday =
                              a.id.startsWith('in_') ||
                              a.id.startsWith('rel_') ||
                              a.id.startsWith('us_') ||
                              a.id.startsWith('gb_') ||
                              (a.notes?.toLowerCase().contains('holiday') ??
                                  false);
                          final bIsHoliday =
                              b.id.startsWith('in_') ||
                              b.id.startsWith('rel_') ||
                              b.id.startsWith('us_') ||
                              b.id.startsWith('gb_') ||
                              (b.notes?.toLowerCase().contains('holiday') ??
                                  false);
                          if (aIsHoliday != bIsHoliday) {
                            return aIsHoliday ? -1 : 1;
                          }
                          if (a.isAllDay != b.isAllDay) {
                            return a.isAllDay ? -1 : 1;
                          }
                          return a.startTime.compareTo(b.startTime);
                        });

                      final isSingleEvent = sortedEvents.length == 1;

                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                            ...sortedEvents.map((event) {
                              final color =
                                  event.customColor ?? event.color.color;
                              final isMeeting =
                                  event.title.toLowerCase().contains(
                                    'stand up',
                                  ) ||
                                  event.title.toLowerCase().contains('meet') ||
                                  event.title.toLowerCase().contains('call') ||
                                  event.title.toLowerCase().contains('session');
                              final bool isHoliday =
                                  event.id.startsWith('in_') ||
                                  event.id.startsWith('rel_') ||
                                  event.id.startsWith('us_') ||
                                  event.id.startsWith('gb_') ||
                                  (event.notes?.toLowerCase().contains(
                                        'holiday',
                                      ) ??
                                      false);

                              if (isExpanded) {
                                Color displayColor = color;
                                if (isOutside) {
                                  displayColor = color.withValues(alpha: 0.5);
                                }

                                // Premium Soft Pill Style
                                return Semantics(
                                  label:
                                      "Event: \${event.title}. \${event.isAllDay ? 'All day' : DateFormat('h:mm a').format(event.startTime)}",
                                  button: true,
                                  child: GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              EventDetailScreen(event: event),
                                        ),
                                      );
                                    },
                                    child: Container(
                                      width: double.infinity,
                                      margin: const EdgeInsets.symmetric(
                                        vertical: 1.5,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 5,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        // Light tint background
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(6),
                                        // Subtle border for definition
                                        border: Border.all(
                                          color: displayColor.withValues(
                                            alpha: 0.2,
                                          ),
                                          width: 0.5,
                                        ),
                                      ),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          // Vertical accent strip inside the pill
                                          Container(
                                            width: 2.5,
                                            height: 12 * fs,
                                            margin: const EdgeInsets.only(
                                              top: 1,
                                              right: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: displayColor,
                                              borderRadius:
                                                  BorderRadius.circular(1),
                                            ),
                                          ),
                                          if (isMeeting)
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                top: 1,
                                                right: 2,
                                              ),
                                              child: Icon(
                                                Icons.videocam_rounded,
                                                size: 11 * fs,
                                                color: Colors.black,
                                              ),
                                            ),
                                          Expanded(
                                            child: MediaQuery.withNoTextScaling(
                                              child: Tooltip(
                                                message: event.title,
                                                child: Text(
                                                  event.title,
                                                  style: TextStyle(
                                                    fontSize:
                                                        9.5 *
                                                        fs, // Standardized premium font size
                                                    color: Colors.black,
                                                    fontWeight:
                                                        (isHoliday ||
                                                            event.isAllDay)
                                                        ? FontWeight.w900
                                                        : FontWeight.w800,
                                                    height: 1.1,
                                                    letterSpacing: -0.2,
                                                  ),
                                                  softWrap: true,
                                                   maxLines: isSingleEvent ? 4 : 2,
                                                   overflow: TextOverflow.clip,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              } else {
                                // Collapsed view (just dots or thin lines)
                                return Container(
                                  height: 3 * fs,
                                  margin: const EdgeInsets.symmetric(
                                    vertical: 1.0,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isOutside
                                        ? color.withValues(alpha: 0.3)
                                        : color,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                );
                              }
                            }).toList(),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
