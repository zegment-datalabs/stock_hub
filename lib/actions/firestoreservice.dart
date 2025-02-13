import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Function to add category data to Firestore
  Future<void> addCategoryData(BuildContext context) async {
    final categoryCollection = _db.collection("category");

    try {
      final categories = [
        {"title": "Electronics", "icon": "devices"},
        {"title": "Clothing", "icon": "shopping_cart"},
        {"title": "Books", "icon": "library_books"},
        {"title": "Shoes", "icon": "local_mall"},
      ];

      for (var category in categories) {
        await categoryCollection.doc(category["title"]).set(category);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Category data successfully added!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding category data: $e')),
      );
    }
  }

  // Function to add product data to Firestore
  Future<void> addProductData(BuildContext context) async {
    final productCollection = _db.collection("product");

    try {
      final products = [
        {
          "product_id": "PRD0001",
          "product_url": "https://example.com/smartphone.jpg",
          "title": "Smartphone",
          "purchase_price": 699.99,
          "selling_price": 699.99,
          "qty": 10,
          "category": "Electronics"
        },
      ];

      for (var product in products) {
        await productCollection.doc(product['title'] as String).set(product);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product data successfully added!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding product data: $e')),
      );
    }
  }
}
