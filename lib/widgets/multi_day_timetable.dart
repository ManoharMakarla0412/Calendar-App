import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/event.dart';
import '../screens/event_detail_screen.dart';
import '../theme/app_theme.dart';

class MultiDayTimetable extends StatefulWidget {
  final DateTime initialDate;
  final int numberOfDays;
  final List<Event> events;
  final double hourHeight;
  final Function(DateTime)? onDateTap;
  final bool showHeader;

  const MultiDayTimetable({
    super.key,
    required this.initialDate,
    required this.events,
    this.numberOfDays = 1,
    this.hourHeight = 60.0,
    this.onDateTap,
    this.showHeader = true,
  });

  @override
  State<MultiDayTimetable> createState() => _MultiDayTimetableState();
}

class _MultiDayTimetableState extends State<MultiDayTimetable> {
  final ScrollController _scrollController = ScrollController();
  final double _timeColumnWidth = 50.0; // Slightly narrower for overlay
  late Timer _timer;
  DateTime _currentTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    _currentTime = DateTime.now();
    // Update every minute to keep the red line perfectly synced
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (mounted) {
        setState(() {
          _currentTime = DateTime.now();
        });
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        // Scroll to current time
        final double scrollOffset =
            (_currentTime.hour * widget.hourHeight) +
            (_currentTime.minute / 60.0 * widget.hourHeight) -
            (widget.hourHeight * 2);
        _scrollController.jumpTo(
          scrollOffset.clamp(0.0, _scrollController.position.maxScrollExtent),
        );
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  List<Event> _getEventsForDay(DateTime day, {bool allDayOnly = false}) {
    return widget.events.where((e) {
      if (allDayOnly) return e.isAllDay && _isSameDay(e.startTime, day);
      return !e.isAllDay && _isSameDay(e.startTime, day);
    }).toList();
  }

  List<Widget> _buildEventWidgets(
    List<Event> dayEvents,
    double dayWidth,
    double hourHeight,
  ) {
    if (dayEvents.isEmpty) return [];
    dayEvents.sort((a, b) => a.startTime.compareTo(b.startTime));
    List<Widget> children = [];

    for (int i = 0; i < dayEvents.length; i++) {
      final event = dayEvents[i];
      final top =
          (event.startTime.hour * hourHeight) +
          (event.startTime.minute / 60.0 * hourHeight);
      final durationMin = event.endTime.difference(event.startTime).inMinutes;
      final height = (durationMin / 60.0) * hourHeight;

      List<Event> overlapping = dayEvents.where((e) {
        return e != event &&
            e.startTime.isBefore(event.endTime) &&
            e.endTime.isAfter(event.startTime);
      }).toList();

      double width = dayWidth;
      double left = 0.0;

      if (overlapping.isNotEmpty) {
        width = dayWidth * 0.85;
        if (overlapping.any((e) => e.startTime.isBefore(event.startTime))) {
          left = dayWidth * 0.15;
        }
      }

      children.add(
        Positioned(
          top: top,
          left: left,
          width: width,
          height: height < hourHeight * 0.4 ? hourHeight * 0.4 : height,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EventDetailScreen(event: event),
                ),
              ),
              borderRadius: BorderRadius.circular(12),
              splashColor: (event.customColor ?? event.color.color).withValues(
                alpha: 0.3,
              ),
              highlightColor: (event.customColor ?? event.color.color)
                  .withValues(alpha: 0.1),
              child: Container(
                margin: const EdgeInsets.only(left: 4, right: 1, bottom: 2),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: (event.customColor ?? event.color.color).withValues(
                    alpha: 0.15,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: (event.customColor ?? event.color.color).withValues(
                      alpha: 0.3,
                    ),
                    width: 1,
                  ),
                  boxShadow: Theme.of(context).brightness == Brightness.dark
                      ? null
                      : AppTheme.softShadows,
                ),
                child: ClipRect(
                  child: SingleChildScrollView(
                    physics: const NeverScrollableScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event.title,
                          style: TextStyle(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                ? Colors.white
                                : Colors.black87,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (height > 30)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              '${DateFormat('h:mm').format(event.startTime)} - ${DateFormat('h:mm').format(event.endTime)}',
                              style: TextStyle(
                                color:
                                    (Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? Colors.white
                                            : Colors.black87)
                                        .withValues(alpha: 0.6),
                                fontSize: 9,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }
    return children;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final days = List.generate(
      widget.numberOfDays,
      (index) => widget.initialDate.add(Duration(days: index)),
    );

    return Column(
      children: [
        if (widget.showHeader) _buildHeaderRow(days, theme),

        Expanded(
          child: SingleChildScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                // Specialized All-day events row
                if (widget.events.any((e) => e.isAllDay))
                  Container(
                    decoration: BoxDecoration(
                      color: theme.brightness == Brightness.dark
                          ? Colors.white.withValues(alpha: 0.02)
                          : Colors.black.withValues(alpha: 0.02),
                      border: Border(
                        bottom: BorderSide(
                          color: theme.dividerColor.withValues(alpha: 0.1),
                        ),
                      ),
                    ),
                    child: Stack(
                      children: [
                        Row(
                          children: days.map((day) {
                            final allDayEvents = _getEventsForDay(
                              day,
                              allDayOnly: true,
                            );
                            return Expanded(
                              child: Container(
                                constraints: const BoxConstraints(
                                  minHeight: 32,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 4,
                                ),
                                child: Column(
                                  children: allDayEvents
                                      .map(
                                        (e) => Material(
                                          color: Colors.transparent,
                                          child: InkWell(
                                            splashColor: Colors.white
                                                .withValues(alpha: 0.3),
                                            highlightColor: Colors.white
                                                .withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                            onTap: () => Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    EventDetailScreen(event: e),
                                              ),
                                            ),
                                            child: Container(
                                              width: double.infinity,
                                              margin: const EdgeInsets.fromLTRB(
                                                4,
                                                1,
                                                4,
                                                1,
                                              ),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 4,
                                                  ),
                                              decoration: BoxDecoration(
                                                color:
                                                    (e.customColor ??
                                                    e.color.color),
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                                boxShadow:
                                                    Theme.of(
                                                          context,
                                                        ).brightness ==
                                                        Brightness.dark
                                                    ? null
                                                    : AppTheme.softShadows,
                                              ),
                                              child: Text(
                                                e.title,
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w700,
                                                  shadows: [
                                                    Shadow(
                                                      color: Colors.black26,
                                                      offset: Offset(0, 1),
                                                      blurRadius: 1,
                                                    ),
                                                  ],
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ),
                                        ),
                                      )
                                      .toList(),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        Positioned(
                          left: 0,
                          top: 0,
                          bottom: 0,
                          child: Container(
                            width: _timeColumnWidth,
                            alignment: Alignment.center,
                            color: theme.scaffoldBackgroundColor.withValues(
                              alpha: 0.6,
                            ),
                            child: Text(
                              'ALL DAY',
                              style: TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.w900,
                                color: theme.colorScheme.primary,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                Stack(
                  children: [
                    Stack(
                      children: [
                        // Days Columns Spanning Full Width
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: days
                              .map(
                                (day) => Expanded(
                                  child: Stack(
                                    children: [
                                      // Horizontal Lines
                                      Column(
                                        children: List.generate(
                                          24,
                                          (hour) => Container(
                                            height: widget.hourHeight,
                                            decoration: BoxDecoration(
                                              border: Border(
                                                bottom: BorderSide(
                                                  color: theme.dividerColor
                                                      .withValues(alpha: 0.05),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      // Vertical Line (Left border of column)
                                      Container(
                                        height: widget.hourHeight * 24,
                                        decoration: BoxDecoration(
                                          border: Border(
                                            left: BorderSide(
                                              color: theme.dividerColor
                                                  .withValues(alpha: 0.05),
                                            ),
                                          ),
                                        ),
                                      ),
                                      // Events
                                      SizedBox(
                                        height: widget.hourHeight * 24,
                                        child: LayoutBuilder(
                                          builder: (context, constraints) {
                                            return Stack(
                                              children: _buildEventWidgets(
                                                _getEventsForDay(day),
                                                constraints.maxWidth,
                                                widget.hourHeight,
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                        // Overlaid Time Labels
                        IgnorePointer(
                          child: Column(
                            children: List.generate(24, (hour) {
                              return SizedBox(
                                height: widget.hourHeight,
                                child: Container(
                                  width: _timeColumnWidth,
                                  padding: const EdgeInsets.only(
                                    right: 6,
                                    top: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: theme.scaffoldBackgroundColor
                                        .withValues(alpha: 0.4),
                                  ),
                                  child: Text(
                                    hour == 0
                                        ? ''
                                        : (hour >= 12
                                              ? (hour == 12
                                                    ? '12PM'
                                                    : '${hour - 12}PM')
                                              : '$hour AM'),
                                    style: TextStyle(
                                      fontSize: 9,
                                      color: const Color(0xFF64748B),
                                      fontWeight: FontWeight.w600,
                                    ),
                                    textAlign: TextAlign.right,
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),
                      ],
                    ),

                    // Current Time Indicator (Red line spanning full width)
                    if (days.any((d) => _isSameDay(d, _currentTime)))
                      Positioned(
                        top:
                            (_currentTime.hour * widget.hourHeight) +
                            (_currentTime.minute / 60.0 * widget.hourHeight),
                        left: 0,
                        right: 0,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            // The Line
                            Container(
                              height: 1.5,
                              width: double.infinity,
                              color: Colors.red,
                            ),
                            // The Time Label (Overlaid)
                            Positioned(
                              left: 0,
                              top: -10,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  DateFormat('h:mm a').format(_currentTime),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            // Sleek Dot at the start
                            Positioned(
                              left: -2,
                              top: -3.5,
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
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderRow(List<DateTime> days, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: theme.brightness == Brightness.dark
                ? Colors.black.withValues(alpha: 0.2)
                : Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: days.map((day) {
          final isToday = _isSameDay(day, DateTime.now());
          return Expanded(
            child: InkWell(
              onTap: widget.onDateTap != null
                  ? () => widget.onDateTap!(day)
                  : null,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 8),
                  Text(
                    DateFormat('EEE').format(day).toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      color: isToday
                          ? theme.colorScheme.primary
                          : theme.textTheme.bodySmall?.color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: 32,
                    height: 32,
                    decoration: isToday
                        ? BoxDecoration(
                            color: theme.colorScheme.primary,
                            shape: BoxShape.circle,
                          )
                        : null,
                    alignment: Alignment.center,
                    child: Text(
                      DateFormat('d').format(day),
                      style: TextStyle(
                        fontSize: 16,
                        color: isToday
                            ? theme.colorScheme.onPrimary
                            : theme.textTheme.titleMedium?.color,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
