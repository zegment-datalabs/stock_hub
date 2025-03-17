import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:stock_hub/widgets/common_widgets.dart';


class OrderToVanPage extends StatefulWidget {
  @override
  OrderToVanPageState createState() => OrderToVanPageState();
}

class OrderToVanPageState extends State<OrderToVanPage> {
  bool isVanWise = false;
  String? selectedVan;
  List<String> vanNames = [];
  Map<String, List<Map<String, dynamic>>> customerOrders = {};

  @override
  void initState() {
    super.initState();
    fetchVanNames();
  }

  // Fetch van names from Firestore
  Future<void> fetchVanNames() async {
    QuerySnapshot snapshot =
        await FirebaseFirestore.instance.collection('vans').get();
    setState(() {
      vanNames =
          snapshot.docs.map((doc) => doc['van_name'].toString()).toList();
    });
  }

  Future<void> processStockTransfer(String productName, int totalQuantity,
      List<Map<String, dynamic>> transactions, WriteBatch batch) async {
    var productQuery = await FirebaseFirestore.instance
        .collection('product')
        .where('title', isEqualTo: productName)
        .limit(1)
        .get();

    if (productQuery.docs.isEmpty) return;

    var productDoc = productQuery.docs.first;
    String productId = productDoc.id;
    int currentStock = (productDoc['opening_stock'] as num).toInt();

    if (currentStock < totalQuantity) return;

    // Update product stock
    batch.update(
        productDoc.reference, {'opening_stock': currentStock - totalQuantity});

    // Use productName as the document ID in the substock collection
    DocumentReference substockRef =
        FirebaseFirestore.instance.collection('substock').doc(productName);

    var substockDoc = await substockRef.get();

    if (substockDoc.exists) {
      int substockQty = (substockDoc['opening_stock'] as num).toInt();

      // Update existing substock
      batch.update(substockRef, {'opening_stock': substockQty + totalQuantity});
    } else {
      // Create a new substock document with productName as the document ID
      batch.set(substockRef, {
        'product_id': productId,
        'title': productName,
        'opening_stock': totalQuantity,
      });
    }

    // Create separate transaction records for each occurrence
    for (var transaction in transactions) {
      String substockTransactionID = FirebaseFirestore.instance
          .collection('substock_transaction')
          .doc()
          .id;
      String productTransactionID =
          FirebaseFirestore.instance.collection('product_transaction').doc().id;

      batch.set(
        FirebaseFirestore.instance
            .collection('substock_transaction')
            .doc(substockTransactionID),
        {
          'substock_transactionID': substockTransactionID,
          'current_user': 'Admin',
          'date': FieldValue.serverTimestamp(),
          'product_id': productId,
          'qty': transaction['quantity'],
          'transaction_type': 'IN',
          'van_id': transaction['vanId'],
        },
      );

      batch.set(
        FirebaseFirestore.instance
            .collection('product_transaction')
            .doc(productTransactionID),
        {
          'product_transactionID': productTransactionID,
          'current_user': 'Admin',
          'date': FieldValue.serverTimestamp(),
          'product_id': productId,
          'qty': transaction['quantity'],
          'transaction_type': 'OUT',
        },
      );
    }
  }

  // Show all vans details in bottom sheet
  Future<void> showAllVansDetails() async {
    QuerySnapshot vansSnapshot =
        await FirebaseFirestore.instance.collection('vans').get();

    List<String> vanIds =
        vansSnapshot.docs.map((doc) => doc['van_id'].toString()).toList();
    int totalVans = vanIds.length;

    if (totalVans == 0) {
      return;
    }

    QuerySnapshot ordersSnapshot = await FirebaseFirestore.instance
        .collection('order_masters')
        .where('status', isEqualTo: 'Pending')
        .get();

    Map<String, Map<String, List<Map<String, dynamic>>>> vanOrders = {};

    if (ordersSnapshot.docs.isNotEmpty) {
      List<Future<QuerySnapshot>> orderDetailsFutures = [];

      for (var order in ordersSnapshot.docs) {
        var orderData = order.data() as Map<String, dynamic>?;

        if (orderData != null &&
            orderData.containsKey('customer_id') &&
            orderData.containsKey('van_id')) {
          String customerId = orderData['customer_id'].toString();
          String vanId = orderData['van_id'].toString();

          // Prepare a list to hold order details per customer per van
          if (!vanOrders.containsKey(vanId)) {
            vanOrders[vanId] = {};
          }
          if (!vanOrders[vanId]!.containsKey(customerId)) {
            vanOrders[vanId]![customerId] = [];
          }

          orderDetailsFutures
              .add(order.reference.collection('order_details').get());
        }
      }

      List<QuerySnapshot> orderDetailsSnapshots =
          await Future.wait(orderDetailsFutures);

      int index = 0;
      for (var snapshot in orderDetailsSnapshots) {
        var order = ordersSnapshot.docs[index];
        var orderData = order.data() as Map<String, dynamic>?;

        if (orderData != null) {
          String customerId = orderData['customer_id'].toString();
          String vanId = orderData['van_id'].toString();

          for (var detail in snapshot.docs) {
            var detailData = detail.data() as Map<String, dynamic>?;

            if (detailData != null &&
                detailData.containsKey('Product Name') &&
                detailData.containsKey('quantity')) {
              vanOrders[vanId]![customerId]!.add({
                'productName': detailData['Product Name'].toString(),
                'quantity': detailData['quantity'].toString(),
              });
            }
          }
        }
        index++;
      }
    }
    if (vanOrders.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No pending orders available')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          builder: (_, scrollController) {
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Drag Handle
                  Center(
                    child: Container(
                      width: 50,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey[400],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Title
                  const Text(
                    'All Orders',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),

                  // Drill-Down List using ExpansionTiles
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      children: vanOrders.entries.map((vanEntry) {
                        String vanId = vanEntry.key;
                        Map<String, List<Map<String, dynamic>>> customers =
                            vanEntry.value;

                        return ExpansionTile(
                          title: Text(
                            'Van ID: $vanId',
                            style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.blueAccent),
                          ),
                          children: customers.entries.map((customerEntry) {
                            String customerId = customerEntry.key;
                            List<Map<String, dynamic>> products =
                                customerEntry.value;

                            return ExpansionTile(
                              title: Text(
                                'Customer ID: $customerId',
                                style: const TextStyle(
                                    fontSize: 17, fontWeight: FontWeight.w600),
                              ),
                              children: [
                                // Column Headers
                                const Padding(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 8),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Item(s)',
                                        style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold),
                                      ),
                                      Text(
                                        'Quantity',
                                        style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                                const Divider(),

                                // Product List
                                ...products.map((product) {
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 4),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          product['productName'],
                                          style: const TextStyle(fontSize: 16),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.only(
                                              right:
                                                  18.0), // Added right padding
                                          child: Text(
                                            '${product['quantity']}',
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ],
                            );
                          }).toList(),
                        );
                      }).toList(),
                    ),
                  ),

                  // Bottom Buttons
                  Row(
                children: [
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel',
                            style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10), // Reduced spacing
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () async {
                          try {
                            WriteBatch batch =
                                FirebaseFirestore.instance.batch();
                            Map<String, int> productQuantities = {};
                            Map<String, List<Map<String, dynamic>>>
                                productTransactions = {};
                            List<DocumentReference> processedOrders = [];

                            // Accumulate product quantities and track order references
                            for (var order in ordersSnapshot.docs) {
                              var orderData =
                                  order.data() as Map<String, dynamic>?;

                              if (orderData != null &&
                                  orderData.containsKey('customer_id')) {
                                String customerId =
                                    orderData['customer_id'].toString();
                                String vanId = orderData['van_id'].toString();
                                String orderId = order.id;

                                var orderDetailsSnapshot = await order
                                    .reference
                                    .collection('order_details')
                                    .get();

                                for (var detail in orderDetailsSnapshot.docs) {
                                  var detailData =
                                      detail.data() as Map<String, dynamic>?;

                                  if (detailData != null &&
                                      detailData.containsKey('Product Name') &&
                                      detailData.containsKey('quantity')) {
                                    String productName =
                                        detailData['Product Name'].toString();
                                    int quantity =
                                        int.tryParse(detailData['quantity']
                                                .toString()) ??
                                            0;

                                    if (quantity > 0) {
                                      productQuantities.update(
                                        productName,
                                        (existingQty) =>
                                            existingQty + quantity,
                                        ifAbsent: () => quantity,
                                      );

                                      productTransactions.putIfAbsent(
                                          productName, () => []);
                                      productTransactions[productName]!.add({
                                        'productName': productName,
                                        'quantity': quantity,
                                        'vanId': selectedVan,
                                      });

                                      DocumentReference orderRef =
                                          FirebaseFirestore.instance
                                              .collection('order_masters')
                                              .doc(orderId);

                                      if (!processedOrders.contains(orderRef)) {
                                        processedOrders.add(orderRef);
                                      }
                                    }
                                  }
                                }
                              }
                            }

                            if (productQuantities.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('No stock to process')),
                              );
                              return;
                            }

                            // Process stock transfers in batch
                            List<Future<void>> operations = [];
                            productQuantities.forEach((productName, totalQuantity) {
                              operations.add(processStockTransfer(
                                productName,
                                totalQuantity,
                                productTransactions[productName]!,
                                batch,
                              ));
                            });

                            await Future.wait(operations);

                            for (var orderRef in processedOrders) {
                              batch.update(orderRef,
                                  {'status': 'Pending + Stock Transferred'});
                            }

                            await batch.commit();

                            setState(() {
                              selectedVan = null;
                              customerOrders.clear();
                            });

                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text(
                                      'Stock successfully processed for this van')),
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content:
                                      Text('Error processing stock: $e')),
                            );
                          }
                        },
                        child: const Text('Process',
                            style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  },);
  
  }

  // Show selected van details
  Future<void> showVanDetails(String vanName) async {
    var vanQuery = await FirebaseFirestore.instance
        .collection('vans')
        .where('van_name', isEqualTo: vanName)
        .limit(1)
        .get();

    if (vanQuery.docs.isEmpty) {
      return;
    }

    var vanData = vanQuery.docs.first;
    var vanId = vanData['van_id'];
    var regNo = vanData['reg_no'] ?? 'N/A';

    var ordersSnapshot = await FirebaseFirestore.instance
        .collection('order_masters')
        .where('van_id', isEqualTo: vanId)
        .where('status', isEqualTo: 'Pending')
        .get();

    Map<String, List<Map<String, dynamic>>> customerOrders = {};
    List<String> customerIds = [];

    if (ordersSnapshot.docs.isNotEmpty) {
      List<Future<QuerySnapshot>> orderDetailsFutures = [];

      for (var order in ordersSnapshot.docs) {
        var orderData = order.data() as Map<String, dynamic>?;

        if (orderData != null && orderData.containsKey('customer_id')) {
          String customerId = orderData['customer_id'].toString();

          if (!customerOrders.containsKey(customerId)) {
            customerOrders[customerId] = [];
            customerIds
                .add(customerId); // Keep track of customer order sequence
          }

          orderDetailsFutures
              .add(order.reference.collection('order_details').get());
        }
      }

      List<QuerySnapshot> orderDetailsSnapshots =
          await Future.wait(orderDetailsFutures);

      for (int i = 0; i < orderDetailsSnapshots.length; i++) {
        var order = ordersSnapshot.docs[i];
        var orderData = order.data() as Map<String, dynamic>?;

        if (orderData != null) {
          String customerId = orderData['customer_id'].toString();

          for (var detail in orderDetailsSnapshots[i].docs) {
            var detailData = detail.data() as Map<String, dynamic>?;

            if (detailData != null &&
                detailData.containsKey('Product Name') &&
                detailData.containsKey('quantity')) {
              customerOrders[customerId]!.add({
                'productName': detailData['Product Name'].toString(),
                'quantity': detailData['quantity'].toString(),
              });
            }
          }
        }
      }
    }
    if (customerOrders.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('No pending orders available for this van')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          builder: (_, scrollController) {
            return Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Drag Handle
                  Center(
                    child: Container(
                      width: 50,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey[400],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),

                  // Van Details Section
                  const Text(
                    'Van Details',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),

                  Text('Van Name: $vanName',
                      style: const TextStyle(fontSize: 16)),
                  Text('Van ID: $vanId', style: const TextStyle(fontSize: 16)),
                  Text('Reg. No: $regNo', style: const TextStyle(fontSize: 16)),
                  Text('Total Orders: ${ordersSnapshot.docs.length}',
                      style: const TextStyle(fontSize: 16)),
                  Text('Total Customers: ${customerOrders.keys.length}',
                      style: const TextStyle(fontSize: 16)),
                  const Divider(),
                  const SizedBox(height: 15),

                  // Customer Orders Section
                  const Text(
                    'Customer Orders:',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  // Drill-down List for Customer Orders
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      children: customerOrders.entries.map((customerEntry) {
                        String customerId = customerEntry.key;
                        List<Map<String, dynamic>> products =
                            customerEntry.value;

                        return ExpansionTile(
                          title: Text(
                            'Customer ID: $customerId',
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          children: [
                            // Column Headers
                            const Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16.0),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Item(s)',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'Quantity',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Divider(),

                            // Product List
                            ...products.map((product) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16.0),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      product['productName'],
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(
                                          right: 18.0), // Added right padding
                                      child: Text(
                                        '${product['quantity']}',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                            const SizedBox(height: 10),
                          ],
                        );
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Bottom Action Buttons
                 Row(
                children: [
                  Expanded(
                     
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel',
                            style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10), // Reduced spacing
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () async {
                          try {
                            WriteBatch batch =
                                FirebaseFirestore.instance.batch();
                            Map<String, int> productQuantities = {};
                            Map<String, List<Map<String, dynamic>>>
                                productTransactions = {};
                            List<DocumentReference> processedOrders = [];

                            // Accumulate product quantities and track order references
                            for (var order in ordersSnapshot.docs) {
                              var orderData =
                                  order.data() as Map<String, dynamic>?;

                              if (orderData != null &&
                                  orderData.containsKey('customer_id')) {
                                String customerId =
                                    orderData['customer_id'].toString();
                                String vanId = orderData['van_id'].toString();
                                String orderId = order.id;

                                var orderDetailsSnapshot = await order
                                    .reference
                                    .collection('order_details')
                                    .get();

                                for (var detail in orderDetailsSnapshot.docs) {
                                  var detailData =
                                      detail.data() as Map<String, dynamic>?;

                                  if (detailData != null &&
                                      detailData.containsKey('Product Name') &&
                                      detailData.containsKey('quantity')) {
                                    String productName =
                                        detailData['Product Name'].toString();
                                    int quantity =
                                        int.tryParse(detailData['quantity']
                                                .toString()) ??
                                            0;

                                    if (quantity > 0) {
                                      productQuantities.update(
                                        productName,
                                        (existingQty) =>
                                            existingQty + quantity,
                                        ifAbsent: () => quantity,
                                      );

                                      productTransactions.putIfAbsent(
                                          productName, () => []);
                                      productTransactions[productName]!.add({
                                        'productName': productName,
                                        'quantity': quantity,
                                        'vanId': selectedVan,
                                      });

                                      DocumentReference orderRef =
                                          FirebaseFirestore.instance
                                              .collection('order_masters')
                                              .doc(orderId);

                                      if (!processedOrders.contains(orderRef)) {
                                        processedOrders.add(orderRef);
                                      }
                                    }
                                  }
                                }
                              }
                            }

                            if (productQuantities.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('No stock to process')),
                              );
                              return;
                            }

                            // Process stock transfers in batch
                            List<Future<void>> operations = [];
                            productQuantities.forEach((productName, totalQuantity) {
                              operations.add(processStockTransfer(
                                productName,
                                totalQuantity,
                                productTransactions[productName]!,
                                batch,
                              ));
                            });

                            await Future.wait(operations);

                            for (var orderRef in processedOrders) {
                              batch.update(orderRef,
                                  {'status': 'Pending + Stock Transferred'});
                            }

                            await batch.commit();

                            setState(() {
                              selectedVan = null;
                              customerOrders.clear();
                            });

                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text(
                                      'Stock successfully processed for this van')),
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content:
                                      Text('Error processing stock: $e')),
                            );
                          }
                        },
                        child: const Text('Process',
                            style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  },
);
  }

  // Main UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Order to Van',
      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold,color: Colors.white)),
        backgroundColor: Colors.indigo,
       iconTheme: const IconThemeData(color: Colors.white),
      centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      isVanWise = false;
                      selectedVan = null;
                    });
                    showAllVansDetails();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        !isVanWise ? Colors.indigo : Colors.grey[300],
                  ),
                  child: Text(
                    'All',
                    style: TextStyle(
                        color: !isVanWise ? Colors.white : Colors.black),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      isVanWise = true;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isVanWise ? Colors.indigo : Colors.grey[300],
                  ),
                  child: Text(
                    'Van Wise',
                    style: TextStyle(
                        color: isVanWise ? Colors.white : Colors.black),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (isVanWise) ...[
              const Text(
                'Select Van:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              DropdownButton<String>(
                value: selectedVan,
                hint: const Text('Choose a van'),
                isExpanded: true,
                onChanged: (value) {
                  setState(() {
                    selectedVan = value;
                    if (value != null) {
                      showVanDetails(value);
                    }
                  });
                },
                items: vanNames.map((van) {
                  return DropdownMenuItem(
                    value: van,
                    child: Text(van),
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 20),
            Expanded(
              child: Center(
                child: Text(
                  isVanWise
                      ? (selectedVan != null
                          ? "Showing orders for $selectedVan"
                          : "Please select a van")
                      : "Showing orders for all vans",
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
