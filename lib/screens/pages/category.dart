import 'dart:ui';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:stock_hub/screens/homepage.dart';
import 'package:stock_hub/screens/pages/products.dart';
import 'package:stock_hub/screens/pages/routes.dart';
import 'package:stock_hub/screens/pages/van.dart';
import 'package:stock_hub/screens/pages/supplier.dart';
import 'package:stock_hub/screens/pages/salesman.dart';
import 'package:stock_hub/screens/login_page.dart';

final FirebaseFirestore _firestore = FirebaseFirestore.instance;

class Category {
  String title;
  String description;
  String icon;
  int category_id;

  Category(
      {required this.title,
      required this.description,
      required this.icon,
      required this.category_id});
}

class CategoryPage extends StatefulWidget {
  const CategoryPage({super.key});

  @override
  _CategoryPageState createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage> {
  List<Category> categories = [];
  final ImagePicker _picker = ImagePicker();
  List<Category> filteredCategories = [];
  final TextEditingController _searchController = TextEditingController();
  bool isDeleteMode = false; // Add this flag
  String? selectedButton; // Declare the selected button state variable

  @override
  void initState() {
    super.initState();
    _fetchCategories();
    _searchController.addListener(_filterCategories);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchCategories() async {
    try {
      QuerySnapshot snapshot = await _firestore.collection('category').get();

      if (snapshot.docs.isEmpty) {
        print("Firestore: No categories found.");
      } else {
        print("Firestore: Categories fetched (${snapshot.docs.length} items)");
      }

      setState(() {
        categories = snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return Category(
            title: data['title'] ?? 'No title',
            description: data['description'] ?? 'No description',
            icon: data['icon'] ?? '',
            category_id: data['category_id'] != null
                ? int.tryParse(data['category_id'].toString()) ?? 0
                : 0,
          );
        }).toList();
        filteredCategories = List.from(
            categories); // Initially, filteredCategories = all categories
      });
    } catch (e) {
      print("Error fetching categories: $e");
    }
  }

  void _filterCategories() async {
    String query = _searchController.text.toLowerCase().trim();

    if (query.isEmpty) {
      await _fetchCategories();
      return;
    }

    final snapshot = await _firestore
        .collection('category')
        .where('title', isGreaterThanOrEqualTo: query)
        .where('title',
            isLessThanOrEqualTo: query + '\uf8ff') // Firestore text search
        .limit(20) // Limit results
        .get();

    setState(() {
      if (query.isEmpty) {
        filteredCategories = List.from(categories); // Reset to all categories
      } else {
        filteredCategories = categories.where((category) {
          return category.title.toLowerCase().contains(query);
        }).toList();
      }
    });
  }

  Future<String> _getNextCategoryId() async {
    try {
      var querySnapshot = await _firestore
          .collection(
              'categories') // Ensure this is the correct Firestore collection name
          .orderBy('category_id',
              descending: true) // Get the latest category ID
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return "0001"; // First category_id
      }

      String lastCategoryId = querySnapshot.docs.first['category_id'];
      print("Last category ID from Firestore: $lastCategoryId");

      // Extract the numeric part correctly
      int numberPart = int.tryParse(lastCategoryId) ?? 0;
      numberPart++; // Increment the number

      // Format back to a 4-digit string (e.g., "0001", "0002", ..., "9999")
      String newCategoryId = numberPart.toString().padLeft(4, '0');

      print("Generated new category ID: $newCategoryId");
      return newCategoryId;
    } catch (e) {
      print("Error generating category ID: $e");
      return "0001"; // Fallback ID
    }
  }

  // Function to show the bottom sheet for adding or editing a category
  void _showCategoryForm(BuildContext context,
      {bool isEditing = false, Category? category}) async {
    final _titleController = TextEditingController(text: category?.title ?? '');
    final _descriptionController =
        TextEditingController(text: category?.description ?? '');
    final _iconController = TextEditingController(text: category?.icon ?? '');
    final _categoryIdController = TextEditingController(
        text: category != null ? category.category_id.toString() : '');
    String? _pickedIcon;

    if (!isEditing) {
      // Generate new category ID if creating a new category
      String nextCategoryId = await _getNextCategoryId();
      _categoryIdController.text = nextCategoryId;
    }

    onPressed:
    () {
      final newCategory = Category(
        title: _titleController.text,
        description: _descriptionController.text,
        icon: _pickedIcon ?? _iconController.text,
        category_id: int.tryParse(_categoryIdController.text) ??
            DateTime.now().millisecondsSinceEpoch, // Auto-generate if empty
      );

      if (isEditing) {
        setState(() {
          categories[categories.indexOf(category!)] = newCategory;
          filteredCategories =
              List.from(categories); // Ensure filtered list is updated
        });
      } else {
        setState(() {
          categories.insert(
              0, newCategory); // Insert the new category at the top of the list
          filteredCategories.insert(
              0, newCategory); // Insert at the top of the filtered list
        });
      }

      // Save to Firestore
      _saveCategoryToFirestore(newCategory, isEditing);

      Navigator.pop(context); // Close the modal
    };

    Future<String> _uploadImageToStorage(File imageFile) async {
      try {
        String fileName = DateTime.now().millisecondsSinceEpoch.toString();
        Reference ref =
            FirebaseStorage.instance.ref().child('category/$fileName.jpg');

        UploadTask uploadTask = ref.putFile(imageFile);
        TaskSnapshot snapshot = await uploadTask;

        String downloadUrl = await snapshot.ref.getDownloadURL();
        return downloadUrl;
      } catch (e) {
        print("Error uploading image: $e");
        return "";
      }
    }

    // Function to pick an image from gallery or camera
    Future<void> _pickImage() async {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        String downloadUrl = await _uploadImageToStorage(File(image.path));
        setState(() {
          _pickedIcon = downloadUrl;
        });
      }
    }

    // Function to capture an image using the camera
    Future<void> _takePicture() async {
      final XFile? image = await _picker.pickImage(source: ImageSource.camera);
      if (image != null) {
        String downloadUrl = await _uploadImageToStorage(File(image.path));
        setState(() {
          _pickedIcon = downloadUrl;
        });
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: AnimatedPadding(
            padding: const EdgeInsets.all(16.0),
            duration: const Duration(seconds: 3),
            curve: Curves.easeInOut,
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24.0),
                topRight: Radius.circular(24.0),
                // bottomLeft: Radius.circular(24.0),
               // bottomRight: Radius.circular(24.0),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.8,
                  height: MediaQuery.of(context).size.height * 0.5,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(isEditing ? 'Edit category' : 'Add category',
                            style: Theme.of(context)
                                .textTheme
                                .headlineMedium
                                ?.copyWith(
                                    color: const Color.fromARGB(255, 2, 3, 7),
                                    fontWeight: FontWeight.bold,fontSize: 22)),
                        const SizedBox(height: 14),
                        TextField(
                          controller: _titleController,
                          decoration: const InputDecoration(
                            labelText: 'Category Title',
                            labelStyle: TextStyle(color: Colors.black54),
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: _categoryIdController,
                          decoration: const InputDecoration(
                            labelText: 'Category ID',
                            labelStyle: TextStyle(color: Colors.black54),
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: _descriptionController,
                          decoration: const InputDecoration(
                            labelText: 'Description',
                            labelStyle: TextStyle(color: Colors.black54),
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: _iconController,
                          decoration: const InputDecoration(
                            labelText: 'Category Icon URL',
                            labelStyle: TextStyle(color: Colors.black54),
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
  children: [
                    // Gallery Button with Icon
                  ElevatedButton(
                      onPressed: _pickImage,
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        foregroundColor:  Colors.indigo, // Color when pressed
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Icon(Icons.photo_library,size:30, color: Color.fromARGB(255, 65, 52, 52)),
                    ),

                    ElevatedButton(
                      onPressed: _takePicture,
                      style: ElevatedButton.styleFrom(
                      elevation: 0,
                        foregroundColor: Colors.indigo, // Color when pressed
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Icon(Icons.camera_alt,size:30,  color: Color.fromARGB(255, 65, 52, 52)),
                    ),
                  ],
                ),

                        const SizedBox(height: 14),
                        if (_pickedIcon != null)
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(
                                File(_pickedIcon!),
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        const SizedBox(height: 14),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              child: const Text('Cancel',
                               style: TextStyle(fontSize: 16, color: Color.fromARGB(255, 201, 35, 35))),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                final newCategory = Category(
                                  title: _titleController.text,
                                  description: _descriptionController.text,
                                  icon: _pickedIcon ?? _iconController.text,
                                  category_id: int.tryParse(
                                          _categoryIdController.text) ??
                                      DateTime.now()
                                          .millisecondsSinceEpoch, // Auto-generate if empty
                                );

                                if (isEditing) {
                                  setState(() {
                                    categories[categories.indexOf(category!)] =
                                        newCategory;
                                  });
                                } else {
                                  // Only update the list after Firestore insertion, don't add twice
                                }

                                // Save to Firestore
                                _saveCategoryToFirestore(
                                    newCategory, isEditing);

                                Navigator.pop(context);
                              },
                              child: Text(isEditing ? 'Update' : 'Add'),
                              style: ElevatedButton.styleFrom(
                               elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 24, vertical: 12),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.zero)
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _saveCategoryToFirestore(
      Category category, bool isEditing) async {
    final categoryRef = _firestore.collection('category');
    try {
      if (isEditing) {
        await categoryRef.doc(category.title).update({
          'title': category.title,
          'description': category.description,
          'icon': category.icon,
          'category_id': category.category_id,
        });
        print("Firestore: Category updated.");
      } else {
        await categoryRef.doc(category.title).set({
          'title': category.title,
          'description': category.description,
          'icon': category.icon,
          'category_id': category.category_id,
        });
        print("Firestore: New category added.");
      }

      // Update the filteredCategories list after saving
      setState(() {
        filteredCategories.insert(
            0, category); // Insert at the top of the filtered list
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Category added successfully!")),
      );
    } catch (e) {
      print("Error saving category: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error saving category.")),
      );
    }
  }

  Future<void> _deleteImageFromStorage(String imageUrl) async {
    try {
      Reference ref = FirebaseStorage.instance.refFromURL(imageUrl);
      await ref.delete();
      print("Image deleted successfully from storage.");
    } catch (e) {
      print("Error deleting image from storage: $e");
    }
  }

  // Function to delete category from Firestore
  Future<void> _deleteCategory(Category category) async {
    try {
      // Get all orders from the order_masters collection
      final ordersSnapshot = await _firestore.collection('order_masters').get();
      bool isCategoryInUse = false;

      // Check if the category is used in any order
      for (var orderDoc in ordersSnapshot.docs) {
        final orderDetailsSnapshot = await _firestore
            .collection('order_masters')
            .doc(orderDoc.id)
            .collection('order_details')
            .where('Category Name', isEqualTo: category.title)
            .get();

        if (orderDetailsSnapshot.docs.isNotEmpty) {
          isCategoryInUse = true;
          print(
              'Category "${category.title}" is used in order ID: ${orderDoc.id}');
          break;
        }
      }

      if (isCategoryInUse) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Cannot delete  "${category.title}" as it is linked to existing orders!')),
        );
      } else {
        // Fetch the category document to get the image URL
        DocumentSnapshot categoryDoc =
            await _firestore.collection('category').doc(category.title).get();

        if (categoryDoc.exists && categoryDoc.data() is Map<String, dynamic>) {
          var categoryData = categoryDoc.data() as Map<String, dynamic>;

          if (categoryData.containsKey('icon') &&
              categoryData['icon'] != null) {
            String imageUrl = categoryData['icon'];

            // **Ensure image is deleted before proceeding**
            await _deleteImageFromStorage(imageUrl);
          }
        }

        // **Now delete the category document**
        await _firestore.collection('category').doc(category.title).delete();

        // Remove from UI lists
        setState(() {
          categories.remove(category);
          filteredCategories.remove(category);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Category deleted successfully!")),
        );
      }
    } catch (e) {
      print("Error deleting category: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error deleting category.")),
      );
    }
  }

  void _showDeleteConfirmationDialog(Category category, int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Confirm Deletion"),
          content: const Text("Are you sure you want to delete this category?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close the dialog
              },
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                // Delete the category from Firestore
                await _deleteCategory(category);
                setState(() {
                  categories.removeAt(index); // Remove from the list
                });
                Navigator.pop(context); // Close the dialog
              },
              child: const Text("Delete"),
            ),
          ],
        );
      },
    );
  }

  void _showCategorySelectionSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          height: 400,
          child: Column(
            children: [
              const Text(
                "Select Category to Update",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: ListView.builder(
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    return ListTile(
                      title: Text(category.title),
                      subtitle: Text(category.description),
                      leading: category.icon.startsWith('http')
                          ? Image.network(category.icon,
                              width: 50, height: 50, fit: BoxFit.cover)
                          : Image.file(File(category.icon),
                              width: 50, height: 50, fit: BoxFit.cover),
                      onTap: () {
                        Navigator.pop(context); // Close selection sheet
                        _showCategoryForm(context,
                            isEditing: true,
                            category: category); // Open edit form
                      },
                    );
                  },
                ),
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
      appBar: AppBar(
        title: const Text('Category Page', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),),
        backgroundColor: Colors.indigo,
        iconTheme: const IconThemeData(color: Colors.black),
          centerTitle: true,
      ),

      // Drawer for Navigation
      endDrawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
           // Reduced Height Drawer Header
      Container(
        height: 120, // Reduced height
        color: Colors.indigo,
      ),
            _buildDrawerItem(Icons.home_outlined, 'Home', const HomePage()),
            _buildDrawerItem(
                Icons.storage_rounded, 'Products', const ProductsPage()),
            _buildDrawerItem(Icons.business, 'Suppliers', const SupplierPage()),
            _buildDrawerItem(
                Icons.local_shipping_outlined, 'Van', const VanPage()),
            _buildDrawerItem(Icons.room_outlined, 'Routes', const RoutesPage()),
            _buildDrawerItem(
                Icons.person_3_outlined, 'Sales Man', const SalesmanPage()),
            _buildDrawerItem(Icons.exit_to_app, 'Logout', const LoginPage()),
          ],
        ),
      ),

      // Body Content
      body: Column(
        children: [
          // Search Bar Outside AppBar
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.black),
              decoration: InputDecoration(
                hintText: "Search categories...",
                hintStyle: const TextStyle(color: Colors.black54),
                prefixIcon: const Icon(Icons.search, color: Colors.black),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.black),
                        onPressed: () {
                          _searchController.clear();
                          _filterCategories();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.black),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.black),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.black, width: 2),
                ),
              ),
              onTap: () {
                if (categories.isEmpty) {
                  _fetchCategories();
                }
              },
              onChanged: (value) {
                _filterCategories();
              },
            ),
          ),

          // Category List
          Expanded(
            child: filteredCategories.isEmpty
                ? const Center(
                    child: Text(
                      "No matching categories.",
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    itemCount: filteredCategories.length > 20
                        ? 20
                        : filteredCategories.length,
                    physics: const BouncingScrollPhysics(),
                    itemBuilder: (context, index) {
                      final category = filteredCategories[index];
                      return Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 8, horizontal: 16),
                            child: Row(
                              children: [
                                // Category Icon
                                category.icon.isNotEmpty
                                    ? (category.icon.startsWith('http')
                                        ? Image.network(
                                            category.icon,
                                            width: 50,
                                            height: 50,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                              return const Icon(
                                                  Icons.image_not_supported,
                                                  size: 50,
                                                  color: Colors.grey);
                                            },
                                          )
                                        : const Icon(Icons.image_not_supported,
                                            size: 50, color: Colors.grey))
                                    : const Icon(Icons.image_not_supported,
                                        size: 50, color: Colors.grey),

                                const SizedBox(width: 12),

                                // Category Title & Description
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        category.title,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                          color: Color.fromARGB(255, 5, 1, 14),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        category.description,
                                        style: const TextStyle(
                                          color: Colors.black54,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Edit & Delete Icons
                                IconButton(
                                  icon: const Icon(Icons.edit,
                                      color: Colors.orange),
                                  onPressed: () {
                                    _showCategoryForm(context,
                                        isEditing: true, category: category);
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete,
                                      color:Color.fromARGB(255, 153, 29, 20)),
                                  onPressed: () {
                                    _showDeleteConfirmationDialog(
                                        category, index);
                                  },
                                ),
                              ],
                            ),
                          ),

                          // Divider for Separation
                          const Divider(
                            color: Colors.grey,
                            thickness: 1,
                            indent: 16,
                            endIndent: 16,
                          ),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),

      // Floating Action Button (FAB) for Adding Categories
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showCategoryForm(context);
        },
        backgroundColor: Colors.indigo,
        child: const Icon(Icons.add, color: Colors.white), // "+" Icon
      ),
    );
  }

// Drawer Item Builder
  Widget _buildDrawerItem(IconData icon, String title, Widget targetPage) {
    return ListTile(
      leading: Icon(icon, color: Colors.black),
      title: Text(title),
      onTap: () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => targetPage),
        );
      },
    );
  }
}
