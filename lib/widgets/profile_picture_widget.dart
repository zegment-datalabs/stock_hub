import 'package:flutter/material.dart';
import 'dart:io';

class ProfilePictureWidget extends StatelessWidget {
  final File? selectedImage;
  final String? uploadedImageUrl;
  final VoidCallback onTap;

  const ProfilePictureWidget({
    super.key,
    required this.selectedImage,
    required this.uploadedImageUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: CircleAvatar(
        radius: 50,
        backgroundImage: selectedImage != null
            ? FileImage(selectedImage!)
            : (uploadedImageUrl != null && uploadedImageUrl!.isNotEmpty
                ? NetworkImage(uploadedImageUrl!)
                : null),
        child: selectedImage == null && (uploadedImageUrl == null || uploadedImageUrl!.isEmpty)
            ? const Icon(Icons.person, size: 90, color: Colors.white)
            : null,
      ),
    );
  }
}
