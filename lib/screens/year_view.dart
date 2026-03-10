import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/date_provider.dart';
import '../providers/settings_provider.dart';
import '../features/events/presentation/events_view_model.dart';
import '../models/event.dart';

class YearView extends ConsumerStatefulWidget {
  final Function(int year, int month)? onMonthSelected;
  final Function(int year)? onYearChanged;
  const YearView({super.key, this.onMonthSelected, this.onYearChanged});

  @override
  ConsumerState<YearView> createState() => YearViewState();
}

class YearViewState extends ConsumerState<YearView> {
  late PageController _pageController;
  late int _focusedYear;
  final int _initialYear = DateTime.now().year;
  // Use a large base page to allow "infinite" swiping in both directions
  final int _basePage = 5000;

  @override
  void initState() {
    super.initState();
    _focusedYear = ref.read(selectedDateProvider).year;
    _pageController = PageController(
      initialPage: _basePage + (_focusedYear - _initialYear),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onMonthTap(int year, int month) {
    final newDate = DateTime(year, month, 1);
    ref.read(selectedDateProvider.notifier).setDate(newDate);
    if (widget.onMonthSelected != null) {
      widget.onMonthSelected!(year, month);
    }
  }

  void selectYear() async {
    final int? selectedYear = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return _YearPickerSheet(initialYear: _focusedYear);
      },
    );

    if (selectedYear != null && selectedYear != _focusedYear) {
      final page = _basePage + (selectedYear - _initialYear);
      _pageController.jumpToPage(page);
    }
  }

  void nextYear() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void previousYear() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (page) {
              setState(() {
                _focusedYear = _initialYear + (page - _basePage);
              });
              if (widget.onYearChanged != null) {
                widget.onYearChanged!(_focusedYear);
              }
            },
            itemBuilder: (context, pageIndex) {
              final year = _initialYear + (pageIndex - _basePage);
              return RepaintBoundary(
                child: _YearGrid(
                  year: year,
                  onMonthTap: (month) => _onMonthTap(year, month),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _YearPickerSheet extends StatefulWidget {
  final int initialYear;
  const _YearPickerSheet({required this.initialYear});

  @override
  State<_YearPickerSheet> createState() => _YearPickerSheetState();
}

class _YearPickerSheetState extends State<_YearPickerSheet> {
  late int _startYear;
  late int _selectedYear;

  @override
  void initState() {
    super.initState();
    _selectedYear = widget.initialYear;
    // Align start year to the beginning of a 12-year block
    _startYear = _selectedYear - (_selectedYear % 12) + 1;
    // Handle the case where the range might looks slightly different than pure modulo
    // In the image 2025-2036 is shown. 2025 % 12 is 9.
    // Let's just use a simpler logic: 12 years per view.
    _startYear = ((_selectedYear - 1) ~/ 12) * 12 + 1;
  }

  void _previousRange() {
    setState(() {
      _startYear -= 12;
    });
  }

  void _nextRange() {
    setState(() {
      _startYear += 12;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final endYear = _startYear + 11;

    return Container(
      margin: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 40),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            // Drag handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            // Header with navigation
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left, color: Colors.grey),
                    onPressed: _previousRange,
                  ),
                  Text(
                    '$_startYear - $endYear',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w400,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right, color: Colors.grey),
                    onPressed: _nextRange,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            // 4x3 Grid of years
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: 20,
                  crossAxisSpacing: 16,
                ),
                itemCount: 12,
                itemBuilder: (context, index) {
                  final year = _startYear + index;
                  final isSelected = year == _selectedYear;

                  return GestureDetector(
                    onTap: () => Navigator.pop(context, year),
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected
                            ? theme.primaryColor
                            : Colors.transparent,
                        border: isSelected
                            ? null
                            : Border.all(
                                color: Colors.grey.withValues(alpha: 0.3),
                              ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '$year',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.w400,
                          color: isSelected
                              ? Colors.white
                              : theme.colorScheme.onSurface,
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
}

class _YearGrid extends ConsumerWidget {
  final int year;
  final Function(int) onMonthTap;

  const _YearGrid({required this.year, required this.onMonthTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    final screenHeight = MediaQuery.of(context).size.height;
    // Calculate aspect ratio dynamically:
    // We want 3 columns, and we want 4 rows to fit nicely into the remaining vertical space.
    // Give more vertical breathing room on shorter devices
    final isCompact = screenHeight < 700;

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(
        16,
        8,
        16,
        100,
      ), // Bottom padding for navigation clearance
      physics: const BouncingScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: isCompact ? 0.85 : 0.95,
        crossAxisSpacing: 16,
        mainAxisSpacing: 20,
      ),
      itemCount: 12,
      itemBuilder: (context, index) {
        final month = index + 1;
        final monthName = DateFormat('MMM').format(DateTime(year, month));

        return Semantics(
          button: true,
          label: "Month: $monthName $year",
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => onMonthTap(month),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 6),
                      child: Consumer(
                        builder: (context, ref, _) {
                          final selectedDate = ref.watch(selectedDateProvider);
                          final bool isActive =
                              selectedDate.year == year &&
                              selectedDate.month == month;

                            return Text(
                              monthName,
                              style: TextStyle(
                                fontWeight: isActive
                                    ? FontWeight.w900
                                    : FontWeight.w600,
                                fontSize: 15,
                                color: theme.brightness == Brightness.dark
                                    ? Colors.white.withValues(alpha: isActive ? 1.0 : 0.8)
                                    : theme.primaryColor.withValues(alpha: isActive ? 1.0 : 0.8),
                                letterSpacing: 0.5,
                              ),
                            );
                          },
                        ),
                      ),
                      Expanded(
                        child: _MonthPreview(
                          year: year,
                          month: month,
                          events: ref.watch(filteredEventsProvider),
                          firstDayOfWeek: ref.watch(settingsProvider).firstDayOfWeek,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
    }
  }

class _MonthPreview extends StatelessWidget {
  final int year;
  final int month;
  final Map<DateTime, List<Event>> events;
  final int firstDayOfWeek;

  const _MonthPreview({
    required this.year,
    required this.month,
    required this.events,
    required this.firstDayOfWeek,
  });

  @override
  Widget build(BuildContext context) {
    final firstDay = DateTime(year, month, 1);
    final lastDay = DateTime(year, month + 1, 0);
    final daysInMonth = lastDay.day;

    return LayoutBuilder(
      builder: (context, constraints) {
        final theme = Theme.of(context);

        return Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children:
                  _getWeekDayHeaders(firstDayOfWeek)
                      .map(
                        (d) => Text(
                          d,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: theme.textTheme.bodySmall?.color?.withValues(
                              alpha: 0.5,
                            ),
                          ),
                        ),
                      )
                      .toList(),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: GridView.count(
                crossAxisCount: 7,
                physics: const NeverScrollableScrollPhysics(),
                children: List.generate(42, (index) {
                  final dayIndex =
                      index - ((firstDay.weekday - firstDayOfWeek + 7) % 7);
                  final day = dayIndex + 1;

                  if (dayIndex < 0 || day > daysInMonth) {
                    return const SizedBox();
                  }

                  final date = DateTime(year, month, day);
                  final hasEvents =
                      events.containsKey(date) && events[date]!.isNotEmpty;
                  final isSunday = date.weekday == DateTime.sunday;
                  final isToday =
                      DateTime.now().year == year &&
                      DateTime.now().month == month &&
                      DateTime.now().day == day;

                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 18,
                        height: 18,
                        decoration: isToday
                            ? BoxDecoration(
                                color: theme.brightness == Brightness.dark
                                    ? Colors.white
                                    : theme.primaryColor,
                                shape: BoxShape.circle,
                              )
                            : (hasEvents
                                  ? BoxDecoration(
                                      color: theme.primaryColor.withValues(
                                        alpha: 0.08,
                                      ),
                                      shape: BoxShape.circle,
                                    )
                                  : null),
                        child: Center(
                          child: MediaQuery.withNoTextScaling(
                            child: Text(
                              '$day',
                              style: TextStyle(
                                fontSize: 10,
                                color: isToday
                                    ? (theme.brightness == Brightness.dark
                                          ? Colors.black
                                          : Colors.white)
                                    : (isSunday
                                          ? theme.colorScheme.error
                                          : theme.textTheme.bodyMedium?.color),
                                fontWeight: (isToday || isSunday)
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (hasEvents && !isToday)
                        Positioned(
                          bottom: 2,
                          child: Container(
                            width: 3,
                            height: 3,
                            decoration: BoxDecoration(
                              color: theme.primaryColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  );
                }),
              ),
            ),
          ],
        );
      },
    );
  }

  List<String> _getWeekDayHeaders(int firstDay) {
    // Dart weekday: Mon=1, Tue=2, Wed=3, Thu=4, Fri=5, Sat=6, Sun=7
    // Map to index 0..6 starting from Sunday for the labels array
    // Labels in Dart weekday order: Mon=1 -> index 0, ..., Sun=7 -> index 6
    const labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S']; // Mon..Sun
    // firstDay is 1 (Mon) .. 7 (Sun)
    final startIndex = firstDay - 1; // 0-based index into labels
    return [
      ...labels.sublist(startIndex),
      ...labels.sublist(0, startIndex),
    ];
  }
}
