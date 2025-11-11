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
  final DatabaseReference _databaseRef = FirebaseDatabase.instance.ref(
    '/latest_reading',
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
      stream: _databaseRef.onValue,
      builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        Map<dynamic, dynamic> data =
            snapshot.data!.snapshot.value as Map<dynamic, dynamic>;

        Map<dynamic, dynamic> gpsData =
            data['gps_location'] as Map<dynamic, dynamic>? ?? {};

        double lat = gpsData['latitude']?.toDouble() ?? 6.9271;
        double lon = gpsData['longitude']?.toDouble() ?? 79.8612;

        return Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Card(
              color: AppTheme.cardColor(context),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'GPS Location Data',
                      style: TextStyle(
                        color: AppTheme.textColor(context),
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Latitude: $lat',
                      style: TextStyle(
                        color: AppTheme.textColor(context),
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      'Longitude: $lon',
                      style: TextStyle(
                        color: AppTheme.textColor(context),
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Farmer ID: ${data['farmer_id'] ?? 'Unknown'}',
                      style: TextStyle(
                        color: AppTheme.textColor(context),
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Note: Google Maps integration removed for web compatibility. '
                      'Add flutter_map package for map visualization.',
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
