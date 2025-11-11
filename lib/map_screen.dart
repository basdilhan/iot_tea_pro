import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_database/firebase_database.dart';
import '../main.dart'; // To use AppTheme

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => MapScreenState();
}

class MapScreenState extends State<MapScreen> {
  final DatabaseReference _workersRef = FirebaseDatabase.instance.ref(
    '/workers',
  );
  final DatabaseReference _devicesRef = FirebaseDatabase.instance.ref(
    '/devices',
  );

  @override
  Widget build(BuildContext context) {
    // On web, the Google Maps JS API must be added to web/index.html.
    // If it's not present the JS runtime throws "cannot read properties of undefined (reading 'maps')".
    // To avoid a hard crash in web debug, show an instructional placeholder instead.
    if (kIsWeb) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Card(
            color: Colors.red.shade800,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Google Maps not available on Web',
                    style: TextStyle(
                      color: Colors.yellow.shade200,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'To enable maps on Flutter Web, add the Google Maps JavaScript API script with your API key to `web/index.html`.',
                  ),
                  const SizedBox(height: 8),
                  const SelectableText(
                    "Add this inside the <head> tag in web/index.html:\n\n<script src=\"https://maps.googleapis.com/maps/api/js?key=YOUR_API_KEY&libraries=places\"></script>\n",
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Or use an alternative map plugin that supports web without the Google API (e.g. flutter_map + OpenStreetMap).',
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    return StreamBuilder(
      stream: _workersRef.onValue,
      builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        Map<dynamic, dynamic> workersData =
            snapshot.data!.snapshot.value as Map<dynamic, dynamic>;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Worker GPS Locations',
                style: TextStyle(
                  color: AppTheme.textColor(context),
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: 16),
              ...workersData.entries.map((entry) {
                String workerId = entry.key;
                Map<dynamic, dynamic> worker =
                    entry.value as Map<dynamic, dynamic>;
                Map<dynamic, dynamic> homeGps =
                    worker['home_gps_location'] as Map<dynamic, dynamic>? ?? {};

                double lat = homeGps['latitude']?.toDouble() ?? 0.0;
                double lon = homeGps['longitude']?.toDouble() ?? 0.0;
                String name = worker['name'] ?? 'Unknown';
                String assignedArea = worker['assigned_area'] ?? 'Unknown';

                return Card(
                  color: AppTheme.cardColor(context),
                  margin: const EdgeInsets.only(bottom: 12.0),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: TextStyle(
                            color: AppTheme.textColor(context),
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Worker ID: $workerId',
                          style: TextStyle(
                            color: AppTheme.textColor(context),
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          'Assigned Area: $assignedArea',
                          style: TextStyle(
                            color: AppTheme.textColor(context),
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Home GPS Location:',
                          style: TextStyle(
                            color: AppTheme.textColor(context),
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          'Latitude: $lat',
                          style: TextStyle(
                            color: AppTheme.textColor(context),
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          'Longitude: $lon',
                          style: TextStyle(
                            color: AppTheme.textColor(context),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ],
          ),
        );
      },
    );
  }
}
