import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:stock_hub/screens/pages/route_to_van.dart';

class SalesmanToVanPage extends StatefulWidget {
  const SalesmanToVanPage({Key? key}) : super(key: key);

  @override
  _SalesmanToVanPageState createState() => _SalesmanToVanPageState();
}

class _SalesmanToVanPageState extends State<SalesmanToVanPage> {
  String? selectedVanId;
  Map<String, bool> selectedSalesmen = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Salesman to Van Assignment")),
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Van Selection Dropdown
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
                    setState(() {
                      selectedVanId = value;
                      selectedSalesmen.clear(); // Clear selections when van changes
                    });
                  },
                  items: vans.map((doc) {
                    return DropdownMenuItem(
                      value: doc.id,
                      child: Text(doc['reg_no']),
                    );
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: 20),

            // Salesmen List with Checkboxes
            const Text(
              "Select Salesmen:",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection("salesmen").snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                  var salesmenList = snapshot.data!.docs;
                  return ListView(
                    children: salesmenList.map((doc) {
                      String salesmanId = doc.id;
                      String name = doc['salesman_name'];
                      return CheckboxListTile(
                        title: Text(name),
                        value: selectedSalesmen[salesmanId] ?? false,
                        onChanged: (bool? value) {
                          int currentSelectionCount = selectedSalesmen.values.where((v) => v).length;

                          if (value == true && currentSelectionCount >= 2) {
                            // Prevent selecting more than 2 salesmen
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("A van can have only 1 or 2 salesmen assigned."),
                                backgroundColor: Colors.orange,
                              ),
                            );
                          } else {
                            setState(() {
                              selectedSalesmen[salesmanId] = value!;
                            });
                          }
                        },
                      );
                    }).toList(),
                  );
                },
              ),
            ),

             // Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const RouteToVanPage()),
                    );
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text("Cancel", style: TextStyle(color: Colors.white)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    await _saveAssignments();
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const RouteToVanPage()),
                    );
                  },
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
  Future<int> _getNextVanSalesmanId() async {
  DocumentReference counterRef = FirebaseFirestore.instance.collection("counters").doc("van_salesman_counter");

  return FirebaseFirestore.instance.runTransaction((transaction) async {
    DocumentSnapshot counterSnapshot = await transaction.get(counterRef);

    int nextId = 1; // Default start value

    if (counterSnapshot.exists) {
      int lastId = counterSnapshot.get("last_van_salesman_id") ?? 0;
      nextId = lastId + 1;
    }

    // Update the counter in Firestore
    transaction.set(counterRef, {"last_van_salesman_id": nextId});

    return nextId;
  });
}

 Future<void> _saveAssignments() async {
  if (selectedVanId == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Please select a van."),
        backgroundColor: Colors.red,
      ),
    );
    return;
  }

  int selectedCount = selectedSalesmen.values.where((v) => v).length;

  if (selectedCount < 1 || selectedCount > 2) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("A van must have at least 1 and at most 2 salesmen assigned."),
        backgroundColor: Colors.orange,
      ),
    );
    return;
  }

  // Clear existing assignments for this van
  QuerySnapshot existingAssignments = await FirebaseFirestore.instance
      .collection("van_salesman")
      .where("van_id", isEqualTo: int.parse(selectedVanId!)) // Convert to int
      .get();

  for (var doc in existingAssignments.docs) {
    await FirebaseFirestore.instance.collection("van_salesman").doc(doc.id).delete();
  }

  // Save new assignments with integer IDs
  for (var entry in selectedSalesmen.entries) {
    if (entry.value) {
      // Generate a unique integer ID using timestamp
      int vanSalesmanId = await _getNextVanSalesmanId();

      await FirebaseFirestore.instance.collection("van_salesman").doc(vanSalesmanId.toString()).set({
        'van_salesman_id': vanSalesmanId, // Storing as integer
        'van_id': int.parse(selectedVanId!), // Convert van ID to int
        'salesman_id': int.parse(entry.key), // Convert salesman ID to int
      });
    }
  }

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text("Salesmen assigned to van successfully!"),
      backgroundColor: Colors.green,
    ),
  );
  setState(() {
    selectedSalesmen.clear();
  });
}
}
