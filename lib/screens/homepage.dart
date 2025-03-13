import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:stock_hub/screens/pages/Assignroute_and_name.dart.dart';
import 'package:stock_hub/screens/pages/products.dart';
import 'package:stock_hub/screens/pages/van.dart';
import 'package:stock_hub/screens/pages/routes.dart';
import 'package:stock_hub/screens/pages/salesman.dart';
import 'package:stock_hub/screens/pages/supplier.dart';
import 'package:stock_hub/screens/pages/category.dart';
import 'package:stock_hub/screens/stock_allocation.dart';
import 'package:stock_hub/screens/pages/salesman_to_van.dart';
import 'package:stock_hub/screens/pages/route_to_van.dart';
import 'package:stock_hub/screens/pages/add_stock.dart';
import 'package:stock_hub/screens/pages/order_to_van.dart';


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
    }
  }
@override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.indigo,
          centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 10.0),
            child: CircleAvatar(
              radius: 22,
              backgroundImage: _profilePicUrl.isNotEmpty ? NetworkImage(_profilePicUrl) : null,
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
            _buildNavItem(Icons.category_outlined, 'Category', const CategoryPage()),
            _buildNavItem(Icons.add_shopping_cart, 'Products', const ProductsPage()),
            _buildNavItem(Icons.inventory_2_outlined, 'Stock', StockAllocationPage()),
            _buildNavItem(Icons.warehouse, 'Add Stock', AddStockPage()),
            _buildNavItem(Icons.receipt_long_outlined, 'Order to Van', OrderToVanPage()),
            _buildNavItem(Icons.person_outline, 'Salesman', const SalesmanPage()),
            _buildNavItem(Icons.route_outlined,'Van and Route', const CustomerPage()),
            _buildNavItem(Icons.local_shipping_outlined, 'Van', const VanPage()),
            _buildNavItem(Icons.local_taxi_outlined, 'Supplier', const SupplierPage()),
            _buildNavItem(Icons.map_outlined, 'Routes', const RoutesPage()),
          ],
        ),
      ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        selectedItemColor: Colors.indigo,
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        elevation: 10,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'My Account'),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, Widget targetPage) {
    return InkWell(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => targetPage));
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
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}
// Animated Gradient Background Widget
// class AnimatedBackground extends StatefulWidget {
//   @override
//   _AnimatedBackgroundState createState() => _AnimatedBackgroundState();
// }

// class _AnimatedBackgroundState extends State<AnimatedBackground> {
//   @override
//   Widget build(BuildContext context) {
//     return AnimatedContainer(
//       duration: const Duration(seconds: 10),
//       decoration: BoxDecoration(
//         gradient: LinearGradient(
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//           colors: [Colors.purple.shade600, Colors.blue.shade600, Colors.green.shade600],
//           stops: [0.0, 0.5, 1.0],
//         ),
//       ),
//       child: Container(),
//     );
 // }
//}
