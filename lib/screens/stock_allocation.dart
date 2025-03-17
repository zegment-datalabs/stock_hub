import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:stock_hub/screens/pages/common_widgets.dart';


class StockAllocationPage extends StatefulWidget {
  @override
  _StockAllocationPageState createState() => _StockAllocationPageState();
}

class _StockAllocationPageState extends State<StockAllocationPage>
    with SingleTickerProviderStateMixin {
  String? selectedVan;
  String? selectedCategory;
  String? selectedVanId;
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
    if (selectedVanId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select a van before processing."),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    String currentUser = "admin"; // Replace with the actual logged-in user

    for (var entry in quantityControllers.entries) {
      String productId = entry.key;
      String qtyText = entry.value.text;

      if (qtyText.isNotEmpty && int.tryParse(qtyText) != null) {
        int transferQty = int.parse(qtyText);

        DocumentSnapshot productDoc = await FirebaseFirestore.instance
            .collection('product')
            .doc(productId)
            .get();
        if (!productDoc.exists) continue;

        var productData = productDoc.data() as Map<String, dynamic>;

        // **Convert all Firestore fields to double**
        double purchasePrice =
            (productData['purchase_price'] as num).toDouble();
        double mrp = (productData['MRP'] as num).toDouble();
        double sellingPrice = (productData['selling_price'] as num).toDouble();
        double reorderLevel = (productData['reorder_level'] as num).toDouble();
        double tax = (productData['TAX'] as num).toDouble();
        double currentStock = (productData['opening_stock'] as num).toDouble();

        if (transferQty > currentStock) {
          print("Not enough stock for ${productData['title']}");
          continue;
        }

        String fetchedProductId = productData['product_id'];
        String productName = productData['title'];

        DocumentReference substockRef =
            FirebaseFirestore.instance.collection('substock').doc(productName);
        DocumentSnapshot substockDoc = await substockRef.get();

        double existingStock = 0;
        if (substockDoc.exists) {
          var substockData = substockDoc.data() as Map<String, dynamic>;
          existingStock = (substockData['opening_stock'] as num).toDouble();
        }

        // **Update substock collection**
        await substockRef.set({
          'product_id': fetchedProductId,
          'title': productName,
          'category': productData['category'],
          'product_url': productData['product_url'],
          'MRP': mrp,
          'TAX': tax,
          'purchase_price': purchasePrice,
          'selling_price': sellingPrice,
          'comments': productData['comments'],
          'supplier_name': productData['supplier_name'],
          'location': productData['location'],
          'reorder_level': reorderLevel,
          'uom': productData['uom'],
          'opening_stock': existingStock + transferQty,
        }, SetOptions(merge: true));

        // **Update main product stock**
        await FirebaseFirestore.instance
            .collection('product')
            .doc(productId)
            .update({
          'opening_stock': (currentStock - transferQty).toInt(),
        });

        // **Insert into Product Transaction Table**
        String stock_transactionID = FirebaseFirestore.instance
            .collection('product_transaction')
            .doc()
            .id;
        await FirebaseFirestore.instance
            .collection('product_transaction')
            .doc(stock_transactionID)
            .set({
          'stock_transactionID': stock_transactionID,
          'transaction_type': 'Stock Transfer',
          'product_id': fetchedProductId,
          'date': FieldValue.serverTimestamp(),
          'qty': transferQty,
          'current_user': currentUser,
        });

        // **Insert into Substock Transaction Table**
        String substockTransactionID = FirebaseFirestore.instance
            .collection('substock_transaction')
            .doc()
            .id;
        await FirebaseFirestore.instance
            .collection('substock_transaction')
            .doc(substockTransactionID)
            .set({
          'substock_transactionID': substockTransactionID,
          'transaction_type': 'Stock Transfer',
          'product_id': fetchedProductId,
          'date': FieldValue.serverTimestamp(),
          'qty': transferQty,
          'current_user': currentUser,
          'van_id': selectedVanId,
        });

        print(
            "Transferred $transferQty of $productName to Van ID: $selectedVanId");
      }
    }
    _clearQuantities();
  }

  @override
   Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppBar('Stock Allocation'),
      endDrawer: buildEndDrawer(context),
       
       body: Column(children: [
        // Van Selection
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              StreamBuilder(
                stream:
                    FirebaseFirestore.instance.collection('vans').snapshots(),
                builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                  if (!snapshot.hasData)
                    return const CircularProgressIndicator();
                  var vans = snapshot.data!.docs;
                  return DropdownButton<String>(
                    hint: const Text("Select Van"),
                    value: selectedVan,
                    onChanged: (value) {
                      setState(() {
                        selectedVan = value;
                        selectedVanId = vans
                            .firstWhere((doc) => doc.id == value)['van_id']
                            .toString();
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
              if (selectedVanId != null)
                Text(
                  "Van ID: $selectedVanId",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
        ),

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
                    builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                      if (!snapshot.hasData)
                        return const Center(child: CircularProgressIndicator());
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
                    padding: const EdgeInsets.all(12.0),
                    child: TextField(
                      controller: searchController,
                      decoration: InputDecoration(
                        hintText: "Search products...",
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
                                        contentPadding: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 12.0), // Reduced height
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
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
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
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
                                          if (selectedVanId == null) {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                    "Please select a van first."),
                                                backgroundColor: Colors.red,
                                                duration: Duration(seconds: 2),
                                              ),
                                            );
                                            return;
                                          }
                                          _processStockTransfer();
                                          // Show success SnackBar after processing
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
      ]),
    );
  }
}
