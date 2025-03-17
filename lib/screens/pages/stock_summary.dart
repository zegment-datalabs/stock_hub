import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class StockSummaryPage extends StatefulWidget {
  const StockSummaryPage({super.key});

  @override
  State<StockSummaryPage> createState() => _StockSummaryPageState();
}

class _StockSummaryPageState extends State<StockSummaryPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  int? _expandedIndex;

  Future<Map<String, List<Map<String, dynamic>>>> fetchStockSummary() async {
    final categoriesSnapshot = await _firestore.collection('category').get();
    final productsSnapshot = await _firestore.collection('product').get();

    Map<String, List<Map<String, dynamic>>> stockSummary = {};

    for (var category in categoriesSnapshot.docs) {
      String categoryName = category['title'];
      stockSummary[categoryName] = productsSnapshot.docs
          .where((product) => product['category'] == categoryName)
          .map((product) => {
                'title': product['title'],
                'quantity': product['opening_stock']
              })
          .toList();
    }

    return stockSummary;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Stock Summary',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.indigo,
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
      ),
      body: FutureBuilder(
        future: fetchStockSummary(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No data available'));
          }

          final stockSummary = snapshot.data!;

          return ListView.builder(
            itemCount: stockSummary.length,
            itemBuilder: (context, index) {
              String categoryName = stockSummary.keys.elementAt(index);
              List<Map<String, dynamic>> products = stockSummary[categoryName]!;

              return ExpansionTile(
                initiallyExpanded: _expandedIndex == index,
                onExpansionChanged: (isExpanded) {
                  setState(() {
                    _expandedIndex = isExpanded ? index : null;
                  });
                },
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      categoryName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${products.length} item(s)',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                children: [
                  Container(
                    color: const Color(0xFFFFF9C4), // Pale Yellow Background
                    padding: const EdgeInsets.only(top: 3.0, bottom: 3.0), // Reduced space
                    child: Column(
                      children: [
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10.0), // Reduced padding
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Item(s)',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Quantity',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Divider(height: 8, thickness: 1), // Reduced divider spacing
                        ...products.map((product) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2.0), // Minimized spacing
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12.0), // Tighter content
                                title: Text(
                                  product['title'],
                                  style: const TextStyle(fontSize: 16),
                                ),
                                trailing: Text(
                                  '${product['quantity']}',
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ),
                            )).toList(),
                      ],
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
