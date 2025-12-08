import 'package:flutter/material.dart';
import 'dart:math' as math;

class AnimatedWelcomeMessage extends StatefulWidget {
  final String userName;
  final String userRole;
  final bool showTeaLeaf;

  const AnimatedWelcomeMessage({
    super.key,
    required this.userName,
    required this.userRole,
    this.showTeaLeaf = true,
  });

  @override
  State<AnimatedWelcomeMessage> createState() => _AnimatedWelcomeMessageState();
}

class _AnimatedWelcomeMessageState extends State<AnimatedWelcomeMessage>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _teaLeafController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _teaLeafController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeIn));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _teaLeafController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF2ECC71).withOpacity(0.15),
                const Color(0xFFFFB300).withOpacity(0.1),
              ],
            ),
            border: Border.all(
              color: const Color(0xFF2ECC71).withOpacity(0.3),
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2ECC71).withOpacity(0.2),
                blurRadius: 12,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Row(
            children: [
              if (widget.showTeaLeaf)
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: AnimatedBuilder(
                    animation: _teaLeafController,
                    builder: (context, child) {
                      final angle = _teaLeafController.value * 2 * math.pi;
                      final floatOffset =
                          math.sin(angle * 2) * 3; // Floating effect

                      return Transform.translate(
                        offset: Offset(0, floatOffset),
                        child: Transform.rotate(
                          angle: math.sin(angle) * 0.15, // Gentle rotation
                          child: const Icon(
                            Icons.eco,
                            size: 32,
                            color: Color(0xFF2ECC71),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome, ${widget.userName}! 🌿',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2ECC71),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Role: ${widget.userRole}',
                      style: TextStyle(
                        fontSize: 12,
                        color: const Color(0xFFFFB300).withOpacity(0.8),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
