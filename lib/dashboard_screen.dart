import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import '../main.dart'; // To use AppTheme

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final DatabaseReference _latestRef = FirebaseDatabase.instance.ref(
    '/latest_reading',
  );

  // New reference to today's logs
  final DatabaseReference _todayLogRef = FirebaseDatabase.instance.ref(
    '/weighing_logs/${DateFormat('yyyy-MM-dd').format(DateTime.now())}',
  );

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Live Dashboard',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryGreen,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Today: ${DateFormat('MMMM d, yyyy').format(DateTime.now())}',
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 20),

          // StreamBuilder for the "Live" card
          StreamBuilder(
            stream: _latestRef.onValue,
            builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
              String liveWeight = "0.0";
              String lastFarmer = "-";

              if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
                Map<dynamic, dynamic> data =
                    snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
                liveWeight = data['weight']?.toString() ?? '0.0';
                lastFarmer = data['farmer_id']?.toString() ?? '-';
              }

              return _StatCard(
                title: 'Live Weight',
                value: '$liveWeight kg',
                subtitle: 'Last reading from Farmer $lastFarmer',
                icon: Icons.satellite_alt,
                color: AppTheme.primaryGreen,
              );
            },
          ),

          const SizedBox(height: 16),

          // StreamBuilder for "Today's" totals
          StreamBuilder(
            stream: _todayLogRef.onValue,
            builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
              double totalWeight = 0.0;
              int totalWeighIns = 0;

              if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
                Map<dynamic, dynamic> logs =
                    snapshot.data!.snapshot.value as Map<dynamic, dynamic>;

                totalWeighIns = logs.length;

                for (var log in logs.values) {
                  totalWeight += (log['weight'] ?? 0.0).toDouble();
                }
              }

              // Use a GridView for the other stats
              return GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                shrinkWrap:
                    true, // Important for GridView in SingleChildScrollView
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _StatCard(
                    title: 'Total Today',
                    value: '${totalWeight.toStringAsFixed(1)} kg',
                    subtitle: 'From $totalWeighIns weigh-ins',
                    icon: Icons.scale,
                    color: AppTheme.accentOrange,
                  ),
                  _StatCard(
                    title: 'Total Weigh-ins',
                    value: '$totalWeighIns',
                    subtitle: 'All collection points',
                    icon: Icons.shopping_bag,
                    color: Colors.blue[700]!,
                  ),
                ],
              );
            },
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
    return Card(
      color: color,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, size: 32, color: Colors.white),
            const SizedBox(height: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.7),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
