import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_auth/firebase_auth.dart';
import 'main_app_screen.dart';
import 'dart:math' as math;

class LoginScreen extends StatefulWidget {
  final bool isCollector;
  const LoginScreen({super.key, this.isCollector = true});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _obscurePassword = true;
  late AnimationController _waveController;
  late AnimationController _glowController;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _waveController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
      });

      try {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
        // Navigate directly to the main app after successful sign-in
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const MainAppScreen()),
            (route) => false,
          );
        }
      } on FirebaseAuthException catch (e) {
        String message = 'An error occurred';
        if (e.code == 'user-not-found') {
          message = 'No user found with this email';
        } else if (e.code == 'wrong-password') {
          message = 'Incorrect password';
        } else if (e.code == 'invalid-email') {
          message = 'Invalid email format';
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: const Color(0xFFFF006E),
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Futuristic Background with waves
          AnimatedBuilder(
            animation: _waveController,
            builder: (context, child) {
              return CustomPaint(
                painter: FuturisticWavePainter(
                  animation: _waveController.value,
                ),
                size: Size.infinite,
              );
            },
          ),

          // Gradient Overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF0A0E27).withOpacity(0.8),
                  const Color(0xFF1a1f3a).withOpacity(0.9),
                  const Color(0xFF0A0E27).withOpacity(0.8),
                ],
              ),
            ),
          ),

          // Abstract shapes
          Positioned(
            top: -100,
            right: -100,
            child: AnimatedBuilder(
              animation: _glowController,
              builder: (context, child) {
                return Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(
                          0xFF00F5FF,
                        ).withOpacity(0.1 * _glowController.value),
                        Colors.transparent,
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          Positioned(
            bottom: -150,
            left: -150,
            child: AnimatedBuilder(
              animation: _glowController,
              builder: (context, child) {
                return Container(
                  width: 400,
                  height: 400,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(
                          0xFF9D4EDD,
                        ).withOpacity(0.15 * (1 - _glowController.value)),
                        Colors.transparent,
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Main Content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo with neon glow
                      AnimatedBuilder(
                        animation: _glowController,
                        builder: (context, child) {
                          return Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFF00F5FF,
                                  ).withOpacity(0.3 * _glowController.value),
                                  blurRadius: 40,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.eco_outlined,
                              size: 80,
                              color: Color(0xFF00F5FF),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 30),

                      // Title with gradient
                      ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [Color(0xFF00F5FF), Color(0xFF9D4EDD)],
                        ).createShader(bounds),
                        child: const Text(
                          'Tea Leaf Weigher',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      Text(
                        'Smart Management System',
                        style: TextStyle(
                          fontSize: 14,
                          color: const Color(0xFF00F5FF).withOpacity(0.7),
                          letterSpacing: 3,
                        ),
                      ),
                      const SizedBox(height: 60),

                      // Email Field
                      _buildFuturisticTextField(
                        controller: _emailController,
                        label: 'EMAIL',
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your email';
                          }
                          if (!value.contains('@')) {
                            return 'Please enter a valid email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),

                      // Password Field
                      _buildFuturisticTextField(
                        controller: _passwordController,
                        label: 'PASSWORD',
                        icon: Icons.lock_outline,
                        obscureText: _obscurePassword,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: const Color(0xFF00F5FF).withOpacity(0.5),
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your password';
                          }
                          if (value.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 40),

                      // Sign In Button
                      _isLoading
                          ? const CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFF00F5FF),
                              ),
                            )
                          : AnimatedBuilder(
                              animation: _glowController,
                              builder: (context, child) {
                                return Container(
                                  width: double.infinity,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFF00F5FF),
                                        Color(0xFF9D4EDD),
                                      ],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Color(0xFF00F5FF).withOpacity(
                                          0.4 * _glowController.value,
                                        ),
                                        blurRadius: 20,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                  child: ElevatedButton(
                                    onPressed: _signIn,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      shadowColor: Colors.transparent,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                    child: const Text(
                                      'SIGN IN',
                                      style: TextStyle(
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
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFuturisticTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    TextInputType? keyboardType,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF00F5FF).withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00F5FF).withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.white, fontSize: 16),
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: const Color(0xFF00F5FF).withOpacity(0.7),
            fontSize: 12,
            letterSpacing: 2,
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: Icon(
            icon,
            color: const Color(0xFF00F5FF).withOpacity(0.7),
          ),
          suffixIcon: suffixIcon,
          filled: true,
          fillColor: const Color(0xFF1a1f3a).withOpacity(0.5),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFF00F5FF), width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFFF006E), width: 1),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFFF006E), width: 2),
          ),
          errorStyle: const TextStyle(color: Color(0xFFFF006E)),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 18,
          ),
        ),
      ),
    );
  }
}

class FuturisticWavePainter extends CustomPainter {
  final double animation;

  FuturisticWavePainter({required this.animation});

  @override
  void paint(Canvas canvas, Size size) {
    final paint1 = Paint()
      ..color = const Color(0xFF00F5FF).withOpacity(0.1)
      ..style = PaintingStyle.fill;

    final paint2 = Paint()
      ..color = const Color(0xFF9D4EDD).withOpacity(0.08)
      ..style = PaintingStyle.fill;

    final paint3 = Paint()
      ..color = const Color(0xFF00F5FF).withOpacity(0.05)
      ..style = PaintingStyle.fill;

    // Wave 1
    Path path1 = Path();
    path1.moveTo(0, size.height * 0.3);
    for (double i = 0; i <= size.width; i++) {
      path1.lineTo(
        i,
        size.height * 0.3 +
            math.sin(
                  (i / size.width * 2 * math.pi) + (animation * 2 * math.pi),
                ) *
                30,
      );
    }
    path1.lineTo(size.width, 0);
    path1.lineTo(0, 0);
    canvas.drawPath(path1, paint1);

    // Wave 2
    Path path2 = Path();
    path2.moveTo(0, size.height * 0.7);
    for (double i = 0; i <= size.width; i++) {
      path2.lineTo(
        i,
        size.height * 0.7 +
            math.sin(
                  (i / size.width * 3 * math.pi) - (animation * 2 * math.pi),
                ) *
                40,
      );
    }
    path2.lineTo(size.width, size.height);
    path2.lineTo(0, size.height);
    canvas.drawPath(path2, paint2);

    // Wave 3
    Path path3 = Path();
    path3.moveTo(0, size.height * 0.5);
    for (double i = 0; i <= size.width; i++) {
      path3.lineTo(
        i,
        size.height * 0.5 +
            math.sin(
                  (i / size.width * 4 * math.pi) + (animation * 3 * math.pi),
                ) *
                25,
      );
    }
    path3.lineTo(size.width, size.height);
    path3.lineTo(0, size.height);
    canvas.drawPath(path3, paint3);
  }

  @override
  bool shouldRepaint(FuturisticWavePainter oldDelegate) => true;
}
