import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_colors.dart';

class OnboardingView extends StatefulWidget {
  final VoidCallback onComplete;
  const OnboardingView({super.key, required this.onComplete});

  @override
  State<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<OnboardingView> {
  final _pageController = PageController();
  int _currentPage = 0;

  final _pages = [
    _OnboardingPageData(
      icon: Icons.checklist_rounded,
      title: 'Smart Task Management',
      description: 'Create tasks naturally. Type "Buy groceries tomorrow at 5pm" and the app auto-fills date, time, category, and priority.',
      color: Color(0xFF007AFF),
    ),
    _OnboardingPageData(
      icon: Icons.timeline_rounded,
      title: 'Timeline View',
      description: 'See your day at a glance. Drag tasks between time slots to reschedule. Swipe to complete.',
      color: Color(0xFF4AC287),
    ),
    _OnboardingPageData(
      icon: Icons.auto_awesome_rounded,
      title: 'AI-Powered Productivity',
      description: 'Let AI break down goals into actionable tasks. Get a daily briefing. Smart suggestions for your best schedule.',
      color: Color(0xFFD4A831),
    ),
    _OnboardingPageData(
      icon: Icons.cloud_sync_rounded,
      title: 'Sync Across Devices',
      description: 'Sign in with Google or email. Your tasks sync instantly via Firebase. Never lose your data.',
      color: Color(0xFF5B78E6),
    ),
  ];

  Future<void> _complete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);
    widget.onComplete();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: page.color.withValues(alpha: 0.1),
                          ),
                          child: Icon(page.icon, size: 56, color: page.color),
                        ),
                        const SizedBox(height: 48),
                        Text(
                          page.title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          page.description,
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16, color: Colors.grey.shade500, height: 1.5),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(40),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _pages.length,
                      (i) => AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _currentPage == i ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          color: _currentPage == i ? _pages[_currentPage].color : Colors.grey.shade300,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: LinearGradient(
                          colors: [context.gradientPrimary, context.gradientSecondary],
                          begin: Alignment.topLeft, end: Alignment.bottomRight,
                        ),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _currentPage < _pages.length - 1
                              ? () => _pageController.nextPage(
                                  duration: const Duration(milliseconds: 300), curve: Curves.easeInOut)
                              : _complete,
                          borderRadius: BorderRadius.circular(20),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            child: Center(
                              child: Text(
                                _currentPage < _pages.length - 1 ? 'Next' : 'Get Started',
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingPageData {
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  const _OnboardingPageData({required this.icon, required this.title, required this.description, required this.color});
}
