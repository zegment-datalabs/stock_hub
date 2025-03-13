import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

final FirebaseFirestore _firestore = FirebaseFirestore.instance;

class RoutesPage extends StatefulWidget {
  const RoutesPage({super.key});

  @override
  State<RoutesPage> createState() => _RoutesPageState();
}

class _RoutesPageState extends State<RoutesPage> {
  final CollectionReference routesCollection =
      FirebaseFirestore.instance.collection('routes');

  // Get the next available 4-digit route_id
  Future<int> _getNextroute_id() async {
    try {
      var querySnapshot = await _firestore
          .collection('routes')
          .orderBy('route_id', descending: true) // Get the latest route ID
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return 1; // First route
      }

      // Get the last route ID as an integer
      int lastRouteId = querySnapshot.docs.first['route_id'];

      return lastRouteId + 1; // Increment the number and return as integer
    } catch (e) {
      print("Error generating Route ID: $e");
      return 1; // Fallback ID as integer
    }
  }

  // Show Bottom Sheet for Adding/Editing Routes
  void _showRouteForm(
      {String? docId, String? route_name, String? from, String? to}) {
    TextEditingController nameController =
        TextEditingController(text: route_name ?? '');
    TextEditingController fromController =
        TextEditingController(text: from ?? '');
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
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 15),

                // Route Name
                TextFormField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Route Name',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.directions),
                  ),
                ),
                const SizedBox(height: 10),

                // Route From
                TextFormField(
                  controller: fromController,
                  decoration: InputDecoration(
                    labelText: 'Route From',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.location_on),
                  ),
                  validator: (value) =>
                      value!.isEmpty ? 'Enter starting location' : null,
                ),
                const SizedBox(height: 10),

                // Route To
                TextFormField(
                  controller: toController,
                  decoration: InputDecoration(
                    labelText: 'Route To',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.flag),
                  ),
                  validator: (value) =>
                      value!.isEmpty ? 'Enter destination location' : null,
                ),
                const SizedBox(height: 20),

                // Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel',
                          style: TextStyle(fontSize: 16, color: Color.fromARGB(255, 201, 35, 35))),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        if (formKey.currentState!.validate()) {
                          try {
                            if (docId == null) {
                              int newroute_id = await _getNextroute_id();

                              await routesCollection
                                  .doc(newroute_id.toString())
                                  .set({
                                'route_id': newroute_id, // Using as document ID
                                'route_name': nameController.text.trim().isEmpty
                                    ? 'Route $docId'
                                    : nameController.text.trim(),
                                'route_from': fromController.text,
                                'route_to': toController.text,
                              });
                            } else {
                              await routesCollection.doc(docId).update({
                                'route_name': nameController.text.trim().isEmpty
                                    ? 'Route $docId'
                                    : nameController.text.trim(),
                                'route_from': fromController.text,
                                'route_to': toController.text,
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
      appBar: AppBar(title: const Text('Routes', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold,)
      ),  backgroundColor: Colors.indigo,
        iconTheme: const IconThemeData(color: Colors.black),
          centerTitle: true
          ),
    
      body: StreamBuilder<QuerySnapshot>(
        stream: routesCollection.orderBy('route_id').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Error loading routes'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          var routeList = snapshot.data!.docs;

        return ListView.separated(
  padding: const EdgeInsets.all(10),
  itemCount: routeList.length,
  separatorBuilder: (context, index) => const Divider(
    thickness: 1,
    height: 8, // Reduced height for less space between rows
    color: Colors.black,
  ),
  itemBuilder: (context, index) {
    var data = routeList[index];
    var docId = data.id; // This is now the route_id
    var route_name = data['route_name'] ?? 'Route $docId';
    var route_from = data['route_from'];
    var route_to = data['route_to'];

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 5, horizontal: 20),
      title: Text(
        route_name,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Text(
        '$route_from ➝ $route_to',
        style: const TextStyle(fontSize: 16),
      ),
      trailing: Wrap(
        spacing: 6,
        children: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.orange),
            onPressed: () => _showRouteForm(
              docId: docId,
              route_name: route_name,
              from: route_from,
              to: route_to,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete, color:Color.fromARGB(255, 153, 29, 20)),
            onPressed: () => _deleteRoute(docId),
          ),
        ],
      ),
    );
  },
);

        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showRouteForm(),
        backgroundColor: Colors.indigo,
        child: const Icon(Icons.add, color: Colors.white),
        tooltip: "Add New Route",
      ),
    );
  }
}
