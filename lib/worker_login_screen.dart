import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'worker_main_screen.dart';
import 'role_selection_screen.dart';

class WorkerLoginScreen extends StatefulWidget {
  const WorkerLoginScreen({super.key});

  @override
  State<WorkerLoginScreen> createState() => _WorkerLoginScreenState();
}

class _WorkerLoginScreenState extends State<WorkerLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  bool _isLoading = false;
  bool _otpSent = false;
  String? _verificationId;
  String? _foundWorkerId; // Store found worker ID

  // Test phone numbers - only these can use test OTP during development
  final List<String> _testPhoneNumbers = ['+94771234567', '+94765544332'];

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    if (!_formKey.currentState!.validate()) return;

    var phone = _phoneController.text.trim();

    // Ensure phone number is in E.164 format
    if (!phone.startsWith('+')) {
      phone = '+$phone';
    }

    // Remove any spaces or dashes
    phone = phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');

    // Validate E.164 format: +[country code][number]
    if (!RegExp(r'^\+\d{7,15}$').hasMatch(phone)) {
      final messenger = ScaffoldMessenger.of(context);
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Invalid phone format. Use +94XXXXXXXXX'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Find worker by phone number
    try {
      setState(() => _isLoading = true);

      final workersSnap = await FirebaseDatabase.instance.ref('/workers').get();

      if (!workersSnap.exists) {
        throw 'No workers registered';
      }

      final workers = workersSnap.value as Map<dynamic, dynamic>;
      String? matchingWorkerId;

      // Search for worker with matching phone (try both formats)
      for (var entry in workers.entries) {
        final workerData = entry.value as Map<dynamic, dynamic>;
        final savedPhone =
            (workerData['phone_number'] ?? workerData['phone'])?.toString() ??
            '';

        // Try exact match
        if (savedPhone == phone) {
          matchingWorkerId = entry.key.toString();
          break;
        }

        // Try without + sign
        if (savedPhone.replaceAll('+', '') == phone.replaceAll('+', '')) {
          matchingWorkerId = entry.key.toString();
          break;
        }
      }

      if (matchingWorkerId == null) {
        throw 'No worker found with this phone number. Contact your manager.';
      }

      _foundWorkerId = matchingWorkerId;

      print('📱 Sending OTP to: $phone for worker: $matchingWorkerId');

      // FOR WEB: Use test OTP or show message for mobile testing
      if (kIsWeb) {
        print(
          '🌐 Web platform detected - Firebase Phone Auth on web requires special setup',
        );
        print('📱 For mobile testing, install the app on a real device');

        setState(() {
          _isLoading = false;
          _otpSent = true;
        });

        // Show message for web users
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Web Testing: Phone Auth requires mobile device.\n'
              'Install the APK on Android for real SMS.\n'
              'Or use test OTP: 123456',
            ),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 6),
          ),
        );
        return;
      }

      // For Mobile: Use Firebase phone verification to send real OTP
      // Set recaptchaVerifier for web, null for mobile
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phone,
        timeout: const Duration(seconds: 120),
        forceResendingToken: null,
        verificationCompleted: (credential) async {
          print('✅ Auto-verification completed');
          await FirebaseAuth.instance.signInWithCredential(credential);
          await _postVerify(_foundWorkerId!);
        },
        verificationFailed: (e) {
          setState(() => _isLoading = false);
          final messenger = ScaffoldMessenger.of(context);

          // Detailed error logging
          print('=== FIREBASE AUTH ERROR ===');
          print('Error code: ${e.code}');
          print('Error message: ${e.message}');
          print('Full error: $e');
          print('========================');

          String errorMsg = e.message ?? 'Verification failed';

          // Handle specific error codes
          switch (e.code) {
            case 'invalid-phone-number':
              errorMsg =
                  'Invalid phone number format.\nUse format: +94XXXXXXXXX\n\n'
                  'Error: The phone number must be in E.164 format (+[country code][number])';
              break;
            case 'too-many-requests':
              errorMsg =
                  'Too many attempts. Please try again later (wait at least 5 minutes).';
              break;
            case 'quota-exceeded':
              errorMsg =
                  'SMS quota exceeded. Contact administrator.\n\n'
                  'Your Firebase project has reached its daily SMS limit.';
              break;
            case 'operation-not-allowed':
              errorMsg =
                  'Phone Auth NOT ENABLED in Firebase Console!\n\n'
                      'Steps to fix:\n'
                      '1. Go to Firebase Console\n'
                      '2. Authentication > Sign-in method\n' +
                  '3. Enable "Phone" provider\n' +
                  '4. Click Save\n' +
                  '5. Download NEW google-services.json\n' +
                  '6. Replace in android/app/ folder\n' +
                  '7. Rebuild app';
              break;
            case 'app-not-authorized':
            case 'project-not-found':
              errorMsg =
                  'App configuration error.\n\n'
                      '1. Download latest google-services.json from Firebase\n'
                      '2. Replace the file in android/app/\n'
                      '3. Make sure SHA-1 fingerprint is registered\n' +
                  '4. Rebuild the app';
              break;
            case 'web-context-cancelled':
            case 'web-internal-error':
              errorMsg =
                  'Phone authentication not properly configured.\n\n'
                  'Check Firebase Console settings and ensure reCAPTCHA is enabled.';
              break;
            case 'captcha-check-failed':
            case 'missing-client-token':
            case 'invalid-app-credential':
            case 'session-expired':
            case 'unknown':
              errorMsg =
                  'reCAPTCHA / Play Integrity verification failed.\n\n'
                      'Fix steps:\n'
                      '• Add BOTH SHA-1 and SHA-256 fingerprints to Firebase (Project settings → Android app)\n'
                      '  - SHA-1: 6F:AF:5F:64:4C:9C:8A:EB:6E:EA:E0:5F:9E:0D:AF:2B:E3:AF:D5:90\n' +
                  '  - SHA-256: A5:73:DB:1A:D2:6E:89:0D:4B:D9:95:08:6C:C6:20:C8:AC:4D:DA:EB:E0:F3:7E:15:82:6E:84:5A:15:E0:B9:61\n' +
                  '• Download a fresh google-services.json after adding fingerprints and replace android/app/google-services.json\n' +
                  '• Make sure Google Play Services is up to date and VPN is off\n' +
                  '• Reinstall the app after updating google-services.json';
              break;
            default:
              if (errorMsg.contains('not allowed') ||
                  errorMsg.contains('disabled')) {
                errorMsg =
                    'Phone Auth not enabled in Firebase.\n\n'
                    'Enable it in: Authentication > Sign-in method';
              } else if (errorMsg.contains('invalid') ||
                  errorMsg.contains('39')) {
                errorMsg =
                    'Invalid phone number or Firebase configuration.\n\n'
                        'Ensure:\n'
                        '• Phone format is +94XXXXXXXXX\n'
                        '• Phone Auth is enabled in Firebase\n' +
                    '• google-services.json is current\n\n' +
                    'Error Details: ${e.message}';
              }
          }

          messenger.showSnackBar(
            SnackBar(
              content: Text('$errorMsg\n\nError Code: ${e.code}'),
              duration: const Duration(seconds: 10),
              backgroundColor: Colors.red,
            ),
          );
        },
        codeSent: (verificationId, resendToken) {
          print('✅ OTP sent successfully!');
          print('   Verification ID: $verificationId');
          print('   Resend Token: $resendToken');
          setState(() {
            _verificationId = verificationId;
            _otpSent = true;
            _isLoading = false;
          });

          final messenger = ScaffoldMessenger.of(context);
          messenger.showSnackBar(
            const SnackBar(
              content: Text('OTP sent! Check your phone for the code.'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 4),
            ),
          );
        },
        codeAutoRetrievalTimeout: (verificationId) {
          print('⏱️ Auto-retrieval timeout. Verification ID: $verificationId');
          _verificationId = verificationId;
        },
      );
    } catch (e) {
      setState(() => _isLoading = false);
      final messenger = ScaffoldMessenger.of(context);
      messenger.showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyOtp() async {
    final smsCode = _otpController.text.trim();
    final verificationId = _verificationId;
    final workerId = _foundWorkerId; // Use found worker ID
    final messenger = ScaffoldMessenger.of(context);

    if (smsCode.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Please enter the 6-digit OTP sent to your phone'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (smsCode.length != 6 || !RegExp(r'^[0-9]{6}$').hasMatch(smsCode)) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('OTP must be exactly 6 digits'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (workerId == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Worker ID not found. Please try again.')),
      );
      return;
    }

    try {
      setState(() => _isLoading = true);

      print('🔐 Verifying OTP: $smsCode for worker: $workerId');

      // FOR WEB DEVELOPMENT: Accept test OTP 123456
      if (kIsWeb && smsCode == '123456') {
        print('✅ Development mode: Test OTP accepted');
        await _postVerify(workerId);
        return;
      }

      if (verificationId == null) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text(
              'Verification session expired. Please request OTP again.',
            ),
            backgroundColor: Colors.orange,
          ),
        );
        setState(() => _isLoading = false);
        return;
      }

      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );

      final userCredential = await FirebaseAuth.instance.signInWithCredential(
        credential,
      );
      print('✅ OTP verification successful! User: ${userCredential.user?.uid}');

      await _postVerify(workerId);
    } on FirebaseAuthException catch (e) {
      setState(() => _isLoading = false);

      print('❌ Firebase Auth Error: ${e.code} - ${e.message}');

      String errorMsg = 'OTP verification failed: ${e.message}';

      if (e.code == 'invalid-verification-code') {
        errorMsg = 'Invalid OTP code. Please check and try again.';
      } else if (e.code == 'session-expired') {
        errorMsg = 'OTP session expired. Please request a new OTP.';
      } else if (e.code == 'too-many-requests') {
        errorMsg =
            'Too many attempts. Please wait a few minutes and try again.';
      }

      messenger.showSnackBar(
        SnackBar(
          content: Text(errorMsg),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      print('❌ Unexpected error: $e');

      messenger.showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _postVerify(String workerId) async {
    // Double-check worker exists and is active
    final snap = await FirebaseDatabase.instance
        .ref('/workers/$workerId')
        .get();
    if (!snap.exists) {
      throw Exception('Worker not found after verification');
    }
    final data = snap.value as Map<dynamic, dynamic>;
    if (data['active'] == false) {
      throw Exception('Worker is not active');
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('logged_in_worker_id', workerId);
    await prefs.setString('user_role', 'worker');
    await prefs.setBool('is_logged_in', true);

    final navigator = Navigator.of(context);
    navigator.pushReplacement(
      MaterialPageRoute(
        builder: (context) => WorkerMainScreen(workerId: workerId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF2D5016),
              const Color(0xFF4A7C2C),
              const Color(0xFF2D5016),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Back button
                    Align(
                      alignment: Alignment.topLeft,
                      child: IconButton(
                        icon: Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (context) => const RoleSelectionScreen(),
                            ),
                          );
                        },
                      ),
                    ),

                    // Icon
                    Icon(Icons.person, size: 80, color: Colors.white),
                    const SizedBox(height: 20),

                    // Title
                    Text(
                      'Worker Login',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Enter Phone to receive OTP',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Phone Number Field
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            labelText: 'Phone Number (+94XXXXXXXXX)',
                            hintText: '+9477XXXXXXX',
                            prefixIcon: Icon(Icons.phone),
                            border: InputBorder.none,
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter your phone number';
                            }
                            if (!value.startsWith('+')) {
                              return 'Use E.164 format e.g., +9477...';
                            }
                            return null;
                          },
                        ),
                      ),
                    ),

                    if (_otpSent) ...[
                      const SizedBox(height: 16),
                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: TextField(
                            controller: _otpController,
                            keyboardType: TextInputType.number,
                            maxLength: 6,
                            decoration: const InputDecoration(
                              labelText: 'OTP Code',
                              hintText: '6-digit code',
                              prefixIcon: Icon(Icons.verified_user),
                              border: InputBorder.none,
                              counterText: '',
                            ),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 32),

                    // Login Button
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: _isLoading
                            ? null
                            : (_otpSent ? _verifyOtp : _sendOtp),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF2D5016),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 4,
                        ),
                        child: _isLoading
                            ? CircularProgressIndicator(
                                color: const Color(0xFF2D5016),
                              )
                            : Text(
                                _otpSent ? 'VERIFY OTP' : 'SEND OTP',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Help Text
                    Text(
                      _otpSent
                          ? 'Didn\'t receive the code? Try again in a moment.'
                          : 'Use the phone number saved by your manager.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
