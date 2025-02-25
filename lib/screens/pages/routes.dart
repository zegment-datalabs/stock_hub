import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class RoutesPage extends StatefulWidget {
  const RoutesPage({super.key});

  @override
  State<RoutesPage> createState() => _RoutesPageState();
}

class _RoutesPageState extends State<RoutesPage> {
  final CollectionReference routesCollection =
      FirebaseFirestore.instance.collection('routes');

  /// Get the next available 4-digit routeId
  Future<String> _getNextRouteId() async {
    QuerySnapshot query = await routesCollection.orderBy('routeId', descending: true).limit(1).get();

    if (query.docs.isEmpty) return '0001'; // Start from "0001"

    int lastId = int.tryParse(query.docs.first['routeId'].toString()) ?? 0;
    int nextId = (lastId + 1).clamp(1, 9999);

    return nextId.toString().padLeft(4, '0'); // Ensures 4-digit format
  }

  /// Show Bottom Sheet for Adding/Editing Routes
  void _showRouteForm({String? docId, String? routeName, String? from, String? to}) {
    TextEditingController nameController = TextEditingController(text: routeName ?? '');
    TextEditingController fromController = TextEditingController(text: from ?? '');
    TextEditingController toController = TextEditingController(text: to ?? '');

    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            top: 20,
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  docId == null ? 'Add Route' : 'Edit Route',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 15),

                // Route Name
                TextFormField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Route Name (Optional)',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.directions),
                  ),
                ),
                const SizedBox(height: 10),

                // Route From
                TextFormField(
                  controller: fromController,
                  decoration: InputDecoration(
                    labelText: 'Route From',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.location_on),
                  ),
                  validator: (value) => value!.isEmpty ? 'Enter starting location' : null,
                ),
                const SizedBox(height: 10),

                // Route To
                TextFormField(
                  controller: toController,
                  decoration: InputDecoration(
                    labelText: 'Route To',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.flag),
                  ),
                  validator: (value) => value!.isEmpty ? 'Enter destination location' : null,
                ),
                const SizedBox(height: 20),

                // Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel', style: TextStyle(fontSize: 16, color: Colors.grey)),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        if (formKey.currentState!.validate()) {
                          try {
                            if (docId == null) {
                              String newRouteId = await _getNextRouteId();
                              String finalRouteName = nameController.text.trim().isEmpty
                                  ? 'Route $newRouteId'
                                  : nameController.text.trim();

                              await routesCollection.doc(newRouteId).set({
                                'routeId': newRouteId, // Using as document ID
                                'routeName': finalRouteName,
                                'routeFrom': fromController.text,
                                'routeTo': toController.text,
                              });
                            } else {
                              await routesCollection.doc(docId).update({
                                'routeName': nameController.text.trim().isEmpty
                                    ? 'Route $docId'
                                    : nameController.text.trim(),
                                'routeFrom': fromController.text,
                                'routeTo': toController.text,
                              });
                            }
                            if (mounted) Navigator.pop(context);
                          } catch (e) {
                            debugPrint("Error: $e");
                          }
                        }
                      },
                      child: Text(docId == null ? 'Add' : 'Update'),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Delete a route with confirmation dialog
  void _deleteRoute(String docId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirm Deletion'),
          content: const Text('Are you sure you want to delete this route?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                await routesCollection.doc(docId).delete();
                Navigator.pop(context);
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Routes')),
      body: StreamBuilder<QuerySnapshot>(
        stream: routesCollection.orderBy('routeId').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Error loading routes'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          var routeList = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: routeList.length,
            itemBuilder: (context, index) {
              var data = routeList[index];
              var docId = data.id; // This is now the routeId
              var routeName = data['routeName'] ?? 'Route $docId';
              var routeFrom = data['routeFrom'];
              var routeTo = data['routeTo'];

              return Card(
                elevation: 5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                  title: Text(
                    routeName,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text('$routeFrom ➝ $routeTo', style: const TextStyle(fontSize: 16)),
                  trailing: Wrap(
                    spacing: 8,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _showRouteForm(docId: docId, routeName: routeName, from: routeFrom, to: routeTo),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteRoute(docId),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showRouteForm(),
        child: const Icon(Icons.add),
        tooltip: "Add New Route",
      ),
    );
  }
}
