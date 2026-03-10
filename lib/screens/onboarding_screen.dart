import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import '../providers/settings_provider.dart';
import '../features/events/presentation/events_view_model.dart';
import '../services/birthday_service.dart';
import '../services/notification_service.dart';
import 'main_screen.dart';
import 'permissions_screen.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  
  bool _calendarGranted = false;
  bool _contactsGranted = false;
  bool _notificationGranted = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    await NotificationService().init();
    // In a real app, you would check permission status here using `flutter_local_notifications` methods or `permission_handler`
  }

  void _nextPage() {
    if (_currentPage < 2) {
      _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    } else {
      ref.read(settingsProvider.notifier).setOnboardingCompleted(true);
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const PermissionsScreen(isFromOnboarding: true)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: () {
                  ref.read(settingsProvider.notifier).setOnboardingCompleted(true);
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const PermissionsScreen(isFromOnboarding: true)),
                  );
                },
                child: const Text('Skip'),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(), // Force user to click Next
                onPageChanged: (page) => setState(() => _currentPage = page),
                children: [
                   _buildWelcomeStep(),
                   _buildFeaturesStep(),
                   _buildReadyStep(),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Indicators
                  Row(
                    children: List.generate(3, (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: _currentPage == index ? 24 : 8,
                      height: 8,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color: _currentPage == index ? Theme.of(context).primaryColor : Colors.grey.withValues(alpha: 0.3),
                      ),
                    )),
                  ),
                  ElevatedButton(
                    onPressed: _nextPage,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(_currentPage == 2 ? 'GET STARTED' : 'NEXT'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeStep() {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset('assets/icon/icon.png', width: 100, height: 100, errorBuilder: (c,e,s) => const Icon(Icons.calendar_today_rounded, size: 100, color: Colors.blue)),
          const SizedBox(height: 48),
          Text(
            'Welcome to\nClearDay',
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, height: 1.2, color: theme.textTheme.headlineLarge?.color),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          const Text(
            'Your beautifully organized schedule, simplified. Manage events, tasks, and birthdays in one place.',
            style: TextStyle(fontSize: 16, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }


  Widget _buildFeaturesStep() {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.widgets, size: 80, color: Colors.purple),
           const SizedBox(height: 32),
          Text(
            'Powerful Features',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: theme.textTheme.headlineLarge?.color),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          _buildFeatureRow(Icons.view_agenda, 'Multiple Views', 'Day, Week, Month, and Agenda views.'),
          const SizedBox(height: 16),
          _buildFeatureRow(Icons.color_lens, 'Customizable', 'Themes, colors, and layout options.'),
          const SizedBox(height: 16),
          _buildFeatureRow(Icons.repeat, 'Recurring Events', 'Flexible rules for repeating tasks.'),
        ],
      ),
    );
  }

  Widget _buildFeatureRow(IconData icon, String title, String desc) {
    return Row(
      children: [
        Icon(icon, color: Colors.purple, size: 24),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text(desc, style: const TextStyle(color: Colors.grey, fontSize: 14)),
            ],
          ),
        )
      ],
    );
  }

  Widget _buildReadyStep() {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.check_rounded, size: 80, color: theme.primaryColor),
          ),
          const SizedBox(height: 48),
          Text(
            "You're All Set!",
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: theme.textTheme.headlineLarge?.color),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          const Text(
            'Your calendar is ready. Start adding events or sync to see your schedule fill up.',
            style: TextStyle(fontSize: 16, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
