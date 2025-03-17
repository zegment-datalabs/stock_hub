import 'package:flutter/material.dart';
import 'package:stock_hub/screens/homepage.dart';
import 'package:stock_hub/screens/pages/products.dart';
import 'package:stock_hub/screens/pages/routes.dart';
import 'package:stock_hub/screens/pages/van.dart';
import 'package:stock_hub/screens/pages/supplier.dart';
import 'package:stock_hub/screens/pages/salesman.dart';
import 'package:stock_hub/screens/login_page.dart';

// Common AppBar
PreferredSizeWidget buildAppBar(String title) {
  return AppBar(
    title: Text(
      title,
      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
    ),
    backgroundColor: Colors.indigo,
    iconTheme: const IconThemeData(color: Colors.white),
    centerTitle: true,
  );
}

// Custom Search Bar
class CustomSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final Function(String) onSearch;
   final FocusNode? focusNode;

  const CustomSearchBar({
    Key? key,
    required this.controller,
    required this.onSearch,
    this.focusNode,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: TextField(
        controller: controller,
        onChanged: onSearch,
        decoration: InputDecoration(
          hintText: 'Search...',
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close, color: Colors.grey),
                  onPressed: () {
                    controller.clear();
                    onSearch(''); // Clear search results
                  },
                )
              : null,
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30.0),
            borderSide: const BorderSide(color: Colors.indigo),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30.0),
            borderSide: const BorderSide(color: Colors.indigo),
          ),
        ),
      ),
    );
  }
}

// Common End Drawer
Widget buildEndDrawer(BuildContext context) {
  return Drawer(
    child: ListView(
      padding: EdgeInsets.zero,
      children: [
        Container(height: 120, color: Colors.indigo), // Reduced height header
        _buildDrawerItem(Icons.home_outlined, 'Home', const HomePage(), context),
        _buildDrawerItem(Icons.storage_rounded, 'Products', const ProductsPage(), context),
        _buildDrawerItem(Icons.business, 'Suppliers', const SupplierPage(), context),
        _buildDrawerItem(Icons.local_shipping_outlined, 'Van', const VanPage(), context),
        _buildDrawerItem(Icons.room_outlined, 'Routes', const RoutesPage(), context),
        _buildDrawerItem(Icons.person_3_outlined, 'Sales Man', const SalesmanPage(), context),
        _buildDrawerItem(Icons.exit_to_app, 'Logout', const LoginPage(), context),
      ],
    ),
  );
}

// Drawer Item Builder
Widget _buildDrawerItem(IconData icon, String title, Widget targetPage, BuildContext context) {
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

// Common Floating Action Button
Widget buildFloatingButton(VoidCallback onPressed) {
  return FloatingActionButton(
    onPressed: onPressed,
    backgroundColor: Colors.indigo,
    child: const Icon(Icons.add, color: Colors.white),
  );
}
//bottom navigation
class CustomBottomNav extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;

  const CustomBottomNav({
    super.key,
    required this.selectedIndex,
    required this.onItemTapped,
  });
  
  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: selectedIndex,
      selectedItemColor: Colors.indigo,
      unselectedItemColor: Colors.grey,
      backgroundColor: Colors.white,
      elevation: 10,
      type: BottomNavigationBarType.fixed,
      onTap: onItemTapped,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
         BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Customer'),
          BottomNavigationBarItem(icon: Icon(Icons.local_shipping), label: 'Van'),
           BottomNavigationBarItem(icon: Icon(Icons.inventory), label: 'Stock Summary'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'My Account'),
      ],
    );
  }
}

/// Common Bottom Sheet for Adding/Editing Forms
void showCustomBottomSheet({
  required BuildContext context,
  required GlobalKey<FormState> formKey,
  required String title,
  required List<Widget> formFields,
  required VoidCallback onSave,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          top: 20,
        ),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 15),
              ...formFields, // Dynamic list of form fields
              const SizedBox(height: 25),

              // Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: onSave,
                    child: const Text('Save'),
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      );
    },
  );
}

// Common Button with Consistent Size
Widget customButton({
  required String text,
  required VoidCallback onPressed,
  double width = 180,
  double height = 40, 
  Color color = Colors.indigo,
  Color textColor = Colors.white,
}) {
  return SizedBox(
    width: width,
    height: height,
    child: ElevatedButton(
      style: ElevatedButton.styleFrom(backgroundColor: color),
      onPressed: onPressed,
      child: Text(
        text,
        style: TextStyle(fontSize: 16, color: textColor),
      ),
    ),
  );
}

// Common TextFormField with Compact Height
Widget customTextField({
  required TextEditingController controller,
  required String label,
  required IconData icon,
  TextInputType keyboardType = TextInputType.text,
  String? Function(String?)? validator,
}) {
  return TextFormField(
    controller: controller,
    decoration: InputDecoration(
      contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12), // Compact Height
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      prefixIcon: Icon(icon),
    ),
    keyboardType: keyboardType,
    validator: validator,
  );
}