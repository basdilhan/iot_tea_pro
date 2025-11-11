import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../main.dart'; // To use AppTheme

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  double _latestWeight = 0.0;
  double _weeklyTotal = 0.0;
  Map<String, double> _farmerTotals = {};
  String _topFarmerId = '';
  double _topFarmerWeight = 0.0;

  // We need this ref to look up names
  final DatabaseReference _workersRef = FirebaseDatabase.instance.ref(
    '/workers',
  );

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    DateTime now = DateTime.now();
    int latestTimestamp = 0;

    for (int i = 6; i >= 0; i--) {
      DateTime date = now.subtract(Duration(days: i));
      String dateKey = DateFormat('yyyy-MM-dd').format(date);
      DatabaseReference ref = FirebaseDatabase.instance.ref(
        '/weighing_logs/$dateKey',
      );

      try {
        DatabaseEvent event = await ref.once();
        if (event.snapshot.value != null) {
          Map<dynamic, dynamic> logs =
              event.snapshot.value as Map<dynamic, dynamic>;
          for (var log in logs.values) {
            double weight = (log['weight'] ?? 0.0).toDouble();
            _weeklyTotal += weight;
            String farmerId = log['farmer_id'] ?? 'unknown';
            _farmerTotals[farmerId] = (_farmerTotals[farmerId] ?? 0.0) + weight;
            int timestamp = (log['timestamp'] ?? 0) as int;
            if (timestamp > latestTimestamp) {
              latestTimestamp = timestamp;
              _latestWeight = weight;
            }
          }
        }
      } catch (e) {
        // Ignore errors for now
      }
    }

    // Find top farmer
    if (_farmerTotals.isNotEmpty) {
      var sortedFarmers = _farmerTotals.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      _topFarmerId = sortedFarmers.first.key;
      _topFarmerWeight = sortedFarmers.first.value;
    }

    setState(() {});
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

    for (int i = 0; i < sortedFarmers.length && i < 7; i++) {
      double percentage = (_weeklyTotal > 0)
          ? (sortedFarmers[i].value / _weeklyTotal) * 100
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tea Leaves Dashboard',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryGreen(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Latest updates and weekly summary',
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(
                context,
              ).textTheme.bodyMedium?.color?.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 20),

          // Latest Weight Card
          _StatCard(
            title: 'Latest Weight',
            value: '${_latestWeight.toStringAsFixed(1)} kg',
            subtitle: 'Most recent weighing',
            icon: Icons.scale,
            color: AppTheme.primaryGreen(context),
          ),
          const SizedBox(height: 16),

          // Weekly Total Card
          _StatCard(
            title: 'Weekly Total',
            value: '${_weeklyTotal.toStringAsFixed(1)} kg',
            subtitle: 'Past 7 days collection',
            icon: Icons.calendar_view_week,
            color: AppTheme.accentOrange(context),
          ),
          const SizedBox(height: 16),

          // Top Farmer Card
          if (_topFarmerId.isNotEmpty)
            FutureBuilder<String>(
              future: _getFarmerName(_topFarmerId),
              builder: (context, snapshot) {
                String farmerName = snapshot.data ?? 'Loading...';
                return _StatCard(
                  title: 'Top Farmer',
                  value: '${_topFarmerWeight.toStringAsFixed(1)} kg',
                  subtitle: '$farmerName (ID: $_topFarmerId)',
                  icon: Icons.person,
                  color: Colors.blue,
                );
              },
            ),
          const SizedBox(height: 20),

          // Pie Chart for Farmer Contributions
          if (_farmerTotals.isNotEmpty)
            Card(
              color: AppTheme.cardColor(context),
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
                    Wrap(spacing: 8, runSpacing: 4, children: _buildLegend()),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// A re-usable widget for the dashboard cards
class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 170,
      child: Card(
        color: color,
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 28, color: Colors.white),
              const SizedBox(height: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withOpacity(0.7),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
