import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/event.dart';
import '../features/events/presentation/events_view_model.dart';
import '../providers/settings_provider.dart';
import '../providers/date_provider.dart';
import '../widgets/multi_day_timetable.dart';
import 'event_detail_screen.dart';
import 'add_event_screen.dart';

class WeekView extends ConsumerStatefulWidget {
  const WeekView({super.key});

  @override
  ConsumerState<WeekView> createState() => _WeekViewState();
}

class _WeekViewState extends ConsumerState<WeekView> {
  late PageController _pageController;
  final DateTime _baseDate = DateTime(2024, 1, 1); // Fixed Monday reference
  final int _basePage = 5000;
  int _lastFirstDayOfWeek = -1; // sentinel — will be set on first build

  @override
  void initState() {
    super.initState();
    final initialFirstDay = ref.read(settingsProvider).firstDayOfWeek;
    _lastFirstDayOfWeek = initialFirstDay;
    _pageController = PageController(
      initialPage: _calculatePage(
        ref.read(selectedDateProvider),
        initialFirstDay,
      ),
    );
  }

  int _calculatePage(DateTime date, int firstDayOfWeek) {
    final startOfDateWeek = _getStartOfWeek(date, firstDayOfWeek);
    final startOfBaseWeek = _getStartOfWeek(_baseDate, firstDayOfWeek);
    final diffDays = startOfDateWeek.difference(startOfBaseWeek).inDays;
    return _basePage + (diffDays / 7).round();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  DateTime _getStartOfWeek(DateTime date, int startDay) {
    final daysToSubtract = (date.weekday - startDay + 7) % 7;
    return DateTime(
      date.year,
      date.month,
      date.day,
    ).subtract(Duration(days: daysToSubtract));
  }

  List<Event> _getEventsForWeek(
    DateTime startOfWeek,
    Map<DateTime, List<Event>> eventsMap,
  ) {
    List<Event> weekEvents = [];
    for (int i = 0; i < 7; i++) {
      final date = startOfWeek.add(Duration(days: i));
      // Use exact date key matching the provider's map structure
      final key = DateTime(date.year, date.month, date.day);
      if (eventsMap.containsKey(key)) {
        weekEvents.addAll(eventsMap[key]!);
      }
    }
    return weekEvents;
  }

  void _onPageChanged(int index) {
    final int firstDayOfWeek = ref.read(settingsProvider).firstDayOfWeek;
    final weeksFromBase = index - _basePage;
    final startOfNewWeek = _getStartOfWeek(
      _baseDate,
      firstDayOfWeek,
    ).add(Duration(days: weeksFromBase * 7));

    final currentSelected = ref.read(selectedDateProvider);
    final dayOfWeekOffset = currentSelected
        .difference(_getStartOfWeek(currentSelected, firstDayOfWeek))
        .inDays;

    final newSelectedDate = startOfNewWeek.add(Duration(days: dayOfWeekOffset));
    ref.read(selectedDateProvider.notifier).setDate(newSelectedDate);
  }

  void _syncPageController(DateTime selectedDate, int firstDayOfWeek) {
    if (_pageController.hasClients) {
      final targetPage = _calculatePage(selectedDate, firstDayOfWeek);
      final currentPos =
          (_pageController.page ?? _pageController.initialPage.toDouble());

      if ((currentPos - targetPage).abs() > 3) {
        _pageController.jumpToPage(targetPage);
      } else if (currentPos.round() != targetPage) {
        _pageController.animateToPage(
          targetPage,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final eventsMap = ref.watch(filteredEventsProvider);
    final rawSelectedDate = ref.watch(selectedDateProvider);
    final selectedDate = DateTime(
      rawSelectedDate.year,
      rawSelectedDate.month,
      rawSelectedDate.day,
    );
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final firstDayOfWeek = settings.firstDayOfWeek;

    // Recreate PageController when firstDayOfWeek changes
    if (_lastFirstDayOfWeek != firstDayOfWeek) {
      _lastFirstDayOfWeek = firstDayOfWeek;
      final newPage = _calculatePage(selectedDate, firstDayOfWeek);
      // Dispose old and create new controller with correct initial page
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final old = _pageController;
        setState(() {
          _pageController = PageController(initialPage: newPage);
        });
        old.dispose();
      });
    }

    // Listen to changes in selectedDate and sync the page controller
    ref.listen(selectedDateProvider, (previous, next) {
      if (previous == null || !isSameDay(previous, next)) {
        _syncPageController(next, firstDayOfWeek);
      }
    });

    final weekStart = _getStartOfWeek(selectedDate, firstDayOfWeek);

    return Column(
      children: [
        // Custom Centered Month Header
        Center(
          child: InkWell(
            onTap: _showMonthYearPicker,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    weekStart.year == DateTime.now().year
                        ? DateFormat('MMM').format(weekStart).toUpperCase()
                        : DateFormat(
                            'MMM yyyy',
                          ).format(weekStart).toUpperCase(),
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.5,
                      color: theme.textTheme.titleLarge?.color,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Custom Date Row
        _buildDateRow(weekStart, theme, isDark, settings.fontSize),

        Expanded(
          child: Stack(
            children: [
              Column(
                children: [
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      onPageChanged: _onPageChanged,
                      itemBuilder: (context, index) {
                        final weeksFromBase = index - _basePage;
                        final weekStartDate = _getStartOfWeek(
                          _baseDate,
                          firstDayOfWeek,
                        ).add(Duration(days: weeksFromBase * 7));
                        final events = _getEventsForWeek(
                          weekStartDate,
                          eventsMap,
                        );

                        return RepaintBoundary(
                          child: MultiDayTimetable(
                            initialDate: weekStartDate,
                            numberOfDays: 7,
                            events: events,
                            hourHeight: 65,
                            showHeader: false,
                          ),
                        );
                      },
                    ),
                  ),

                  // Better way to show selected day events
                  _buildSelectedDayAgenda(
                    context,
                    selectedDate,
                    eventsMap,
                    isDark,
                  ),

                  // Padding for the bottom pill
                  const SizedBox(height: 80),
                ],
              ),

              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (context) => Padding(
                              padding: EdgeInsets.only(
                                top: MediaQuery.of(context).padding.top + 40,
                              ),
                              child: AddEventScreen(initialDate: selectedDate),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(30),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.08)
                                : Colors.grey[100],
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: isDark ? Colors.white10 : Colors.white60,
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Text(
                            'Add event on ${DateFormat('MMM d').format(selectedDate)}',
                            style: TextStyle(
                              color: isDark ? Colors.white70 : Colors.black54,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    FloatingActionButton(
                      heroTag: null,
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (context) => Padding(
                            padding: EdgeInsets.only(
                              top: MediaQuery.of(context).padding.top + 40,
                            ),
                            child: AddEventScreen(initialDate: selectedDate),
                          ),
                        );
                      },
                      backgroundColor: isDark ? Colors.white : Colors.black,
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        Icons.add,
                        color: isDark ? Colors.black : Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<Event> _getEventsForDay(
    DateTime day,
    Map<DateTime, List<Event>> eventsMap,
  ) {
    final key = DateTime(day.year, day.month, day.day);
    return eventsMap[key] ?? [];
  }

  Widget _buildSelectedDayAgenda(
    BuildContext context,
    DateTime selectedDate,
    Map<DateTime, List<Event>> eventsMap,
    bool isDark,
  ) {
    final dayEvents = _getEventsForDay(selectedDate, eventsMap);
    if (dayEvents.isEmpty) return const SizedBox.shrink();

    return Container(
      height:
          120, // Increased height to prevent bottom text clipping on large fonts
      margin: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Text(
              'Events for ${DateFormat('MMM d').format(selectedDate)}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : Colors.black54,
                letterSpacing: 0.5,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: dayEvents.length,
              itemBuilder: (context, index) {
                final event = dayEvents[index];
                final color = event.customColor ?? event.color.color;

                return GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EventDetailScreen(event: event),
                    ),
                  ),
                  child: Container(
                    width: 200,
                    margin: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 4,
                    ),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? Colors.white12 : Colors.grey[200]!,
                        width: 1,
                      ),
                      boxShadow: [
                        if (!isDark)
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 4,
                          height: double.infinity,
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                event.title,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                event.isAllDay
                                    ? 'All Day'
                                    : DateFormat(
                                        'h:mm a',
                                      ).format(event.startTime),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark
                                      ? Colors.white54
                                      : Colors.grey[600],
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.05)
                                  : Colors.black.withValues(alpha: 0.03),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.chevron_right_rounded,
                              size: 16,
                              color: isDark ? Colors.white54 : Colors.black38,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateRow(
    DateTime weekStart,
    ThemeData theme,
    bool isDark,
    double fs,
  ) {
    final rawSelectedDate = ref.watch(selectedDateProvider);
    final selectedDate = DateTime(
      rawSelectedDate.year,
      rawSelectedDate.month,
      rawSelectedDate.day,
    );
    final eventsMap = ref.watch(filteredEventsProvider);

    return Container(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      color: theme.scaffoldBackgroundColor,
      child: Row(
        children: [
          ...List.generate(7, (index) {
            final day = weekStart.add(Duration(days: index));
            final isToday = isSameDay(day, DateTime.now());
            final isSelected = isSameDay(day, selectedDate);
            final isSunday = day.weekday == DateTime.sunday;
            final dayName = DateFormat('E').format(day).substring(0, 1);
            final dayEvents = _getEventsForDay(day, eventsMap);

            return Expanded(
              child: Semantics(
                label:
                    "Select \${dayName}, \${DateFormat('MMMM d').format(day)}. \${dayEvents.isNotEmpty ? 'Has events' : 'No events'}",
                button: true,
                child: GestureDetector(
                  onTap: () =>
                      ref.read(selectedDateProvider.notifier).setDate(day),
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    key: ValueKey(
                      'week_cell_${day.year}_${day.month}_${day.day}',
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    decoration: isSelected
                        ? BoxDecoration(
                            color: theme.primaryColor.withValues(
                              alpha: isDark ? 0.2 : 0.1,
                            ),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: theme.primaryColor.withValues(alpha: 0.3),
                              width: 1,
                            ),
                          )
                        : null,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          dayName,
                          style: TextStyle(
                            fontSize: 12 * fs,
                            fontWeight: FontWeight.w600,
                            color: isSunday
                                ? Colors.red
                                : (isDark ? Colors.white70 : Colors.grey[600]),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          width: 24,
                          height: 24,
                          alignment: Alignment.center,
                          decoration: isToday
                              ? BoxDecoration(
                                  color: isDark ? Colors.white : Colors.black,
                                  borderRadius: BorderRadius.circular(6),
                                )
                              : null,
                          child: MediaQuery.withNoTextScaling(
                            child: Text(
                              '${day.day}',
                              style: TextStyle(
                                fontSize: 13 * fs,
                                fontWeight: isToday
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                                color: isToday
                                    ? (isDark ? Colors.black : Colors.white)
                                    : (isSunday
                                          ? Colors.red
                                          : (isDark
                                                ? Colors.white
                                                : Colors.black87)),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (dayEvents.isNotEmpty)
                          Column(
                            children: [
                              ...dayEvents.take(2).map((event) {
                                final color =
                                    event.customColor ?? event.color.color;
                                return Container(
                                  width: double.infinity,
                                  margin: const EdgeInsets.only(bottom: 2),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 2,
                                    vertical: 1,
                                  ),
                                  decoration: BoxDecoration(
                                    color: color.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(2),
                                    border: Border(
                                      left: BorderSide(
                                        color: color,
                                        width: 2.5,
                                      ),
                                    ),
                                  ),
                                  child: Text(
                                    event.title,
                                    style: TextStyle(
                                      fontSize: 8,
                                      fontWeight: FontWeight.w500,
                                      color: isDark
                                          ? Colors.white.withValues(alpha: 0.8)
                                          : Colors.black87,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.start,
                                  ),
                                );
                              }).toList(),
                              if (dayEvents.length > 2)
                                Text(
                                  '+${dayEvents.length - 2} more',
                                  style: TextStyle(
                                    fontSize: 7,
                                    fontWeight: FontWeight.bold,
                                    color: isDark
                                        ? Colors.white38
                                        : Colors.grey[500],
                                  ),
                                ),
                            ],
                          )
                        else if (isToday)
                          Icon(
                            Icons.sentiment_satisfied_alt_outlined,
                            size: 14,
                            color: isDark ? Colors.white54 : Colors.grey[600],
                          )
                        else
                          const SizedBox(height: 14),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  void _showMonthYearPicker() async {
    final DateTime? result = await showModalBottomSheet<DateTime>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _WeekMonthYearPickerSheet(
        initialDate: ref.read(selectedDateProvider),
      ),
    );

    if (result != null) {
      ref.read(selectedDateProvider.notifier).setDate(result);
    }
  }
}

class _WeekMonthYearPickerSheet extends StatefulWidget {
  final DateTime initialDate;
  const _WeekMonthYearPickerSheet({required this.initialDate});

  @override
  State<_WeekMonthYearPickerSheet> createState() =>
      _WeekMonthYearPickerSheetState();
}

class _WeekMonthYearPickerSheetState extends State<_WeekMonthYearPickerSheet> {
  late int _selectedYear;
  int? _selectedMonth;

  @override
  void initState() {
    super.initState();
    _selectedYear = widget.initialDate.year;
    // Don't auto-select month so users can see the month grid first, 
    // unless they want to jump straight to the current month.
  }

  void _previousYear() => setState(() {
    _selectedYear--;
    _selectedMonth = null;
  });
  
  void _nextYear() => setState(() {
    _selectedYear++;
    _selectedMonth = null;
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 16),
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left_rounded),
                  onPressed: _previousYear,
                ),
                GestureDetector(
                  onTap: () => setState(() => _selectedMonth = null),
                  child: Column(
                    children: [
                      Text(
                        '$_selectedYear',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      if (_selectedMonth != null)
                        Text(
                          DateFormat('MMMM').format(DateTime(_selectedYear, _selectedMonth!)),
                          style: TextStyle(
                            fontSize: 14,
                            color: theme.primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right_rounded),
                  onPressed: _nextYear,
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          
          if (_selectedMonth == null)
            // Month Grid
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 1.5,
                ),
                itemCount: 12,
                itemBuilder: (context, index) {
                  final month = index + 1;
                  final monthName = DateFormat('MMM').format(DateTime(_selectedYear, month));
                  final isSelected =
                      widget.initialDate.year == _selectedYear &&
                      widget.initialDate.month == month;

                  return GestureDetector(
                    onTap: () => setState(() => _selectedMonth = month),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected
                            ? theme.primaryColor
                            : (isDark ? Colors.white10 : Colors.grey[100]),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        monthName,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected ? Colors.white : (isDark ? Colors.white : Colors.black87),
                        ),
                      ),
                    ),
                  );
                },
              ),
            )
          else
            // Day Grid for selected month
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 7,
                      mainAxisSpacing: 4,
                      crossAxisSpacing: 4,
                    ),
                    itemCount: DateTime(_selectedYear, _selectedMonth! + 1, 0).day,
                    itemBuilder: (context, index) {
                      final day = index + 1;
                      final date = DateTime(_selectedYear, _selectedMonth!, day);
                      final isSelected = widget.initialDate.year == date.year &&
                          widget.initialDate.month == date.month &&
                          widget.initialDate.day == date.day;
                      final isToday = DateTime.now().year == date.year &&
                          DateTime.now().month == date.month &&
                          DateTime.now().day == date.day;

                      return GestureDetector(
                        onTap: () => Navigator.pop(context, date),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected
                                ? theme.primaryColor
                                : (isToday ? theme.primaryColor.withValues(alpha: 0.1) : Colors.transparent),
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '$day',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected 
                                  ? Colors.white 
                                  : (isToday ? theme.primaryColor : (isDark ? Colors.white : Colors.black87)),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
