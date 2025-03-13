import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
// import 'package:van_app_demo/cart_page.dart';
// import 'package:van_app_demo/homepage.dart';
// import 'package:van_app_demo/category/categorypage.dart';
// import 'package:van_app_demo/category/allproducts.dart';
// import 'package:van_app_demo/widgets/common_widgets.dart';

class MyAccountPage extends StatefulWidget {
  const MyAccountPage({super.key});

  @override
  _MyAccountPageState createState() => _MyAccountPageState();
}

class _MyAccountPageState extends State<MyAccountPage> {
  String _username = "";
  String _emailOrPhone = "";
  String _profilePicUrl = "";
  String _contact = "";
  bool _isEditing = false;
  int _selectedIndex = 4;
  

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _username = prefs.getString('username') ?? 'User';
      _emailOrPhone = prefs.getString('emailOrphone') ?? 'Not Available';
      _profilePicUrl = prefs.getString('profilePicPath') ?? "";
      _contact = prefs.getString('contact_number') ?? "Not Available";

      // Set text field controllers
      _usernameController.text = _username;
      _contactController.text = _contact;
    });
  }

  Future<void> _saveUserData() async {
    String? userEmail = FirebaseAuth.instance.currentUser?.email;

    if (userEmail != null) {
      QuerySnapshot customerSnapshot = await FirebaseFirestore.instance
          .collection('customer')
          .where('customer_email', isEqualTo: userEmail)
          .limit(1)
          .get();

      if (customerSnapshot.docs.isNotEmpty) {
        String customerId = customerSnapshot.docs.first.id;

        // Update Firebase customer collection
        await FirebaseFirestore.instance.collection('customer').doc(customerId).update({
          'customer_name': _usernameController.text,
          'customer_contact': _contactController.text,
          'customer_image_url': _profilePicUrl,
        });

        // Update users collection
        QuerySnapshot userSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .where('emailOrPhone', isEqualTo: userEmail)
            .limit(1)
            .get();

        if (userSnapshot.docs.isNotEmpty) {
          String userId = userSnapshot.docs.first.id;
          await FirebaseFirestore.instance.collection('users').doc(userId).update({
            'username': _usernameController.text,
            'contact_number': _contactController.text,
            'profileImageUrl': _profilePicUrl,
          });
        }
      }
    }

    // Update shared preferences
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('username', _usernameController.text);
    prefs.setString('contact_number', _contactController.text);
    prefs.setString('profilePicPath', _profilePicUrl);

    setState(() {
      _username = _usernameController.text;
      _contact = _contactController.text;
      _isEditing = false; // Switch back to profile view
    });
  }

  Future<void> _pickImageOptions() async {
  showModalBottomSheet(
    context: context,
    builder: (BuildContext context) {
      return SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text("Take a Photo"),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text("Choose from Gallery"),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            if (_profilePicUrl.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.delete),
                title: const Text("Remove Picture"),
                onTap: () {
                  Navigator.pop(context);
                  _removeProfilePicture();
                },
              ),
          ],
        ),
      );
    },
  );
}

Future<void> _pickImage(ImageSource source) async {
  final ImagePicker picker = ImagePicker();
  final XFile? image = await picker.pickImage(source: source);

  if (image != null) {
    File file = File(image.path);
    String userId = FirebaseAuth.instance.currentUser!.uid;
    Reference storageRef = FirebaseStorage.instance.ref().child("user_profiles/$userId.jpg");

    UploadTask uploadTask = storageRef.putFile(file);
    TaskSnapshot snapshot = await uploadTask;
    String downloadUrl = await snapshot.ref.getDownloadURL();

    setState(() {
      _profilePicUrl = downloadUrl;
    });

    _updateProfilePictureInFirebase(downloadUrl);
  }
}

Future<void> _removeProfilePicture() async {
  String userId = FirebaseAuth.instance.currentUser!.uid;
  Reference storageRef = FirebaseStorage.instance.ref().child("user_profiles/$userId.jpg");

  try {
    await storageRef.delete();
  } catch (e) {
    print("Error deleting profile picture: $e");
  }

  setState(() {
    _profilePicUrl = "";
  });

  _updateProfilePictureInFirebase("");
}

Future<void> _updateProfilePictureInFirebase(String newUrl) async {
  String? userEmail = FirebaseAuth.instance.currentUser?.email;

  if (userEmail != null) {
    QuerySnapshot customerSnapshot = await FirebaseFirestore.instance
        .collection('customer')
        .where('customer_email', isEqualTo: userEmail)
        .limit(1)
        .get();

    if (customerSnapshot.docs.isNotEmpty) {
      String customerId = customerSnapshot.docs.first.id;
      await FirebaseFirestore.instance.collection('customer').doc(customerId).update({
        'customer_image_url': newUrl,
      });

      QuerySnapshot userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('emailOrPhone', isEqualTo: userEmail)
          .limit(1)
          .get();

      if (userSnapshot.docs.isNotEmpty) {
        String userId = userSnapshot.docs.first.id;
        await FirebaseFirestore.instance.collection('users').doc(userId).update({
          'profileImageUrl': newUrl,
        });
      }
    }
  }

  SharedPreferences prefs = await SharedPreferences.getInstance();
  prefs.setString('profilePicPath', newUrl);
}


  // void _onItemTapped(int index) {
  //   switch (index) {
  //     case 0:
  //       Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) =>  HomePage()));
  //       break;
  //     case 1:
  //       Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) =>  CategoryPage()));
  //       break;
  //     case 2:
  //       Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) =>  CartPage()));
  //       break;
  //     case 3:
  //       Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) =>  AllProductsPage()));
  //       break;
  //     case 4:
  //       Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) =>  MyAccountPage()));
  //       break;
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('My Account', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.indigo,
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 40),
            decoration: const BoxDecoration(
              color: Colors.indigo,
              borderRadius: BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
            ),
            child: Column(
              children: [
                GestureDetector(
                  onTap: _pickImageOptions,
                  child: CircleAvatar(
                    radius: 50,
                    backgroundImage: _profilePicUrl.isNotEmpty
                        ? NetworkImage(_profilePicUrl)
                        : const AssetImage("assets/default_profile.png") as ImageProvider,
                    child: _profilePicUrl.isEmpty ? const Icon(Icons.camera_alt, size: 30, color: Colors.white) : null,
                  ),
                ),
                const SizedBox(height: 10),
                if (!_isEditing)
                  Column(
                    children: [
                      Text(
                        _username,
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white70),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        _emailOrPhone,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white70),
                      ),
                      // Text(
                      //   _contact,
                      //   style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white70),
                      // ),
                    ],
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _isEditing
              ? Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      TextField(
                        controller: _usernameController,
                        decoration: const InputDecoration(labelText: "Username"),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _contactController,
                        decoration: const InputDecoration(labelText: "Contact Number"),
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _saveUserData,
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                        child: const Text("Save"),
                      ),
                    ],
                  ),
                )
              : ElevatedButton(
                  onPressed: () => setState(() => _isEditing = true),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                  child: const Text("Edit Profile",style: TextStyle(color: Colors.white)),
                ),
        ],
      ),
bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1,
        selectedItemColor: Colors.indigo,
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        elevation: 10,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'My Account'),
        ],
      ),    );
  }
}
