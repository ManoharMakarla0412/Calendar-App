import '../models/event.dart';

class RecurrenceUtils {
  static List<Event> generateOccurrences(Event event, {DateTime? rangeStart, DateTime? rangeEnd}) {
    if (!event.recurrence.isRecurring) return [event];

    final List<Event> instances = [];
    final DateTime baseStart = event.startTime;
    final DateTime baseEnd = event.endTime;
    final Duration duration = baseEnd.difference(baseStart);
    final RecurrenceRule rule = event.recurrence;
    final int interval = rule.interval > 0 ? rule.interval : 1;

    // Limit to 2 years by default if no end range is provided to prevent extreme memory usage
    rangeEnd ??= baseStart.add(const Duration(days: 365 * 2));

    DateTime currentCheck = baseStart;
    int count = 0;
    int safetyCounter = 0;
    const int maxInstances = 1000; // Safety limit for total instances

    while (safetyCounter < 10000) { // Limit total iterations
      safetyCounter++;

      // Check termination conditions
      if (rule.endType == RecurrenceEndType.onDate && 
          rule.endDate != null && 
          currentCheck.isAfter(rule.endDate!)) {
        break;
      }

      if (rule.endType == RecurrenceEndType.afterCount && 
          rule.count != null && 
          count >= rule.count!) {
        break;
      }

      if (currentCheck.isAfter(rangeEnd)) {
        break;
      }

      // Check if currentCheck matches the pattern
      if (_matchesRecurrence(currentCheck, baseStart, rule)) {
        instances.add(event.copyWith(
          id: '${event.id}_$count',
          startTime: currentCheck,
          endTime: currentCheck.add(duration),
          recurrenceGroupId: event.id,
        ));
        count++;
        
        if (count >= maxInstances) break;
      }

      // Optimized Incrementation
      switch (rule.type) {
        case RecurrenceType.daily:
          currentCheck = currentCheck.add(Duration(days: interval));
          break;
        case RecurrenceType.weekly:
          // If we have specific days of week, we still need to check daily but can skip large intervals
          if (rule.daysOfWeek != null && rule.daysOfWeek!.isNotEmpty) {
             currentCheck = currentCheck.add(const Duration(days: 1));
             // Optimization: If we just finished a week and the next day is in a different interval block
             // This is complex, so for now daily increments with internal check is safer but slower.
             // Let's stick to simple increments but add more safety.
          } else {
             currentCheck = currentCheck.add(Duration(days: 7 * interval));
          }
          break;
        case RecurrenceType.monthly:
           if (rule.daysOfMonth != null && rule.daysOfMonth!.isNotEmpty) {
             currentCheck = currentCheck.add(const Duration(days: 1));
           } else {
              currentCheck = DateTime(currentCheck.year, currentCheck.month + interval, currentCheck.day, currentCheck.hour, currentCheck.minute);
           }
          break;
        case RecurrenceType.yearly:
           if ((rule.monthsOfYear != null && rule.monthsOfYear!.isNotEmpty) || (rule.daysOfMonth != null && rule.daysOfMonth!.isNotEmpty)) {
              currentCheck = currentCheck.add(const Duration(days: 1));
           } else {
              currentCheck = DateTime(currentCheck.year + interval, currentCheck.month, currentCheck.day, currentCheck.hour, currentCheck.minute);
           }
          break;
        default:
          return instances;
      }
    }

    return instances;
  }

  static bool _matchesRecurrence(DateTime current, DateTime base, RecurrenceRule rule) {
    if (current.isBefore(base)) return false;

    final interval = rule.interval > 0 ? rule.interval : 1;

    switch (rule.type) {
      case RecurrenceType.daily:
        final diffDays = current.difference(DateTime(base.year, base.month, base.day)).inDays;
        return diffDays % interval == 0;

      case RecurrenceType.weekly:
        // Week check
        DateTime baseMonday = base.subtract(Duration(days: base.weekday - 1));
        DateTime currentMonday = current.subtract(Duration(days: current.weekday - 1));
        final diffWeeks = (currentMonday.difference(baseMonday).inDays / 7).round();
        if (diffWeeks % interval != 0) return false;

        // Day check
        if (rule.daysOfWeek != null && rule.daysOfWeek!.isNotEmpty) {
          return rule.daysOfWeek!.contains(current.weekday);
        }
        return current.weekday == base.weekday;

      case RecurrenceType.monthly:
        // Month check
        final diffMonths = (current.year - base.year) * 12 + (current.month - base.month);
        if (diffMonths % interval != 0) return false;

        // Day check
        if (rule.daysOfMonth != null && rule.daysOfMonth!.isNotEmpty) {
          return rule.daysOfMonth!.contains(current.day);
        }
        return current.day == base.day;

      case RecurrenceType.yearly:
        // Year check
        final diffYears = current.year - base.year;
        if (diffYears % interval != 0) return false;

        // Month check
        if (rule.monthsOfYear != null && rule.monthsOfYear!.isNotEmpty) {
          if (!rule.monthsOfYear!.contains(current.month)) return false;
        } else {
          if (current.month != base.month) return false;
        }

        // Day check
        if (rule.daysOfMonth != null && rule.daysOfMonth!.isNotEmpty) {
          return rule.daysOfMonth!.contains(current.day);
        }
        return current.day == base.day;

      default:
        return false;
    }
  }
}
