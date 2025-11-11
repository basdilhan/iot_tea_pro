import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import '../main.dart'; // For theme

class LogListScreen extends StatefulWidget {
  const LogListScreen({super.key});

  @override
  State<LogListScreen> createState() => _LogListScreenState();
}

class _LogListScreenState extends State<LogListScreen> {
  DateTime _selectedDate = DateTime.now();

  // We need these refs to look up names
  final DatabaseReference _workersRef = FirebaseDatabase.instance.ref(
    '/workers',
  );
  final DatabaseReference _devicesRef = FirebaseDatabase.instance.ref(
    '/devices',
  );

  // Function to show the date picker
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  // Helper to format the date string for the database path
  String _getFormattedDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  // Helper to get farmer name from ID
  Future<String> _getFarmerName(String farmerId) async {
    final snapshot = await _workersRef.child('$farmerId/name').get();
    if (snapshot.exists) {
      return snapshot.value.toString();
    }
    return 'Unknown ID: $farmerId';
  }

  // Helper to get device name from ID
  Future<String> _getDeviceName(String deviceId) async {
    final snapshot = await _devicesRef.child('$deviceId/location_name').get();
    if (snapshot.exists) {
      return snapshot.value.toString();
    }
    return 'Unknown Device';
  }

  @override
  Widget build(BuildContext context) {
    // Reference to the logs for the selected date
    DatabaseReference logRef = FirebaseDatabase.instance.ref(
      '/weighing_logs/${_getFormattedDate(_selectedDate)}',
    );

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date Selector Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Weighing History',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryGreen(context),
                    ),
                  ),
                  const Text(
                    'All logs for the selected day',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
              TextButton.icon(
                icon: Icon(
                  Icons.calendar_today,
                  color: AppTheme.accentOrange(context),
                ),
                label: Text(
                  DateFormat('MMM d, yyyy').format(_selectedDate),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.accentOrange(context),
                  ),
                ),
                onPressed: () => _selectDate(context),
              ),
            ],
          ),
          const Divider(height: 30),

          // StreamBuilder to get the logs
          Expanded(
            child: StreamBuilder(
              stream: logRef.onValue,
              builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData ||
                    snapshot.data!.snapshot.value == null) {
                  return const Center(
                    child: Text(
                      'No logs found for this date.',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  );
                }

                // Process the data
                Map<dynamic, dynamic> logsMap =
                    snapshot.data!.snapshot.value as Map<dynamic, dynamic>;

                // Convert to a list
                var logList = logsMap.entries.map((e) {
                  var logData = e.value as Map<dynamic, dynamic>;
                  logData['key'] = e.key; // Keep the log ID
                  return logData;
                }).toList();

                // Sort by timestamp (newest first)
                logList.sort(
                  (a, b) =>
                      (b['timestamp'] as int).compareTo(a['timestamp'] as int),
                );

                return ListView.builder(
                  itemCount: logList.length,
                  itemBuilder: (context, index) {
                    Map<dynamic, dynamic> log = logList[index];
                    String farmerId = log['farmer_id'] ?? 'N/A';
                    String deviceId = log['device_id'] ?? 'N/A';
                    String weight = log['weight']?.toString() ?? '0';
                    int timestamp = log['timestamp'] ?? 0;

                    String formattedTime = 'No timestamp';
                    if (timestamp != 0) {
                      formattedTime =
                          DateFormat('hh:mm:ss a') // Just the time
                              .format(
                                DateTime.fromMillisecondsSinceEpoch(
                                  timestamp * 1000,
                                ),
                              );
                    }

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppTheme.primaryGreen(
                            context,
                          ).withOpacity(0.1),
                          child: Text(
                            weight,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryGreen(context),
                            ),
                          ),
                        ),
                        // Use FutureBuilders to get the names
                        title: FutureBuilder(
                          future: _getFarmerName(farmerId),
                          builder:
                              (context, AsyncSnapshot<String> nameSnapshot) {
                                String name = nameSnapshot.data ?? '...';
                                return Text(
                                  '$name (ID: $farmerId)',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                );
                              },
                        ),
                        subtitle: FutureBuilder(
                          future: _getDeviceName(deviceId),
                          builder:
                              (context, AsyncSnapshot<String> deviceSnapshot) {
                                String deviceName =
                                    deviceSnapshot.data ?? '...';
                                return Text('At $formattedTime on $deviceName');
                              },
                        ),
                        trailing: Text(
                          '$weight kg',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.accentOrange(context),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
