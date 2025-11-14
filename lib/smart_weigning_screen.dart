import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';

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
  bool _isScaleOnline = false; // You can add logic to check last_seen timestamp

  @override
  void initState() {
    super.initState();
    _listenToWeight();
  }

  void _listenToWeight() {
    // Listen to the live weight from ESP32
    _dbRef.child('latest_reading/weight').onValue.listen((event) {
      if (event.snapshot.value != null) {
        setState(() {
          _currentWeight = double.parse(event.snapshot.value.toString());
          // Simple check: if weight updates, scale is "online"
          _isScaleOnline = true;
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

    // Create the log entry
    String date = DateFormat('yyyy-MM-dd').format(DateTime.now());
    String timestamp = DateTime.now().millisecondsSinceEpoch.toString();

    Map<String, dynamic> newLog = {
      'farmer_id': _selectedFarmerId,
      'farmer_name': _selectedFarmerName, // Storing name for easier reporting
      'weight': _currentWeight,
      'unit': 'kg',
      'timestamp': ServerValue.timestamp,
      'device_id': 'SCALE-01', // Hardcoded for now, or get from settings
    };

    // Save to Firebase
    try {
      await _dbRef.child('weighing_logs/$date').push().set(newLog);
      await _dbRef.child('latest_reading/weight').set(0.0);
      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Saved $_currentWeight kg for $_selectedFarmerName'),
            backgroundColor: Colors.green,
          ),
        );
      }

      // Reset selection
      setState(() {
        _selectedFarmerId = null;
        _selectedFarmerName = null;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Weighing'),
        centerTitle: true,
        backgroundColor: Colors.green[700],
        elevation: 0,
      ),
      body: Column(
        children: [
          // 1. Live Weight Display Section
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.green[700],
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Column(
              children: [
                const Text(
                  'LIVE SCALE READING',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      _currentWeight.toStringAsFixed(2),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 60,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'kg',
                      style: TextStyle(color: Colors.white70, fontSize: 24),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _isScaleOnline ? Colors.green[400] : Colors.red[400],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _isScaleOnline ? Icons.wifi : Icons.wifi_off,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _isScaleOnline ? 'Scale Online' : 'Scale Offline',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // 2. Farmer Selection Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: const [
                Icon(Icons.people, color: Colors.green),
                SizedBox(width: 10),
                Text(
                  'Select Farmer',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // 3. Farmer List (Grid View)
          Expanded(
            child: StreamBuilder(
              stream: _dbRef.child('workers').onValue,
              builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
                if (!snapshot.hasData ||
                    snapshot.data!.snapshot.value == null) {
                  return const Center(child: CircularProgressIndicator());
                }

                Map<dynamic, dynamic> workers =
                    snapshot.data!.snapshot.value as Map;
                List<MapEntry<dynamic, dynamic>> workerList = workers.entries
                    .toList();

                return GridView.builder(
                  padding: const EdgeInsets.all(15),

                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3, // Now 3 columns
                    childAspectRatio:
                        1.2, // Adjusted for a slightly taller look
                    crossAxisSpacing: 10, // Reduced spacing
                    mainAxisSpacing: 10, // Reduced spacing
                  ),
                  // --- END OF MODIFIED SECTION ---
                  itemCount: workerList.length,
                  itemBuilder: (context, index) {
                    String id = workerList[index].key;
                    String name = workerList[index].value['name'];
                    bool isSelected = _selectedFarmerId == id;

                    return GestureDetector(
                      onTap: () => _selectFarmer(id, name),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.green[100] : Colors.white,
                          border: Border.all(
                            color: isSelected
                                ? Colors.green
                                : Colors.grey.shade300,
                            width: isSelected ? 2 : 1,
                          ),
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            if (!isSelected)
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.1),
                                blurRadius: 5,
                                offset: const Offset(0, 3),
                              ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircleAvatar(
                              backgroundColor: isSelected
                                  ? Colors.green
                                  : Colors.grey[200],
                              child: Text(
                                name[0].toUpperCase(),
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.black87,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              name,
                              style: TextStyle(
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: isSelected
                                    ? Colors.green[800]
                                    : Colors.black87,
                                fontSize:
                                    13, // Slightly smaller font for 3 columns
                              ),
                              textAlign: TextAlign.center,
                              overflow:
                                  TextOverflow.ellipsis, // Handle long names
                            ),
                            Text(
                              'ID: $id',
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 10, // Slightly smaller font
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // 4. Action Button (Save)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _selectedFarmerId == null ? null : _saveLog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[700],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    elevation: 5,
                  ),
                  child: Text(
                    _selectedFarmerId == null
                        ? 'Select a Farmer'
                        : 'SAVE RECORD',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
