import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';

// This is the same code from our previous `dashboard_screen.dart`
// I have just renamed the class to 'LiveViewScreen'

class LiveViewScreen extends StatefulWidget {
  const LiveViewScreen({super.key});

  @override
  State<LiveViewScreen> createState() => _LiveViewScreenState();
}

class _LiveViewScreenState extends State<LiveViewScreen> {
  final DatabaseReference _databaseRef = FirebaseDatabase.instance.ref(
    '/latest_reading',
  );

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: StreamBuilder(
          stream: _databaseRef.onValue,
          builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const CircularProgressIndicator();
            }
            if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            }
            if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
              Map<dynamic, dynamic> data =
                  snapshot.data!.snapshot.value as Map<dynamic, dynamic>;

              String weight = data['weight']?.toString() ?? '0.0';
              String unit = data['unit']?.toString() ?? 'kg';
              int timestamp = data['timestamp'] ?? 0;
              String farmerId = data['farmer_id']?.toString() ?? 'N/A';
              String deviceId = data['device_id']?.toString() ?? 'N/A';

              Map<dynamic, dynamic> gpsData =
                  data['gps_location'] as Map<dynamic, dynamic>? ?? {};
              String lat = gpsData['latitude']?.toString() ?? 'N/A';
              String lon = gpsData['longitude']?.toString() ?? 'N/A';

              String formattedTime = 'No timestamp';
              if (timestamp != 0) {
                formattedTime = DateFormat(
                  'MMM d, yyyy - hh:mm a',
                ).format(DateTime.fromMillisecondsSinceEpoch(timestamp * 1000));
              }

              return WeightDisplayCard(
                weight: weight,
                unit: unit,
                time: formattedTime,
                latitude: lat,
                longitude: lon,
                farmerId: farmerId,
                deviceId: deviceId, // Pass new data
              );
            }
            return const Text(
              'Waiting for data from IoT device...',
              style: TextStyle(fontSize: 18, color: Colors.grey),
              textAlign: TextAlign.center,
            );
          },
        ),
      ),
    );
  }
}

class WeightDisplayCard extends StatelessWidget {
  final String weight;
  final String unit;
  final String time;
  final String latitude;
  final String longitude;
  final String farmerId;
  final String deviceId; // New field

  const WeightDisplayCard({
    super.key,
    required this.weight,
    required this.unit,
    required this.time,
    required this.latitude,
    required this.longitude,
    required this.farmerId,
    required this.deviceId, // New field
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 8.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
      child: Container(
        padding: const EdgeInsets.all(25.0),
        child: SingleChildScrollView(
          // Added for small screens
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'LIVE WEIGHT',
                style: TextStyle(
                  fontSize: 22.0,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    weight,
                    style: const TextStyle(
                      fontSize: 72.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    unit,
                    style: const TextStyle(
                      fontSize: 28.0,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              const Divider(),
              const SizedBox(height: 20),
              _buildFarmerDetails(farmerId),
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 20),
              _buildDeviceDetails(deviceId), // New widget
              _buildDetailRow('Last Reading:', time),
              _buildDetailRow('GPS Location:', '$latitude, $longitude'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        Text(value, style: const TextStyle(fontSize: 16)),
        const SizedBox(height: 15),
      ],
    );
  }

  Widget _buildFarmerDetails(String farmerId) {
    final DatabaseReference workerNameRef = FirebaseDatabase.instance.ref(
      '/workers/$farmerId/name',
    );

    return FutureBuilder(
      future: workerNameRef.once(),
      builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
        String farmerName = 'Loading...';
        if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
          farmerName = snapshot.data!.snapshot.value.toString();
        } else if (snapshot.hasError) {
          farmerName = 'Error';
        } else if (snapshot.hasData && snapshot.data!.snapshot.value == null) {
          farmerName = 'Unknown ID';
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Farmer ID:', farmerId),
            _buildDetailRow('Farmer Name:', farmerName),
          ],
        );
      },
    );
  }

  // New widget to get device info
  Widget _buildDeviceDetails(String deviceId) {
    final DatabaseReference deviceNameRef = FirebaseDatabase.instance.ref(
      '/devices/$deviceId/location_name',
    );

    return FutureBuilder(
      future: deviceNameRef.once(),
      builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
        String deviceName = 'Loading...';
        if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
          deviceName = snapshot.data!.snapshot.value.toString();
        } else {
          deviceName = 'Unknown Device';
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [_buildDetailRow('Device:', deviceName)],
        );
      },
    );
  }
}
