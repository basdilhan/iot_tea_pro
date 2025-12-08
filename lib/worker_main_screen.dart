import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'worker_dashboard_screen.dart';
import 'worker_analytics_screen.dart';
import 'role_selection_screen.dart';
import 'ui_design.dart';

class WorkerMainScreen extends StatefulWidget {
  final String workerId;

  const WorkerMainScreen({super.key, required this.workerId});

  @override
  State<WorkerMainScreen> createState() => _WorkerMainScreenState();
}

class _WorkerMainScreenState extends State<WorkerMainScreen> {
  String _workerName = '';

  @override
  void initState() {
    super.initState();
    _loadWorkerInfo();
  }

  Future<void> _loadWorkerInfo() async {
    try {
      DatabaseReference workerRef = FirebaseDatabase.instance.ref(
        '/workers/${widget.workerId}',
      );
      DatabaseEvent event = await workerRef.once();

      if (event.snapshot.exists) {
        Map<dynamic, dynamic> data =
            event.snapshot.value as Map<dynamic, dynamic>;
        if (mounted) {
          setState(() {
            _workerName = data['name'] ?? widget.workerId;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading worker info: $e');
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: UIDesign.errorRed),
            child: const Text('Logout'),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // Sign out Firebase Auth if worker used phone auth
        await FirebaseAuth.instance.signOut();

        // Clear all prefs including onboarding to show it every time
        final prefs = await SharedPreferences.getInstance();
        await prefs.clear();

        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => const RoleSelectionScreen(),
            ),
            (route) => false,
          );
        }
      } catch (e) {
        debugPrint('Logout error: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: UIDesign.charcoalElevated,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _workerName.isNotEmpty ? _workerName : 'Worker',
              style: TextStyle(
                fontSize: 18,
                color: UIDesign.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'ID: ${widget.workerId}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.normal,
                color: UIDesign.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.analytics, color: UIDesign.accentCyan),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => Scaffold(
                    appBar: AppBar(
                      title: const Text('Analytics'),
                      backgroundColor: UIDesign.charcoalElevated,
                    ),
                    body: WorkerAnalyticsScreen(workerId: widget.workerId),
                  ),
                ),
              );
            },
            tooltip: 'View Analytics',
          ),
          IconButton(
            icon: Icon(Icons.logout, color: UIDesign.errorRed),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: WorkerDashboardScreen(workerId: widget.workerId),
    );
  }
}
