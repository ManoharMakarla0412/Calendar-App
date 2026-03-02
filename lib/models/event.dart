import 'package:flutter/material.dart';

// ─── COLOR CODING ───────────────────────────────────
enum EventColor {
  urgent(Color(0xFFE53935), 'Important/Urgent'),     // Red
  health(Color(0xFF1E88E5), 'Health/Medical'),        // Blue
  bills(Color(0xFF43A047), 'Money/Bills'),             // Green
  social(Color(0xFFFDD835), 'Social'),                 // Yellow
  family(Color(0xFF8E24AA), 'Family'),                 // Purple
  low(Color(0xFF9E9E9E), 'Low Priority'),              // Gray
  personal(Color(0xFFFF4081), 'Personal'),             // Pink
  work(Color(0xFFFB8C00), 'Work');                     // Orange

  final Color color;
  final String label;
  const EventColor(this.color, this.label);
}

// ─── RECURRENCE ─────────────────────────────────────
enum RecurrenceType { none, daily, weekly, monthly, yearly }

enum RecurrenceEndType { never, afterCount, onDate }

class RecurrenceRule {
  final RecurrenceType type;
  final RecurrenceEndType endType;
  final int interval;           // e.g. "Every 2 weeks" -> 2
  final List<int>? daysOfWeek;  // 1=Mon, 7=Sun, only for Weekly
  final List<int>? daysOfMonth; // 1-31, for Monthly
  final List<int>? monthsOfYear; // 1-12, for Yearly
  
  final int? count;           // For afterCount
  final DateTime? endDate;    // For onDate

  const RecurrenceRule({
    this.type = RecurrenceType.none,
    this.endType = RecurrenceEndType.never,
    this.interval = 1,
    this.daysOfWeek,
    this.daysOfMonth,
    this.monthsOfYear,
    this.count,
    this.endDate,
  });

  bool get isRecurring => type != RecurrenceType.none;

  String get displayLabel {
    if (!isRecurring) return 'Does not repeat';
    
    String intervalPrefix = interval > 1 ? 'Every $interval ' : 'Every ';
    String base = switch (type) {
      RecurrenceType.daily => interval > 1 ? 'days' : 'day',
      RecurrenceType.weekly => interval > 1 ? 'weeks' : 'week',
      RecurrenceType.monthly => interval > 1 ? 'months' : 'month',
      RecurrenceType.yearly => interval > 1 ? 'years' : 'year',
      _ => '',
    };
    
    String weekdayStr = '';
    if (type == RecurrenceType.weekly && daysOfWeek != null && daysOfWeek!.isNotEmpty) {
      if (daysOfWeek!.length == 7) {
        weekdayStr = '';
      } else {
        final days = daysOfWeek!.map((d) => _getWeekdayShort(d)).join(', ');
        weekdayStr = ' on $days';
      }
    }

    String monthDayStr = '';
    if (type == RecurrenceType.monthly && daysOfMonth != null && daysOfMonth!.isNotEmpty) {
      monthDayStr = ' on day ${daysOfMonth!.join(', ')}';
    }

    String yearStr = '';
    if (type == RecurrenceType.yearly && monthsOfYear != null && monthsOfYear!.isNotEmpty) {
      final months = monthsOfYear!.map((m) => _getMonthShort(m)).join(', ');
      final days = (daysOfMonth != null && daysOfMonth!.isNotEmpty) 
          ? ' on ${daysOfMonth!.join(', ')}' 
          : '';
      yearStr = ' in $months$days';
    }

    String end = switch (endType) {
      RecurrenceEndType.never => '',
      RecurrenceEndType.afterCount => ', ${count ?? 0} times',
      RecurrenceEndType.onDate => endDate != null
          ? ', until ${endDate!.month}/${endDate!.day}/${endDate!.year}'
          : '',
    };
    
    return '$intervalPrefix$base$weekdayStr$monthDayStr$yearStr$end';
  }

  String _getMonthShort(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    if (month >= 1 && month <= 12) return months[month - 1];
    return '';
  }
  
  // Also provide a toString useful for UI
  @override
  String toString() => displayLabel;
  
  String _getWeekdayShort(int day) {
    const days = ['Mon', 'Tue', 'Wen', 'Thu', 'Fri', 'Sat', 'Sun'];
    if (day >= 1 && day <= 7) return days[day - 1];
    return '';
  }

  RecurrenceRule copyWith({
    RecurrenceType? type,
    RecurrenceEndType? endType,
    int? interval,
    List<int>? daysOfWeek,
    List<int>? daysOfMonth,
    List<int>? monthsOfYear,
    int? count,
    DateTime? endDate,
  }) {
    return RecurrenceRule(
      type: type ?? this.type,
      endType: endType ?? this.endType,
      interval: interval ?? this.interval,
      daysOfWeek: daysOfWeek ?? this.daysOfWeek,
      daysOfMonth: daysOfMonth ?? this.daysOfMonth,
      monthsOfYear: monthsOfYear ?? this.monthsOfYear,
      count: count ?? this.count,
      endDate: endDate ?? this.endDate,
    );
  }

  Map<String, dynamic> toJson() => {
    'type': type.index,
    'endType': endType.index,
    'interval': interval,
    'daysOfWeek': daysOfWeek,
    'daysOfMonth': daysOfMonth,
    'monthsOfYear': monthsOfYear,
    'count': count,
    'endDate': endDate?.toIso8601String(),
  };

  factory RecurrenceRule.fromJson(Map<String, dynamic> json) => RecurrenceRule(
    type: RecurrenceType.values[json['type'] as int],
    endType: RecurrenceEndType.values[json['endType'] as int],
    interval: json['interval'] as int? ?? 1,
    daysOfWeek: (json['daysOfWeek'] as List?)?.map((e) => e as int).toList(),
    daysOfMonth: (json['daysOfMonth'] as List?)?.map((e) => e as int).toList(),
    monthsOfYear: (json['monthsOfYear'] as List?)?.map((e) => e as int).toList(),
    count: json['count'] as int?,
    endDate: json['endDate'] != null ? DateTime.parse(json['endDate'] as String) : null,
  );
}

// ─── EVENT MODEL ────────────────────────────────────
// ─── AVAILABILITY & VISIBILITY ──────────────────────
enum EventAvailability { busy, free }
enum EventVisibility { initial, public, private }

// ─── EVENT MODEL ────────────────────────────────────
class Event {
  final String id;
  final String title;
  final DateTime startTime;
  final DateTime endTime;
  final bool isAllDay;
  final EventColor color;
  final String? location;
  final String? notes;
  final bool isDeleted;
  final DateTime? deletedAt;
  final List<Duration> reminders;
  final RecurrenceRule recurrence;
  final String? timeZone;         // null = floating (device TZ)
  final String? photoPath;        // local file path, max 10MB
  final String? recurrenceGroupId; // links recurring instances
  final DateTime? updatedAt;
  final String? url;
  final List<String>? attendees;
  final String? organizer;
  final Color? customColor; // Direct color from device calendar
  final String? emoji;
  final String? calendarId; // Added for calendar grouping
  final EventAvailability availability;
  final EventVisibility visibility;

  const Event({
    required this.id,
    required this.title,
    required this.startTime,
    required this.endTime,
    this.isAllDay = false,
    this.color = EventColor.low,
    this.location,
    this.notes,
    this.isDeleted = false,
    this.deletedAt,
    this.reminders = const [],
    this.recurrence = const RecurrenceRule(),
    this.timeZone,
    this.photoPath,
    this.recurrenceGroupId,
    this.updatedAt,
    this.url,
    this.attendees,
    this.organizer,
    this.customColor,
    this.emoji,
    this.calendarId,
    this.availability = EventAvailability.busy,
    this.visibility = EventVisibility.initial,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'startTime': startTime.toIso8601String(),
    'endTime': endTime.toIso8601String(),
    'isAllDay': isAllDay,
    'color': color.index,
    'location': location,
    'notes': notes,
    'isDeleted': isDeleted,
    'deletedAt': deletedAt?.toIso8601String(),
    'reminders': reminders.map((d) => d.inMinutes).toList(),
    'recurrence': recurrence.toJson(),
    'timeZone': timeZone,
    'photoPath': photoPath,
    'recurrenceGroupId': recurrenceGroupId,
    'updatedAt': updatedAt?.toIso8601String(),
    'url': url,
    'attendees': attendees,
    'organizer': organizer,
    'customColor': customColor?.toARGB32(),
    'emoji': emoji,
    'calendarId': calendarId,
    'availability': availability.index,
    'visibility': visibility.index,
  };

  factory Event.fromJson(Map<String, dynamic> json) => Event(
    id: json['id'] as String,
    title: json['title'] as String,
    startTime: DateTime.parse(json['startTime'] as String),
    endTime: DateTime.parse(json['endTime'] as String),
    isAllDay: json['isAllDay'] as bool,
    color: EventColor.values[json['color'] as int],
    location: json['location'] as String?,
    notes: json['notes'] as String?,
    isDeleted: json['isDeleted'] as bool,
    deletedAt: json['deletedAt'] != null ? DateTime.parse(json['deletedAt'] as String) : null,
    reminders: (json['reminders'] as List? ?? []).map((m) => Duration(minutes: m as int)).toList(),
    recurrence: RecurrenceRule.fromJson(json['recurrence'] as Map<String, dynamic>),
    timeZone: json['timeZone'] as String?,
    photoPath: json['photoPath'] as String?,
    recurrenceGroupId: json['recurrenceGroupId'] as String?,
    updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt'] as String) : null,
    url: json['url'] as String?,
    attendees: (json['attendees'] as List?)?.map((e) => e as String).toList(),
    organizer: json['organizer'] as String?,
    customColor: json['customColor'] != null ? Color(json['customColor'] as int) : null,
    emoji: json['emoji'] as String?,
    calendarId: json['calendarId'] as String?,
    availability: json['availability'] != null ? EventAvailability.values[json['availability'] as int] : EventAvailability.busy,
    visibility: json['visibility'] != null ? EventVisibility.values[json['visibility'] as int] : EventVisibility.initial,
  );

  Event copyWith({
    String? id,
    String? title,
    DateTime? startTime,
    DateTime? endTime,
    bool? isAllDay,
    EventColor? color,
    String? location,
    String? notes,
    bool? isDeleted,
    DateTime? deletedAt,
    List<Duration>? reminders,
    RecurrenceRule? recurrence,
    String? timeZone,
    String? photoPath,
    String? recurrenceGroupId,
    DateTime? updatedAt,
    String? url,
    List<String>? attendees,
    String? organizer,
    Color? customColor,
    String? emoji,
    String? calendarId,
    EventAvailability? availability,
    EventVisibility? visibility,
  }) {
    return Event(
      id: id ?? this.id,
      title: title ?? this.title,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      isAllDay: isAllDay ?? this.isAllDay,
      color: color ?? this.color,
      location: location ?? this.location,
      notes: notes ?? this.notes,
      isDeleted: isDeleted ?? this.isDeleted,
      deletedAt: deletedAt ?? this.deletedAt,
      reminders: reminders ?? this.reminders,
      recurrence: recurrence ?? this.recurrence,
      timeZone: timeZone ?? this.timeZone,
      photoPath: photoPath ?? this.photoPath,
      recurrenceGroupId: recurrenceGroupId ?? this.recurrenceGroupId,
      updatedAt: updatedAt ?? this.updatedAt,
      url: url ?? this.url,
      attendees: attendees ?? this.attendees,
      organizer: organizer ?? this.organizer,
      customColor: customColor ?? this.customColor,
      emoji: emoji ?? this.emoji,
      calendarId: calendarId ?? this.calendarId,
      availability: availability ?? this.availability,
      visibility: visibility ?? this.visibility,
    );
  }
}
