import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:async';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => MapScreenState();
}

class MapScreenState extends State<MapScreen> {
  final Completer<GoogleMapController> _controller = Completer();
  final DatabaseReference _databaseRef = FirebaseDatabase.instance.ref(
    '/latest_reading',
  );

  static const CameraPosition _defaultLocation = CameraPosition(
    target: LatLng(6.9271, 79.8612), // Default to Colombo, Sri Lanka
    zoom: 14.0,
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

        LatLng currentPosition = LatLng(lat, lon);

        // Update camera to new position
        _moveCamera(currentPosition);

        return GoogleMap(
          mapType: MapType.hybrid,
          initialCameraPosition: _defaultLocation,
          onMapCreated: (GoogleMapController controller) {
            _controller.complete(controller);
          },
          markers: {
            // The single marker for the latest reading
            Marker(
              markerId: const MarkerId('latest_reading'),
              position: currentPosition,
              infoWindow: InfoWindow(
                title: 'Last Weigh-in',
                snippet: 'Farmer: ${data['farmer_id']}',
              ),
            ),
          },
        );
      },
    );
  }

  // Function to animate camera to new position
  Future<void> _moveCamera(LatLng position) async {
    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: position, zoom: 16.0),
      ),
    );
  }
}
