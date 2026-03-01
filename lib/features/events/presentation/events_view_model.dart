import 'dart:async';
import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:device_calendar/device_calendar.dart' as device_cal;

import '../../../../models/event.dart';
import '../../../../services/notification_service.dart';
import '../../../../services/holiday_service.dart';
import '../../../../utils/recurrence_utils.dart';
import '../../../../providers/settings_provider.dart';
import '../data/event_repository.dart';

final notificationServiceProvider = Provider((ref) => NotificationService());

final deviceCalendarsProvider = FutureProvider<List<device_cal.Calendar>>((
  ref,
) async {
  final plugin = device_cal.DeviceCalendarPlugin();
  final permissionsGranted = await plugin.hasPermissions();
  if (permissionsGranted.isSuccess && (permissionsGranted.data ?? false)) {
    final calendarsResult = await plugin.retrieveCalendars();
    if (calendarsResult.isSuccess && calendarsResult.data != null) {
      return calendarsResult.data!;
    }
  }
  return [];
});

final eventRepositoryProvider = Provider<EventRepository>((ref) {
  return EventRepositoryImpl();
});

class EventsViewModel extends Notifier<LinkedHashMap<DateTime, List<Event>>> {
  late EventRepository _repository;
  bool _isSyncing = false;
  bool get isSyncing => _isSyncing;
  Timer? _syncTimer;

  @override
  LinkedHashMap<DateTime, List<Event>> build() {
    _repository = ref.watch(eventRepositoryProvider);
    _init();
    return LinkedHashMap<DateTime, List<Event>>(
      equals: isSameDay,
      hashCode: getHashCode,
    );
  }

  Future<void> _init() async {
    await _loadFromCache();
    await fetchDeviceEvents();
    _startSyncTimer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      WidgetsBinding.instance.addObserver(_LifecycleObserver(this));
    });
  }

  void _startSyncTimer() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (!_isSyncing) fetchDeviceEvents();
    });
  }

  void _stopSyncTimer() {
    _syncTimer?.cancel();
    _syncTimer = null;
  }

  Future<void> _loadFromCache() async {
    final cachedEvents = await _repository.getLocalEvents();
    final newState = LinkedHashMap<DateTime, List<Event>>(
      equals: isSameDay,
      hashCode: getHashCode,
    );
    for (var event in cachedEvents) {
      final date = DateTime(
        event.startTime.year,
        event.startTime.month,
        event.startTime.day,
      );
      if (newState[date] == null) newState[date] = [];
      newState[date]!.add(event);
    }
    state = newState;
  }

  Future<void> _saveToCache() async {
    final allEvents = state.values.expand((e) => e).toList();
    await _repository.saveLocalEvents(allEvents);
  }

  Future<bool> fetchDeviceEvents() async {
    if (_isSyncing) return false;
    _isSyncing = true;

    try {
      final now = DateTime.now();
      final startDate = now.subtract(const Duration(days: 120));
      final endDate = now.add(const Duration(days: 365));

      final deviceEvents = await _repository.getDeviceEvents(
        startDate,
        endDate,
      );

      final newState = LinkedHashMap<DateTime, List<Event>>(
        equals: isSameDay,
        hashCode: getHashCode,
      );

      final Set<String> existingEventKeys = {};

      // Keep User Events
      state.forEach((date, events) {
        for (var event in events) {
          if (!event.id.startsWith('dev_')) {
            if (newState[date] == null) newState[date] = [];
            newState[date]!.add(event);
            existingEventKeys.add(
              '\${event.id}_\${event.startTime.millisecondsSinceEpoch}',
            );
          }
        }
      });

      // Add Device Events
      for (var event in deviceEvents) {
        final key = '\${event.id}_\${event.startTime.millisecondsSinceEpoch}';
        if (!existingEventKeys.contains(key)) {
          final date = DateTime(
            event.startTime.year,
            event.startTime.month,
            event.startTime.day,
          );
          if (newState[date] == null) newState[date] = [];
          newState[date]!.add(event);
          existingEventKeys.add(key);
        }
      }

      state = newState;
      return true;
    } catch (e) {
      debugPrint("Sync Exception: $e");
      return false;
    } finally {
      _isSyncing = false;
    }
  }

  void addEvent(Event event) {
    if (event.recurrence.isRecurring) {
      final List<Event> instances = RecurrenceUtils.generateOccurrences(event);
      final newState = LinkedHashMap<DateTime, List<Event>>(
        equals: isSameDay,
        hashCode: getHashCode,
      );
      state.forEach((key, value) => newState[key] = List.from(value));

      for (var instance in instances) {
        final date = DateTime(
          instance.startTime.year,
          instance.startTime.month,
          instance.startTime.day,
        );
        if (newState[date] == null) newState[date] = [];
        newState[date]!.add(instance);
        for (var reminder in instance.reminders) {
          ref
              .read(notificationServiceProvider)
              .scheduleNotification(instance, reminder);
        }
      }
      state = newState;
    } else {
      final date = DateTime(
        event.startTime.year,
        event.startTime.month,
        event.startTime.day,
      );
      final newState = LinkedHashMap<DateTime, List<Event>>(
        equals: isSameDay,
        hashCode: getHashCode,
      );
      state.forEach((key, value) => newState[key] = List.from(value));

      if (newState[date] == null) newState[date] = [];
      newState[date]!.add(event);

      for (var reminder in event.reminders) {
        ref
            .read(notificationServiceProvider)
            .scheduleNotification(event, reminder);
      }
      state = newState;
    }
    _saveToCache();
  }

  void deleteEvent(
    Event event, {
    bool deleteAllInGroup = false,
    DateTime? deleteFromDate,
  }) {
    ref.read(notificationServiceProvider).cancelAllForEvent(event);

    final newState = LinkedHashMap<DateTime, List<Event>>(
      equals: isSameDay,
      hashCode: getHashCode,
    );
    state.forEach((key, value) => newState[key] = List.from(value));

    if (deleteAllInGroup && event.recurrenceGroupId != null) {
      newState.forEach((date, events) {
        events.removeWhere(
          (e) => e.recurrenceGroupId == event.recurrenceGroupId,
        );
      });
    } else {
      final date = DateTime(
        event.startTime.year,
        event.startTime.month,
        event.startTime.day,
      );
      if (newState[date] != null) {
        newState[date]!.removeWhere((e) => e.id == event.id);
      }
    }

    newState.removeWhere((key, value) => value.isEmpty);
    state = newState;
    _saveToCache();
  }

  void restoreEvent(Event event) {
    addEvent(event.copyWith(isDeleted: false, deletedAt: null));
  }

  Future<void> syncBirthdays(List<Event> birthdays) async {
    final newState = LinkedHashMap<DateTime, List<Event>>(
      equals: isSameDay,
      hashCode: getHashCode,
    );
    state.forEach((key, value) => newState[key] = List.from(value));

    final Set<String> existingIds = {};
    state.forEach((date, events) {
      for (var e in events) {
        existingIds.add(e.id);
      }
    });

    bool added = false;
    for (var birthday in birthdays) {
      if (!existingIds.contains(birthday.id)) {
        final date = DateTime(
          birthday.startTime.year,
          birthday.startTime.month,
          birthday.startTime.day,
        );
        if (newState[date] == null) newState[date] = [];
        newState[date]!.add(birthday);
        added = true;
      }
    }

    if (added) {
      state = newState;
      _saveToCache();
    }
  }
}

class _LifecycleObserver extends WidgetsBindingObserver {
  final EventsViewModel viewModel;
  _LifecycleObserver(this.viewModel);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      viewModel.fetchDeviceEvents();
      viewModel._startSyncTimer();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      viewModel._stopSyncTimer();
    }
  }
}

int getHashCode(DateTime key) {
  return key.day * 1000000 + key.month * 10000 + key.year;
}

final eventsProvider =
    NotifierProvider<EventsViewModel, LinkedHashMap<DateTime, List<Event>>>(() {
      return EventsViewModel();
    });

final holidayServiceProvider = Provider((ref) => HolidayService());

final filteredEventsProvider = Provider<LinkedHashMap<DateTime, List<Event>>>((
  ref,
) {
  final baseEvents = ref.watch(eventsProvider);
  final settings = ref.watch(settingsProvider);
  final holidayService = ref.watch(holidayServiceProvider);

  final newState = LinkedHashMap<DateTime, List<Event>>(
    equals: isSameDay,
    hashCode: getHashCode,
  );

  baseEvents.forEach((date, events) {
    newState[date] = List.from(events);
  });

  if (settings.showPublicHolidays ||
      settings.showReligiousHolidays ||
      settings.showSchoolHolidays) {
    final holidays = holidayService.getHolidays(
      countryCode: settings.holidayCountry,
      public: settings.showPublicHolidays,
      religious: settings.showReligiousHolidays,
      school: settings.showSchoolHolidays,
    );

    for (var holiday in holidays) {
      final date = DateTime(
        holiday.startTime.year,
        holiday.startTime.month,
        holiday.startTime.day,
      );
      if (newState[date] == null) newState[date] = [];

      if (!newState[date]!.any((e) => e.id == holiday.id)) {
        newState[date]!.add(holiday);
      }
    }
  }

  return newState;
});
