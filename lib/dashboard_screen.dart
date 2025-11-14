import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../main.dart'; // To use AppTheme

// Import your new animation file
import 'package:iot_tea/tea_leaf_animation.dart';

// --- NEW MODERN COLOR PALETTE ---
final Color primaryColor = Color(0xFF00796B); // Main Teal
final Color primaryColorDark = Color(0xFF004D40); // Dark Teal
final Color primaryColorLight = Color(0xFFB2DFDB); // Light Teal
final Color accentColor1 = Color(0xFFFFA726); // Orange
final Color accentColor2 = Color(0xFF546E7A); // Blue Grey

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  double _latestWeight = 0.0;
  double _weeklyTotal = 0.0;
  final Map<String, double> _farmerTotals = {};
  String _topFarmerId = '';
  double _topFarmerWeight = 0.0;
  final Map<String, String> _farmerNames = {};

  final DatabaseReference _workersRef = FirebaseDatabase.instance.ref(
    '/workers',
  );

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // (This function is the same, just here for completeness)
  Future<void> _loadData() async {
    DateTime now = DateTime.now();
    int latestTimestamp = 0;
    _weeklyTotal = 0.0;
    _farmerTotals.clear();
    _farmerNames.clear();
    _latestWeight = 0.0;
    _topFarmerId = '';
    _topFarmerWeight = 0.0;

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
            if (farmerId != 'unknown' && !_farmerNames.containsKey(farmerId)) {
              _farmerNames[farmerId] = await _getFarmerName(farmerId);
            }
            _farmerTotals[farmerId] = (_farmerTotals[farmerId] ?? 0.0) + weight;
            int timestamp = (log['timestamp'] ?? 0) as int;
            if (timestamp > latestTimestamp) {
              latestTimestamp = timestamp;
              _latestWeight = weight;
            }
          }
        }
      } catch (e) {
        debugPrint('Error loading logs for $dateKey: $e');
      }
    }

    if (_farmerTotals.isNotEmpty) {
      var sortedFarmers = _farmerTotals.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      _topFarmerId = sortedFarmers.first.key;
      _topFarmerWeight = sortedFarmers.first.value;
    }
    if (mounted) {
      setState(() {});
    }
  }

  // (This function is the same, just here for completeness)
  Future<String> _getFarmerName(String farmerId) async {
    if (_farmerNames.containsKey(farmerId)) {
      return _farmerNames[farmerId]!;
    }
    try {
      final snapshot = await _workersRef.child('$farmerId/name').get();
      if (snapshot.exists) {
        String name = snapshot.value.toString();
        _farmerNames[farmerId] = name;
        return name;
      }
    } catch (e) {
      debugPrint('Error fetching name for $farmerId: $e');
    }
    _farmerNames[farmerId] = 'ID: $farmerId';
    return 'ID: $farmerId';
  }

  List<PieChartSectionData> _buildPieChartSections() {
    List<PieChartSectionData> sections = [];
    List<Color> colors = [
      primaryColor,
      accentColor1,
      accentColor2,
      primaryColorLight,
      Colors.teal.shade200,
    ];

    var sortedFarmers = _farmerTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    double otherTotal = 0;
    int maxSections = 4; // Show top 4 + "Other"

    for (int i = 0; i < sortedFarmers.length; i++) {
      double percentage = (_weeklyTotal > 0)
          ? (sortedFarmers[i].value / _weeklyTotal) * 100
          : 0;
      if (i < maxSections) {
        sections.add(
          PieChartSectionData(
            value: sortedFarmers[i].value,
            title: '${percentage.toStringAsFixed(0)}%',
            color: colors[i % colors.length],
            radius: 50,
            titleStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              shadows: [Shadow(blurRadius: 2, color: Colors.black38)],
            ),
          ),
        );
      } else {
        otherTotal += sortedFarmers[i].value;
      }
    }

    if (otherTotal > 0) {
      double percentage = (_weeklyTotal > 0)
          ? (otherTotal / _weeklyTotal) * 100
          : 0;
      sections.add(
        PieChartSectionData(
          value: otherTotal,
          title: '${percentage.toStringAsFixed(0)}%',
          color: Colors.grey.shade400,
          radius: 50,
          titleStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: [Shadow(blurRadius: 2, color: Colors.black38)],
          ),
        ),
      );
    }
    return sections;
  }

  List<Widget> _buildLegend() {
    List<Widget> legendItems = [];
    List<Color> colors = [
      primaryColor,
      accentColor1,
      accentColor2,
      primaryColorLight,
      Colors.teal.shade200,
    ];

    var sortedFarmers = _farmerTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    double otherTotal = 0;
    int maxSections = 4;

    for (int i = 0; i < sortedFarmers.length; i++) {
      if (i < maxSections) {
        String farmerId = sortedFarmers[i].key;
        String name = _farmerNames[farmerId] ?? 'ID: $farmerId';
        legendItems.add(
          _LegendItem(
            color: colors[i % colors.length],
            text: name,
            context: context,
          ),
        );
      } else {
        otherTotal += sortedFarmers[i].value;
      }
    }

    if (otherTotal > 0) {
      legendItems.add(
        _LegendItem(
          color: Colors.grey.shade400,
          text: 'Other',
          context: context,
        ),
      );
    }
    return legendItems;
  }

  @override
  Widget build(BuildContext context) {
    // Check light/dark mode
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDarkMode ? Colors.grey[850]! : Colors.white;

    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- FIXED TITLE AREA ---
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tea Leaves Dashboard',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textColor(context),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Latest updates and weekly summary',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppTheme.textColor(context).withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),

            // --- FEATURED CARD (Weekly Total) ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Card(
                clipBehavior: Clip.antiAlias, // Important for gradient
                elevation: 8.0, // More shadow
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Container(
                  height: 180,
                  width: double.infinity,
                  // --- APPLY THE ANIMATION HERE ---
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: AnimatedCardBackground(
                          color1: primaryColor,
                          color2: primaryColorDark,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.calendar_view_week,
                              size: 32,
                              color: Colors.white,
                            ),
                            const Spacer(),
                            Text(
                              'Weekly Total',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${_weeklyTotal.toStringAsFixed(1)} kg',
                              style: const TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Past 7 days collection',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // --- 2-COLUMN GRID FOR OTHER CARDS ---
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              crossAxisSpacing: 16.0,
              mainAxisSpacing: 16.0,
              childAspectRatio: 1.0, // Make them square
              children: [
                _StatCard(
                  title: 'Latest Weight',
                  value: '${_latestWeight.toStringAsFixed(1)} kg',
                  icon: Icons.scale,
                  iconColor: accentColor1,
                  cardColor: cardColor,
                ),
                _StatCard(
                  title: 'Top Farmer',
                  value: _farmerNames[_topFarmerId] ?? 'ID: $_topFarmerId',
                  subtitle: '${_topFarmerWeight.toStringAsFixed(1)} kg',
                  icon: Icons.person,
                  iconColor: accentColor2,
                  cardColor: cardColor,
                ),
              ],
            ),
            const SizedBox(height: 20),

            // --- PIE CHART SECTION ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'Farmer Contributions',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textColor(context),
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_farmerTotals.isNotEmpty)
              Container(
                height: 180,
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: PieChart(
                  PieChartData(
                    sections: _buildPieChartSections(),
                    sectionsSpace: 3,
                    centerSpaceRadius: 50,
                  ),
                ),
              ),
            const SizedBox(height: 20),

            // --- LEGEND ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Wrap(
                spacing: 16,
                runSpacing: 10,
                children: _buildLegend(),
              ),
            ),
            const SizedBox(height: 30), // Extra space at bottom
          ],
        ),
      ),
    );
  }
}

// --- NEW MODERN STAT CARD WIDGET ---
class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color iconColor;
  final Color cardColor;

  const _StatCard({
    required this.title,
    required this.value,
    this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.cardColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: cardColor,
      elevation: 4.0, // Softer shadow
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Icon in a colored circle
            Container(
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 28, color: iconColor),
            ),

            // Spacer
            const SizedBox(height: 10),

            // Data
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textColor(context).withOpacity(0.8),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textColor(context),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.textColor(context).withOpacity(0.6),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// --- NEW LEGEND ITEM WIDGET ---
class _LegendItem extends StatelessWidget {
  const _LegendItem({
    required this.color,
    required this.text,
    required this.context,
  });

  final Color color;
  final String text;
  final BuildContext context;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(fontSize: 14, color: AppTheme.textColor(context)),
        ),
      ],
    );
  }
}
