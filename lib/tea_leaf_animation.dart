import 'package:flutter/material.dart';

class AnimatedCardBackground extends StatefulWidget {
  final Color color1;
  final Color color2;
  const AnimatedCardBackground({
    super.key,
    required this.color1,
    required this.color2,
  });

  @override
  State<AnimatedCardBackground> createState() => _AnimatedCardBackgroundState();
}

class _AnimatedCardBackgroundState extends State<AnimatedCardBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4), // Slower, more subtle
    )..repeat(reverse: true);

    _animation = Tween<double>(
      begin: -1.5,
      end: 2.5,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [widget.color1, widget.color2, widget.color1],
              // This animates a "shine" across the card
              begin: Alignment(_animation.value - 1.0, -1.0),
              end: Alignment(_animation.value, 1.0),
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        );
      },
    );
  }
}
