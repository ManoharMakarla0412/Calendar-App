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
