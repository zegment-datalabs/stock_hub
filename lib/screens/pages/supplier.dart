import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SupplierPage extends StatefulWidget {
  const SupplierPage({super.key});

  @override
  _SupplierPageState createState() => _SupplierPageState();
}

class _SupplierPageState extends State<SupplierPage> {
  final CollectionReference supplierCollection =
      FirebaseFirestore.instance.collection('supplier');

  void _openBottomSheet({String? supplierId, Map<String, dynamic>? supplier}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SupplierBottomSheet(
          supplierCollection: supplierCollection,
          supplierId: supplierId,
          supplier: supplier,
        );
      },
    );
  }

  void _confirmDelete(String supplierId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: const Text('Are you sure you want to delete this supplier?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await supplierCollection.doc(supplierId).delete();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Suppliers',style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),),
        centerTitle: true,
          backgroundColor: Colors.indigo,
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 2,
        foregroundColor: const Color.fromARGB(255, 10, 10, 10),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: supplierCollection.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No suppliers available.'));
          }

          final suppliers = snapshot.data!.docs;
return ListView.separated(
  padding: const EdgeInsets.all(10),
  itemCount: suppliers.length,
  separatorBuilder: (context, index) => const Divider(
    thickness: 1,
    height: 8, // Reduced height for less space between rows
    color: Colors.black,
  ),
  itemBuilder: (context, index) {
    final supplier = suppliers[index].data() as Map<String, dynamic>;
    final supplierId = suppliers[index].id;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 5, horizontal: 20),
      title: Text(
        supplier['supplier_name'],
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
      subtitle: Text(
        "Contact: ${supplier['contact_number']}",
        style: const TextStyle(fontSize: 14, color: Colors.black87),
      ),
      trailing: Wrap(
        spacing: 6,
        children: [
          IconButton(
            icon: const Icon(Icons.edit,color: Colors.orange),
            onPressed: () => _openBottomSheet(
                supplierId: supplierId, supplier: supplier),
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Color.fromARGB(255, 153, 29, 20)),
            onPressed: () => _confirmDelete(supplierId),
          ),
        ],
      ),
    );
  },
);

        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openBottomSheet(),
       backgroundColor: Colors.indigo,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class SupplierBottomSheet extends StatefulWidget {
  final CollectionReference supplierCollection;
  final String? supplierId;
  final Map<String, dynamic>? supplier;

  const SupplierBottomSheet({
    required this.supplierCollection,
    this.supplierId,
    this.supplier,
    super.key,
  });

  @override
  _SupplierBottomSheetState createState() => _SupplierBottomSheetState();
}

class _SupplierBottomSheetState extends State<SupplierBottomSheet> {
  final TextEditingController _supplierNameController = TextEditingController();
  final TextEditingController _contactNumberController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.supplier != null) {
      _supplierNameController.text = widget.supplier!['supplier_name'];
      _contactNumberController.text =
          widget.supplier!['contact_number'].toString();
    }
  }

  Future<int> _getNextSupplierId() async {
    QuerySnapshot query = await widget.supplierCollection.get();

    List<int> ids = query.docs
        .map<int>((doc) => (doc['supplier_id'] is int)
            ? doc['supplier_id'] as int
            : int.tryParse(doc['supplier_id'].toString()) ?? 0)
        .toList();

    ids.sort((a, b) => b.compareTo(a));

    return ids.isNotEmpty ? ids.first + 1 : 1;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
            right: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            top: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.supplier == null ? 'Add Supplier' : 'Update Supplier',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
         TextField(
              controller: _supplierNameController,
              decoration: const InputDecoration(
                labelText: 'Supplier Name',
                border: OutlineInputBorder(), // Boxed style added
              ),
            ),

            const SizedBox(height: 12),

         TextField(
              controller: _contactNumberController,
              decoration: const InputDecoration(
                labelText: 'Contact Number',
                border: OutlineInputBorder(), // Boxed style added
              ),
              keyboardType: TextInputType.phone,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),

          // Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel',
                    style: TextStyle(fontSize: 16, color: Color.fromARGB(255, 201, 35, 35))),
              ),

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () async {
                      int supplierId = widget.supplierId != null
                          ? int.parse(widget
                              .supplierId!) // Convert existing supplierId to int
                          : await _getNextSupplierId(); // Get new int supplierId

                      final newSupplier = {
                        'supplier_id': supplierId, // Ensure it's stored as int
                        'supplier_name': _supplierNameController.text.trim(),
                        'contact_number': _contactNumberController.text.trim(),
                      };

                      if (widget.supplierId != null) {
                        await widget.supplierCollection
                            .doc(widget.supplierId)
                            .update(newSupplier);
                      } else {
                        await widget.supplierCollection
                            .doc(supplierId
                                .toString()) // Use int as a string for Firestore doc ID
                            .set(newSupplier);
                      }

                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 248, 243, 248),
                  foregroundColor: Colors.deepPurple,
                ),
                child: Text(widget.supplier == null ? 'Add' : 'Update'),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
