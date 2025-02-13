import 'package:flutter/material.dart';

class CategoryPage extends StatelessWidget {
  const CategoryPage({super.key});

  void _showBottomSheet(BuildContext context, String action) {
    showModalBottomSheet(
      context: context,
      shape:const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$action Category',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              if (action != 'Delete')
               TextField(
                  decoration: InputDecoration(
                    labelText: 'Category Name',
                    border: OutlineInputBorder(),
                  ),
                ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Close Bottom Sheet
                  // Handle action (New, Edit, Delete)
                },
                child: Text(action),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Category Page')),
      body: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton.icon(
              onPressed: () => _showBottomSheet(context, 'New'),
              icon: Icon(Icons.add),
              label: Text('New'),
            ),
            ElevatedButton.icon(
              onPressed: () => _showBottomSheet(context, 'Edit'),
              icon: Icon(Icons.edit),
              label: Text('Edit'),
            ),
            ElevatedButton.icon(
              onPressed: () => _showBottomSheet(context, 'Delete'),
              icon: Icon(Icons.delete),
              label: Text('Delete'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            ),
          ],
        ),
      ),
    );
  }
}
