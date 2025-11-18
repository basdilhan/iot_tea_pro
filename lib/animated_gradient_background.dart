import 'package:flutter/material.dart';

class AnimatedGradientBackground extends StatefulWidget {
  const AnimatedGradientBackground({super.key});

  @override
  State<AnimatedGradientBackground> createState() =>
      _AnimatedGradientBackgroundState();
}

class _AnimatedGradientBackgroundState extends State<AnimatedGradientBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Color?> _colorAnimation1;
  late Animation<Color?> _colorAnimation2;
  late Animation<Color?> _colorAnimation3;
  bool _isInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      // Get theme colors to make the animation match your app
      final primary = Theme.of(context).colorScheme.primary;
      final secondary = Theme.of(context).colorScheme.secondary;
      final surface = Theme.of(context).colorScheme.surface;

      _controller = AnimationController(
        vsync: this,
        duration: const Duration(seconds: 15), // Slower, more elegant
      )..repeat(reverse: true);

      // Create three color animations that blend together
      _colorAnimation1 = ColorTween(
        begin: primary.withOpacity(0.3),
        end: secondary.withOpacity(0.3),
      ).animate(_controller);

      _colorAnimation2 = ColorTween(
        begin: secondary.withOpacity(0.1),
        end: surface.withOpacity(0.05),
      ).animate(_controller);

      _colorAnimation3 = ColorTween(
        begin: surface.withOpacity(0.05),
        end: primary.withOpacity(0.1),
      ).animate(_controller);

      _isInitialized = true;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      // Fallback while waiting for theme
      return Container(color: Theme.of(context).colorScheme.surface);
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                _colorAnimation1.value!,
                _colorAnimation2.value!,
                _colorAnimation3.value!,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        );
      },
    );
  }
}
