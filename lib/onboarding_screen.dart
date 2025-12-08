import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math' as math;

class OnboardingScreen extends StatefulWidget {
  final VoidCallback? onCompleted;

  const OnboardingScreen({super.key, this.onCompleted});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  late AnimationController _glowController;
  late AnimationController _rotateController;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _glowController.dispose();
    _rotateController.dispose();
    super.dispose();
  }

  final List<OnboardingPageData> _pages = [
    OnboardingPageData(
      title: 'Welcome to\nTea Leaf Weigher',
      description:
          'Next-generation smart tea leaf management with  analytics and real-time tracking.',
      icon: Icons.eco_outlined,
      gradient: const [Color(0xFF00F5FF), Color(0xFF00D4FF)],
    ),
    OnboardingPageData(
      title: 'Real-Time\nDashboard',
      description:
          'Advanced analytics with beautiful visualizations. Track performance, monitor trends, and make data-driven decisions.',
      icon: Icons.dashboard_outlined,
      gradient: const [Color(0xFF9D4EDD), Color(0xFF7B2CBF)],
    ),
    OnboardingPageData(
      title: 'Smart Payment\nCalculator',
      description:
          'Automated earnings calculation with instant payment tracking. Configure rates and monitor transactions effortlessly.',
      icon: Icons.payments_outlined,
      gradient: const [Color(0xFF00F5FF), Color(0xFF9D4EDD)],
    ),
    OnboardingPageData(
      title: 'Live Tracking\n& Management',
      description:
          'Real-time location tracking, comprehensive search, and complete fleet management at your fingertips.',
      icon: Icons.location_on_outlined,
      gradient: [Color(0xFF7B2CBF), Color(0xFF00F5FF)],
    ),
  ];

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);
    if (mounted) {
      // Call the callback to update parent state
      widget.onCompleted?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Futuristic Background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0A0E27),
                  Color(0xFF1a1f3a),
                  Color(0xFF0A0E27),
                ],
              ),
            ),
          ),

          // Animated circles
          AnimatedBuilder(
            animation: _rotateController,
            builder: (context, child) {
              return CustomPaint(
                painter: CirclesPainter(animation: _rotateController.value),
                size: Size.infinite,
              );
            },
          ),

          SafeArea(
            child: Column(
              children: [
                // Skip button
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: TextButton(
                      onPressed: _completeOnboarding,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        backgroundColor: const Color(
                          0xFF00F5FF,
                        ).withOpacity(0.1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: const Color(0xFF00F5FF).withOpacity(0.3),
                          ),
                        ),
                      ),
                      child: const Text(
                        'SKIP',
                        style: TextStyle(
                          color: Color(0xFF00F5FF),
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                  ),
                ),

                // PageView
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (int page) {
                      setState(() {
                        _currentPage = page;
                      });
                    },
                    itemCount: _pages.length,
                    itemBuilder: (context, index) {
                      return _buildPage(_pages[index], index);
                    },
                  ),
                ),

                // Dots indicator
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _pages.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        height: 8,
                        width: _currentPage == index ? 32 : 8,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          gradient: _currentPage == index
                              ? LinearGradient(colors: _pages[index].gradient)
                              : null,
                          color: _currentPage == index
                              ? null
                              : Colors.white.withOpacity(0.3),
                        ),
                      ),
                    ),
                  ),
                ),

                // Next/Get Started button
                Padding(
                  padding: const EdgeInsets.fromLTRB(32, 0, 32, 40),
                  child: AnimatedBuilder(
                    animation: _glowController,
                    builder: (context, child) {
                      return Container(
                        width: double.infinity,
                        height: 56,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(28),
                          gradient: LinearGradient(
                            colors: _pages[_currentPage].gradient,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: _pages[_currentPage].gradient[0]
                                  .withOpacity(0.4 * _glowController.value),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: () {
                            if (_currentPage == _pages.length - 1) {
                              _completeOnboarding();
                            } else {
                              _pageController.nextPage(
                                duration: const Duration(milliseconds: 400),
                                curve: Curves.easeInOut,
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28),
                            ),
                          ),
                          child: Text(
                            _currentPage == _pages.length - 1
                                ? 'GET STARTED'
                                : 'NEXT',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage(OnboardingPageData page, int index) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon with gradient and glow
          AnimatedBuilder(
            animation: _glowController,
            builder: (context, child) {
              return Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      page.gradient[0].withOpacity(0.2),
                      Colors.transparent,
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: page.gradient[0].withOpacity(
                        0.3 * _glowController.value,
                      ),
                      blurRadius: 40,
                      spreadRadius: 10,
                    ),
                  ],
                ),
                child: Center(
                  child: ShaderMask(
                    shaderCallback: (bounds) => LinearGradient(
                      colors: page.gradient,
                    ).createShader(bounds),
                    child: Icon(page.icon, size: 70, color: Colors.white),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 60),

          // Title with gradient
          ShaderMask(
            shaderCallback: (bounds) =>
                LinearGradient(colors: page.gradient).createShader(bounds),
            child: Text(
              page.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                height: 1.2,
                letterSpacing: 1,
              ),
            ),
          ),
          const SizedBox(height: 30),

          // Description
          Text(
            page.description,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.7),
              height: 1.6,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class OnboardingPageData {
  final String title;
  final String description;
  final IconData icon;
  final List<Color> gradient;

  OnboardingPageData({
    required this.title,
    required this.description,
    required this.icon,
    required this.gradient,
  });
}

class CirclesPainter extends CustomPainter {
  final double animation;

  CirclesPainter({required this.animation});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Draw rotating circles
    for (int i = 0; i < 3; i++) {
      paint.color = Color(0xFF00F5FF).withOpacity(0.1 - (i * 0.03));
      final radius = 100.0 + (i * 50);
      final offset = Offset(
        size.width * 0.5 + math.cos(animation * 2 * math.pi + i) * 30,
        size.height * 0.3 + math.sin(animation * 2 * math.pi + i) * 30,
      );
      canvas.drawCircle(offset, radius, paint);
    }

    for (int i = 0; i < 2; i++) {
      paint.color = Color(0xFF9D4EDD).withOpacity(0.08 - (i * 0.03));
      final radius = 120.0 + (i * 60);
      final offset = Offset(
        size.width * 0.5 + math.sin(animation * 2 * math.pi - i) * 40,
        size.height * 0.7 + math.cos(animation * 2 * math.pi - i) * 40,
      );
      canvas.drawCircle(offset, radius, paint);
    }
  }

  @override
  bool shouldRepaint(CirclesPainter oldDelegate) => true;
}
