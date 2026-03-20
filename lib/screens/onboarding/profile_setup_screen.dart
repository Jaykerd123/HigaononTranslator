import 'dart:io';
import 'package:Higa/models/user.dart';
import 'package:Higa/screens/services/database.dart';
import 'package:Higa/shared/loading.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:firebase_storage/firebase_storage.dart'; // Import Firebase Storage

class ProfileSetupScreen extends StatefulWidget {
  final VoidCallback onNext;

  const ProfileSetupScreen({Key? key, required this.onNext}) : super(key: key);

  @override
  _ProfileSetupScreenState createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  File? _image;
  bool _isLoading = false;
  String? _profileImageUrl; // To store the URL of the uploaded image

  final List<String> defaultAvatars = [
    'assets/avatars/avatar1.png',
    'assets/avatars/avatar2.png',
    'assets/avatars/avatar3.png',
    // Add more default avatars as needed
  ];

  @override
  void initState() {
    super.initState();
    // You might want to pre-select a default avatar or load an existing one
    // For now, let's assume no avatar is selected initially.
  }

  Future _pickImage(ImageSource source) async {
    final pickedFile = await ImagePicker().pickImage(source: source);
    setState(() {
      if (pickedFile != null) {
        _image = File(pickedFile.path);
        _profileImageUrl = null; // Clear default avatar selection if custom image is uploaded
      }
    });
  }

  Future<void> _uploadImage() async {
    if (_image == null) return; // No image to upload

    setState(() {
      _isLoading = true;
    });

    final user = Provider.of<CustomUser?>(context, listen: false);
    if (user == null) return;

    try {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('user_profile_images')
          .child('${user.uid}.jpg');
      await storageRef.putFile(_image!);
      _profileImageUrl = await storageRef.getDownloadURL();

      // Update the user's profile with the new image URL
      await DatabaseService(uid: user.uid)
          .updateUserData(profileImageUrl: _profileImageUrl);

      widget.onNext();
    } catch (e) {
      print(e);
      // Handle error, show a Snackbar, etc.
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _selectDefaultAvatar(String avatarPath) async {
    setState(() {
      _image = null; // Clear custom image selection
      _profileImageUrl = avatarPath;
    });

    final user = Provider.of<CustomUser?>(context, listen: false);
    if (user == null) return;

    // Update the user's profile with the default avatar path
    await DatabaseService(uid: user.uid)
        .updateUserData(profileImageUrl: _profileImageUrl);

    widget.onNext();
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const LoadingSpinner() // Corrected to LoadingSpinner
        : Scaffold(
            appBar: AppBar(
              title: const Text('Profile Setup'),
              backgroundColor: Colors.red,
              elevation: 0,
            ),
            body: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Progress Indicator (Placeholder for now)
                  _buildProgressIndicator(),
                  const SizedBox(height: 40),
                  GestureDetector(
                    onTap: () => _pickImage(ImageSource.gallery),
                    child: CircleAvatar(
                      radius: 80,
                      backgroundColor: Colors.grey[300],
                      backgroundImage: _image != null
                          ? FileImage(_image!) as ImageProvider<Object>?
                          : (_profileImageUrl != null &&
                                  _profileImageUrl!.startsWith('assets'))
                              ? AssetImage(_profileImageUrl!)
                              : null,
                      child: _image == null && _profileImageUrl == null
                          ? Icon(
                              Icons.camera_alt,
                              size: 50,
                              color: Colors.grey[600],
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextButton.icon(
                    onPressed: () => _pickImage(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Take Photo'),
                  ),
                  TextButton.icon(
                    onPressed: () => _pickImage(ImageSource.gallery),
                    icon: const Icon(Icons.image),
                    label: const Text('Choose from Gallery'),
                  ),
                  const SizedBox(height: 40),
                  const Text(
                    'Or choose a default avatar:',
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 80,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: defaultAvatars.length,
                      itemBuilder: (context, index) {
                        final avatarPath = defaultAvatars[index];
                        return GestureDetector(
                          onTap: () => _selectDefaultAvatar(avatarPath),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8.0),
                            child: CircleAvatar(
                              radius: 30,
                              backgroundImage: AssetImage(avatarPath),
                              backgroundColor: _profileImageUrl == avatarPath
                                  ? Colors.red.withOpacity(0.5)
                                  : Colors.transparent,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: (_image != null || _profileImageUrl != null)
                        ? (_image != null ? _uploadImage : widget.onNext)
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                    child: const Text('Next'),
                  ),
                ],
              ),
            ),
          );
  }

  Widget _buildProgressIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        return Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: index <= 0 ? Colors.red : Colors.grey,
                boxShadow: index <= 0
                    ? [
                        BoxShadow(
                          color: Colors.red.withOpacity(0.5),
                          blurRadius: 8.0,
                          spreadRadius: 3.0,
                        ),
                      ]
                    : null,
              ),
            ),
            if (index < 2)
              Container(
                width: 50,
                height: 2,
                color: index < 0 ? Colors.red : Colors.grey,
              ),
          ],
        );
      }),
    );
  }
}

