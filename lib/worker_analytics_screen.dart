import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'payment_provider.dart';

class WorkerAnalyticsScreen extends StatefulWidget {
  final String workerId;

  const WorkerAnalyticsScreen({super.key, required this.workerId});

  @override
  State<WorkerAnalyticsScreen> createState() => _WorkerAnalyticsScreenState();
}

class _WorkerAnalyticsScreenState extends State<WorkerAnalyticsScreen> {
  bool _isLoading = true;
  List<WeeklyData> _weeklyData = [];
  double _averagePerWeek = 0.0;
  double _totalEarnings = 0.0;

  @override
  void initState() {
    super.initState();
    _loadWeeklyData();
  }

  Future<void> _loadWeeklyData() async {
    setState(() => _isLoading = true);

    try {
      DateTime now = DateTime.now();

      // Precompute week boundaries (last 8 weeks) and map dates to week indexes
      final List<DateTime> weekStarts = List.generate(8, (i) {
        return now.subtract(Duration(days: 7 * i + now.weekday - 1));
      });
      final List<DateTime> weekEnds = weekStarts
          .map((ws) => ws.add(const Duration(days: 6)))
          .toList();

      // Prepare all day fetches (up to 56) to run concurrently
      final List<_DayRequest> dayRequests = [];
      for (int weekNum = 0; weekNum < 8; weekNum++) {
        for (int day = 0; day < 7; day++) {
          final date = weekStarts[weekNum].add(Duration(days: day));
          if (date.isAfter(now)) continue; // skip future days in current week
          final dateKey = DateFormat('yyyy-MM-dd').format(date);
          dayRequests.add(_DayRequest(weekIndex: weekNum, dateKey: dateKey));
        }
      }

      // Fetch all days in parallel and compute day totals for this worker
      final futures = dayRequests.map((_DayRequest req) async {
        final ref = FirebaseDatabase.instance.ref(
          '/weighing_logs/${req.dateKey}',
        );
        final event = await ref.once();
        double dayTotal = 0.0;
        final value = event.snapshot.value;
        if (value is Map) {
          // Iterate logs and sum weights for this worker only
          value.forEach((_, dynamic logData) {
            try {
              if (logData is Map && logData['farmer_id'] == widget.workerId) {
                final w = (logData['weight'] ?? 0).toDouble();
                dayTotal += w;
              }
            } catch (_) {}
          });
        }
        return _DayTotal(weekIndex: req.weekIndex, totalKg: dayTotal);
      }).toList();

      final List<_DayTotal> dayTotals = await Future.wait(futures);

      // Aggregate day totals into week totals
      final List<double> weekTotals = List<double>.filled(8, 0.0);
      for (final dt in dayTotals) {
        weekTotals[dt.weekIndex] += dt.totalKg;
      }

      // Build WeeklyData list (keep same display rule: always show at least recent 4 weeks)
      List<WeeklyData> weeks = [];
      for (int i = 0; i < 8; i++) {
        if (weekTotals[i] > 0 || i < 4) {
          weeks.add(
            WeeklyData(
              weekStart: weekStarts[i],
              weekEnd: weekEnds[i],
              totalKg: weekTotals[i],
              weekNumber: i,
            ),
          );
        }
      }

      weeks = weeks.reversed.toList();

      final double total = weeks.fold(0.0, (sum, week) => sum + week.totalKg);
      final double average = weeks.isNotEmpty ? total / weeks.length : 0.0;

      if (mounted) {
        setState(() {
          _weeklyData = weeks;
          _averagePerWeek = average;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading weekly data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final paymentProvider = Provider.of<PaymentProvider>(context);
    _totalEarnings = _weeklyData.fold(
      0.0,
      (sum, week) => sum + paymentProvider.calculateEarnings(week.totalKg),
    );

    return RefreshIndicator(
      onRefresh: _loadWeeklyData,
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    'Weekly Analytics',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your performance over the last 8 weeks',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 24),

                  // Summary Cards
                  Row(
                    children: [
                      Expanded(
                        child: _SummaryCard(
                          title: 'Average/Week',
                          value: '${_averagePerWeek.toStringAsFixed(1)} kg',
                          icon: Icons.trending_up,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _SummaryCard(
                          title: 'Total Earnings',
                          value:
                              '₨${NumberFormat('#,##0').format(_totalEarnings)}',
                          icon: Icons.payments,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Bar Chart
                  Text(
                    'Weekly Harvest (kg)',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  if (_weeklyData.isEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Center(
                          child: Text(
                            'No data available',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      ),
                    )
                  else
                    Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: SizedBox(
                          height: 250,
                          child: BarChart(
                            BarChartData(
                              alignment: BarChartAlignment.spaceAround,
                              maxY:
                                  _weeklyData
                                      .map((e) => e.totalKg)
                                      .reduce((a, b) => a > b ? a : b) *
                                  1.2,
                              // Reduce animation cost for better perceived performance
                              barTouchData: BarTouchData(
                                enabled: true,
                                touchTooltipData: BarTouchTooltipData(
                                  getTooltipItem:
                                      (group, groupIndex, rod, rodIndex) {
                                        return BarTooltipItem(
                                          '${rod.toY.toStringAsFixed(1)} kg',
                                          TextStyle(color: Colors.white),
                                        );
                                      },
                                ),
                              ),
                              gridData: FlGridData(
                                show: true,
                                drawVerticalLine: false,
                              ),
                              titlesData: FlTitlesData(
                                show: true,
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (value, meta) {
                                      if (value.toInt() >= 0 &&
                                          value.toInt() < _weeklyData.length) {
                                        return Padding(
                                          padding: const EdgeInsets.only(
                                            top: 8.0,
                                          ),
                                          child: Text(
                                            'W${_weeklyData.length - value.toInt()}',
                                            style: TextStyle(fontSize: 10),
                                          ),
                                        );
                                      }
                                      return Text('');
                                    },
                                  ),
                                ),
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 40,
                                    getTitlesWidget: (value, meta) {
                                      return Text(
                                        value.toInt().toString(),
                                        style: TextStyle(fontSize: 10),
                                      );
                                    },
                                  ),
                                ),
                                topTitles: AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                rightTitles: AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                              ),
                              borderData: FlBorderData(show: false),
                              barGroups: _weeklyData.asMap().entries.map((
                                entry,
                              ) {
                                return BarChartGroupData(
                                  x: entry.key,
                                  barRods: [
                                    BarChartRodData(
                                      toY: entry.value.totalKg,
                                      color: const Color(0xFF2D5016),
                                      width: 16,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),

                  // Weekly List
                  Text(
                    'Weekly Breakdown',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),

                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _weeklyData.length,
                    itemBuilder: (context, index) {
                      WeeklyData week = _weeklyData[index];
                      double earnings = paymentProvider.calculateEarnings(
                        week.totalKg,
                      );

                      String dateRange =
                          '${DateFormat('MMM dd').format(week.weekStart)} - ${DateFormat('MMM dd').format(week.weekEnd)}';

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.green.withOpacity(0.1),
                            child: Text(
                              'W${_weeklyData.length - index}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          title: Text(
                            dateRange,
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            '${week.totalKg.toStringAsFixed(1)} kg harvested',
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '₨${NumberFormat('#,##0').format(earnings)}',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
    );
  }
}

class _DayRequest {
  final int weekIndex;
  final String dateKey;
  _DayRequest({required this.weekIndex, required this.dateKey});
}

class _DayTotal {
  final int weekIndex;
  final double totalKg;
  _DayTotal({required this.weekIndex, required this.totalKg});
}

class WeeklyData {
  final DateTime weekStart;
  final DateTime weekEnd;
  final double totalKg;
  final int weekNumber;

  WeeklyData({
    required this.weekStart,
    required this.weekEnd,
    required this.totalKg,
    required this.weekNumber,
  });
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
