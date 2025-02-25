import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class VanPage extends StatefulWidget {
  const VanPage({super.key});

  @override
  _VanPageState createState() => _VanPageState();
}

class _VanPageState extends State<VanPage> {
  final CollectionReference vansCollection =
      FirebaseFirestore.instance.collection('vans');
  final CollectionReference salesmenCollection =
      FirebaseFirestore.instance.collection('salesmen');

  void _openForm({String? docId, Map<String, dynamic>? van}) {
    showDialog(
      context: context,
      builder: (context) {
        return VanFormDialog(
          vansCollection: vansCollection,
          salesmenCollection: salesmenCollection,
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
      appBar: AppBar(title: const Text('Van Management')),
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

          return ListView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: vans.length,
            itemBuilder: (context, index) {
              final van = vans[index].data() as Map<String, dynamic>;
              final docId = vans[index].id;

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                elevation: 3,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(15),
                  title: Text("Van ID: ${van['van_id'].toString()}",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                      "Reg No: ${van['reg_no']}\nSalesman ID: ${van['salesman_id']}",
                      style: TextStyle(color: Colors.grey[700])),
                  trailing: Wrap(
                    spacing: 8,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _openForm(docId: docId, van: van),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteVan(docId),
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
        child: const Icon(Icons.add),
      ),
    );
  }
}


class VanFormDialog extends StatefulWidget {
  final CollectionReference vansCollection;
  final CollectionReference salesmenCollection;
  final String? docId;
  final Map<String, dynamic>? van;

  const VanFormDialog({
    required this.vansCollection,
    required this.salesmenCollection,
    this.docId,
    this.van,
    super.key,
  });

  @override
  _VanFormDialogState createState() => _VanFormDialogState();
}

class _VanFormDialogState extends State<VanFormDialog> {
  final TextEditingController _vanIdController = TextEditingController();
  final TextEditingController _regNoController = TextEditingController();
  String? _selectedSalesmanId;
  List<DropdownMenuItem<String>> _salesmanDropdownItems = [];

  @override
  void initState() {
    super.initState();
    if (widget.van != null) {
      _vanIdController.text = widget.van!['van_id'].toString();
      _regNoController.text = widget.van!['reg_no'];
      _selectedSalesmanId = widget.van!['salesman_id'];
    }
    _fetchSalesmen();
  }

  void _fetchSalesmen() async {
    var snapshot = await widget.salesmenCollection.get();
    setState(() {
      _salesmanDropdownItems = snapshot.docs.map((doc) {
        var salesmanData = doc.data() as Map<String, dynamic>;
        return DropdownMenuItem<String>(
          value: salesmanData['salesmanId'],
          child: Text("Salesman ID: ${salesmanData['salesmanId']}",
              style: TextStyle(fontSize: 16)),
        );
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: SizedBox(
        width: MediaQuery.of(context).size.width * 0.8, // 80% of screen width
        height:
            MediaQuery.of(context).size.height * 0.6, // 60% of screen height
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Text(
                  widget.van == null ? 'Add Van' : 'Update Van',
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 20),

              // Van ID Field
              TextField(
                controller: _vanIdController,
                decoration: InputDecoration(
                  labelText: 'Van ID',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 15),

              // Registration No Field
              TextField(
                controller: _regNoController,
                decoration: InputDecoration(
                  labelText: 'Registration No',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 15),

              // Salesman Dropdown
              DropdownButtonFormField<String>(
                value: _selectedSalesmanId,
                hint: const Text('Select Salesman ID'),
                isExpanded: true,
                items: _salesmanDropdownItems,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedSalesmanId = newValue;
                  });
                },
              ),

              const SizedBox(height: 25),

              // Buttons (Aligned to Bottom)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
              ElevatedButton(
                onPressed: () async {
                  final String vanId = _vanIdController.text.trim();
                  
                  if (vanId.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Van ID cannot be empty')),
                    );
                    return;
                  }

                  final newVan = {
                    'van_id': int.parse(vanId),
                    'reg_no': _regNoController.text,
                    'salesman_id': _selectedSalesmanId,
                  };

                  await widget.vansCollection.doc(vanId).set(newVan, SetOptions(merge: true));

                  Navigator.pop(context);
                },
                child: Text(widget.van == null ? 'Add' : 'Update'),
              ),

                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
