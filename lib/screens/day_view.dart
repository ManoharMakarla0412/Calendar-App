import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../features/events/presentation/events_view_model.dart';
import '../providers/date_provider.dart';
import '../widgets/multi_day_timetable.dart';
import 'add_event_screen.dart';
import '../providers/mood_provider.dart';

class DayView extends ConsumerStatefulWidget {
  const DayView({super.key});

  @override
  ConsumerState<DayView> createState() => _DayViewState();
}

class _DayViewState extends ConsumerState<DayView> {
  late PageController _pageController;
  final int _basePage = 5000;
  late DateTime _baseDate;

  @override
  void initState() {
    super.initState();
    _baseDate = DateTime.now();
    _pageController = PageController(initialPage: _basePage);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    final newDate = _baseDate.add(Duration(days: index - _basePage));
    ref.read(selectedDateProvider.notifier).setDate(newDate);
  }

  @override
  Widget build(BuildContext context) {
    final rawSelectedDate = ref.watch(selectedDateProvider);
    final selectedDate = DateTime(
      rawSelectedDate.year,
      rawSelectedDate.month,
      rawSelectedDate.day,
    );
    final eventsMap = ref.watch(filteredEventsProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Check if we need to jump the page controller if selectedDate changed from outside
    _syncPageController(selectedDate);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Column(
        children: [
          // Centered Month Header
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: MediaQuery.withNoTextScaling(
              child: Text(
                selectedDate.year == DateTime.now().year
                    ? DateFormat('MMM').format(selectedDate).toUpperCase()
                    : DateFormat('MMM yyyy').format(selectedDate).toUpperCase(),
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.5,
                  color: theme.textTheme.titleLarge?.color,
                ),
              ),
            ),
          ),

          // Date Selection Row (Samsung Style)
          Semantics(
            label:
                "Selected Date: \${DateFormat('EEEE, MMMM d').format(selectedDate)}. \${(eventsMap[DateTime(selectedDate.year, selectedDate.month, selectedDate.day)]?.isNotEmpty ?? false) ? 'Has events' : 'No events'}",
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Row(
                children: [
                  Container(
                    width: 45,
                    height: 45,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white : Colors.black,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: MediaQuery.withNoTextScaling(
                      child: Text(
                        '${selectedDate.day}',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.black : Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      DateFormat('EEEE').format(selectedDate),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                        color: theme.textTheme.titleLarge?.color,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Spacer(),
                  Semantics(
                    button: true,
                    label: 'Set mood for the day',
                    child: GestureDetector(
                      onTap: () => _showMoodPicker(context, ref, selectedDate),
                      child: Consumer(
                        builder: (context, ref, _) {
                          final moodMap = ref.watch(moodProvider);
                          final dateKey =
                              "${selectedDate.year}-${selectedDate.month}-${selectedDate.day}";
                          final mood = moodMap[dateKey];

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              if (mood != null)
                                Text(
                                  mood.label,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? Colors.white38
                                        : Colors.grey[400],
                                  ),
                                ),
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: mood != null
                                    ? BoxDecoration(
                                        color: isDark
                                            ? Colors.white.withValues(
                                                alpha: 0.05,
                                              )
                                            : Colors.grey[100],
                                        shape: BoxShape.circle,
                                      )
                                    : null,
                                child: mood != null
                                    ? Text(
                                        mood.emoji,
                                        style: const TextStyle(fontSize: 24),
                                      )
                                    : Icon(
                                        Icons.sentiment_satisfied_alt_outlined,
                                        size: 28,
                                        color: isDark
                                            ? Colors.white54
                                            : Colors.grey[600],
                                      ),
                              ),
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

          Expanded(
            child: Stack(
              children: [
                PageView.builder(
                  controller: _pageController,
                  onPageChanged: _onPageChanged,
                  itemBuilder: (context, index) {
                    final date = _baseDate.add(
                      Duration(days: index - _basePage),
                    );
                    final dayKey = DateTime(date.year, date.month, date.day);
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
                                  top: MediaQuery.of(context).padding.top + 40,
                                ),
                                child: AddEventScreen(
                                  initialDate: selectedDate,
                                ),
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
                                  ? Colors.grey[900]!.withValues(alpha: 0.8)
                                  : Colors.grey[100]!.withValues(alpha: 0.8),
                              borderRadius: BorderRadius.circular(30),
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
                                top: MediaQuery.of(context).padding.top + 40,
                              ),
                              child: AddEventScreen(initialDate: selectedDate),
                            ),
                          );
                        },
                        backgroundColor: isDark ? Colors.white : Colors.black,
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

  void _showMoodPicker(BuildContext context, WidgetRef ref, DateTime date) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(
              'Mood of the day',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: theme.textTheme.titleLarge?.color,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'How are you feeling today?',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 350,
              child: GridView.builder(
                padding: const EdgeInsets.only(bottom: 20),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: 20,
                  crossAxisSpacing: 16,
                  childAspectRatio: 0.85,
                ),
                itemCount: availableMoods.length,
                itemBuilder: (context, index) {
                  final mood = availableMoods[index];
                  return InkWell(
                    onTap: () {
                      ref.read(moodProvider.notifier).setMood(date, mood);
                      Navigator.pop(context);
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(mood.emoji, style: const TextStyle(fontSize: 32)),
                        const SizedBox(height: 8),
                        Text(
                          mood.label,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: theme.textTheme.bodyMedium?.color,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
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

  void _syncPageController(DateTime selectedDate) {
    if (_pageController.hasClients) {
      final targetPage = _basePage + selectedDate.difference(_baseDate).inDays;
      if (_pageController.page?.round() != targetPage) {
        _pageController.animateToPage(
          targetPage,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    }
  }
}
