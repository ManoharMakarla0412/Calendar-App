// import 'dart:collection';
// import 'package:flutter_test/flutter_test.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:calendar_2026/models/event.dart';
// import 'package:calendar_2026/features/events/data/event_repository.dart';
// import 'package:calendar_2026/features/events/presentation/events_view_model.dart';
// import 'package:calendar_2026/services/notification_service.dart';
// import 'package:shared_preferences/shared_preferences.dart';

// class FakeNotificationService implements NotificationService {
//   @override
//   Future<void> init() async {}

//   @override
//   Future<bool> requestPermissions() async => true;

//   @override
//   Future<void> scheduleNotification(Event event, Duration leadTime) async {}

//   @override
//   Future<void> cancelAllForEvent(Event event) async {}
// }

// // Fake Repository to test ViewModel without platform channels
// class FakeEventRepository implements EventRepository {
//   List<Event> _localEvents = [];
//   bool devicePermission = true;

//   @override
//   Future<List<Event>> getDeviceEvents(
//     DateTime startDate,
//     DateTime endDate,
//   ) async {
//     if (!devicePermission) return [];
//     // Could simulate device events here
//     return [];
//   }

//   @override
//   Future<List<Event>> getLocalEvents() async {
//     return _localEvents;
//   }

//   @override
//   Future<bool> requestDeviceCalendarPermissions() async {
//     return devicePermission;
//   }

//   @override
//   Future<void> saveLocalEvents(List<Event> events) async {
//     _localEvents = List.from(events);
//   }
// }

// void main() {
//   TestWidgetsFlutterBinding.ensureInitialized();

//   late ProviderContainer container;
//   late FakeEventRepository fakeRepository;

//   setUp(() {
//     SharedPreferences.setMockInitialValues({});
//     fakeRepository = FakeEventRepository();

//     // Create a ProviderContainer that injects our Fake repository
//     container = ProviderContainer(
//       overrides: [
//         eventRepositoryProvider.overrideWithValue(fakeRepository),
//         notificationServiceProvider.overrideWithValue(
//           FakeNotificationService(),
//         ),
//       ],
//     );
//   });

//   tearDown(() {
//     container.dispose();
//   });

//   test('EventsViewModel initialization should be empty initially', () {
//     final state = container.read(eventsProvider);
//     expect(state, isA<LinkedHashMap<DateTime, List<Event>>>());
//     expect(state.isEmpty, true);
//   });

//   test(
//     'Adding an event should update the state and save to repository',
//     () async {
//       final viewModel = container.read(eventsProvider.notifier);

//       final event = Event(
//         id: 'test_1',
//         title: 'Meeting',
//         startTime: DateTime(2026, 3, 1, 10, 0),
//         endTime: DateTime(2026, 3, 1, 11, 0),
//         isAllDay: false,
//         color: EventColor.personal,
//       );

//       // Act
//       viewModel.addEvent(event);

//       // Assert State updated
//       final state = container.read(eventsProvider);
//       final dateKey = DateTime(2026, 3, 1);
//       expect(state.containsKey(dateKey), true);
//       expect(state[dateKey]!.length, 1);
//       expect(state[dateKey]!.first.title, 'Meeting');

//       // Due to the _saveToCache call happening without awaiting internally,
//       // we yield control to the event loop so the FakeRepo saves it.
//       await Future.delayed(Duration.zero);

//       final savedEvents = await fakeRepository.getLocalEvents();
//       expect(savedEvents.length, 1);
//       expect(savedEvents.first.id, 'test_1');
//     },
//   );

//   test('Deleting an event should remove it from state', () async {
//     final viewModel = container.read(eventsProvider.notifier);

//     final event = Event(
//       id: 'test_1',
//       title: 'Meeting',
//       startTime: DateTime(2026, 3, 1, 10, 0),
//       endTime: DateTime(2026, 3, 1, 11, 0),
//       isAllDay: false,
//       color: EventColor.personal,
//     );

//     viewModel.addEvent(event);

//     // Act
//     viewModel.deleteEvent(event);

//     // Assert
//     final state = container.read(eventsProvider);
//     final dateKey = DateTime(2026, 3, 1);
//     expect(state.containsKey(dateKey), false);
//   });
// }
