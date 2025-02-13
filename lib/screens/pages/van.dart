import 'package:flutter/material.dart';

class VanPage  extends StatelessWidget {
  const VanPage ({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Van Page')),
      body: const Center(child: Text('Van Page Content')),
    );
  }
}
