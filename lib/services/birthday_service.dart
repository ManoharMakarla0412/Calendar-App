import 'package:flutter_contacts/flutter_contacts.dart' as contacts;
import '../models/event.dart';

class BirthdayService {
  Future<List<Event>> fetchBirthdays() async {
    if (await contacts.FlutterContacts.requestPermission()) {
      final contactList = await contacts.FlutterContacts.getContacts(withProperties: true);
      final List<Event> birthdayEvents = [];

      for (var contact in contactList) {
        if (contact.events.any((e) => e.label == contacts.EventLabel.birthday)) {
          final birthdayEvent = contact.events.firstWhere((e) => e.label == contacts.EventLabel.birthday);
          if (birthdayEvent.year != null || (birthdayEvent.month != 0 && birthdayEvent.day != 0)) {
            final now = DateTime.now();
            final year = birthdayEvent.year ?? now.year;
            final birthday = DateTime(year, birthdayEvent.month, birthdayEvent.day);
            
            birthdayEvents.add(Event(
              id: 'birthday_${contact.id}',
              title: "${contact.displayName}'s Birthday",
              startTime: DateTime(birthday.year, birthday.month, birthday.day, 0, 0),
              endTime: DateTime(birthday.year, birthday.month, birthday.day, 23, 59),
              isAllDay: true,
              color: EventColor.personal,
              notes: "Source: Contacts",
              recurrence: const RecurrenceRule(type: RecurrenceType.yearly),
            ));
          }
        }
      }
      return birthdayEvents;
    }
    return [];
  }
}
