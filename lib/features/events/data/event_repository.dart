import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_calendar/device_calendar.dart' as device_cal;
import '../../../../models/event.dart';

abstract class EventRepository {
  Future<List<Event>> getLocalEvents();
  Future<void> saveLocalEvents(List<Event> events);
  Future<List<Event>> getDeviceEvents(DateTime startDate, DateTime endDate);
  Future<bool> requestDeviceCalendarPermissions();
}

class EventRepositoryImpl implements EventRepository {
  final device_cal.DeviceCalendarPlugin _deviceCalendarPlugin;
  final String _cacheKey = 'events_cache';

  EventRepositoryImpl({device_cal.DeviceCalendarPlugin? plugin})
    : _deviceCalendarPlugin = plugin ?? device_cal.DeviceCalendarPlugin();

  @override
  Future<List<Event>> getLocalEvents() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? cachedData = prefs.getString(_cacheKey);
      if (cachedData == null) return [];

      final List<dynamic> jsonList = jsonDecode(cachedData);
      return jsonList
          .map((j) => Event.fromJson(j))
          .where((e) => !e.id.startsWith('dev_'))
          .toList();
    } catch (e) {
      debugPrint('Error loading events cache: $e');
      return [];
    }
  }

  @override
  Future<void> saveLocalEvents(List<Event> events) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userEvents = events.where((e) => !e.id.startsWith('dev_')).toList();
      final String jsonData = jsonEncode(
        userEvents.map((e) => e.toJson()).toList(),
      );
      await prefs.setString(_cacheKey, jsonData);
    } catch (e) {
      debugPrint('Error saving events cache: $e');
    }
  }

  @override
  Future<bool> requestDeviceCalendarPermissions() async {
    var permissionsGranted = await _deviceCalendarPlugin.hasPermissions();
    bool hasPermission =
        permissionsGranted.isSuccess && (permissionsGranted.data ?? false);

    if (!hasPermission) {
      permissionsGranted = await _deviceCalendarPlugin.requestPermissions();
      hasPermission =
          permissionsGranted.isSuccess && (permissionsGranted.data ?? false);
    }
    return hasPermission;
  }

  @override
  Future<List<Event>> getDeviceEvents(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final hasPermission = await requestDeviceCalendarPermissions();
      if (!hasPermission) return [];

      final calendarsResult = await _deviceCalendarPlugin.retrieveCalendars();
      if (!calendarsResult.isSuccess || calendarsResult.data == null) {
        return [];
      }

      final calendars = calendarsResult.data!;
      if (calendars.isEmpty) return [];

      final List<Event> allDeviceEvents = [];
      final futures = calendars.where((c) => c.id != null).map((
        calendar,
      ) async {
        try {
          final eventsResult = await _deviceCalendarPlugin.retrieveEvents(
            calendar.id,
            device_cal.RetrieveEventsParams(
              startDate: startDate,
              endDate: endDate,
            ),
          );

          if (eventsResult.isSuccess && eventsResult.data != null) {
            return eventsResult.data!
                .map(
                  (dEvent) => _mapDeviceEventToAppEvent(dEvent, calendar.color),
                )
                .where((e) => e != null)
                .cast<Event>()
                .toList();
          }
        } catch (e) {
          debugPrint('Sync Error for \${calendar.name}: $e');
        }
        return <Event>[];
      });

      final results = await Future.wait(futures);
      for (var list in results) {
        allDeviceEvents.addAll(list);
      }
      return allDeviceEvents;
    } catch (e) {
      debugPrint("Sync Exception: $e");
      return [];
    }
  }

  Event? _mapDeviceEventToAppEvent(
    device_cal.Event dEvent,
    int? calendarColor,
  ) {
    if (dEvent.eventId == null || dEvent.start == null || dEvent.end == null)
      return null;

    String? organizer;
    if (dEvent.attendees != null) {
      for (var a in dEvent.attendees!) {
        if (a?.isOrganiser == true) {
          organizer = a?.emailAddress ?? a?.name;
          break;
        }
      }
    }

    final start = dEvent.start!;
    final end = dEvent.end!;
    final localStart = DateTime(
      start.year,
      start.month,
      start.day,
      start.hour,
      start.minute,
      start.second,
    );
    final localEnd = DateTime(
      end.year,
      end.month,
      end.day,
      end.hour,
      end.minute,
      end.second,
    );

    return Event(
      id: 'dev_\${dEvent.eventId}',
      title: dEvent.title ?? 'No Title',
      startTime: localStart,
      endTime: localEnd,
      isAllDay: dEvent.allDay ?? false,
      color: EventColor.social,
      customColor: calendarColor != null ? Color(calendarColor) : null,
      location: dEvent.location,
      notes: dEvent.description,
      organizer: organizer,
      attendees: dEvent.attendees
          ?.map((a) => a?.emailAddress ?? a?.name ?? '')
          .where((s) => s.isNotEmpty)
          .toList(),
      timeZone: dEvent.start?.timeZoneName,
    );
  }
}
