import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class ManageWorkersScreen extends StatefulWidget {
  const ManageWorkersScreen({super.key});

  @override
  State<ManageWorkersScreen> createState() => _ManageWorkersScreenState();
}

class _ManageWorkersScreenState extends State<ManageWorkersScreen> {
  final DatabaseReference _workersRef = FirebaseDatabase.instance.ref(
    '/workers',
  );

  // This function shows the popup dialog for adding/editing a worker
  void _showWorkerDialog({String? workerId, String? currentName}) {
    final TextEditingController idController = TextEditingController(
      text: workerId,
    );
    final TextEditingController nameController = TextEditingController(
      text: currentName,
    );

    // If we are editing, 'workerId' will not be null, so disable the ID field
    bool isEditing = workerId != null;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: Text(isEditing ? 'Edit Worker' : 'Add New Worker'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: idController,
                enabled: !isEditing, // Disable if editing
                decoration: const InputDecoration(
                  labelText: 'Farmer ID (e.g., 1234)',
                ),
              ),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Farmer Name'),
              ),
            ],
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

                if (id.isNotEmpty && name.isNotEmpty) {
                  // This is the WRITE command
                  _workersRef
                      .child(id)
                      .set({'name': name})
                      .then((_) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Worker ${isEditing ? 'updated' : 'added'}!',
                            ),
                          ),
                        );
                        Navigator.of(context).pop();
                      })
                      .catchError((error) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed: $error')),
                        );
                      });
                }
              },
            ),
          ],
        );
      },
    );
  }

  // This function handles deleting a worker
  void _deleteWorker(String workerId) {
    // This is the DELETE command
    _workersRef
        .child(workerId)
        .remove()
        .then((_) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Worker deleted!')));
        })
        .catchError((error) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Failed to delete: $error')));
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 1. READ the list of workers
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

          return ListView.builder(
            itemCount: workersMap.length,
            itemBuilder: (context, index) {
              String workerId = workersMap.keys.elementAt(index);
              Map<dynamic, dynamic> workerData =
                  workersMap[workerId] as Map<dynamic, dynamic>;
              String workerName = workerData['name'] ?? 'No Name';

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                child: ListTile(
                  title: Text(workerName),
                  subtitle: Text('ID: $workerId'),
                  // 2. EDIT by tapping
                  onTap: () => _showWorkerDialog(
                    workerId: workerId,
                    currentName: workerName,
                  ),
                  // 3. DELETE with a trailing button
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteWorker(workerId),
                  ),
                ),
              );
            },
          );
        },
      ),
      // 4. ADD a new worker
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showWorkerDialog(),
        tooltip: 'Add New Worker',
        child: const Icon(Icons.add),
      ),
    );
  }
}
