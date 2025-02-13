import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_page.dart';

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
      userName = prefs.getString('name') ?? 'Guest';
    });

    print("✅ Loaded Username: userName");
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
      appBar: AppBar(title: const Text('Home')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundImage: _profilePicUrl.isNotEmpty
                      ? NetworkImage(_profilePicUrl)
                      : null, // No icon if URL is available
                  backgroundColor: Colors.grey.shade400, // No image if URL is empty
                  child: _profilePicUrl.isEmpty
                      ? const Icon(Icons.person, size: 50, color: Colors.white) // Placeholder icon
                      : null, // Background color for the icon
                ),
                const SizedBox(height: 10),
                Text("Welcome, ${userName ?? 'loading'}!", style: const TextStyle(fontSize: 24)),
                const SizedBox(height: 20),
                GridView.count(
                  crossAxisCount: 3, // 3 columns
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  padding: const EdgeInsets.all(16),
                  children: [
                    CircularButton(Icons.category, 'Category', Colors.blue, () {
                      // Navigate to Category page
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => CategoryPage()),
                      );
                    }),
                    CircularButton(Icons.add_shopping_cart, 'Products', Colors.green, () {
                      // Navigate to Products page
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => ProductsPage()),
                      );
                    }),
                    CircularButton(Icons.local_shipping, 'Van', Colors.orange, () {
                      // Navigate to Van page
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => VanPage()),
                      );
                    }),
                    CircularButton(Icons.local_taxi, 'Supplier', Colors.red, () {
                      // Navigate to Supplier page
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => SupplierPage()),
                      );
                    }),
                    CircularButton(Icons.directions, 'Routes', Colors.purple, () {
                      // Navigate to Routes page
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => RoutesPage()),
                      );
                    }),
                    CircularButton(Icons.person, 'Salesman', Colors.cyan, () {
                      // Navigate to Salesman page
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => SalesmanPage()),
                      );
                    }),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.black,
        unselectedItemColor: const Color.fromARGB(255, 0, 0, 0),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'My Account'),
        ],
      ),
    );
  }

  Widget CircularButton(IconData icon, String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          shape: BoxShape.circle,
          border: Border.all(color: color, width: 2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 40),
            const SizedBox(height: 10),
            Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }
}

// Example Pages for navigation
class CategoryPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Category Page')),
      body: Center(child: Text('Category Page Content')),
    );
  }
}

class ProductsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Products Page')),
      body: Center(child: Text('Products Page Content')),
    );
  }
}

class VanPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Van Page')),
      body: Center(child: Text('Van Page Content')),
    );
  }
}

class SupplierPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Supplier Page')),
      body: Center(child: Text('Supplier Page Content')),
    );
  }
}

class RoutesPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Routes Page')),
      body: Center(child: Text('Routes Page Content')),
    );
  }
}

class SalesmanPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Salesman Page')),
      body: Center(child: Text('Salesman Page Content')),
    );
  }
}
