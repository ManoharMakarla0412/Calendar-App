import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'month_view.dart';
import 'week_view.dart';
import 'day_view.dart';
import 'agenda_view.dart';
import 'year_view.dart';
import 'search_screen.dart';
import '../providers/date_provider.dart';
import '../widgets/responsive_scaffold.dart';
import '../widgets/main_drawer.dart';
import 'package:animations/animations.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  int _currentIndex = 1; // Default to Month View
  int _currentYearViewYear = DateTime.now().year;
  final GlobalKey<YearViewState> _yearViewKey = GlobalKey<YearViewState>();

  @override
  void initState() {
    super.initState();
  }

  // Note: Year view is index 0. User reported it missing, but it is in the list.
  final List<String> _titles = ['Year', 'Month', 'Week', 'Day', 'Agenda'];

  Future<void> _onDestinationSelected(int index) async {
    // Small delay to allow ripple effect to show as per user request
    await Future.delayed(const Duration(milliseconds: 200));
    if (mounted) {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  void _showExitBottomSheet() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SafeArea(
        child: Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize:
                MainAxisSize.min, // Fixes overflow by growing with content
            children: [
              const SizedBox(height: 12),
              // Handle bar
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),

              // Dedicated Ad Space on Exit
              Container(
                height: 180,
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 24),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.black.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark ? Colors.white10 : Colors.black12,
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.ads_click,
                        color: theme.primaryColor.withValues(alpha: 0.5),
                        size: 32,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'ADVERTISEMENT',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                          color: isDark ? Colors.white24 : Colors.black26,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),
              Icon(
                Icons.logout_rounded,
                size: 48,
                color: const Color(0xFFDC2626).withValues(alpha: 0.8),
              ),
              const SizedBox(height: 16),
              Text(
                'Exit ClearDay?',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : Colors.black87,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  'Are you sure you want to close the app?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.white70 : Colors.black54,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                child: Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(color: theme.dividerColor),
                          ),
                        ),
                        child: Text(
                          'Stay',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white70 : Colors.black87,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => exit(0),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFDC2626),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'Exit App',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 13),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedDate = ref.watch(selectedDateProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final List<Widget> screens = [
      YearView(
        key: _yearViewKey,
        onMonthSelected: (year, month) {
          ref
              .read(selectedDateProvider.notifier)
              .setDate(DateTime(year, month));
          setState(() => _currentIndex = 1); // Switch to Month
        },
        onYearChanged: (year) {
          setState(() {
            _currentYearViewYear = year;
          });
        },
      ),
      const MonthView(),
      const WeekView(),
      const DayView(),
      const AgendaView(),
    ];

    String titleText = _titles[_currentIndex];
    Widget? customTitle;

    // Custom Title for Year View
    if (_currentIndex == 0) {
      customTitle = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(
              Icons.chevron_left,
              color: theme.textTheme.titleLarge?.color,
            ),
            onPressed: () => _yearViewKey.currentState?.previousYear(),
          ),
          Flexible(
            child: InkWell(
              onTap: () => _yearViewKey.currentState?.selectYear(),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12.0,
                  vertical: 4.0,
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  transitionBuilder:
                      (Widget child, Animation<double> animation) {
                        return FadeTransition(opacity: animation, child: child);
                      },
                  child: Text(
                    '$_currentYearViewYear',
                    key: ValueKey(_currentYearViewYear),
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.5,
                      color: theme.textTheme.titleLarge?.color,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.chevron_right,
              color: theme.textTheme.titleLarge?.color,
            ),
            onPressed: () => _yearViewKey.currentState?.nextYear(),
          ),
        ],
      );
    }
    // Custom Title for Month View
    else if (_currentIndex == 1) {
      customTitle = MediaQuery.withNoTextScaling(
        child: RichText(
          text: TextSpan(
            style: TextStyle(
              fontSize: 20,
              letterSpacing: 1.5,
              color: theme.textTheme.titleLarge?.color,
              fontFamily: theme.textTheme.titleLarge?.fontFamily,
            ),
            children: [
              TextSpan(
                text: DateFormat('MMM').format(selectedDate).toUpperCase(),
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: theme.primaryColor,
                ),
              ),
              TextSpan(
                text: ' ${selectedDate.year}',
                style: const TextStyle(fontWeight: FontWeight.w400),
              ),
            ],
          ),
        ),
      );
      titleText = '';
    }
    // Empty text title for views that have their own internal headers (Week/Day)
    else if (_currentIndex == 2 || _currentIndex == 3) {
      titleText = '';
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _showExitBottomSheet();
      },
      child: ResponsiveScaffold(
        title: titleText,
        titleWidget: customTitle != null
            ? GestureDetector(
                onTap: () {
                  if (_currentIndex == 1) {
                    _showMonthYearPicker(context, selectedDate);
                  }
                },
                child: customTitle,
              )
            : null,
        actions: [
          IconButton(
            tooltip: 'Go to Today',
            icon: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                border: Border.all(
                  color: theme.colorScheme.onSurface,
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(6),
              ),
              alignment: Alignment.center,
              child: Text(
                '${DateTime.now().day}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
            onPressed: () {
              ref.read(selectedDateProvider.notifier).setDate(DateTime.now());
              if (_currentIndex == 0) setState(() => _currentIndex = 1);
            },
          ),

          IconButton(
            tooltip: 'Search events',
            icon: Icon(Icons.search, color: theme.colorScheme.onSurface),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SearchScreen()),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
        drawer: MainDrawer(
          currentIndex: _currentIndex,
          onDestinationSelected: _onDestinationSelected,
        ),
        bottomNavigationBar: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            NavigationBarTheme(
              data: NavigationBarThemeData(
                labelTextStyle: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: theme.colorScheme.primary,
                      letterSpacing: 0.5,
                    );
                  }
                  return TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white54 : Colors.grey[500],
                  );
                }),
                iconTheme: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return IconThemeData(
                      size: 28,
                      color: theme.colorScheme.primary,
                    );
                  }
                  return IconThemeData(
                    size: 24,
                    color: isDark ? Colors.white54 : Colors.grey[500],
                  );
                }),
                indicatorColor: theme.colorScheme.primary.withValues(
                  alpha: isDark ? 0.25 : 0.15,
                ),
                indicatorShape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: NavigationBar(
                height: 65,
                elevation: 0,
                selectedIndex: _currentIndex,
                onDestinationSelected: _onDestinationSelected,
                backgroundColor: theme.scaffoldBackgroundColor,
                destinations: [
                  const NavigationDestination(
                    icon: Icon(Icons.calendar_view_day_outlined),
                    selectedIcon: Icon(Icons.calendar_view_day),
                    label: 'Year',
                  ),
                  const NavigationDestination(
                    icon: Icon(Icons.calendar_month_outlined),
                    selectedIcon: Icon(Icons.calendar_month),
                    label: 'Month',
                  ),
                  const NavigationDestination(
                    icon: Icon(Icons.calendar_view_week_outlined),
                    selectedIcon: Icon(Icons.calendar_view_week),
                    label: 'Week',
                  ),
                  const NavigationDestination(
                    icon: Icon(Icons.calendar_view_day_rounded),
                    selectedIcon: Icon(Icons.calendar_view_day),
                    label: 'Day',
                  ),
                  const NavigationDestination(
                    icon: Icon(Icons.view_agenda_outlined),
                    selectedIcon: Icon(Icons.view_agenda),
                    label: 'Schedule',
                  ),
                ],
              ),
            ),
          ],
        ),
        body: PageTransitionSwitcher(
          duration: const Duration(milliseconds: 350),
          transitionBuilder: (child, primaryAnimation, secondaryAnimation) {
            return FadeThroughTransition(
              animation: primaryAnimation,
              secondaryAnimation: secondaryAnimation,
              fillColor: Colors.transparent,
              child: child,
            );
          },
          child: KeyedSubtree(
            key: ValueKey<int>(_currentIndex),
            child: screens[_currentIndex],
          ),
        ),
      ),
    );
  }

  void _showMonthYearPicker(BuildContext context, DateTime currentMonth) async {
    final DateTime? result = await showModalBottomSheet<DateTime>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          _MainMonthYearPickerSheet(initialDate: currentMonth),
    );

    if (result != null) {
      ref.read(selectedDateProvider.notifier).setDate(result);
    }
  }
}

class _MainMonthYearPickerSheet extends StatefulWidget {
  final DateTime initialDate;
  const _MainMonthYearPickerSheet({required this.initialDate});

  @override
  State<_MainMonthYearPickerSheet> createState() =>
      _MainMonthYearPickerSheetState();
}

class _MainMonthYearPickerSheetState extends State<_MainMonthYearPickerSheet> {
  late int _selectedYear;

  @override
  void initState() {
    super.initState();
    _selectedYear = widget.initialDate.year;
  }

  void _previousYear() => setState(() => _selectedYear--);
  void _nextYear() => setState(() => _selectedYear++);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 16),
          // Year Selection Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left_rounded),
                  onPressed: _previousYear,
                ),
                Text(
                  '$_selectedYear',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right_rounded),
                  onPressed: _nextYear,
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // Months Grid
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
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
                // We'll just use a simple static list to avoid DateFormat dependency here or we can import intl
                final monthNames = [
                  'January',
                  'February',
                  'March',
                  'April',
                  'May',
                  'June',
                  'July',
                  'August',
                  'September',
                  'October',
                  'November',
                  'December',
                ];
                final monthName = monthNames[index];
                final isSelected =
                    widget.initialDate.year == _selectedYear &&
                    widget.initialDate.month == month;

                return GestureDetector(
                  onTap: () =>
                      Navigator.pop(context, DateTime(_selectedYear, month, 1)),
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
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.w500,
                        color: isSelected
                            ? Colors.white
                            : (isDark ? Colors.white : Colors.black87),
                      ),
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
}
