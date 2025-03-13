import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class SalesmanPage extends StatefulWidget {
  const SalesmanPage({super.key});

  @override
  State<SalesmanPage> createState() => _SalesmanPageState();
}

class _SalesmanPageState extends State<SalesmanPage> {
  final CollectionReference salesmen =
      FirebaseFirestore.instance.collection('salesmen');

  /// Get the next available 4-digit salesman_id
  Future<int> _getNextsalesman_id() async {
    QuerySnapshot query = await salesmen.get(); // Fetch all documents

    List<int> ids = query.docs
        .map((doc) => int.tryParse(doc.id) ?? 0) // Convert doc ID to int
        .toList();

    ids.sort((a, b) => b.compareTo(a)); // Sort in descending order

    int nextId = (ids.isNotEmpty ? ids.first + 1 : 1).clamp(1, 9999);
    return nextId; // Ensure it remains an int
  }

  /// Show Bottom Sheet for Adding/Editing Salesman
  void _showSalesmanForm({String? docId, String? name, String? contact}) {
    final TextEditingController nameController =
        TextEditingController(text: name ?? '');
    final TextEditingController contactController =
        TextEditingController(text: contact ?? '');

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
                  docId == null ? 'Add Salesman' : 'Edit Salesman',
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 15),

                // Salesman Name
                TextFormField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Salesman Name',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.person),
                  ),
                  validator: (value) =>
                      value!.isEmpty ? 'Enter Salesman Name' : null,
                ),
                const SizedBox(height: 10),

                // Contact Number
                TextFormField(
                  controller: contactController,
                  decoration: InputDecoration(
                    labelText: 'Contact Number',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.phone),
                  ),
                  validator: (value) =>
                      value!.isEmpty ? 'Enter Contact Number' : null,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 20),

                // Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel',
                          style: TextStyle(
                              fontSize: 16,
                              color: Color.fromARGB(255, 177, 33, 33))),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        if (formKey.currentState!.validate()) {
                          try {
                            if (docId == null) {
                              int newSalesmanId =
                                  await _getNextsalesman_id(); // Get next int ID

                              await salesmen.doc(newSalesmanId.toString()).set({
                                'salesman_id':
                                    newSalesmanId, // Store as int in Firestore
                                'salesman_name': nameController.text.trim(),
                                'contact_number': contactController.text.trim(),
                              });
                            } else {
                              await salesmen.doc(docId).update({
                                'salesman_name': nameController.text.trim(),
                                'contact_number': contactController.text.trim(),
                              });
                            }
                            if (mounted) Navigator.pop(context);
                          } catch (e) {
                            print("Error: $e");
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

  /// Delete a salesman with confirmation dialog
  void _deleteSalesman(String docId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirm Deletion'),
          content: const Text('Are you sure you want to delete this salesman?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                await salesmen.doc(docId).delete();
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
      appBar:
          AppBar(title: const Text('Salesmen',style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),), 
          backgroundColor: Colors.indigo,centerTitle: true),
      body: StreamBuilder<QuerySnapshot>(
        stream: salesmen.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Error loading salesmen'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          var salesmenList = snapshot.data!.docs;
return ListView.separated(
  padding: const EdgeInsets.all(10),
  itemCount: salesmenList.length,
  separatorBuilder: (context, index) => const Divider(
    thickness: 1,
    height: 8, // Reduced height for less space between rows
    color: Colors.black,
  ),
  itemBuilder: (context, index) {
    var data = salesmenList[index];
    var docId = data.id;
    var salesman_name = data['salesman_name'];
    var contact = data['contact_number'];

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 5, horizontal: 20),
      title: Text(
        salesman_name,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        'Contact: $contact',
        style: const TextStyle(fontSize: 16),
      ),
      trailing: Wrap(
        spacing: 8,
        children: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.orange),
            onPressed: () => _showSalesmanForm(
              docId: docId,
              name: salesman_name,
              contact: contact,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Color.fromARGB(255, 153, 29, 20)),
            onPressed: () => _deleteSalesman(docId),
          ),
        ],
      ),
    );
  },
);

        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showSalesmanForm(),
        backgroundColor: Colors.indigo,
        child: const Icon(Icons.add, color: Colors.white),
        tooltip: "Add New Salesman",
      ),
    );
  }
}
