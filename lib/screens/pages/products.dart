import 'dart:ui';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:stock_hub/screens/homepage.dart';
import 'package:stock_hub/screens/pages/stock_summary.dart';
import 'package:stock_hub/screens/pages/van.dart';
import 'package:stock_hub/screens/pages/common_widgets.dart';
import 'package:stock_hub/screens/pages/customer.dart';
import 'package:stock_hub/screens/myaccount.dart';


final FirebaseFirestore _firestore = FirebaseFirestore.instance;

class Products {
  double purchasePrice;
  double mrp;
  double tax;
  double minimumStock;
  double maximumStock;
  double Openingstock;
  double reorderLevel;
  double sellingPrice;
  String category;
  String comments;
  String location;
  String productId;
  String uom;
  String title;
  String icon;
  String suppliername;
  String? selectedCategory;
  String? selectedSupplier;

  Products(
      {required this.category,
      required this.comments,
      required this.location,
      required this.productId,
      required this.purchasePrice,
      required this.Openingstock,
      required this.reorderLevel,
      required this.sellingPrice,
      required this.uom,
      required this.title,
      required this.icon,
      required this.maximumStock,
      required this.minimumStock,
      required this.mrp,
      required this.tax,
      required this.suppliername});
}

class ProductsPage extends StatefulWidget {
  const ProductsPage({super.key});

  @override
  _ProductsPageState createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  final ImagePicker _picker = ImagePicker();
  final TextEditingController searchController = TextEditingController();
  final List<String> uomOptions = ['Kg', 'Liters', 'Meters', 'Pieces'];
  List<Products> filteredProducts = [];
  List<Products> products = [];
  String searchQuery = '';
  int _selectedIndex = 0;
  List<String> locationOptions = [
    'Warehouse',
    'Store',
    'Office',
    'Factory',
    'Distribution Center'
  ];
  bool isDeleteMode = false; // Add this flag
  String? selectedButton;

  @override
  void initState() {
    super.initState();
    _fetchProducts();
    searchController
        .addListener(_filterProducts); // Filter instead of refetching
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }
void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (_selectedIndex) {
      case 0:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
        break;
        case 1:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const CustomerPage ()),
        );
        break;
         case 2:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const VanPage ()),
        );
        break;
         case 3:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) =>  StockSummaryPage()),
        );
        break;
      case 4:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const MyAccountPage()),
        );
        break;
    }
  }
  Future<void> _fetchProducts() async {
    try {
      QuerySnapshot snapshot = await _firestore.collection('product').get();

      if (snapshot.docs.isEmpty) {
        print("Firestore: No products found.");
      } else {
        print("Firestore: Products fetched (${snapshot.docs.length} items)");
      }

      setState(() {
        products.clear(); // ✅ Clear list before adding new items
        products = snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return Products(
            category: data['category'] ?? 'No Category',
            title: data['title'] ?? 'No title',
            comments: data['comments'] ?? 'No comments',
            suppliername: data['supplier_name'] ?? '',
            location: data['location'] ?? '',
            productId: data['product_id'] ?? '',
            purchasePrice: (data['purchasePrice'] is num)
                ? (data['purchasePrice'] as num).toDouble()
                : double.tryParse(data['purchasePrice']?.toString() ?? '0') ??
                    0.0,
            mrp: (data['MRP'] is num)
                ? (data['MRP'] as num).toDouble()
                : double.tryParse(data['MRP']?.toString() ?? '0') ?? 0.0,
            tax: (data['TAX'] is num)
                ? (data['TAX'] as num).toDouble()
                : double.tryParse(data['TAX']?.toString() ?? '0') ?? 0.0,
            Openingstock:
                double.tryParse(data['opening_stock']?.toString() ?? '0') ?? 0,
            maximumStock:
                double.tryParse(data['maximum_stock']?.toString() ?? '0') ?? 0,
            minimumStock:
                double.tryParse(data['minimum_stock']?.toString() ?? '0') ?? 0,
            reorderLevel:
                double.tryParse(data['reorder_level']?.toString() ?? '0') ?? 0,
            sellingPrice:
                double.tryParse(data['selling_price']?.toString() ?? '0') ?? 0,
            uom: data['uom'] ?? '',
            icon: data['product_url'] ?? '',
          );
        }).toList();
        filteredProducts = List.from(products);
      });
    } catch (e) {
      print("Error fetching products: $e");
    }
  }

  void _filterProducts() async {
    String query = searchController.text.toLowerCase().trim();

    if (query.isEmpty) {
      await _fetchProducts();
      return;
    }
    final snapshot = await _firestore
        .collection('product')
        .where('title', isGreaterThanOrEqualTo: query)
        .where('title',
            isLessThanOrEqualTo: query + '\uf8ff') // Firestore text search
        .limit(20) // Limit results
        .get();
    setState(() {
      if (query.isEmpty) {
        filteredProducts = List.from(products); // Reset to all categories
      } else {
        filteredProducts = products.where((category) {
          return category.title.toLowerCase().contains(query);
        }).toList();
      }
    });
  }

  Future<String> _getNextProductId() async {
    try {
      var querySnapshot = await _firestore
          .collection('product')
          .orderBy('product_id', descending: true) // Get the latest product ID
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return "PRD0001"; // First product
      }

      String lastProductId = querySnapshot.docs.first['product_id'];

      // Extract the numeric part from 'PRD0001'
      int numberPart = int.tryParse(lastProductId.substring(3)) ?? 0;
      numberPart++; // Increment the number

      // Format back to PRD000X
      return "PRD${numberPart.toString().padLeft(4, '0')}";
    } catch (e) {
      print("Error generating product ID: $e");
      return "PRD0001"; // Fallback ID
    }
  }

// Function to show the bottom sheet for adding or editing a products
  void _showProductsForm(BuildContext context,
      {bool isEditing = false, Products? product}) async {
    final _titleController = TextEditingController(text: product?.title ?? '');
    final _descriptionController =
        TextEditingController(text: product?.comments ?? ''); // Comments
    final _suppliernameController =
        TextEditingController(text: product?.suppliername ?? ''); //suppliername
    final _mrpController = TextEditingController(
        text: product != null ? product.mrp.toString() : '');
    final _taxController = TextEditingController(
        text: product != null ? product.tax.toString() : '');
    final _minimumstockController = TextEditingController(
        text: product != null ? product.minimumStock.toString() : '');
    final _maximumstockController = TextEditingController(
        text: product != null ? product.maximumStock.toString() : '');
    final _categoryController =
        TextEditingController(text: product?.category ?? ''); // Category
    final _locationController =
        TextEditingController(text: product?.location ?? ''); // Location
    final _productIdController =
        TextEditingController(text: product?.productId ?? ''); // Product ID
    final _purchasePriceController = TextEditingController(
        text: product != null ? product.purchasePrice.toString() : '');
    final _OpeninstockController = TextEditingController(text: '0');
    final _reorderLevelController = TextEditingController(
        text: product != null ? product.reorderLevel.toString() : '');
    final _sellingPriceController = TextEditingController(
        text: product != null ? product.sellingPrice.toString() : '');
    final _uomController = TextEditingController(
        text: product?.uom ?? ''); // Unit of Measure (UOM)
    final _iconController = TextEditingController(text: product?.icon ?? '');
    
    final ImagePicker _picker = ImagePicker();
    String? _pickedIcon;
    String? _selectedCategory = product?.category;
    String? _selectedSupplier = product?.suppliername;

    if (!isEditing) {
      // Generate new Product ID if creating a new product
      String nextProductId = await _getNextProductId();
      _productIdController.text = nextProductId;
    }

    onPressed:
    () {
      final newProduct = Products(
        title: _titleController.text,
        comments: _descriptionController.text,
        category: _selectedCategory ?? _categoryController.text,
        location: _locationController.text,
        productId: _productIdController.text,
        uom: _uomController.text,
        icon: _pickedIcon ?? _iconController.text,
        purchasePrice: double.tryParse(_purchasePriceController.text) ??
            0, // Convert to double
        Openingstock: 0,
        reorderLevel: double.tryParse(_reorderLevelController.text) ??
            0, // Convert to double
        sellingPrice: double.tryParse(_sellingPriceController.text) ??
            0, // Convert to double
        mrp: double.tryParse(_mrpController.text) ?? 0,
        tax: double.tryParse(_taxController.text) ?? 0,
        maximumStock: double.tryParse(_maximumstockController.text) ??
            0, // Convert to double
        minimumStock: double.tryParse(_minimumstockController.text) ??
            0, // Convert to double
        suppliername: _selectedSupplier ?? _suppliernameController.text,
      );
      print("DEBUG: Final icon URL being saved: ${newProduct.icon}");
      if (isEditing) {
        setState(() {
          products[products.indexOf(product!)] = newProduct;
          filteredProducts =
              List.from(products); // Ensure filtered list is updated
        });
      } else {
        setState(() {
          products.insert(
              0, newProduct); // Insert the new category at the top of the list
          filteredProducts.insert(
              0, newProduct); // Insert at the top of the filtered list
        });
      }

      _saveProductToFirestore(newProduct, isEditing);
      Navigator.pop(context); // Close the modal
    };

// // Selling Price Calculation
//     void _calculateSellingPrice() {
//       double purchasePrice =
//           double.tryParse(_purchasePriceController.text) ?? 0.0;
//       double profitMargin = 1.2; // 20% markup
//       double sellingPrice = purchasePrice * profitMargin;

//       setState(() {
//         _sellingPriceController.text = sellingPrice.toStringAsFixed(2);
//       });
//     }

    Future<String> _uploadImageToStorage(File imageFile) async {
      try {
        String fileName = DateTime.now().millisecondsSinceEpoch.toString();
        Reference ref =
            FirebaseStorage.instance.ref().child('products/$fileName.jpg');
        UploadTask uploadTask = ref.putFile(imageFile);
        TaskSnapshot snapshot = await uploadTask.whenComplete(() => null);

        // Check if the upload was successful
        if (snapshot.state == TaskState.success) {
          String downloadUrl = await snapshot.ref.getDownloadURL();
          print("DEBUG: Image uploaded successfully, URL: $downloadUrl");
          return downloadUrl;
        } else {
          print("ERROR: Image upload failed.");
          return "";
        }
      } catch (e) {
        print("Error uploading image: $e");
        return "";
      }
    }

// Function to pick an image from gallery or camera
    Future<void> _pickImage() async {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        String downloadUrl = await _uploadImageToStorage(File(pickedFile.path));

        if (downloadUrl.isNotEmpty) {
          setState(() {
            _pickedIcon = downloadUrl;
            _iconController.text = downloadUrl; // Ensure URL is set
          });
          print("DEBUG: Image uploaded, URL: $_pickedIcon");
        } else {
          print("ERROR: Image upload failed, URL not generated.");
        }
      } else {
        print("DEBUG: No image selected.");
      }
    }

// Function to capture an image using the camera
    Future<void> _takePicture() async {
      final XFile? image = await _picker.pickImage(source: ImageSource.camera);
      if (image != null) {
        String downloadUrl = await _uploadImageToStorage(File(image.path));

        if (downloadUrl.isNotEmpty) {
          setState(() {
            _pickedIcon = downloadUrl;
            _iconController.text = downloadUrl; // Ensure URL is set
          });
          print("DEBUG: Image uploaded from camera, URL: $_pickedIcon");
        } else {
          print("ERROR: Image upload failed, URL not generated.");
        }
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
                //bottomLeft: Radius.circular(24.0),
                //bottomRight: Radius.circular(24.0),
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
                        Text(isEditing ? 'Edit Product' : 'Add Product',
                            style: Theme.of(context)
                                .textTheme
                                .headlineMedium
                                ?.copyWith(
                                    color:
                                        const Color.fromARGB(255, 6, 7, 15),
                                    fontWeight: FontWeight.bold,fontSize: 22)),
                        const SizedBox(height: 14),
                        // Product Title
                        TextField(
                          controller: _titleController,
                          decoration: const InputDecoration(
                            labelText: 'Product Title',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Comments
                        TextField(
                          controller: _descriptionController,
                          decoration: const InputDecoration(
                            labelText: 'Comments',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Supplier Name
                        FutureBuilder<QuerySnapshot>(
                          future: FirebaseFirestore.instance
                              .collection('supplier')
                              .get(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const CircularProgressIndicator();
                            }

                            if (snapshot.hasError) {
                              print(
                                  'Error fetching suppliers: ${snapshot.error}');
                              return const Text('Error loading suppliers');
                            }

                            if (!snapshot.hasData ||
                                snapshot.data!.docs.isEmpty) {
                              print('No suppliers found in Firestore');
                              return const Text('No suppliers found');
                            }

                            print(
                                'Suppliers fetched: ${snapshot.data!.docs.length}');

                            List<DropdownMenuItem<String>> supplierItems =
                                snapshot.data!.docs.map((doc) {
                              print(
                                  'Supplier: ${doc['supplier_name']}'); // Debugging line
                              return DropdownMenuItem<String>(
                                value: doc['supplier_name'],
                                child: Text(doc['supplier_name']),
                              );
                            }).toList();

                            return DropdownButtonFormField<String>(
                              value: _selectedSupplier,
                              decoration: const InputDecoration(
                                labelText: 'Select Supplier',
                                border: OutlineInputBorder(),
                              ),
                              items: supplierItems,
                              onTap: () {
                                FocusScope.of(context)
                                    .unfocus(); // Hide keyboard before opening dropdown
                              },
                              onChanged: (value) {
                                setState(() {
                                  _selectedSupplier = value!;
                                  print(
                                      "Selected supplier: $_selectedSupplier"); // Debugging
                                });
                              },
                            );
                          },
                        ),

                        const SizedBox(height: 14),

                        // Category Dropdown (Fetching from Firestore)
                        FutureBuilder<QuerySnapshot>(
                          future: FirebaseFirestore.instance
                              .collection('category')
                              .get(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const CircularProgressIndicator();
                            }

                            if (snapshot.hasError) {
                              print(
                                  'Error fetching categories: ${snapshot.error}');
                              return const Text('Error loading categories');
                            }

                            if (!snapshot.hasData ||
                                snapshot.data!.docs.isEmpty) {
                              print('No categories found in Firestore');
                              return const Text('No categories found');
                            }

                            print(
                                'Categories fetched: ${snapshot.data!.docs.length}');

                            List<DropdownMenuItem<String>> categoryItems =
                                snapshot.data!.docs.map((doc) {
                              print(
                                  'Category: ${doc['title']}'); // Print each category title
                              return DropdownMenuItem<String>(
                                value: doc['title'],
                                child: Text(doc['title']),
                              );
                            }).toList();

                            return DropdownButtonFormField<String>(
                              value: _selectedCategory,
                              decoration: const InputDecoration(
                                labelText: 'Select Category',
                                border: OutlineInputBorder(),
                              ),
                              items: categoryItems,
                              onTap: () {
                                FocusScope.of(context)
                                    .unfocus(); // Hide keyboard before opening dropdown
                              },
                              onChanged: (value) {
                                setState(() {
                                  _selectedCategory = value!;
                                  print(
                                      "Selected category: $_selectedCategory"); // Debugging
                                });
                              },
                            );
                          },
                        ),

                        const SizedBox(height: 14),

                        // Location
                        DropdownButtonFormField<String>(
                          value:
                              locationOptions.contains(_locationController.text)
                                  ? _locationController.text
                                  : null,
                          decoration: const InputDecoration(
                            labelText: 'Select Location',
                            border: OutlineInputBorder(),
                          ),
                          items: locationOptions.map((String location) {
                            return DropdownMenuItem<String>(
                              value: location,
                              child: Text(location),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _locationController.text = value!;
                            });
                          },
                        ),
                        const SizedBox(height: 14),

                        // Product ID
                        TextField(
                          controller: _productIdController,
                          decoration: const InputDecoration(
                            labelText: 'Product ID',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Purchase Price
                        TextField(
                          controller: _purchasePriceController,
                          decoration: const InputDecoration(
                            labelText: 'Purchase Price',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            setState(() {
                              //_calculateSellingPrice();
                            });
                          },
                        ),
                        const SizedBox(height: 14),

                        // Quantity
                        TextField(
                          controller: _OpeninstockController,
                          decoration: const InputDecoration(
                            labelText: 'Opening stock',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          enabled: false,
                        ),
                        const SizedBox(height: 14),

                        // MRP
                        TextField(
                          controller: _mrpController,
                          decoration: const InputDecoration(
                            labelText: 'MRP',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 14),

                        // Tax
                        TextField(
                          controller: _taxController,
                          decoration: const InputDecoration(
                            labelText: 'Tax',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 14),

                        // Minimum Stock
                        TextField(
                          controller: _minimumstockController,
                          decoration: const InputDecoration(
                            labelText: 'Minimum Stock',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 14),

                        // Maximum Stock
                        TextField(
                          controller: _maximumstockController,
                          decoration: const InputDecoration(
                            labelText: 'Maximum Stock',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 14),

                        // Reorder Level
                        TextField(
                          controller: _reorderLevelController,
                          decoration: const InputDecoration(
                            labelText: 'Reorder Level',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 14),

                        // Selling Price
                        TextField(
                          controller: _sellingPriceController,
                          decoration: const InputDecoration(
                            labelText: 'Selling Price ',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 14),
                        //   TextField(
                        //     controller: _sellingPriceController,
                        //     decoration: const InputDecoration(
                        //       labelText: 'Selling Price (Auto-calculated)',
                        //       border: OutlineInputBorder(),
                        //     ),
                        //     keyboardType: TextInputType.number,
                        //     readOnly: true,
                        //   ),
                        // const SizedBox(height: 14),

                        // Unit of Measure Dropdown
                        DropdownButtonFormField<String>(
                          value: uomOptions.contains(_uomController.text)
                              ? _uomController.text
                              : null,
                          decoration: const InputDecoration(
                            labelText: 'Unit of Measure (UOM)',
                            border: OutlineInputBorder(),
                          ),
                          items: uomOptions.map((String uom) {
                            return DropdownMenuItem<String>(
                              value: uom,
                              child: Text(uom),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _uomController.text = value!;
                            });
                          },
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: _iconController,
                          decoration: const InputDecoration(
                            labelText: 'Product Icon URL',
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
                        const SizedBox(height: 16),
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
                                final newProduct = Products(
                                  title: _titleController.text,
                                  comments: _descriptionController.text,
                                  category: _selectedCategory ??
                                      _categoryController.text,
                                  location: _locationController.text,
                                  productId: _productIdController.text,
                                  uom: _uomController.text,
                                  icon: _pickedIcon ?? _iconController.text,
                                  purchasePrice: double.tryParse(
                                          _purchasePriceController.text) ??
                                      0, // Convert to double
                                  Openingstock: double.tryParse(
                                          _OpeninstockController.text) ??
                                      0, // Convert to double
                                  reorderLevel: double.tryParse(
                                          _reorderLevelController.text) ??
                                      0, // Convert to double
                                  sellingPrice: double.tryParse(
                                          _sellingPriceController.text) ??
                                      0, // Convert to double
                                  mrp:
                                      double.tryParse(_mrpController.text) ?? 0,
                                  tax:
                                      double.tryParse(_taxController.text) ?? 0,
                                  maximumStock: double.tryParse(
                                          _maximumstockController.text) ??
                                      0, // Convert to double
                                  minimumStock: double.tryParse(
                                          _minimumstockController.text) ??
                                      0, // Convert to double
                                  suppliername: _selectedSupplier ??
                                      _suppliernameController.text,
                                );
                                if (isEditing) {
                                  setState(() {
                                    products[products.indexOf(product!)] =
                                        newProduct;
                                  });
                                } else {
                                  // Only update the list after Firestore insertion, don't add twice
                                }
                                // Save to Firestore
                                _saveProductToFirestore(newProduct, isEditing);
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

  Future<void> _saveProductToFirestore(Products product, bool isEditing) async {
    print(
        "Saving product: ${product.title}, Supplier: ${product.suppliername}");

    final productRef = _firestore.collection('product');
    try {
      if (isEditing) {
        await productRef.doc(product.title).update({
          'title': product.title,
          'comments': product.comments,
          'category': product.category,
          'location': product.location,
          'purchase_price': product.purchasePrice,
          'opening_stock': product.Openingstock,
          'reorder_level': product.reorderLevel,
          'selling_price': product.sellingPrice,
          'uom': product.uom,
          'product_url': product.icon,
          'product_id': product.productId,
          'supplier_name': product.suppliername,
          'MRP': product.mrp,
          'TAX': product.tax,
          'minimum_stock': product.minimumStock,
          'maximum_stock': product.maximumStock,
        });
        print("Firestore: Product updated.");
      } else {
        await productRef.doc(product.title).set({
          'title': product.title,
          'comments': product.comments,
         'category': product.category,
          'location': product.location,
          'purchase_price': product.purchasePrice,
          'opening_stock': product.Openingstock,
          'reorder_level': product.reorderLevel,
          'selling_price': product.sellingPrice,
          'uom': product.uom,
          'product_url': product.icon,
          'product_id': product.productId,
          'supplier_name': product.suppliername,
          'MRP': product.mrp,
          'TAX': product.tax,
          'minimum_stock': product.minimumStock,
          'maximum_stock': product.maximumStock,
        });
        print(
            "Saving product: ${product.title}, Category: ${product.category}");
      }
      setState(() {
        filteredProducts.insert(0, product); // Insert at the top of the list
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Product added successfully!")),
      );
    } catch (e) {
      print("Error saving Product: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error saving Product.")),
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

// Function to delete Product from Firestore
  Future<void> _deleteProduct(Products product) async {
    try {
      // Get all orders from the order_masters collection
      final ordersSnapshot = await _firestore
          .collection('order_masters') // The parent collection
          .get();

      bool isProductInUse = false;
      // Loop through each order in the order_masters collection
      for (var orderDoc in ordersSnapshot.docs) {
        // Check if the category name exists in the order_details subcollection
        final orderDetailsSnapshot = await _firestore
            .collection('order_masters')
            .doc(orderDoc.id)
            .collection('order_details') // Subcollection of order_masters
            .where('Product Name',
                isEqualTo: product.title) // Match category name
            .get();

        if (orderDetailsSnapshot.docs.isNotEmpty) {
          isProductInUse = true;
          print(
              'Product "${product.title}" is used in order ID: ${orderDoc.id}');
          break;
        }
      }
      if (isProductInUse) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Cannot delete  "${product.title}" as it is linked to existing orders!')),
        );
      } else {
        // Fetch the category document to get the image URL
        DocumentSnapshot productDoc =
            await _firestore.collection('product').doc(product.title).get();

        if (productDoc.exists && productDoc.data() is Map<String, dynamic>) {
          var productData = productDoc.data() as Map<String, dynamic>;

          if (productData.containsKey('product_url') &&
              productData['product_url'] != null) {
            String imageUrl = productData['product_url'];

            // **Ensure image is deleted before proceeding**
            await _deleteImageFromStorage(imageUrl);
          }
        }
        // Proceed with deletion if not in use
        await _firestore.collection('product').doc(product.title).delete();
        setState(() {
          products.remove(product); // Remove from the local list
          filteredProducts.remove(product); // Remove from filtered list
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Product deleted successfully!")),
        );
      }
    } catch (e) {
      print("Error deleting product: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error deleting product.")),
      );
    }
  }

  void _showDeleteConfirmationDialog(Products product, int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Confirm Deletion"),
          content: const Text("Are you sure you want to delete this product?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close the dialog
              },
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                // Delete the product from Firestore
                await _deleteProduct(product);
                setState(() {
                  products.removeAt(index); // Remove from the list
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

  void _showProductsSelectionSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          height: 400,
          child: Column(
            children: [
              const Text(
                "Select Product to Update",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: ListView.builder(
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index];
                    return ListTile(
                      title: Text(product.title),
                      subtitle: Text(product.comments),
                      leading: product.icon.startsWith('http')
                          ? Image.network(product.icon,
                              width: 50, height: 50, fit: BoxFit.cover)
                          : Image.file(File(product.icon),
                              width: 50, height: 50, fit: BoxFit.cover),
                      onTap: () {
                        Navigator.pop(context); // Close selection sheet
                        _showProductsForm(context,
                            isEditing: true,
                            product: product); // Open edit form
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
      appBar: buildAppBar('Product Page'),
      endDrawer: buildEndDrawer(context),
      body: Column(
        children: [
          CustomSearchBar(
            controller: searchController,
            onSearch: (query) {
              setState(() {
                searchQuery = query;
              });
            },
          ),

          // Product List
          Expanded(
            child: filteredProducts.isEmpty
                ? const Center(
                    child: Text(
                      "No matching Product.",
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    itemCount: filteredProducts.length > 20
                        ? 20
                        : filteredProducts.length,
                    physics: const BouncingScrollPhysics(),
                    itemBuilder: (context, index) {
                      final products = filteredProducts[index];
                      return Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 8, horizontal: 16),
                            child: Row(
                              children: [
                                // Product Icon
                                products.icon.isNotEmpty
                                    ? (products.icon.startsWith('http')
                                        ? Image.network(
                                            products.icon,
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

                                const SizedBox(width: 30),

                                // Product Title & Description
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        products.title,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                          color: Color.fromARGB(255, 5, 2, 10),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        products.comments,
                                        style: const TextStyle(
                                          color: Colors.black54,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Edit & Delete Icons in List
                                IconButton(
                                  icon: const Icon(Icons.edit,
                                      color: Colors.orange),
                                  onPressed: () {
                                    _showProductsForm(context,
                                        isEditing: true, product: products);
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete,
                                      color: Color.fromARGB(255, 153, 29, 20)),
                                  onPressed: () {
                                    _showDeleteConfirmationDialog(
                                        products, index);
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

      // Use the Custom Bottom Navigation Bar
      bottomNavigationBar: CustomBottomNav(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    
      // Floating Action Button (FAB) for Adding Categories
      floatingActionButton: buildFloatingButton(() {
        _showProductsForm(context);
      }),
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
