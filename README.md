# ClearDay Calendar App

A premium, modern Calendar application built with Flutter, Riverpod, and clean MVVM architecture.

## Recent Updates & Refactoring

### 1. Architecture & State Management (Phase 2)
- **MVVM Refactoring:** Transitioned from a simple `Notifier` to a robust MVVM architecture comprising `EventRepository` (data layer) and `EventsViewModel` (presentation layer). This ensures a clean separation of concerns and improves testability.
- **State Management:** Implemented `flutter_riverpod` for precise, granular state reactivity across events, moods, and settings.
- **Dependency Injection:** Created specific providers (e.g., `eventRepositoryProvider`, `notificationServiceProvider`) to allow easy substitution of mock implementations during testing.

### 2. Performance & Accessibility
- **Render Optimization:** Strategically placed `RepaintBoundary` around computation-heavy components like `TableCalendar` and `MultiDayTimetable` to prevent unnecessary widget tree repaints on scrolling or date selection.
- **Accessibility Guarantee:** Designed with VoiceOver/TalkBack in mind. Hand-applied `Semantics` tags to all complex visual components (event pills, month chips, day cells) ensuring screen reader users get clear descriptions like "Event: Standup Meeting. 10:00 AM".

### 3. UI Refinement and Professionalism (Phase 1)
- **Responsive Typography:** Ensured `MediaQuery.withNoTextScaling` wraps our highly customized, mathematically scaled fonts based on the user's base font size (`fs`). Fixed the text overflow/cut-off issue across event pills with proper `maxLines: 1` and `TextOverflow.ellipsis`.
- **Premium Empty States & UI Handling:** Introduced `PremiumEmptyState` illustrations for "no events" or "no agenda", replacing generic placeholders. Upgraded error and validation messages utilizing a new `SnackbarHelpers` utility.
- **Fluid Navigation:** Refactored the core views structure. Traded a static `IndexedStack` (which led to a nasty `Duplicate GlobalKey` bug) for a performant `PageTransitionSwitcher` giving smooth `FadeThroughTransition` transitions on every tab navigation.
- **Polished Splash Experience:** Created an introductory animated `SplashScreen` using implicit and explicit animations (fade, scale, and text slide up) that evaluates the user state before gracefully navigating seamlessly to Onboarding or the Main screen. 

## Setup Instructions
1. **Prerequisites**:
   - Flutter SDK (`>=3.6.0`)
   - Dart SDK
   - A compatible IDE (VS Code, Android Studio, Xcode)
2. **Installation**:
   - Clone the repository: 
     ```bash
     git clone https://github.com/abhi012211/Calendar-App.git
     ```
   - Navigate to the project directory: 
     ```bash
     cd calender_app-Qzene
     ```
   - Install dependencies: 
     ```bash
     flutter pub get
     ```
3. **Run the App**:
   - Launch on an emulator or connected device: 
     ```bash
     flutter run
     ```

## Explanation of Fixes
- **Inconsistent Font Size in Month View**: Fixed by using responsive design properties (`fs * baseSize`) combined with `MediaQuery.withNoTextScaling` instead of hardcoded `width`/`height` constraints on the event pills. Standardized disabled and holiday condition cells via specific `TableCalendar` builders.
- **Event Text Cut-off Issue**: Implemented `maxLines: 1` and `TextOverflow.ellipsis` on text nodes within the compact month pills to keep the UI clean and prevent layout overflows. Users can access the full details by tapping the event card.
- **`Duplicate GlobalKey` Errors**: Unwrapped the `IndexedStack` widget, which aggressively retained children during rapid tab switches, and replaced it cleanly with `PageTransitionSwitcher` combined with targeted keys.
- **Architecture**: Transitioned monolithic logic away from UI files into a dedicated `EventsViewModel` and `EventRepository`, maintaining synchronous predictable state while simplifying widget trees.

## Assumptions Made
- **Storage Priority**: Assumed the app currently relies primarily on robust local storage/caching via `SharedPreferences` as its single source of truth, integrating conditionally with the native `device_calendar`.
- **User Demographics**: Assumed the target userbase requires high accessibility and inclusive design, justifying the dedicated investment into `Semantics` tags and rigid text scale overrides rather than prioritizing pure aesthetics.
- **Hardware Profile**: Assumed deployment across vastly different form factors and potential lower-end devices, justifying the deliberate use of `RepaintBoundary` wrappers to ensure the app maintains a silky 60FPS consistently when scrolling massive grid structures.
