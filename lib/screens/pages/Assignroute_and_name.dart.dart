import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

final FirebaseFirestore _firestore = FirebaseFirestore.instance;

class CustomerPage extends StatefulWidget {
  const CustomerPage({super.key});

  @override
  State<CustomerPage> createState() => _CustomerPageState();
}

class _CustomerPageState extends State<CustomerPage> {
  final CollectionReference customer =
      FirebaseFirestore.instance.collection('customer');
  final CollectionReference vansCollection =
      FirebaseFirestore.instance.collection('vans');
  final CollectionReference routesCollection =
      FirebaseFirestore.instance.collection('routes');

  int? _selectedVanId;
  int? _selectedRouteId;
  List<DropdownMenuItem<int>> _vanDropdownItems = [];
  List<DropdownMenuItem<int>> _routeDropdownItems = [];

  @override
  void initState() {
    super.initState();
    _fetchVanIds();
    _fetchRouteIds();
  }

 Future<void> _fetchVanIds() async {
  var snapshot = await vansCollection.get();
  setState(() {
    _vanDropdownItems = snapshot.docs.map((doc) {
      var vanData = doc.data() as Map<String, dynamic>;
      int vanId = vanData['van_id'];
      return DropdownMenuItem<int>(
        value: vanId,
        child: Text("Van ID: $vanId"),
      );
    }).toSet().toList(); // Prevent duplicates
  });
}
Future<void> _fetchRouteIds() async {
  var snapshot = await routesCollection.get();
  setState(() {
    _routeDropdownItems = snapshot.docs.map((doc) {
      var routeData = doc.data() as Map<String, dynamic>;
      int routeId = routeData['route_id'];
      return DropdownMenuItem<int>(
        value: routeId,
        child: Text("Route ID: $routeId"),
      );
    }).toSet().toList(); // Prevent duplicates
  });
}

  // Get the next available customer_id
  Future<int> _getNextCustomerId() async {
    try {
      var querySnapshot = await customer
          .orderBy('customer_id', descending: true)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return 1; // First customer
      }

      int lastCustomerId = querySnapshot.docs.first['customer_id'];
      return lastCustomerId + 1;
    } catch (e) {
      print("Error generating Customer ID: $e");
      return 1;
    }
  }
   



  // Show Bottom Sheet for Adding/Editing Customer
 void _showCustomerForm({String? docId, String? name, String? contact, int? vanId, int? routeId}) {
    final TextEditingController nameController = TextEditingController(text: name ?? '');
    final TextEditingController contactController = TextEditingController(text: contact ?? '');

    // Initialize selected IDs
    setState(() {
      _selectedVanId = vanId;
      _selectedRouteId = routeId;
    });

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
                  docId == null ? 'Add Customer' : 'Edit Customer',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 15),

                // Customer Name
                TextFormField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Customer Name',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.person),
                  ),
                  validator: (value) => value!.isEmpty ? 'Enter Customer Name' : null,
                ),
                const SizedBox(height: 10),

                // Contact Number
                TextFormField(
                  controller: contactController,
                  decoration: InputDecoration(
                    labelText: 'Contact Number',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.phone),
                  ),
                  validator: (value) => value!.isEmpty ? 'Enter Contact Number' : null,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 20),

                // Van ID Dropdown
                      DropdownButtonFormField<int>(
                      value: _selectedVanId != null &&
                              _vanDropdownItems.any((item) => item.value == _selectedVanId)
                          ? _selectedVanId
                          : null, // Set to null if value is invalid
                      hint: const Text('Select Van ID'),
                      isExpanded: true,
                      items: _vanDropdownItems,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onChanged: (int? newValue) {
                        setState(() {
                          _selectedVanId = newValue;
                        });
                      },
                    ),


                const SizedBox(height: 15),

                // Route ID Dropdown
                          DropdownButtonFormField<int>(
                          value: _selectedRouteId != null &&
                                  _routeDropdownItems.any((item) => item.value == _selectedRouteId)
                              ? _selectedRouteId
                              : null,
                          hint: const Text('Select Route ID'),
                          isExpanded: true,
                          items: _routeDropdownItems,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onChanged: (int? newValue) {
                            setState(() {
                              _selectedRouteId = newValue;
                            });
                          },
                        ),


                const SizedBox(height: 25),

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
                              int newCustomerId = await _getNextCustomerId();

                              await customer.doc(newCustomerId.toString()).set({
                                'customer_id': newCustomerId,
                                'customer_name': nameController.text.trim(),
                                'customer_contact': contactController.text.trim(),
                                'van_id': _selectedVanId,
                                'route_id': _selectedRouteId,
                              });
                            } else {
                              await customer.doc(docId).update({
                                'customer_name': nameController.text.trim(),
                                'customer_contact': contactController.text.trim(),
                                'van_id': _selectedVanId,
                                'route_id': _selectedRouteId,
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

// Delete a Customer with confirmation dialog
  void _deleteCustomer(String docId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirm Deletion'),
          content: const Text('Are you sure you want to delete this Customer?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                await customer.doc(docId).delete();
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
      appBar: AppBar(title: const Text('Assign Route And Van',style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
      backgroundColor: Colors.indigo,
      centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: customer.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Error loading customer'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          var customerList = snapshot.data!.docs;

        return ListView.separated(
  padding: const EdgeInsets.all(10),
  itemCount: customerList.length,
  separatorBuilder: (context, index) => const Divider(thickness: 1, height: 8,color: Colors.black,),
  itemBuilder: (context, index) {
    var data = customerList[index];
    var docId = data.id;
    var customerName = data['customer_name'];
    var contact = data['customer_contact'];

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
      title: Text(
        customerName,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        'Contact: $contact',
        style: const TextStyle(fontSize: 16, color: Color.fromARGB(255, 15, 11, 11)),
      ),
      trailing: Wrap(
        spacing: 8,
        children: [
          IconButton(
            icon: const Icon(Icons.edit,  color: Colors.orange),
            onPressed: () => _showCustomerForm(
              docId: docId,
              name: customerName,
              contact: contact,
              vanId: data['van_id'],
              routeId: data['route_id'],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete,color:Color.fromARGB(255, 153, 29, 20)),
            onPressed: () => _deleteCustomer(docId),
          ),
        ],
      ),
    );
  },
);
        },),
      // floatingActionButton: FloatingActionButton(
      //   onPressed: () => _showCustomerForm(),
      //   child: const Icon(Icons.add,color: Colors.white),
      //    backgroundColor: Colors.indigo,
         
      //   tooltip: "Add New Customer",
      // ),
    );
  }
}
