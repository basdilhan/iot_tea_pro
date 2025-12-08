import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';

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

  // Default to Sri Lanka center
  CameraPosition _initialCameraPosition = const CameraPosition(
    target: LatLng(7.8731, 80.7718),
    zoom: 7.5,
  );

  bool _locationPermissionGranted = false;
  String _statusMessage = 'Loading map...';

  @override
  void initState() {
    super.initState();
    _checkLocationPermission();
  }

  Future<void> _checkLocationPermission() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() {
          _statusMessage = 'Location permission denied. Showing default view.';
          _locationPermissionGranted = false;
        });
        return;
      }

      setState(() {
        _locationPermissionGranted = true;
        _statusMessage = '';
      });

      // Try to get current location
      try {
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 5),
        );

        setState(() {
          _initialCameraPosition = CameraPosition(
            target: LatLng(position.latitude, position.longitude),
            zoom: 14.0,
          );
        });

        // Move camera to current location
        final GoogleMapController controller = await _controller.future;
        controller.animateCamera(
          CameraUpdate.newCameraPosition(_initialCameraPosition),
        );
      } catch (e) {
        debugPrint('Could not get current location: $e');
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Error checking permissions: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          StreamBuilder(
            stream: _workersRef.onValue,
            builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
              // Always show the map
              Set<Marker> markers = {};

              if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
                try {
                  Map<dynamic, dynamic> workersData =
                      snapshot.data!.snapshot.value as Map<dynamic, dynamic>;

                  workersData.forEach((workerId, workerData) {
                    if (workerData != null) {
                      Map<dynamic, dynamic> worker =
                          workerData as Map<dynamic, dynamic>;

                      Map<dynamic, dynamic>? homeGps =
                          worker['home_gps_location'] as Map<dynamic, dynamic>?;

                      if (homeGps != null &&
                          homeGps['latitude'] != null &&
                          homeGps['longitude'] != null) {
                        double lat = homeGps['latitude'].toDouble();
                        double lon = homeGps['longitude'].toDouble();
                        String name = worker['name'] ?? 'Unknown';

                        markers.add(
                          Marker(
                            markerId: MarkerId(workerId.toString()),
                            position: LatLng(lat, lon),
                            infoWindow: InfoWindow(
                              title: name,
                              snippet: 'Worker ID: $workerId',
                            ),
                            icon: BitmapDescriptor.defaultMarkerWithHue(
                              BitmapDescriptor.hueCyan,
                            ),
                          ),
                        );
                      }
                    }
                  });
                } catch (e) {
                  debugPrint('Error parsing workers: $e');
                }
              }

              return GoogleMap(
                mapType: MapType.normal,
                initialCameraPosition: _initialCameraPosition,
                markers: markers,
                onMapCreated: (GoogleMapController controller) {
                  if (!_controller.isCompleted) {
                    _controller.complete(controller);
                  }
                },
                myLocationEnabled: _locationPermissionGranted,
                myLocationButtonEnabled: _locationPermissionGranted,
                compassEnabled: true,
                scrollGesturesEnabled: true,
                zoomGesturesEnabled: true,
                rotateGesturesEnabled: true,
                tiltGesturesEnabled: true,
              );
            },
          ),
          if (_statusMessage.isNotEmpty)
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Text(
                    _statusMessage,
                    style: const TextStyle(fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: _locationPermissionGranted
          ? FloatingActionButton(
              onPressed: () async {
                try {
                  Position position = await Geolocator.getCurrentPosition();
                  final GoogleMapController controller =
                      await _controller.future;
                  controller.animateCamera(
                    CameraUpdate.newCameraPosition(
                      CameraPosition(
                        target: LatLng(position.latitude, position.longitude),
                        zoom: 14.0,
                      ),
                    ),
                  );
                } catch (e) {
                  final messenger = ScaffoldMessenger.of(context);
                  messenger.showSnackBar(
                    SnackBar(content: Text('Could not get location: $e')),
                  );
                }
              },
              child: const Icon(Icons.my_location),
            )
          : null,
    );
  }
}
