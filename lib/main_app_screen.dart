import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iot_tea/dashboard_screen.dart';
import 'package:iot_tea/log_list_screen.dart';
import 'package:iot_tea/manage_workers_screen.dart';
import 'package:iot_tea/map_screen.dart';
import 'package:iot_tea/reports_screen.dart';
import 'theme_provider.dart';

class MainAppScreen extends StatefulWidget {
  const MainAppScreen({Key? key}) : super(key: key);

  @override
  State<MainAppScreen> createState() => _MainAppScreenState();
}

class _MainAppScreenState extends State<MainAppScreen> {
  int _selectedIndex = 0;

  // This title will change when you tap a bottom bar icon
  String _currentTitle = 'Dashboard';

  // The list of all your main pages
  static final List<Widget> _widgetOptions = <Widget>[
    DashboardScreen(),
    LogListScreen(),
    ReportsScreen(),
    MapScreen(),
    ManageWorkersScreen(),
  ];

  // This function is called when you tap an icon
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      // Update the title based on the selected index
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
          _currentTitle = 'Map';
          break;
        case 4:
          _currentTitle = 'Manage Workers';
          break;
      }
    });
  }

  // --- THIS IS THE NEW LOGOUT FUNCTION ---
  Future<void> _signOut() async {
    try {
      // This single line signs the user out of Firebase
      await FirebaseAuth.instance.signOut();
      // The AuthWrapper will automatically see this change and show the LoginScreen.
    } catch (e) {
      // Handle error, e.g., show a snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error signing out: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // --- THIS IS THE NEW APPBAR WITH LOGOUT BUTTON ---
      appBar: AppBar(
        title: Text(_currentTitle),
        // This is the main color from your theme
        backgroundColor: Theme.of(context).primaryColor,
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
          // This is the new button
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign Out',
            onPressed: () {
              // Ask the user to confirm before logging out
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
                          Navigator.of(dialogContext).pop(); // Close the dialog
                        },
                      ),
                      TextButton(
                        child: const Text('Sign Out'),
                        onPressed: () {
                          Navigator.of(dialogContext).pop(); // Close the dialog
                          _signOut(); // Call the sign-out function
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

      // --- END OF NEW APPBAR ---
      body: IndexedStack(index: _selectedIndex, children: _widgetOptions),
      bottomNavigationBar: BottomNavigationBar(
        // This makes the icons always show their text
        type: BottomNavigationBarType.fixed,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Reports',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Map'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Workers'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Theme.of(context).primaryColor, // Use theme color
        unselectedItemColor: Colors.grey, // Unselected icons are grey
        onTap: _onItemTapped,
      ),
    );
  }
}
