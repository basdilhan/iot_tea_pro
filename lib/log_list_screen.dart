import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';

class LogListScreen extends StatelessWidget {
  const LogListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final DatabaseReference logRef = FirebaseDatabase.instance.ref(
      '/weighing_log',
    );

    return StreamBuilder(
      stream: logRef.onValue, // Listens to the entire log
      builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
          return const Center(child: Text('No log entries found.'));
        }

        // Convert the map of logs into a list
        Map<dynamic, dynamic> logMap =
            snapshot.data!.snapshot.value as Map<dynamic, dynamic>;

        // Convert to a list and sort by timestamp (newest first)
        List<Map<dynamic, dynamic>> logList = logMap.entries.map((entry) {
          Map<dynamic, dynamic> log = entry.value as Map<dynamic, dynamic>;
          log['key'] = entry.key; // Keep the log ID
          return log;
        }).toList();

        // Sort by timestamp in descending order
        logList.sort(
          (a, b) => (b['timestamp'] as int).compareTo(a['timestamp'] as int),
        );

        return ListView.builder(
          itemCount: logList.length,
          itemBuilder: (context, index) {
            Map<dynamic, dynamic> log = logList[index];
            String weight = log['weight']?.toString() ?? '0';
            String unit = log['unit'] ?? 'kg';
            int timestamp = log['timestamp'] ?? 0;
            String farmerId = log['farmer_id'] ?? 'N/A';

            String formattedTime = 'No timestamp';
            if (timestamp != 0) {
              formattedTime = DateFormat(
                'MMM d, yyyy - hh:mm a',
              ).format(DateTime.fromMillisecondsSinceEpoch(timestamp * 1000));
            }

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.secondary.withOpacity(0.15),
                  child: Text(
                    weight,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                ),
                title: Text('$weight $unit - Farmer $farmerId'),
                subtitle: Text(formattedTime),
              ),
            );
          },
        );
      },
    );
  }
}
