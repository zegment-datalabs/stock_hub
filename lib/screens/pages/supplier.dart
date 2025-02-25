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

  void _openForm({String? supplierId, Map<String, dynamic>? supplier}) {
    showDialog(
      context: context,
      builder: (context) {
        return SupplierFormDialog(
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
        title: const Text('Suppliers'),
        centerTitle: true,
        elevation: 2,
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
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

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: suppliers.length,
            itemBuilder: (context, index) {
              final supplier =
                  suppliers[index].data() as Map<String, dynamic>;
              final supplierId = suppliers[index].id;

              return Card(
                elevation: 3,
                margin: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  title: Text(
                    supplier['supplier_name'],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  subtitle: Text(
                    "ID: ${supplier['supplier_id']} | Contact: ${supplier['contact_number']}",
                    style: const TextStyle(fontSize: 14, color: Color.fromARGB(255, 8, 8, 8)),
                  ),
                  trailing: Wrap(
                    spacing: 6,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () =>
                            _openForm(supplierId: supplierId, supplier: supplier),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _confirmDelete(supplierId),
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
        onPressed: () => _openForm(),
        backgroundColor: Colors.deepPurple,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class SupplierFormDialog extends StatefulWidget {
  final CollectionReference supplierCollection;
  final String? supplierId;
  final Map<String, dynamic>? supplier;

  const SupplierFormDialog({
    required this.supplierCollection,
    this.supplierId,
    this.supplier,
    super.key,
  });

  @override
  _SupplierFormDialogState createState() => _SupplierFormDialogState();
}

class _SupplierFormDialogState extends State<SupplierFormDialog> {
  final TextEditingController _supplierIdController = TextEditingController();
  final TextEditingController _supplierNameController = TextEditingController();
  final TextEditingController _contactNumberController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.supplier != null) {
      _supplierIdController.text = widget.supplier!['supplier_id'];
      _supplierNameController.text = widget.supplier!['supplier_name'];
      _contactNumberController.text = widget.supplier!['contact_number'].toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.supplier == null ? 'Add Supplier' : 'Update Supplier',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _supplierIdController,
              decoration: const InputDecoration(
                labelText: 'Supplier ID',
                border: OutlineInputBorder(),
              ),
              enabled: widget.supplier == null,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _supplierNameController,
              decoration: const InputDecoration(
                labelText: 'Supplier Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _contactNumberController,
              decoration: const InputDecoration(
                labelText: 'Contact Number',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () async {
                    final supplierId = _supplierIdController.text.trim();
                    final newSupplier = {
                      'supplier_id': supplierId,
                      'supplier_name': _supplierNameController.text,
                      'contact_number':
                          int.tryParse(_contactNumberController.text) ?? 0,
                    };

                    if (widget.supplierId != null) {
                      await widget.supplierCollection
                          .doc(widget.supplierId)
                          .update(newSupplier);
                    } else {
                      await widget.supplierCollection
                          .doc(supplierId)
                          .set(newSupplier);
                    }

                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(widget.supplier == null ? 'Add' : 'Update'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
