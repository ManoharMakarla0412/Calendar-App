# Task: Finalize Create Event Screen Functionality

The goal is to ensure every option on the "Create Event" screen is fully functional, including the newly requested Time Zone (GMT) dropdown.

## Status: Pending

## Subtasks
- [ ] **Fix Analysis Errors**: Run `flutter analyze` and fix any issues in `lib/models/event.dart` or `lib/screens/add_event_screen.dart`. <!-- id: 1 -->
- [ ] **Add Permissions**: Update `android/app/src/main/AndroidManifest.xml` and `ios/Runner/Info.plist` (if applicable) to support: <!-- id: 2 -->
    - Contacts (Read)
    - Camera/Gallery (Read Media/Images)
- [ ] **Implement Time Zone Picker**: <!-- id: 3 -->
    - Add `timezone` package initialization in `main.dart`.
    - Create a Time Zone selection logic in `AddEventScreen`.
    - Ensure it displays GMT offsets correctly.
- [ ] **Verify & Polish**: <!-- id: 4 -->
    - Ensure "Save" logic persists all new fields correctly.
    - Check UI alignment and aesthetics.

## User Review Required
> Please check the plan. I will specifically focus on making the "Time Zone" row clickable and functional, allowing you to search or select from a list of time zones with GMT offsets.
