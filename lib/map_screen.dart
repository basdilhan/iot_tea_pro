import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async'; // For Completer

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => MapScreenState();
}

class MapScreenState extends State<MapScreen> {
  final DatabaseReference _workersRef = FirebaseDatabase.instance.ref(
    '/workers',
  );

  final Completer<GoogleMapController> _controller = Completer();

  // Set the initial camera position (e.g., center of Sri Lanka)
  static const CameraPosition _initialCameraPosition = CameraPosition(
    target: LatLng(7.8731, 80.7718),
    zoom: 7.5,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder(
        stream: _workersRef.onValue,
        builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          // 1. Prepare a set to hold all the map markers
          Set<Marker> markers = {};

          if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
            Map<dynamic, dynamic> workersData =
                snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
            
            workersData.forEach((workerId, workerData) {
              Map<dynamic, dynamic> worker = workerData as Map<dynamic, dynamic>;
              
              // 2. Read the nested GPS location
              Map<dynamic, dynamic>? homeGps =
                  worker['home_gps_location'] as Map<dynamic, dynamic>?;

              if (homeGps != null && homeGps['latitude'] != null && homeGps['longitude'] != null) {
                double lat = homeGps['latitude'].toDouble();
                double lon = homeGps['longitude'].toDouble();
                String name = worker['name'] ?? 'Unknown';

                // 3. Create a Marker for each worker
                markers.add(
                  Marker(
                    markerId: MarkerId(workerId),
                    position: LatLng(lat, lon),
                    infoWindow: InfoWindow(
                      title: name,
                      snippet: 'ID: $workerId',
                    ),
                  ),
                );
              }
            });
          }

          // 4. Return the GoogleMap widget
          return GoogleMap(
            mapType: MapType.normal,
            initialCameraPosition: _initialCameraPosition,
            markers: markers, // Display all the markers
            onMapCreated: (GoogleMapController controller) {
              if (!_controller.isCompleted) {
                 _controller.complete(controller);
              }
            },
            // This is required for web to handle mouse scrolling
            scrollGesturesEnabled: true,
            zoomGesturesEnabled: true, 
          );
        },
      ),
    );
  }
}