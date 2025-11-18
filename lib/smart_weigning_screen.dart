import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'dart:ui'; // For BackdropFilter (Glass effect)
// Adjust this import path if you placed the file in a different folder
import 'animated_gradient_background.dart';
// import 'payment_provider.dart';
// import 'package:provider/provider.dart';

class SmartWeighingScreen extends StatefulWidget {
  const SmartWeighingScreen({super.key});

  @override
  State<SmartWeighingScreen> createState() => _SmartWeighingScreenState();
}

class _SmartWeighingScreenState extends State<SmartWeighingScreen> {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();
  String? _selectedFarmerId;
  String? _selectedFarmerName;
  double _currentWeight = 0.0;
  bool _isScaleOnline = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _listenToWeight();
    _listenToStatus();
  }

  void _listenToWeight() {
    _dbRef.child('latest_reading/weight').onValue.listen((event) {
      if (event.snapshot.value != null && mounted) {
        setState(() {
          _currentWeight = double.parse(event.snapshot.value.toString());
          // Scale is online only if weight is greater than 0
          _isScaleOnline = _currentWeight > 0;
        });
      }
    });
  }

  void _listenToStatus() {
    _dbRef.child('latest_reading/status').onValue.listen((event) {
      if (event.snapshot.value != null && mounted) {
        String status = event.snapshot.value.toString();
        setState(() {
          // Override scale status based on Firebase status field
          if (status == 'offline') {
            _isScaleOnline = false;
          }
        });
      }
    });
  }

  void _selectFarmer(String id, String name) {
    setState(() {
      _selectedFarmerId = id;
      _selectedFarmerName = name;
    });
  }

  Future<void> _saveLog() async {
    if (_isSaving) return; // Prevent multiple taps
    if (_selectedFarmerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a farmer first!')),
      );
      return;
    }
    if (_currentWeight <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Weight must be greater than 0!')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    String date = DateFormat('yyyy-MM-dd').format(DateTime.now());

    // Get the next log ID number
    final logsSnapshot = await _dbRef.child('weighing_logs/$date').get();
    int nextLogNumber = 1;
    if (logsSnapshot.exists) {
      final logs = logsSnapshot.value as Map;
      nextLogNumber = logs.length + 1;
    }
    String logId = 'Logs_ID_${nextLogNumber.toString().padLeft(3, '0')}';

    Map<String, dynamic> newLog = {
      'farmer_id': _selectedFarmerId,
      'farmer_name': _selectedFarmerName,
      'weight': _currentWeight,
      'unit': 'kg',
      'timestamp': ServerValue.timestamp,
      'device_id': 'SCALE-01',
    };

    try {
      await _dbRef.child('weighing_logs/$date/$logId').set(newLog);
      // Reset weight to 0 and set scale offline
      await _dbRef.child('latest_reading/weight').set(0.0);
      await _dbRef.child('latest_reading/status').set('offline');

      // SMS notification removed (future enhancement)

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Saved $_currentWeight kg for $_selectedFarmerName'),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }
      setState(() {
        _selectedFarmerId = null;
        _selectedFarmerName = null;
        _isSaving = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
      setState(() {
        _isSaving = false;
      });
    }
  }

  // SMS notification function removed (future enhancement)

  @override
  Widget build(BuildContext context) {
    // This screen is part of the MainAppScreen's IndexedStack,
    // so the AppBar is already provided.

    return Scaffold(
      // We use a Stack to layer the background, content, and save bar
      body: Stack(
        children: [
          // --- 1. THE ANIMATED BACKGROUND ---
          const Positioned.fill(child: AnimatedGradientBackground()),

          // --- 2. THE SCROLLABLE CONTENT ---
          // CustomScrollView lets us mix scrolling lists (Slivers)
          // with a dynamic header.
          CustomScrollView(
            slivers: [
              // --- 3. LIVE WEIGHT HEADER (Sliver) ---
              // This is the new header that shrinks and sticks
              SliverPersistentHeader(
                pinned: true,
                delegate: _LiveWeightHeader(
                  weight: _currentWeight,
                  isOnline: _isScaleOnline,
                ),
              ),

              // --- 4. "SELECT FARMER" TITLE (Sliver) ---
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                  child: Text(
                    'Select Farmer',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
              ),

              // --- 5. FARMER LIST (Sliver) ---
              _buildFarmerList(),

              // --- 6. PADDING AT THE BOTTOM ---
              // This makes sure the list can scroll above the save button
              const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ],
          ),

          // --- 7. THE "GLASS" SAVE BUTTON ---
          // This is positioned at the bottom of the Stack
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildGlassSaveBar(context),
          ),
        ],
      ),
    );
  }

  // --- WIDGET: "GLASS" SAVE BAR ---
  Widget _buildGlassSaveBar(BuildContext context) {
    final bool canSave = _selectedFarmerId != null;

    // A clipped rectangle with a blur effect
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
        child: Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            // Semi-transparent surface color
            color: Theme.of(context).colorScheme.surface.withOpacity(0.5),
            border: Border(
              top: BorderSide(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
              ),
            ),
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              width: double.infinity,
              height: 55,
              child: FilledButton(
                onPressed: (canSave && !_isSaving) ? _saveLog : null,
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  disabledBackgroundColor: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                // AnimatedSwitcher for the loading spinner
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _isSaving
                      ? SizedBox(
                          key: const ValueKey('loading'),
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Theme.of(context).colorScheme.onPrimary,
                            strokeWidth: 3,
                          ),
                        )
                      : Text(
                          // The key tells the switcher to animate
                          key: ValueKey(_selectedFarmerId ?? 'default'),
                          _selectedFarmerId == null
                              ? 'SELECT A FARMER'
                              : 'SAVE RECORD',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                            color: Theme.of(context).colorScheme.onPrimary
                                .withOpacity(canSave ? 1.0 : 0.5),
                          ),
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- WIDGET: FARMER LIST ---
  Widget _buildFarmerList() {
    return StreamBuilder(
      stream: _dbRef.child('workers').onValue,
      builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
        if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
          return const SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: CircularProgressIndicator(),
              ),
            ),
          );
        }

        Map<dynamic, dynamic> workers = snapshot.data!.snapshot.value as Map;
        List<MapEntry<dynamic, dynamic>> workerList = workers.entries.toList();

        // Use SliverList for high-performance scrolling
        return SliverList(
          delegate: SliverChildBuilderDelegate((context, index) {
            String id = workerList[index].key;
            String name = workerList[index].value['name'];
            bool isSelected = _selectedFarmerId == id;

            // Use our custom, animated card widget
            return _FarmerCard(
              name: name,
              id: id,
              isSelected: isSelected,
              onTap: () => _selectFarmer(id, name),
            );
          }, childCount: workerList.length),
        );
      },
    );
  }
}

// --- NEW: A DEDICATED WIDGET FOR THE FARMER CARD ---
// This makes the code much cleaner and manages the selection animation
class _FarmerCard extends StatelessWidget {
  final String name;
  final String id;
  final bool isSelected;
  final VoidCallback onTap;

  const _FarmerCard({
    required this.name,
    required this.id,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
      // AnimatedContainer handles all the visual changes
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.0),
          // Use elevation for a "lift" effect when selected
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: theme.colorScheme.primary.withOpacity(0.3),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        // Material and InkWell provide the tap effect and shape
        child: Material(
          color: isSelected
              ? theme
                    .colorScheme
                    .primary // Selected color
              : theme.cardColor.withOpacity(0.8), // Default color
          borderRadius: BorderRadius.circular(16.0),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16.0),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  // --- AVATAR ---
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: isSelected
                        ? theme.colorScheme.onPrimary
                        : theme.colorScheme.secondary,
                    child: Text(
                      name[0].toUpperCase(),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isSelected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // --- NAME & ID ---
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isSelected
                                ? theme.colorScheme.onPrimary
                                : theme.colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          'ID: $id',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: isSelected
                                ? theme.colorScheme.onPrimary.withOpacity(0.7)
                                : theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // --- CHECKMARK ---
                  // AnimatedSwitcher fades the checkmark in/out
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    transitionBuilder: (child, animation) {
                      return ScaleTransition(scale: animation, child: child);
                    },
                    child: isSelected
                        ? Icon(
                            Icons.check_circle,
                            color: theme.colorScheme.onPrimary,
                            key: const ValueKey('icon'),
                          )
                        : const SizedBox(key: ValueKey('empty')),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// --- NEW: A DEDICATED WIDGET FOR THE DYNAMIC HEADER ---
class _LiveWeightHeader extends SliverPersistentHeaderDelegate {
  final double weight;
  final bool isOnline;

  _LiveWeightHeader({required this.weight, required this.isOnline});

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final theme = Theme.of(context);
    final progress = shrinkOffset / (maxExtent - minExtent);
    // isShrunk is true when the header is small
    final isShrunk = progress > 0.5;

    // Use a container with "glass" effect for the header
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.8),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: SafeArea(
              bottom: false,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // --- Title ---
                  // This text fades out as you shrink the header
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: isShrunk ? 0.0 : 1.0,
                    child: Text(
                      'LIVE SCALE READING',
                      style: TextStyle(
                        color: theme.colorScheme.onPrimary.withOpacity(0.7),
                        fontSize: 14,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // --- Weight Display ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      // AnimatedSwitcher for smooth weight changes
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 400),
                        transitionBuilder: (child, animation) {
                          // Slide/fade animation for new weight
                          return FadeTransition(
                            opacity: animation,
                            child: SlideTransition(
                              position:
                                  Tween<Offset>(
                                    begin: const Offset(0, 0.5),
                                    end: Offset.zero,
                                  ).animate(
                                    animation,
                                  ), // 'animation' is the variable from the builder
                              child: child,
                            ),
                          );
                        },
                        child: Text(
                          key: ValueKey<double>(weight),
                          weight.toStringAsFixed(2),
                          style: TextStyle(
                            color: theme.colorScheme.onPrimary,
                            fontSize: isShrunk ? 32 : 60, // Shrinks
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'kg',
                        style: TextStyle(
                          color: theme.colorScheme.onPrimary.withOpacity(0.7),
                          fontSize: isShrunk ? 16 : 24, // Shrinks
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // --- Status Chip ---
                  // This also fades out
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: isShrunk ? 0.0 : 1.0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isOnline
                            ? Colors.green.shade400
                            : Colors.red.shade400,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isOnline ? Icons.wifi : Icons.wifi_off,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isOnline ? 'Scale Online' : 'Scale Offline',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Define the min/max sizes for the shrinking header
  @override
  double get maxExtent => 250.0; // Large, expanded header

  @override
  double get minExtent => 100.0; // Small, pinned header

  @override
  bool shouldRebuild(covariant _LiveWeightHeader oldDelegate) {
    // Rebuild only if the weight or online status changes
    return weight != oldDelegate.weight || isOnline != oldDelegate.isOnline;
  }
}
