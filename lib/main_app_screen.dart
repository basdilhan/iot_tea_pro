import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:iot_tea/dashboard_screen.dart';
import 'package:iot_tea/log_list_screen.dart';
import 'package:iot_tea/manage_workers_screen.dart';
import 'package:iot_tea/map_screen.dart';
import 'package:iot_tea/reports_screen.dart';
import 'package:iot_tea/smart_weigning_screen.dart';
import 'package:iot_tea/payment_settings_screen.dart';
// import 'package:iot_tea/onboarding_screen.dart';
import 'theme_provider.dart';

class MainAppScreen extends StatefulWidget {
  const MainAppScreen({super.key});

  @override
  State<MainAppScreen> createState() => _MainAppScreenState();
}

class _MainAppScreenState extends State<MainAppScreen> {
  int _selectedIndex = 0;
  String _currentTitle = 'Dashboard';

  static final List<Widget> _widgetOptions = <Widget>[
    DashboardScreen(),
    LogListScreen(),
    ReportsScreen(),
    ManageWorkersScreen(),
    SmartWeighingScreen(), // <-- Changed order, put Map last
    MapScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      switch (index) {
        case 0:
          _currentTitle = 'Dashboard';
          break;
        case 1:
          _currentTitle = 'History';
          break;
        case 2:
          _currentTitle = 'Reports';
          break;
        case 3:
          _currentTitle = 'Manage Workers';
          break;
        case 4:
          _currentTitle = 'Smart Weighing'; // <-- Updated index
          break;
        case 5:
          _currentTitle = 'Map'; // <-- Updated index
          break;
      }
    });
  }

  Future<void> _signOut() async {
    try {
      // Reset onboarding flag before signing out
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('onboarding_completed', false);
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error signing out: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_currentTitle),
        backgroundColor: Theme.of(context).primaryColor,
        elevation: 1.0, // Subtle shadow
        actions: [
          // Theme toggle button
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) {
              return IconButton(
                icon: Icon(
                  themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                ),
                tooltip: 'Toggle Theme',
                onPressed: () {
                  themeProvider.toggleTheme();
                },
              );
            },
          ),
          // Payment Settings Button
          PopupMenuButton<String>(
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
            onSelected: (value) {
              if (value == 'payment') {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const PaymentSettingsScreen(),
                  ),
                );
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'payment',
                child: ListTile(
                  leading: Icon(Icons.payments),
                  title: Text('Payment Settings'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
          // Sign Out Button
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign Out',
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext dialogContext) {
                  return AlertDialog(
                    title: const Text('Sign Out'),
                    content: const Text('Are you sure you want to sign out?'),
                    actions: <Widget>[
                      TextButton(
                        child: const Text('Cancel'),
                        onPressed: () {
                          Navigator.of(dialogContext).pop();
                        },
                      ),
                      TextButton(
                        child: const Text('Sign Out'),
                        onPressed: () {
                          Navigator.of(dialogContext).pop();
                          _signOut();
                        },
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
      body: IndexedStack(index: _selectedIndex, children: _widgetOptions),

      // --- MODERN NAVIGATION BAR ---
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
        // Hides labels for unselected items, giving a clean look
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        destinations: const <Widget>[
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: 'History',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'Reports',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'Workers',
          ),
          NavigationDestination(
            icon: Icon(Icons.scale_outlined),
            selectedIcon: Icon(Icons.scale),
            label: 'Weighing',
          ),
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map),
            label: 'Map',
          ),
        ],
      ),
    );
  }
}
