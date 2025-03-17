import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:stock_hub/screens/pages/common_widgets.dart';


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

  
  showCustomBottomSheet(
    context: context,
    formKey: formKey,
    title: docId == null ? 'Add Customer' : 'Edit Customer',
    formFields: [
      customTextField(
        controller: nameController,
        label: 'Customer Name',
        icon: Icons.person,
        validator: (value) => value!.isEmpty ? 'Enter Customer Name' : null,
      ),
      const SizedBox(height: 10),

      customTextField(
        controller: contactController,
        label: 'Contact Number',
        icon: Icons.phone,
        keyboardType: TextInputType.phone,
        validator: (value) => value!.isEmpty ? 'Enter Contact Number' : null,
      ),
    ],
    onSave: () async {
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
      appBar: AppBar(title: const Text('Assign Route And Van',style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold,color: Colors.white),), 
          backgroundColor: Colors.indigo, iconTheme: const IconThemeData(color: Colors.white),centerTitle: true),
      
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
      
    );
  }
}
