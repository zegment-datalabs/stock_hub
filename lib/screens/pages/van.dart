import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:stock_hub/screens/pages/salesman_to_van.dart';

class VanPage extends StatefulWidget {
  const VanPage({super.key});

  @override
  _VanPageState createState() => _VanPageState();
}

class _VanPageState extends State<VanPage> {
  final CollectionReference vansCollection =
      FirebaseFirestore.instance.collection('vans');

  void _openBottomSheet({String? docId, Map<String, dynamic>? van}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return VanFormBottomSheet(
          vansCollection: vansCollection,
          docId: docId,
          van: van,
        );
      },
    );
  }

  void _deleteVan(String docId) async {
    bool? confirmDelete = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirm Deletion'),
        content: Text('Are you sure you want to delete this van?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmDelete == true) {
      await vansCollection.doc(docId).delete();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text(
            'Van Management',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold,color: Colors.white)
          ),
          backgroundColor: Colors.indigo,
          iconTheme: const IconThemeData(color: Colors.white),
          centerTitle: true),
      body: StreamBuilder<QuerySnapshot>(
        stream: vansCollection.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
                child:
                    Text('No vans available.', style: TextStyle(fontSize: 18)));
          }

          final vans = snapshot.data!.docs;
          return ListView.separated(
            padding: const EdgeInsets.all(10),
            itemCount: vans.length,
            separatorBuilder: (context, index) =>
                const Divider(thickness: 1, height: 8, color: Colors.black),
            itemBuilder: (context, index) {
              final van = vans[index].data() as Map<String, dynamic>;
              final docId = vans[index].id;

              return ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                title: Text(
                  "Van ID: ${van['van_id'].toString()}",
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 18),
                ),
                subtitle: Text(
                  "Reg No: ${van['reg_no']}",
                  style: TextStyle(color: Colors.grey[700], fontSize: 16),
                ),
                trailing: Wrap(
                  spacing: 8,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.orange),
                      onPressed: () => _openBottomSheet(docId: docId, van: van),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete,
                          color: Color.fromARGB(255, 153, 29, 20)),
                      onPressed: () => _deleteVan(docId),
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

class VanFormBottomSheet extends StatefulWidget {
  final CollectionReference vansCollection;
  final String? docId;
  final Map<String, dynamic>? van;

  const VanFormBottomSheet({
    required this.vansCollection,
    this.docId,
    this.van,
    super.key,
  });

  @override
  _VanFormBottomSheetState createState() => _VanFormBottomSheetState();
}

class _VanFormBottomSheetState extends State<VanFormBottomSheet> {
   final _formKey = GlobalKey<FormState>();
  final TextEditingController _regNoController = TextEditingController();
  final TextEditingController _vanNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.van != null) {
      _regNoController.text = widget.van!['reg_no'];
      _vanNameController.text = widget.van!['van_name'];
    }
  }

  // Check if Registration Number is Unique
  Future<bool> _isRegNumberUnique(String regNo) async {
    final query =
        await widget.vansCollection.where('reg_no', isEqualTo: regNo).get();

    return query.docs.isEmpty; // True if no existing record found
  }

  // Generate Sequential Van ID
  Future<int> _getNextVanId() async {
    final querySnapshot = await widget.vansCollection
        .orderBy('van_id', descending: true)
        .limit(1)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      final highestVanId = querySnapshot.docs.first['van_id'];
      return highestVanId + 1; // Next sequential ID
    }
    return 1; // Start from 1 if no van exists
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
      child: Form(
        key: _formKey, // Form key for validation
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(
                widget.van == null ? 'Add Van' : 'Update Van',
                style:
                    const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 20),
           TextFormField(
              controller: _vanNameController,
              decoration: const InputDecoration(
                labelText: 'Van Name',
                border: OutlineInputBorder(), // Boxed style added
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Please enter Van Name'
                  : null,
            ),

                    const SizedBox(height: 15),

          TextFormField(
              controller: _regNoController,
              decoration: const InputDecoration(
                labelText: 'Registration No',
                border: OutlineInputBorder(), // Boxed style added
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Please enter Registration No'
                  : null,
            ),

            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                        fontSize: 16, color: Color.fromARGB(255, 201, 35, 35)),
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (!_formKey.currentState!.validate()) {
                      return; // Stops execution if fields are invalid
                    }

                    final String regNo = _regNoController.text.trim();
                    final String vanName = _vanNameController.text.trim();

                    // Check for unique registration number
                    if (widget.van == null) {
                      bool isUnique = await _isRegNumberUnique(regNo);
                      if (!isUnique) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content:
                                  Text('Registration number already exists')),
                        );
                        return;
                      }

                      // Generate Sequential Van ID
                      final int newVanId = await _getNextVanId();

                      final newVan = {
                        'van_id': newVanId,
                        'reg_no': regNo,
                        'van_name': vanName,
                      };

                      await widget.vansCollection
                          .doc(newVanId.toString())
                          .set(newVan);
                    } else {
                      final updatedVan = {
                        'reg_no': regNo,
                        'van_name': vanName,
                      };

                      await widget.vansCollection
                          .doc(widget.docId)
                          .set(updatedVan, SetOptions(merge: true));
                    }

                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const SalesmanToVanPage()),
                    );
                  },
                  child: Text(widget.van == null ? 'Add' : 'Update'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
