import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddStockPage extends StatefulWidget {
  @override
  _AddStockPageState createState() => _AddStockPageState();
}

class _AddStockPageState extends State<AddStockPage>
    with SingleTickerProviderStateMixin {
  String? selectedCategory;
  Map<String, TextEditingController> quantityControllers = {};
  bool isProcessEnabled = false;
  late AnimationController _blinkController;

  TextEditingController searchController = TextEditingController();
  String searchQuery = "";

  @override
  void initState() {
    super.initState();
    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _blinkController.dispose();
    super.dispose();
  }

  void _updateProcessButtonState() {
    bool hasValidQty = quantityControllers.values.any(
      (controller) =>
          controller.text.isNotEmpty &&
          int.tryParse(controller.text) != null &&
          int.parse(controller.text) > 0,
    );

    setState(() {
      isProcessEnabled = hasValidQty;
    });
  }

  void _clearQuantities() {
    for (var controller in quantityControllers.values) {
      controller.clear();
    }
    setState(() {
      isProcessEnabled = false;
    });
  }

  Future<void> _processStockTransfer() async {
    String currentUser = "admin"; // Replace with actual logged-in user

    for (var entry in quantityControllers.entries) {
      String productId = entry.key;
      String qtyText = entry.value.text;

      if (qtyText.isNotEmpty && int.tryParse(qtyText) != null) {
        int transferQty = int.parse(qtyText);

        DocumentReference productRef =
            FirebaseFirestore.instance.collection('product').doc(productId);
        DocumentSnapshot productDoc = await productRef.get();

        if (!productDoc.exists) continue;

        var productData = productDoc.data() as Map<String, dynamic>;
        double currentStock = (productData['opening_stock'] as num).toDouble();

        String fetchedProductId = productData['product_id'];

        // Add stock transaction
        await FirebaseFirestore.instance.collection('product_transaction').add({
          'stock_transactionID': FirebaseFirestore.instance
              .collection('product_transaction')
              .doc()
              .id,
          'transaction_type': 'Stock Addition',
          'product_id': fetchedProductId,
          'date': FieldValue.serverTimestamp(),
          'qty': transferQty,
          'current_user': currentUser,
        });

        // Update product stock in Firestore (allow adding any amount)
        await productRef.update({
          'opening_stock':
              currentStock + transferQty, // Always add the transferred quantity
        });
      }
    }
    _clearQuantities();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add Stock ",style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
      backgroundColor: Colors.indigo,
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                // Category List
                Expanded(
                  flex: 2,
                  child: Card(
                    margin: const EdgeInsets.all(8.0),
                    child: StreamBuilder(
                      stream: FirebaseFirestore.instance
                          .collection('category')
                          .snapshots(),
                      builder:
                          (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                        if (!snapshot.hasData)
                          return const Center(
                              child: CircularProgressIndicator());
                        return ListView.separated(
                          padding: EdgeInsets.zero,
                          itemCount: snapshot.data!.docs.length,
                          separatorBuilder: (context, index) =>
                              const Divider(height: 0),
                          itemBuilder: (context, index) {
                            var doc = snapshot.data!.docs[index];
                            return ListTile(
                              dense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              title: Text(
                                doc['title'],
                                style: const TextStyle(
                                    fontSize: 14, fontWeight: FontWeight.bold),
                              ),
                              onTap: () {
                                setState(() {
                                  selectedCategory = doc['title'];
                                  searchController
                                      .clear(); // Clear search field when changing category
                                  searchQuery = ""; // Reset search query
                                });
                              },
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),

                Expanded(
                  flex: 4,
                  child: Column(
                    children: [
                      if (selectedCategory != null)
                        // Search Bar
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: TextField(
                            controller: searchController,
                            style: const TextStyle(color: Colors.black),
                            decoration: InputDecoration(
                              hintText: "Search products...",
                             hintStyle: const TextStyle(color: Colors.black54),
                              prefixIcon: Icon(Icons.search),
                              suffixIcon: searchController.text.isNotEmpty
                                  ? IconButton(
                                      icon: Icon(Icons.clear),
                                      onPressed: () {
                                        setState(() {
                                          searchController.clear();
                                          searchQuery = "";
                                        });
                                      },
                                    )
                                  : null,
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                            onChanged: (value) {
                              setState(() {
                                searchQuery = value.toLowerCase();
                              });
                            },
                          ),
                        ),

                      // Product List
                     Expanded(
                              flex: 4,
                              child: Column(
                                children: [
                                  Expanded(
                                    child: Card(
                                      margin: const EdgeInsets.all(8.0),
                                      child: StreamBuilder(
                                        stream: selectedCategory == null
                                            ? FirebaseFirestore.instance
                                                .collection('product')
                                                .snapshots()
                                            : FirebaseFirestore.instance
                                                .collection('product')
                                                .where('category', isEqualTo: selectedCategory)
                                                .snapshots(),
                                        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                                          if (!snapshot.hasData) {
                                            return const Center(child: CircularProgressIndicator());
                                          }


                                          var filteredDocs =
                                              snapshot.data!.docs.where((doc) {
                                            String title = doc['title']
                                                .toString()
                                                .toLowerCase();
                                            return title.contains(searchQuery);
                                          }).toList();

                                         
                     return ListView(
  padding: const EdgeInsets.all(8.0),
  children: filteredDocs.map((doc) {
    String productId = doc.id;
    double stock = (doc['opening_stock'] as num).toDouble();
    int stockInt = stock.toInt();

    bool isLowStock = stock <= 5;
    bool isWarningStock = stock > 5 && stock <= 10;
    Color stockColor = isLowStock
        ? Colors.red
        : (isWarningStock ? Colors.orange : Colors.black);

    quantityControllers.putIfAbsent(
      productId,
      () => TextEditingController(),
    );

                                            return Card(
                                              margin: const EdgeInsets.symmetric(vertical: 4.0),
                                              child: Padding(
                                                padding: const EdgeInsets.all(8.0),
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    if (isLowStock)
                                                      AnimatedBuilder(
                                                        animation: _blinkController,
                                                        builder: (context, child) {
                                                          return Opacity(
                                                            opacity: _blinkController.value,
                                                            child: Text(
                                                              doc['title'],
                                                              style: const TextStyle(
                                                                fontSize: 16,
                                                                fontWeight: FontWeight.bold,
                                                                color: Colors.red,
                                                              ),
                                                            ),
                                                          );
                                                        },
                                                      )
                                                    else
                                                      Text(
                                                        doc['title'],
                                                        style: TextStyle(
                                                          fontSize: 16,
                                                          fontWeight: FontWeight.bold,
                                                          color: stockColor,
                                                        ),
                                                      ),
                                                    const SizedBox(height: 8),

                                                    // Stock and Qty in One Row
                                                    Row(
                                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                      children: [
                                                        Text(
                                                          "Stock: $stockInt",
                                                          style: TextStyle(
                                                            color: stockColor,
                                                            fontWeight: FontWeight.bold,
                                                          ),
                                                        ),
                                                        SizedBox(
                                                          width: 60,
                                                          child: TextField(
                                                            controller: quantityControllers[productId],
                                                            keyboardType: TextInputType.number,
                                                            decoration: const InputDecoration(
                                                              hintText: "Qty",
                                                              border: OutlineInputBorder(),
                                                              contentPadding: EdgeInsets.symmetric(horizontal: 6),
                                                            ),
                                                            onChanged: (_) => _updateProcessButtonState(),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          }).toList(),
                                        );
                                     },
                                    ),
                            ),
                          ),
                            // Buttons
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 8.0),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  ElevatedButton(
                                    onPressed: _clearQuantities,
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red),
                                    child: const Text("Cancel",
                                        style: TextStyle(color: Colors.white)),
                                  ),
                                  ElevatedButton(
                                    onPressed: isProcessEnabled
                                        ? () {
                                            _processStockTransfer();
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                    "Stock transfer processed successfully!"),
                                                backgroundColor: Colors.green,
                                                duration: Duration(seconds: 2),
                                              ),
                                            );
                                          }
                                        : null,
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green),
                                    child: const Text("Process",
                                        style: TextStyle(color: Colors.white)),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
