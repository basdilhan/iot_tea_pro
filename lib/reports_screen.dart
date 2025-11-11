import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../main.dart'; // For theme

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  DateTime _selectedDate = DateTime.now();

  // This function will store the data we process
  Map<String, double> _farmerTotals = {};

  // We need a separate ref to look up names
  final DatabaseReference _workersRef = FirebaseDatabase.instance.ref(
    '/workers',
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

  List<PieChartSectionData> _buildPieChartSections() {
    List<PieChartSectionData> sections = [];
    List<Color> colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.red,
      Colors.purple,
      Colors.teal,
      Colors.pink,
    ];

    var sortedFarmers = _farmerTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    double totalWeight = sortedFarmers.fold(
      0.0,
      (sum, entry) => sum + entry.value,
    );

    for (int i = 0; i < sortedFarmers.length && i < 7; i++) {
      double percentage = (totalWeight > 0)
          ? (sortedFarmers[i].value / totalWeight) * 100
          : 0;
      sections.add(
        PieChartSectionData(
          value: sortedFarmers[i].value,
          title: '${percentage.toStringAsFixed(1)}%',
          color: colors[i % colors.length],
          radius: 50,
          titleStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
    }
    return sections;
  }

  List<Widget> _buildLegend() {
    List<Widget> legendItems = [];
    List<Color> colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.red,
      Colors.purple,
      Colors.teal,
      Colors.pink,
    ];

    var sortedFarmers = _farmerTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    for (int i = 0; i < sortedFarmers.length && i < 7; i++) {
      legendItems.add(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 12, height: 12, color: colors[i % colors.length]),
            const SizedBox(width: 4),
            Text(
              'Farmer ${sortedFarmers[i].key}',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textColor(context),
              ),
            ),
          ],
        ),
      );
    }
    return legendItems;
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
                    'Farmer Report',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryGreen(context),
                    ),
                  ),
                  Text(
                    'Total weight by farmer',
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
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

          // StreamBuilder to get the logs for the selected date
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
                      'No data found for this date.',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  );
                }

                // Process the data
                _farmerTotals = {};
                Map<dynamic, dynamic> logs =
                    snapshot.data!.snapshot.value as Map<dynamic, dynamic>;

                logs.forEach((key, value) {
                  String farmerId = value['farmer_id'] ?? 'unknown';
                  double weight = (value['weight'] ?? 0.0).toDouble();

                  _farmerTotals[farmerId] =
                      (_farmerTotals[farmerId] ?? 0.0) + weight;
                });

                // Sort the map by weight (highest first)
                var sortedEntries = _farmerTotals.entries.toList()
                  ..sort((a, b) => b.value.compareTo(a.value));

                return SingleChildScrollView(
                  child: Column(
                    children: [
                      // Pie Chart for Farmer Contributions
                      if (_farmerTotals.isNotEmpty)
                        Card(
                          color: AppTheme.cardColor(context),
                          margin: const EdgeInsets.only(bottom: 20),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Farmer Contributions',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textColor(context),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                SizedBox(
                                  height: 200,
                                  child: PieChart(
                                    PieChartData(
                                      sections: _buildPieChartSections(),
                                      sectionsSpace: 2,
                                      centerSpaceRadius: 40,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 4,
                                  children: _buildLegend(),
                                ),
                              ],
                            ),
                          ),
                        ),

                      // Farmer List
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: sortedEntries.length,
                        itemBuilder: (context, index) {
                          String farmerId = sortedEntries[index].key;
                          double totalWeight = sortedEntries[index].value;

                          // Use a FutureBuilder to get the farmer's name
                          return FutureBuilder(
                            future: _getFarmerName(farmerId),
                            builder:
                                (context, AsyncSnapshot<String> nameSnapshot) {
                                  String name =
                                      nameSnapshot.data ?? 'Loading...';
                                  return Card(
                                    margin: const EdgeInsets.symmetric(
                                      vertical: 6,
                                    ),
                                    child: ListTile(
                                      leading: CircleAvatar(
                                        backgroundColor: AppTheme.primaryGreen(
                                          context,
                                        ),
                                        child: Text(
                                          '${index + 1}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                      title: Text(
                                        name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      subtitle: Text('ID: $farmerId'),
                                      trailing: Text(
                                        '${totalWeight.toStringAsFixed(1)} kg',
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
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
