import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'ui_design.dart';
import 'payment_provider.dart';

class LogListScreen extends StatefulWidget {
  const LogListScreen({super.key});

  @override
  State<LogListScreen> createState() => _LogListScreenState();
}

class _LogListScreenState extends State<LogListScreen> {
  DateTime _selectedDate = DateTime.now();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // We need these refs to look up names
  final DatabaseReference _workersRef = FirebaseDatabase.instance.ref(
    '/workers',
  );
  final DatabaseReference _devicesRef = FirebaseDatabase.instance.ref(
    '/devices',
  );

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Function to show the date picker
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            dialogTheme: DialogThemeData(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            datePickerTheme: const DatePickerThemeData(
              headerHeadlineStyle: TextStyle(fontSize: 20),
              dayStyle: TextStyle(fontSize: 12),
              yearStyle: TextStyle(fontSize: 14),
            ),
          ),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.65,
              maxWidth: MediaQuery.of(context).size.width * 0.85,
            ),
            child: child!,
          ),
        );
      },
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

  // Helper to get device label from ID
  // If a human-friendly name exists under /devices/{id}/location_name, use it.
  // Otherwise, fall back to showing the raw device_id from the log.
  Future<String> _getDeviceName(String deviceId) async {
    try {
      final snapshot = await _devicesRef.child('$deviceId/location_name').get();
      if (snapshot.exists) {
        final value = snapshot.value?.toString().trim();
        if (value != null && value.isNotEmpty) {
          return value;
        }
      }
    } catch (_) {
      // Ignore lookup errors and fall back to deviceId
    }
    return deviceId; // show the exact device_id when no name found
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
                      color: UIDesign.accentCyan,
                    ),
                  ),
                  const Text(
                    'All logs for the selected day',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
              Flexible(
                child: TextButton.icon(
                  icon: Icon(
                    Icons.calendar_today,
                    color: UIDesign.accentPurple,
                  ),
                  label: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      DateFormat('MMM d, yyyy').format(_selectedDate),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: UIDesign.accentPurple,
                      ),
                    ),
                  ),
                  onPressed: () => _selectDate(context),
                ),
              ),
            ],
          ),
          const Divider(height: 30),

          // Search Bar
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by farmer name...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),

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
                logList.sort((a, b) {
                  int timeA = (a['timestamp'] as int?) ?? 0;
                  int timeB = (b['timestamp'] as int?) ?? 0;
                  return timeB.compareTo(timeA);
                });

                // Get payment provider for earnings calculation
                final paymentProvider = Provider.of<PaymentProvider>(context);

                return FutureBuilder<
                  List<MapEntry<Map<dynamic, dynamic>, String>>
                >(
                  future: Future.wait(
                    logList.map((log) async {
                      String farmerId = log['farmer_id'] ?? 'N/A';
                      String farmerName = await _getFarmerName(farmerId);
                      return MapEntry(log, farmerName);
                    }),
                  ),
                  builder:
                      (
                        context,
                        AsyncSnapshot<
                          List<MapEntry<Map<dynamic, dynamic>, String>>
                        >
                        namesSnapshot,
                      ) {
                        if (namesSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        var logsWithNames = namesSnapshot.data ?? [];

                        // Filter by search query
                        if (_searchQuery.isNotEmpty) {
                          logsWithNames = logsWithNames.where((entry) {
                            return entry.value.toLowerCase().contains(
                              _searchQuery,
                            );
                          }).toList();
                        }

                        if (logsWithNames.isEmpty) {
                          return Center(
                            child: Text(
                              _searchQuery.isNotEmpty
                                  ? 'No results for "$_searchQuery"'
                                  : 'No logs found for this date.',
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                          );
                        }

                        return ListView.builder(
                          itemCount: logsWithNames.length,
                          itemBuilder: (context, index) {
                            Map<dynamic, dynamic> log =
                                logsWithNames[index].key;
                            String farmerName = logsWithNames[index].value;
                            String farmerId = log['farmer_id'] ?? 'N/A';
                            String deviceId = log['device_id'] ?? 'N/A';
                            double weight =
                                double.tryParse(
                                  log['weight']?.toString() ?? '0',
                                ) ??
                                0.0;
                            int timestamp = log['timestamp'] ?? 0;
                            double earnings = paymentProvider.calculateEarnings(
                              weight,
                            );

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
                              margin: const EdgeInsets.symmetric(
                                vertical: 6,
                                horizontal: 4,
                              ),
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                leading: CircleAvatar(
                                  backgroundColor: UIDesign.accentCyan
                                      .withOpacity(0.15),
                                  child: Text(
                                    weight.toStringAsFixed(1),
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: UIDesign.accentCyan,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  '$farmerName (ID: $farmerId)',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: FutureBuilder(
                                  future: _getDeviceName(deviceId),
                                  builder:
                                      (
                                        context,
                                        AsyncSnapshot<String> deviceSnapshot,
                                      ) {
                                        final deviceLabel =
                                            deviceSnapshot.data ?? deviceId;
                                        return Text(
                                          'At $formattedTime on $deviceLabel',
                                        );
                                      },
                                ),
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '${weight.toStringAsFixed(1)} kg',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: UIDesign.accentPurple,
                                      ),
                                    ),
                                    Text(
                                      '₨${NumberFormat('#,##0.00').format(earnings)}',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: UIDesign.successGreen,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
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
