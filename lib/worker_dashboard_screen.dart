import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import 'payment_provider.dart';
import 'ui_design.dart';
import 'animated_welcome_message.dart';

class WorkerDashboardScreen extends StatefulWidget {
  final String workerId;

  const WorkerDashboardScreen({super.key, required this.workerId});

  @override
  State<WorkerDashboardScreen> createState() => _WorkerDashboardScreenState();
}

class _WorkerDashboardScreenState extends State<WorkerDashboardScreen>
    with AutomaticKeepAliveClientMixin, TickerProviderStateMixin {
  double _todayTotal = 0.0;
  double _weekTotal = 0.0;
  double _monthTotal = 0.0;
  int _todayRecords = 0;
  bool _isLoading = true;
  String _workerName = 'Worker';
  List<Map<String, dynamic>> _recentRecords = [];
  late AnimationController _teaLeafAnimation;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _teaLeafAnimation = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat();
    _loadWorkerName();
    _loadData();
  }

  Future<void> _loadWorkerName() async {
    try {
      final event = await FirebaseDatabase.instance
          .ref('/workers/${widget.workerId}')
          .once();

      if (event.snapshot.value != null) {
        final workerData = event.snapshot.value as Map<dynamic, dynamic>;
        final name = workerData['name']?.toString() ?? widget.workerId;
        if (mounted) {
          setState(() {
            _workerName = name;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading worker name: $e');
    }
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
      String today = DateFormat('yyyy-MM-dd').format(now);

      double todaySum = 0.0;
      double weekSum = 0.0;
      double monthSum = 0.0;
      int recordCount = 0;
      List<Map<String, dynamic>> records = [];

      // Optimized: Parallel loading
      final List<Future<Map<String, dynamic>>> futures = [];

      for (int i = 0; i < 30; i++) {
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
        String dateKey = result['date'];
        Map<dynamic, dynamic> logs = result['logs'];

        if (logs.isNotEmpty) {
          logs.forEach((logId, logData) {
            String logWorkerId = logData['worker_id']?.toString().trim() ?? '';
            String logFarmerId = logData['farmer_id']?.toString().trim() ?? '';
            String workerId = widget.workerId.toString().trim();

            bool isMatch =
                (logWorkerId.isNotEmpty && logWorkerId == workerId) ||
                (logFarmerId.isNotEmpty && logFarmerId == workerId);

            if (isMatch) {
              double weight = (logData['weight'] ?? 0.0).toDouble();
              int timestamp = 0;
              if (logData['timestamp'] != null) {
                timestamp = (logData['timestamp'] is int)
                    ? logData['timestamp'] as int
                    : int.tryParse(logData['timestamp'].toString()) ?? 0;
              }

              monthSum += weight;

              if (dateKey.compareTo(
                    DateFormat(
                      'yyyy-MM-dd',
                    ).format(now.subtract(const Duration(days: 7))),
                  ) >=
                  0) {
                weekSum += weight;
              }

              if (dateKey == today) {
                todaySum += weight;
                recordCount++;
              }

              if (records.length < 15) {
                records.add({
                  'weight': weight,
                  'timestamp': timestamp,
                  'date': dateKey,
                  'log_id': logId,
                });
              }
            }
          });
        }
      }

      records.sort((a, b) {
        int timeA = (a['timestamp'] as int?) ?? 0;
        int timeB = (b['timestamp'] as int?) ?? 0;
        return timeB.compareTo(timeA);
      });

      if (mounted) {
        setState(() {
          _todayTotal = todaySum;
          _weekTotal = weekSum;
          _monthTotal = monthSum;
          _todayRecords = recordCount;
          _recentRecords = records;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading worker data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final paymentProvider = Provider.of<PaymentProvider>(context);

    return RefreshIndicator(
      onRefresh: _loadData,
      color: const Color(0xFF2ECC71),
      backgroundColor: UIDesign.charcoalElevated,
      child: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF2ECC71)),
            )
          : CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // Header
                SliverAppBar(
                  expandedHeight: 260,
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
                            const Color(0xFF2ECC71).withOpacity(0.85),
                            const Color(0xFFFFB300).withOpacity(0.75),
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
                                    "Worker's Dashboard",
                                    style: TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _workerName.isNotEmpty
                                        ? _workerName
                                        : 'ID: ${widget.workerId}',
                                    style: TextStyle(
                                      fontSize: 13,
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
                          userName: _workerName,
                          userRole: 'Farmer Worker',
                          showTeaLeaf: true,
                        ),
                        const SizedBox(height: 20),
                        // Today's Harvest Hero Card
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                const Color(0xFF2ECC71).withOpacity(0.3),
                                const Color(0xFFFFB300).withOpacity(0.2),
                              ],
                            ),
                            border: Border.all(
                              color: const Color(0xFF2ECC71).withOpacity(0.4),
                              width: 1.5,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF2ECC71).withOpacity(0.3),
                                blurRadius: 28,
                                spreadRadius: 2,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(20),
                          child: Row(
                            children: [
                              Container(
                                width: 70,
                                height: 70,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      const Color(0xFF2ECC71).withOpacity(0.25),
                                      const Color(0xFFFFB300).withOpacity(0.20),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Icon(
                                  Icons.eco,
                                  color: Color(0xFF2ECC71),
                                  size: 40,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      "Today's Harvest",
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: UIDesign.textSecondary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.baseline,
                                      textBaseline: TextBaseline.alphabetic,
                                      children: [
                                        Text(
                                          _todayTotal.toStringAsFixed(1),
                                          style: const TextStyle(
                                            fontSize: 40,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF2ECC71),
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        const Text(
                                          'kg',
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: UIDesign.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      '₨${NumberFormat('#,##0').format(paymentProvider.calculateEarnings(_todayTotal))}',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: UIDesign.successGreen,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Stats Row
                        Row(
                          children: [
                            Expanded(
                              child: _MiniStatCard(
                                title: 'This Week',
                                value: _weekTotal.toStringAsFixed(1),
                                unit: 'kg',
                                icon: Icons.calendar_view_week,
                                color: const Color(0xFF2ECC71),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _MiniStatCard(
                                title: 'This Month',
                                value: _monthTotal.toStringAsFixed(1),
                                unit: 'kg',
                                icon: Icons.calendar_month,
                                color: const Color(0xFFFFB300),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _MiniStatCard(
                                title: 'Daily Avg',
                                value: _todayRecords > 0
                                    ? (_todayTotal / _todayRecords)
                                          .toStringAsFixed(2)
                                    : '0.0',
                                unit: 'kg',
                                icon: Icons.trending_up,
                                color: const Color(0xFF2ECC71),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _MiniStatCard(
                                title: 'Records',
                                value: _todayRecords.toString(),
                                unit: 'today',
                                icon: Icons.receipt_long,
                                color: const Color(0xFFFFB300),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        // Recent Records
                        if (_recentRecords.isNotEmpty)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Recent Harvests',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: UIDesign.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 12),
                              ..._recentRecords.map((record) {
                                final timestamp =
                                    (record['timestamp'] as int?) ?? 0;
                                final date = timestamp > 0
                                    ? DateTime.fromMillisecondsSinceEpoch(
                                        timestamp > 9999999999
                                            ? timestamp
                                            : timestamp * 1000,
                                      )
                                    : DateTime.now();
                                final timeStr = DateFormat(
                                  'HH:mm',
                                ).format(date);
                                final dateStr = record['date'] as String;

                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: UIDesign.charcoalElevated,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: const Color(
                                          0xFF2ECC71,
                                        ).withOpacity(0.2),
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(
                                            0xFF2ECC71,
                                          ).withOpacity(0.2),
                                          blurRadius: 12,
                                          spreadRadius: 1,
                                        ),
                                      ],
                                    ),
                                    padding: const EdgeInsets.all(12),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 44,
                                          height: 44,
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                              colors: [
                                                const Color(
                                                  0xFF2ECC71,
                                                ).withOpacity(0.7),
                                                const Color(
                                                  0xFFFFB300,
                                                ).withOpacity(0.6),
                                              ],
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.scale,
                                            color: Colors.white,
                                            size: 22,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Harvest Logged',
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                  color: UIDesign.textPrimary,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                '$dateStr at $timeStr',
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: UIDesign.textSecondary,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Text(
                                          '${(record['weight'] as double).toStringAsFixed(1)} kg',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF2ECC71),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            ],
                          ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _MiniStatCard extends StatelessWidget {
  final String title;
  final String value;
  final String unit;
  final IconData icon;
  final Color color;

  const _MiniStatCard({
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
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.35),
            blurRadius: 16,
            spreadRadius: 1,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  color: UIDesign.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, color: color, size: 14),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(width: 2),
              Text(
                unit,
                style: const TextStyle(
                  fontSize: 11,
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
