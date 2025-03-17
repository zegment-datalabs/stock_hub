import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:stock_hub/screens/pages/customer.dart';
import 'package:stock_hub/screens/pages/products.dart';
import 'package:stock_hub/screens/pages/stock_summary.dart';
import 'package:stock_hub/screens/pages/van.dart';
import 'package:stock_hub/screens/pages/routes.dart';
import 'package:stock_hub/screens/pages/salesman.dart';
import 'package:stock_hub/screens/pages/supplier.dart';
import 'package:stock_hub/screens/pages/category.dart';
import 'package:stock_hub/screens/stock_allocation.dart';
import 'package:stock_hub/screens/pages/add_stock.dart';
import 'package:stock_hub/screens/pages/order_to_van.dart';
import 'package:stock_hub/screens/myaccount.dart';
import 'package:stock_hub/screens/pages/common_widgets.dart';


class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? userEmail;
  String _profilePicUrl = "";
  String? userName;

  final FirebaseFirestore db = FirebaseFirestore.instance;

  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // Load the saved user data from SharedPreferences
  void _loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      userEmail = prefs.getString('emailOrPhone') ?? 'Guest';
      _profilePicUrl = prefs.getString('profilePicPath') ?? "";
      userName = prefs.getString('username') ?? 'Guest';
    });

    print("✅ Loaded Username: $userName");
    print("✅ Loaded Profile Pic URL: $_profilePicUrl");
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold,color: Colors.white)),
            automaticallyImplyLeading: false,
        backgroundColor: Colors.indigo,
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 10.0),
            child: CircleAvatar(
              radius: 22,
              backgroundImage: _profilePicUrl.isNotEmpty
                  ? NetworkImage(_profilePicUrl)
                  : null,
              backgroundColor: Colors.grey.shade400,
              child: _profilePicUrl.isEmpty
                  ? const Icon(Icons.person, size: 28, color: Colors.white)
                  : null,
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 3,
          crossAxisSpacing: 20,
          mainAxisSpacing: 20,
          children: [
            _buildNavItem(
                Icons.category_outlined, 'Category', const CategoryPage()),
            _buildNavItem(
                Icons.add_shopping_cart, 'Products', const ProductsPage()),
            _buildNavItem(
                Icons.inventory_2_outlined, 'Stock', StockAllocationPage()),
            _buildNavItem(Icons.warehouse, 'Add Stock', AddStockPage()),
            _buildNavItem(
                Icons.receipt_long_outlined, 'Order to Van', OrderToVanPage()),
            _buildNavItem(
                Icons.person_outline, 'Salesman', const SalesmanPage()),
            _buildNavItem(
                Icons.route_outlined, 'Van and Route', const CustomerPage()),
            _buildNavItem(
                Icons.local_shipping_outlined, 'Van', const VanPage()),
            _buildNavItem(
                Icons.local_taxi_outlined, 'Supplier', const SupplierPage()),
            _buildNavItem(Icons.map_outlined, 'Routes', const RoutesPage()),
          _buildNavItem(Icons.inventory_2, 'Stock Summary', const StockSummaryPage()),

          ],
        ),
      ),// Use the Custom Bottom Navigation Bar
      bottomNavigationBar: CustomBottomNav(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, Widget targetPage) {
    return InkWell(
      onTap: () {
        Navigator.push(
            context, MaterialPageRoute(builder: (context) => targetPage));
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.indigo.withOpacity(0.15),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.indigo, width: 2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.indigo, size: 30),
            const SizedBox(height: 8),
            Text(label,
                style:
                    const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}
