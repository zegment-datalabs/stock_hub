import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RouteToVanPage extends StatefulWidget {
  const RouteToVanPage({Key? key}) : super(key: key);

  @override
  _RouteToVanPageState createState() => _RouteToVanPageState();
}

class _RouteToVanPageState extends State<RouteToVanPage> {
  String? selectedVanId;
  Map<String, bool> selectedRoutes = {}; // Store selected routes

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Assign Route to Van",style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold,color: Colors.white))),
      body: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Van Selection
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection("vans").snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const CircularProgressIndicator();
                var vans = snapshot.data!.docs;
                return DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: "Select Van",
                    border: OutlineInputBorder(),
                  ),
                  value: selectedVanId,
                  onChanged: (value) {
                    setState(() => selectedVanId = value);
                  },
                  items: vans.map((doc) {
                    return DropdownMenuItem(
                      value: doc.id,
                      child: Text("Van: ${doc['van_name']}"),
                    );
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: 20),

            // Route Selection (Checkbox List)
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection("routes").snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                  var routes = snapshot.data!.docs;

                  return ListView(
                    children: routes.map((doc) {
                      String routeId = doc.id;
                      Map<String, dynamic> routeData = doc.data() as Map<String, dynamic>;
                      return CheckboxListTile(
                        title: Text("Route: ${routeData['route_name']}"),
                        subtitle: Text("${routeData['route_from']} → ${routeData['route_to']}"),
                        value: selectedRoutes[routeId] ?? false,
                        onChanged: (bool? value) {
                          setState(() {
                            selectedRoutes[routeId] = value ?? false;
                          });
                        },
                      );
                    }).toList(),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),

            // Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () => setState(() {
                    selectedVanId = null;
                    selectedRoutes.clear();
                  }),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text("Cancel", style: TextStyle(color: Colors.white)),
                ),
                ElevatedButton(
                  onPressed: _saveAssignment,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  child: const Text("Save", style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Function to get the next van_route_id
  Future<int> _getNextVanRouteId() async {
    DocumentReference counterRef = FirebaseFirestore.instance.collection("counters").doc("van_route_counter");

    return FirebaseFirestore.instance.runTransaction((transaction) async {
      DocumentSnapshot counterSnapshot = await transaction.get(counterRef);
      int nextId = 1; // Default start value

      if (counterSnapshot.exists) {
        int lastId = counterSnapshot.get("last_van_route_id") ?? 0;
        nextId = lastId + 1;
      }

      // Update counter in Firestore
      transaction.set(counterRef, {"last_van_route_id": nextId});
      return nextId;
    });
  }

  // Save Assignments
  Future<void> _saveAssignment() async {
    if (selectedVanId == null || selectedRoutes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a van and at least one route."), backgroundColor: Colors.red),
      );
      return;
    }

    List<String> assignedRoutes = selectedRoutes.entries
        .where((entry) => entry.value) // Only selected routes
        .map((entry) => entry.key)
        .toList();

    int nextVanRouteId = await _getNextVanRouteId();

    for (String routeId in assignedRoutes) {
      await FirebaseFirestore.instance.collection("van_routes").doc(nextVanRouteId.toString()).set({
        'van_route_id': nextVanRouteId,
        'van_id': int.parse(selectedVanId!), // Ensure integer type
        'route_id': int.parse(routeId), // Ensure integer type
      });
      nextVanRouteId++; // Increment ID for the next entry
    }

    // Update the last used van_route_id in Firestore counter
    await FirebaseFirestore.instance.collection("counters").doc("van_route_counter").set({
      "last_van_route_id": nextVanRouteId - 1, // Store the last used ID
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Routes assigned successfully!"), backgroundColor: Colors.green),
    );

    setState(() {
      selectedVanId = null;
      selectedRoutes.clear();
    });
  }
}
