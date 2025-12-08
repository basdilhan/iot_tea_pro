import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:geolocator/geolocator.dart'; // <-- 1. IMPORT

class ManageWorkersScreen extends StatefulWidget {
  const ManageWorkersScreen({super.key});

  @override
  State<ManageWorkersScreen> createState() => _ManageWorkersScreenState();
}

class _ManageWorkersScreenState extends State<ManageWorkersScreen> {
  final DatabaseReference _workersRef = FirebaseDatabase.instance.ref(
    '/workers',
  );

  // --- 2. ADDED GPS HELPER FUNCTION ---
  Future<Position> _determinePosition() async {
    // ... (This function is correct, no changes needed)
    bool serviceEnabled;
    LocationPermission permission;
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      return Future.error(
        'Location permissions are permanently denied, we cannot request permissions.',
      );
    }
    return await Geolocator.getCurrentPosition();
  }

  // --- 3. MODIFIED DIALOG FUNCTION ---
  void _showWorkerDialog({
    String? workerId,
    Map<dynamic, dynamic>? workerData,
  }) {
    final TextEditingController idController = TextEditingController(
      text: workerId,
    );
    final TextEditingController nameController = TextEditingController(
      text: workerData?['name'],
    );
    final TextEditingController phoneController = TextEditingController(
      text: workerData?['phone_number'] ?? workerData?['phone'],
    );

    bool isEditing = workerId != null;
    Position? currentPosition;
    bool isLoadingLocation = false;

    // --- FIX #1: Read from the nested 'home_gps_location' object ---
    if (workerData?['home_gps_location'] != null &&
        workerData?['home_gps_location'] is Map) {
      var locationMap = workerData!['home_gps_location'];
      currentPosition = Position.fromMap({
        'latitude': locationMap['latitude'],
        'longitude': locationMap['longitude'],
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              title: Text(isEditing ? 'Edit Worker' : 'Add New Worker'),
              content: SingleChildScrollView(
                // Added for small screens
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: idController,
                      enabled: !isEditing,
                      decoration: const InputDecoration(
                        labelText: 'Farmer ID (e.g., W-001)',
                      ),
                    ),
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Farmer Name',
                      ),
                    ),
                    TextField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number (+94XXXXXXXXX)',
                        hintText: '+9477XXXXXXX',
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Location:',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        if (isLoadingLocation)
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        else
                          TextButton.icon(
                            icon: const Icon(Icons.my_location),
                            label: Text(
                              currentPosition == null
                                  ? 'Get Location'
                                  : 'Get Again',
                            ),
                            onPressed: () async {
                              setDialogState(() {
                                isLoadingLocation = true;
                              });
                              try {
                                Position position = await _determinePosition();
                                setDialogState(() {
                                  currentPosition = position;
                                  isLoadingLocation = false;
                                });
                              } catch (e) {
                                setDialogState(() {
                                  isLoadingLocation = false;
                                });
                                final messenger = ScaffoldMessenger.of(context);
                                messenger.showSnackBar(
                                  SnackBar(content: Text('Error: $e')),
                                );
                              }
                            },
                          ),
                      ],
                    ),
                    if (currentPosition != null)
                      Text(
                        'Lat: ${currentPosition!.latitude.toStringAsFixed(4)}, Lon: ${currentPosition!.longitude.toStringAsFixed(4)}',
                        style: const TextStyle(color: Colors.green),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  ),
                  child: const Text('Save'),
                  onPressed: () {
                    String id = idController.text.trim();
                    String name = nameController.text.trim();
                    String phone = phoneController.text.trim();

                    if (id.isEmpty || name.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('ID and Name are required!'),
                        ),
                      );
                      return;
                    }
                    if (phone.isEmpty || !phone.startsWith('+')) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Valid E.164 phone (e.g., +9477...) required',
                          ),
                        ),
                      );
                      return;
                    }
                    if (currentPosition == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please get GPS location!'),
                        ),
                      );
                      return;
                    }

                    // --- FIX #2: Save data in the correct nested structure ---
                    Map<String, dynamic> dataToSave = {
                      'name': name,
                      'phone_number': phone,
                      'home_gps_location': {
                        // Save as a nested map
                        'latitude': currentPosition!.latitude,
                        'longitude': currentPosition!.longitude,
                      },
                    };

                    if (!isEditing) {
                      dataToSave['registered_on'] = ServerValue.timestamp;
                      // You can also add other fields like 'assigned_area' here
                      // dataToSave['assigned_area'] = "Default Area";
                    }

                    final navigator = Navigator.of(context);
                    final messenger = ScaffoldMessenger.of(context);
                    _workersRef
                        .child(id)
                        .update(
                          dataToSave,
                        ) // Use .update to preserve other fields
                        .then((_) {
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(
                                'Worker ${isEditing ? 'updated' : 'added'}!',
                              ),
                            ),
                          );
                          navigator.pop();
                        })
                        .catchError((error) {
                          messenger.showSnackBar(
                            SnackBar(content: Text('Failed to save: $error')),
                          );
                        });
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _deleteWorker(String workerId) {
    final messenger = ScaffoldMessenger.of(context);
    _workersRef
        .child(workerId)
        .remove()
        .then((_) {
          messenger.showSnackBar(
            const SnackBar(content: Text('Worker deleted!')),
          );
        })
        .catchError((error) {
          messenger.showSnackBar(
            SnackBar(content: Text('Failed to delete: $error')),
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder(
        stream: _workersRef.onValue,
        builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
            return const Center(child: Text('No workers found.'));
          }

          Map<dynamic, dynamic> workersMap =
              snapshot.data!.snapshot.value as Map<dynamic, dynamic>;

          var workerList = workersMap.entries.toList();
          workerList.sort((a, b) => a.key.compareTo(b.key));

          return ListView.builder(
            itemCount: workerList.length,
            itemBuilder: (context, index) {
              String workerId = workerList[index].key;
              Map<dynamic, dynamic> workerData =
                  workerList[index].value as Map<dynamic, dynamic>;
              String workerName = workerData['name'] ?? 'No Name';
              String phone =
                  workerData['phone_number'] ??
                  workerData['phone'] ??
                  'No phone';

              // --- FIX #3: Read from the nested 'home_gps_location' object ---
              String locationText = 'No location set';
              if (workerData['home_gps_location'] != null &&
                  workerData['home_gps_location'] is Map) {
                var locationMap = workerData['home_gps_location'];
                // Check if keys exist before accessing
                if (locationMap['latitude'] != null &&
                    locationMap['longitude'] != null) {
                  locationText =
                      'Lat: ${locationMap['latitude'].toStringAsFixed(4)}, Lon: ${locationMap['longitude'].toStringAsFixed(4)}';
                }
              }

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                child: ListTile(
                  isThreeLine: true,
                  title: Text(workerName),
                  subtitle: Text('ID: $workerId\nPhone: $phone\n$locationText'),
                  onTap: () => _showWorkerDialog(
                    workerId: workerId,
                    workerData: workerData,
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      // ... (This delete dialog logic is correct)
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Are you sure?'),
                          content: Text('Do you want to delete $workerName?'),
                          actions: [
                            TextButton(
                              child: const Text('Cancel'),
                              onPressed: () => Navigator.of(ctx).pop(),
                            ),
                            TextButton(
                              child: const Text(
                                'Delete',
                                style: TextStyle(color: Colors.red),
                              ),
                              onPressed: () {
                                Navigator.of(ctx).pop();
                                _deleteWorker(workerId);
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showWorkerDialog(),
        tooltip: 'Add New Worker',
        child: const Icon(Icons.add),
      ),
    );
  }
}
