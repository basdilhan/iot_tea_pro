import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math' as math;
import 'ui_design.dart';
import 'animated_welcome_message.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with AutomaticKeepAliveClientMixin, TickerProviderStateMixin {
  double _latestWeight = 0.0;
  double _weeklyTotal = 0.0;
  final Map<String, double> _farmerTotals = {};
  String _topFarmerId = '';
  double _topFarmerWeight = 0.0;
  final Map<String, String> _farmerNames = {};
  bool _isLoading = true;
  late AnimationController _teaLeafAnimation;

  final DatabaseReference _workersRef = FirebaseDatabase.instance.ref(
    '/workers',
  );

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _teaLeafAnimation = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat();
    _loadData();
  }

  @override
  void dispose() {
    _teaLeafAnimation.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      DateTime now = DateTime.now();
      int latestTimestamp = 0;
      _weeklyTotal = 0.0;
      _farmerTotals.clear();
      _farmerNames.clear();
      _latestWeight = 0.0;
      _topFarmerId = '';
      _topFarmerWeight = 0.0;

      // Optimized: Load data in parallel where possible
      final List<Future<Map<String, dynamic>>> futures = [];

      for (int i = 6; i >= 0; i--) {
        DateTime date = now.subtract(Duration(days: i));
        String dateKey = DateFormat('yyyy-MM-dd').format(date);

        futures.add(
          FirebaseDatabase.instance
              .ref('/weighing_logs/$dateKey')
              .once()
              .then((event) {
                if (event.snapshot.value != null) {
                  Map<dynamic, dynamic> logs =
                      event.snapshot.value as Map<dynamic, dynamic>;
                  return {'logs': logs, 'date': dateKey};
                }
                return {'logs': {}, 'date': dateKey};
              })
              .catchError((e) {
                debugPrint('Error loading logs for $dateKey: $e');
                return {'logs': {}, 'date': dateKey};
              }),
        );
      }

      final results = await Future.wait(futures);

      for (var result in results) {
        Map<dynamic, dynamic> logs = result['logs'] as Map<dynamic, dynamic>;
        if (logs.isNotEmpty) {
          for (var log in logs.values) {
            double weight = (log['weight'] ?? 0.0).toDouble();
            _weeklyTotal += weight;
            String farmerId = log['farmer_id'] ?? 'unknown';

            if (farmerId != 'unknown' && !_farmerNames.containsKey(farmerId)) {
              _farmerNames[farmerId] = await _getFarmerName(farmerId);
            }

            _farmerTotals[farmerId] = (_farmerTotals[farmerId] ?? 0.0) + weight;
            int timestamp = 0;
            if (log['timestamp'] != null) {
              timestamp = (log['timestamp'] is int)
                  ? log['timestamp'] as int
                  : int.tryParse(log['timestamp'].toString()) ?? 0;
            }

            if (timestamp > latestTimestamp) {
              latestTimestamp = timestamp;
              _latestWeight = weight;
            }
          }
        }
      }

      if (_farmerTotals.isNotEmpty) {
        var sortedFarmers = _farmerTotals.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        _topFarmerId = sortedFarmers.first.key;
        _topFarmerWeight = sortedFarmers.first.value;
      }

      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Error loading dashboard data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<String> _getFarmerName(String farmerId) async {
    if (_farmerNames.containsKey(farmerId)) {
      return _farmerNames[farmerId]!;
    }
    try {
      final snapshot = await _workersRef.child('$farmerId/name').get();
      if (snapshot.exists) {
        return snapshot.value.toString();
      }
    } catch (e) {
      debugPrint('Error fetching name for $farmerId: $e');
    }
    return 'Farmer $farmerId';
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return RefreshIndicator(
      onRefresh: _loadData,
      color: UIDesign.accentCyan,
      backgroundColor: UIDesign.charcoalElevated,
      child: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: UIDesign.accentCyan),
            )
          : CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // Header Hero Section
                SliverAppBar(
                  expandedHeight: 280,
                  pinned: true,
                  elevation: 0,
                  backgroundColor: UIDesign.charcoalElevated,
                  flexibleSpace: FlexibleSpaceBar(
                    background: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            UIDesign.accentCyan.withOpacity(0.9),
                            UIDesign.accentPurple.withOpacity(0.8),
                          ],
                        ),
                      ),
                      child: SafeArea(
                        child: Stack(
                          children: [
                            // Animated tea leaf background
                            Positioned(
                              right: 20,
                              top: 20,
                              child: AnimatedBuilder(
                                animation: _teaLeafAnimation,
                                builder: (context, child) {
                                  final angle =
                                      _teaLeafAnimation.value * 2 * math.pi;
                                  final floatOffset = math.sin(angle * 2) * 4;

                                  return Transform.translate(
                                    offset: Offset(0, floatOffset),
                                    child: Transform.rotate(
                                      angle: math.sin(angle) * 0.25,
                                      child: Opacity(
                                        opacity: 0.4,
                                        child: Icon(
                                          Icons.eco,
                                          size: 60,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            // Main header content
                            Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 10),
                                  const Text(
                                    'Collector Dashboard',
                                    style: TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Weekly Overview',
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
                ),
                // Content
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        // Welcome Message
                        AnimatedWelcomeMessage(
                          userName: 'Collector',
                          userRole: 'Dashboard Manager',
                          showTeaLeaf: true,
                        ),
                        const SizedBox(height: 20),
                        // Stats Grid
                        Row(
                          children: [
                            Expanded(
                              child: _StatCard(
                                title: 'This Week',
                                value: _weeklyTotal.toStringAsFixed(1),
                                unit: 'kg',
                                icon: Icons.trending_up,
                                color: UIDesign.accentCyan,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _StatCard(
                                title: 'Latest',
                                value: _latestWeight.toStringAsFixed(1),
                                unit: 'kg',
                                icon: Icons.scale,
                                color: UIDesign.accentPurple,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Top Farmer Card
                        if (_topFarmerId.isNotEmpty)
                          Container(
                            decoration: BoxDecoration(
                              color: UIDesign.charcoalElevated,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: UIDesign.accentCyan.withOpacity(0.3),
                                width: 1,
                              ),
                              boxShadow: [
                                UIDesign.softGlow(UIDesign.accentCyan),
                              ],
                            ),
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: UIDesign.accentCyan.withOpacity(
                                          0.2,
                                        ),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(
                                        Icons.emoji_events,
                                        color: UIDesign.accentCyan,
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Top Performer',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: UIDesign.textSecondary,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _farmerNames[_topFarmerId] ??
                                              'Farmer $_topFarmerId',
                                          style: UIDesign.heroNumber(size: 20),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Total: ${_topFarmerWeight.toStringAsFixed(1)} kg',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: UIDesign.successGreen,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 16),
                        // Farmer List
                        if (_farmerTotals.isNotEmpty)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'All Farmers',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: UIDesign.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 12),
                              ..._farmerTotals.entries
                                  .toList()
                                  .asMap()
                                  .entries
                                  .map((e) {
                                    final index = e.key;
                                    final entry = e.value;
                                    return Padding(
                                      padding: EdgeInsets.only(
                                        bottom: index < _farmerTotals.length - 1
                                            ? 8
                                            : 0,
                                      ),
                                      child: _FarmerListItem(
                                        name:
                                            _farmerNames[entry.key] ??
                                            'Farmer ${entry.key}',
                                        weight: entry.value,
                                        index: index,
                                      ),
                                    );
                                  }),
                            ],
                          ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String unit;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.unit,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: UIDesign.charcoalElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
        boxShadow: [UIDesign.softGlow(color)],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  color: UIDesign.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                unit,
                style: const TextStyle(
                  fontSize: 14,
                  color: UIDesign.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FarmerListItem extends StatelessWidget {
  final String name;
  final double weight;
  final int index;

  const _FarmerListItem({
    required this.name,
    required this.weight,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final colors = [
      UIDesign.accentCyan,
      UIDesign.accentPurple,
      UIDesign.successGreen,
      UIDesign.warningAmber,
    ];
    final color = colors[index % colors.length];

    return Container(
      decoration: BoxDecoration(
        color: UIDesign.charcoalElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: UIDesign.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'This week',
                  style: TextStyle(
                    fontSize: 12,
                    color: UIDesign.textSecondary.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${weight.toStringAsFixed(1)} kg',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
