import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../features/events/presentation/events_view_model.dart';
import '../providers/date_provider.dart';
import '../widgets/multi_day_timetable.dart';
import 'add_event_screen.dart';

class DayView extends ConsumerStatefulWidget {
  const DayView({super.key});

  @override
  ConsumerState<DayView> createState() => _DayViewState();
}

class _DayViewState extends ConsumerState<DayView> {
  late PageController _pageController;
  final int _basePage = 5000;
  late DateTime _baseDate;

  // Date strip — uses a fixed window of dates centered on today
  // The "anchor" is the date at the center of the visible strip.
  // We keep track of it so we can rebuild when the user swipes far.
  late ScrollController _stripScrollController;
  // Each strip item is 63px wide (55 width + 4 margin each side)
  static const double _itemWidth = 63.0;
  // We show _windowSize items max in the strip.
  // The "center" item index within the window is _windowSize ~/ 2
  static const int _windowSize = 61; // ±30 days
  late DateTime _stripCenterDate; // center of the current strip window

  @override
  void initState() {
    super.initState();
    _baseDate = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );
    _baseDate = _baseDate; // normalize

    final initialSelected = DateTime.now();
    _stripCenterDate = DateTime(
      initialSelected.year,
      initialSelected.month,
      initialSelected.day,
    );

    _pageController = PageController(initialPage: _basePage);
    // Start the strip so the selected date is centred
    final initialOffset = (_windowSize ~/ 2) * _itemWidth;
    _stripScrollController = ScrollController(
      initialScrollOffset: initialOffset,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _stripScrollController.dispose();
    super.dispose();
  }

  // Called when the user swipes the day PageView
  void _onPageChanged(int index) {
    final newDate = _baseDate.add(Duration(days: index - _basePage));
    final currentSelected = ref.read(selectedDateProvider);
    if (!isSameDay(newDate, currentSelected)) {
      ref.read(selectedDateProvider.notifier).setDate(newDate);
      // Scroll strip to keep selected item centred
      _scrollStripTo(newDate, animate: true);
    }
  }

  // Scroll the date strip so [date] is centred in the visible area.
  void _scrollStripTo(DateTime date, {bool animate = true}) {
    if (!_stripScrollController.hasClients) return;

    final diff = DateTime(date.year, date.month, date.day)
        .difference(_stripCenterDate)
        .inDays;
    final centerItemIndex = _windowSize ~/ 2;
    final targetItemIndex = centerItemIndex + diff;

    // Clamp: if targetItemIndex is near the edges, re-center the window
    if (targetItemIndex < 5 || targetItemIndex > _windowSize - 5) {
      // Shift the window center to the current date,
      // then immediately jump without animation
      setState(() {
        _stripCenterDate = DateTime(date.year, date.month, date.day);
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_stripScrollController.hasClients) {
          _stripScrollController.jumpTo(
            ((_windowSize ~/ 2) * _itemWidth).clamp(
              0,
              _stripScrollController.position.maxScrollExtent,
            ),
          );
        }
      });
      return;
    }

    final targetOffset = (targetItemIndex * _itemWidth).clamp(
      0.0,
      _stripScrollController.position.maxScrollExtent,
    );

    if (animate) {
      _stripScrollController.animateTo(
        targetOffset,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    } else {
      _stripScrollController.jumpTo(targetOffset);
    }
  }

  // Sync the main PageView to a given date (called from external provider changes)
  void _syncPageController(DateTime selectedDate) {
    if (!_pageController.hasClients) return;

    final diff = DateTime(selectedDate.year, selectedDate.month, selectedDate.day)
        .difference(_baseDate)
        .inDays;
    final targetPage = _basePage + diff;
    final currentPage =
        (_pageController.page ?? _pageController.initialPage.toDouble()).round();

    if (currentPage == targetPage) return;

    // Jump (instant) for large distances, animate for short
    if ((currentPage - targetPage).abs() > 5) {
      _pageController.jumpToPage(targetPage);
    } else {
      _pageController.animateToPage(
        targetPage,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
    _scrollStripTo(selectedDate, animate: (currentPage - targetPage).abs() <= 5);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final eventsMap = ref.watch(filteredEventsProvider);
    final selectedDate = ref.watch(selectedDateProvider);

    // Listen to provider changes caused by external sources (e.g. YearView tap)
    ref.listen<DateTime>(selectedDateProvider, (previous, next) {
      if (previous != null && isSameDay(previous, next)) return;
      _syncPageController(next);
    });

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Column(
        children: [
          // Month / Year header — tappable to jump via picker
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: InkWell(
              onTap: _showMonthYearPicker,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: MediaQuery.withNoTextScaling(
                  child: Text(
                    selectedDate.year == DateTime.now().year
                        ? DateFormat('MMM')
                            .format(selectedDate)
                            .toUpperCase()
                        : DateFormat('MMM yyyy')
                            .format(selectedDate)
                            .toUpperCase(),
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.5,
                      color: theme.textTheme.titleLarge?.color,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Date Strip (bounded, no ANR) ────────────────────────────
          SizedBox(
            height: 90,
            child: ListView.builder(
              controller: _stripScrollController,
              scrollDirection: Axis.horizontal,
              itemCount: _windowSize,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.only(left: 65),
              itemBuilder: (context, index) {
                final centerIdx = _windowSize ~/ 2;
                final date = _stripCenterDate
                    .add(Duration(days: index - centerIdx));
                final isSelected = isSameDay(date, selectedDate);
                final isToday = isSameDay(date, DateTime.now());

                return GestureDetector(
                  onTap: () {
                    ref.read(selectedDateProvider.notifier).setDate(date);
                    _syncPageController(date);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 55,
                    margin: const EdgeInsets.symmetric(
                        horizontal: 4, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? (isDark ? Colors.white : Colors.black)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                      border: isToday && !isSelected
                          ? Border.all(
                              color: isDark
                                  ? Colors.white24
                                  : Colors.black12,
                              width: 1,
                            )
                          : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          DateFormat('EEE').format(date).toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: isSelected
                                ? (isDark ? Colors.black : Colors.white)
                                : (isDark
                                    ? Colors.white38
                                    : Colors.black38),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${date.day}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isSelected
                                ? (isDark ? Colors.black : Colors.white)
                                : (isDark ? Colors.white : Colors.black),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // ── Day Timetable (PageView) ─────────────────────────────────
          Expanded(
            child: Stack(
              children: [
                PageView.builder(
                  controller: _pageController,
                  onPageChanged: _onPageChanged,
                  allowImplicitScrolling: true,
                  itemBuilder: (context, index) {
                    final date =
                        _baseDate.add(Duration(days: index - _basePage));
                    final dayKey =
                        DateTime(date.year, date.month, date.day);
                    final events = eventsMap[dayKey] ?? [];

                    return RepaintBoundary(
                      child: MultiDayTimetable(
                        initialDate: date,
                        numberOfDays: 1,
                        events: events,
                        hourHeight: 65,
                        showHeader: false,
                      ),
                    );
                  },
                ),

                // Bottom Add Event Pill
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
                                  top:
                                      MediaQuery.of(context).padding.top +
                                      40,
                                ),
                                child: AddEventScreen(
                                    initialDate: selectedDate),
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
                                  ? Colors.grey[900]!
                                      .withValues(alpha: 0.8)
                                  : Colors.grey[100]!
                                      .withValues(alpha: 0.8),
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Text(
                              'Add event on ${DateFormat('MMM d').format(selectedDate)}',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 13,
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
                                top:
                                    MediaQuery.of(context).padding.top +
                                    40,
                              ),
                              child: AddEventScreen(
                                  initialDate: selectedDate),
                            ),
                          );
                        },
                        backgroundColor:
                            isDark ? Colors.white : Colors.black,
                        elevation: 4,
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
      ),
    );
  }

  void _showMonthYearPicker() async {
    final DateTime? result = await showModalBottomSheet<DateTime>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _DayMonthYearPickerSheet(
        initialDate: ref.read(selectedDateProvider),
      ),
    );

    if (result != null) {
      ref.read(selectedDateProvider.notifier).setDate(result);
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Month / Year / Day picker sheet
// ─────────────────────────────────────────────────────────────────────────────

class _DayMonthYearPickerSheet extends StatefulWidget {
  final DateTime initialDate;
  const _DayMonthYearPickerSheet({required this.initialDate});

  @override
  State<_DayMonthYearPickerSheet> createState() =>
      _DayMonthYearPickerSheetState();
}

class _DayMonthYearPickerSheetState
    extends State<_DayMonthYearPickerSheet> {
  late int _selectedYear;
  int? _selectedMonth;

  @override
  void initState() {
    super.initState();
    _selectedYear = widget.initialDate.year;
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
                  onTap: () =>
                      setState(() => _selectedMonth = null),
                  child: Column(
                    children: [
                      Text(
                        '$_selectedYear',
                        style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold),
                      ),
                      if (_selectedMonth != null)
                        Text(
                          DateFormat('MMMM').format(
                              DateTime(_selectedYear, _selectedMonth!)),
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 1.5,
                ),
                itemCount: 12,
                itemBuilder: (context, index) {
                  final month = index + 1;
                  final monthName = DateFormat('MMM')
                      .format(DateTime(_selectedYear, month));
                  final isSelected =
                      widget.initialDate.year == _selectedYear &&
                          widget.initialDate.month == month;

                  return GestureDetector(
                    onTap: () =>
                        setState(() => _selectedMonth = month),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected
                            ? theme.primaryColor
                            : (isDark
                                ? Colors.white10
                                : Colors.grey[100]),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        monthName,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.w500,
                          color: isSelected
                              ? Colors.white
                              : (isDark
                                  ? Colors.white
                                  : Colors.black87),
                        ),
                      ),
                    ),
                  );
                },
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  mainAxisSpacing: 4,
                  crossAxisSpacing: 4,
                ),
                itemCount:
                    DateTime(_selectedYear, _selectedMonth! + 1, 0).day,
                itemBuilder: (context, index) {
                  final day = index + 1;
                  final date =
                      DateTime(_selectedYear, _selectedMonth!, day);
                  final isSelected =
                      isSameDay(date, widget.initialDate);
                  final isToday = isSameDay(date, DateTime.now());

                  return GestureDetector(
                    onTap: () => Navigator.pop(context, date),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected
                            ? theme.primaryColor
                            : (isToday
                                ? theme.primaryColor
                                    .withValues(alpha: 0.1)
                                : Colors.transparent),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '$day',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: isSelected
                              ? Colors.white
                              : (isToday
                                  ? theme.primaryColor
                                  : (isDark
                                      ? Colors.white
                                      : Colors.black87)),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
