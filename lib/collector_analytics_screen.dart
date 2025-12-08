import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'payment_provider.dart';
import 'animated_welcome_message.dart';

class CollectorAnalyticsScreen extends StatefulWidget {
  const CollectorAnalyticsScreen({super.key});

  @override
  State<CollectorAnalyticsScreen> createState() =>
      _CollectorAnalyticsScreenState();
}

class _CollectorAnalyticsScreenState extends State<CollectorAnalyticsScreen> {
  bool _isLoading = true;
  Map<String, WorkerWeeklyData> _workerData = {};
  final DatabaseReference _workersRef = FirebaseDatabase.instance.ref(
    '/workers',
  );
  int _selectedWeeks = 4; // Default to 4 weeks

  @override
  void initState() {
    super.initState();
    _loadAnalyticsData();
  }

  Future<void> _loadAnalyticsData() async {
    setState(() => _isLoading = true);

    try {
      DateTime now = DateTime.now();
      Map<String, WorkerWeeklyData> tempData = {};

      // Get all workers first
      DatabaseEvent workersEvent = await _workersRef.once();
      if (workersEvent.snapshot.value != null) {
        Map<dynamic, dynamic> workers =
            workersEvent.snapshot.value as Map<dynamic, dynamic>;

        for (var entry in workers.entries) {
          String workerId = entry.key;
          String workerName = entry.value['name'] ?? workerId;

          tempData[workerId] = WorkerWeeklyData(
            workerId: workerId,
            workerName: workerName,
            weeklyTotals: {},
            totalKg: 0.0,
          );
        }
      }

      // Load data for selected number of weeks
      for (int weekNum = 0; weekNum < _selectedWeeks; weekNum++) {
        DateTime weekStart = now.subtract(
          Duration(days: 7 * weekNum + now.weekday - 1),
        );

        String weekKey = 'Week ${_selectedWeeks - weekNum}';

        for (int day = 0; day < 7; day++) {
          DateTime date = weekStart.add(Duration(days: day));
          if (date.isAfter(now)) continue;

          String dateKey = DateFormat('yyyy-MM-dd').format(date);
          DatabaseReference logsRef = FirebaseDatabase.instance.ref(
            '/weighing_logs/$dateKey',
          );

          DatabaseEvent event = await logsRef.once();
          if (event.snapshot.value != null) {
            Map<dynamic, dynamic> logs =
                event.snapshot.value as Map<dynamic, dynamic>;

            logs.forEach((logId, logData) {
              String farmerId = logData['farmer_id'];
              double weight = (logData['weight'] ?? 0.0).toDouble();

              if (tempData.containsKey(farmerId)) {
                tempData[farmerId]!.weeklyTotals[weekKey] =
                    (tempData[farmerId]!.weeklyTotals[weekKey] ?? 0.0) + weight;
                tempData[farmerId]!.totalKg += weight;
              }
            });
          }
        }
      }

      // Remove workers with no data
      tempData.removeWhere((key, value) => value.totalKg == 0.0);

      if (mounted) {
        setState(() {
          _workerData = tempData;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading analytics: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _changeWeekRange(int weeks) {
    setState(() {
      _selectedWeeks = weeks;
    });
    _loadAnalyticsData();
  }

  @override
  Widget build(BuildContext context) {
    final paymentProvider = Provider.of<PaymentProvider>(context);

    // Sort workers by total kg (descending)
    List<WorkerWeeklyData> sortedWorkers = _workerData.values.toList()
      ..sort((a, b) => b.totalKg.compareTo(a.totalKg));

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.eco, size: 28),
            SizedBox(width: 8),
            Text('Worker Analytics'),
          ],
        ),
        actions: [
          PopupMenuButton<int>(
            icon: const Icon(Icons.calendar_today),
            tooltip: 'Select Week Range',
            onSelected: _changeWeekRange,
            itemBuilder: (context) => [
              const PopupMenuItem(value: 2, child: Text('Last 2 Weeks')),
              const PopupMenuItem(value: 4, child: Text('Last 4 Weeks')),
              const PopupMenuItem(value: 8, child: Text('Last 8 Weeks')),
              const PopupMenuItem(value: 12, child: Text('Last 12 Weeks')),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadAnalyticsData,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : sortedWorkers.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.analytics_outlined,
                      size: 64,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No data available for the selected period',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ],
                ),
              )
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Welcome Message
                    AnimatedWelcomeMessage(
                      userName: 'Collector',
                      userRole: 'Analytics Manager',
                      showTeaLeaf: true,
                    ),
                    const SizedBox(height: 24),
                    // Header
                    Text(
                      'Person-wise Performance',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Last $_selectedWeeks weeks analysis',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 24),

                    // Worker Cards
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: sortedWorkers.length,
                      itemBuilder: (context, index) {
                        WorkerWeeklyData worker = sortedWorkers[index];
                        double totalEarnings = paymentProvider
                            .calculateEarnings(worker.totalKg);

                        return Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          elevation: 3,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ExpansionTile(
                            leading: CircleAvatar(
                              backgroundColor: _getColorForRank(index),
                              child: Text(
                                '${index + 1}',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              worker.workerName,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            subtitle: Text(
                              'ID: ${worker.workerId}',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${worker.totalKg.toStringAsFixed(1)} kg',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                  ),
                                ),
                                Text(
                                  '₨${NumberFormat('#,##0').format(totalEarnings)}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                            children: [
                              Divider(height: 1),
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Weekly Breakdown',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    ...List.generate(_selectedWeeks, (
                                      weekIndex,
                                    ) {
                                      String weekKey =
                                          'Week ${_selectedWeeks - weekIndex}';
                                      double weekKg =
                                          worker.weeklyTotals[weekKey] ?? 0.0;
                                      double weekEarnings = paymentProvider
                                          .calculateEarnings(weekKg);

                                      return Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 8.0,
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Row(
                                              children: [
                                                Container(
                                                  width: 8,
                                                  height: 8,
                                                  decoration: BoxDecoration(
                                                    color: weekKg > 0
                                                        ? Colors.green
                                                        : Colors.grey,
                                                    shape: BoxShape.circle,
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  weekKey,
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.end,
                                              children: [
                                                Text(
                                                  '${weekKg.toStringAsFixed(1)} kg',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                Text(
                                                  '₨${NumberFormat('#,##0').format(weekEarnings)}',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.green,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      );
                                    }),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Color _getColorForRank(int rank) {
    if (rank == 0) return Colors.amber; // Gold
    if (rank == 1) return Colors.grey[400]!; // Silver
    if (rank == 2) return Colors.brown[300]!; // Bronze
    return Colors.blue;
  }
}

class WorkerWeeklyData {
  final String workerId;
  final String workerName;
  final Map<String, double> weeklyTotals;
  double totalKg;

  WorkerWeeklyData({
    required this.workerId,
    required this.workerName,
    required this.weeklyTotals,
    required this.totalKg,
  });
}
