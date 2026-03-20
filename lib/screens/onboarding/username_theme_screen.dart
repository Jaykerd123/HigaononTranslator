import 'dart:io';
import 'package:Higa/models/user.dart';
import 'package:Higa/screens/services/database.dart';
import 'package:Higa/shared/loading.dart'; // For LoadingSpinner
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:firebase_storage/firebase_storage.dart'; // For Firebase Storage
import 'package:shared_preferences/shared_preferences.dart';

class UsernameThemeScreen extends StatefulWidget {
  const UsernameThemeScreen({super.key}); // Removed avatar parameter

  @override
  State<UsernameThemeScreen> createState() => _UsernameThemeScreenState();
}

class _UsernameThemeScreenState extends State<UsernameThemeScreen> {
  final PageController _pageController = PageController();
  int _currentPageIndex = 0;
  final _usernameController = TextEditingController();
  bool _isDarkMode = false;

  File? _pickedImageFile; // For a custom image picked from gallery/camera
  String? _finalProfileImageUrl; // For the URL from Firebase Storage or asset path

  final GlobalKey<FormState> _usernameFormKey = GlobalKey<FormState>();

  final List<String> _defaultAvatars = [
    'assets/avatar/anby.webp',
    'assets/avatar/billy.webp',
    'assets/avatar/corin.webp',
    'assets/avatar/harumasa.webp',
    'assets/avatar/lighter.webp',
    'assets/avatar/miyabi.webp',
    'assets/avatar/nekomata.webp',
    'assets/avatar/nicole.webp',
  ];

  @override
  void dispose() {
    _pageController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  void _uploadImageAndProceed(String uid) {
    // Navigate immediately to avoid blocking the user
    if (mounted) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeIn,
      );
    }

    try {
      if (_pickedImageFile != null) {
        // Just use the local file path instead of Firebase Storage, as requested
        _finalProfileImageUrl = _pickedImageFile!.path;
        print('Using local image path: $_finalProfileImageUrl');
      }
    } catch (e) {
      print('Error assigning image local path: $e');
      if (_finalProfileImageUrl == null && _pickedImageFile != null) {
        _finalProfileImageUrl = _defaultAvatars[0];
      }
    } finally {
      _pickedImageFile = null;
      if (_finalProfileImageUrl == null) {
        _finalProfileImageUrl = _defaultAvatars[0];
      }
    }
  }

  void _goToNextPage() {
    if (_currentPageIndex == 0) { // On avatar selection page
      final user = Provider.of<CustomUser?>(context, listen: false);
      if (user != null) {
        // If a custom image is picked, upload it first
        if (_pickedImageFile != null) {
          _uploadImageAndProceed(user.uid);
          return; // Don't proceed until upload is done
        } else if (_finalProfileImageUrl == null) {
          // If no custom image and no default selected, default to first avatar
          _finalProfileImageUrl = _defaultAvatars[0];
        }
      }
    } else if (_currentPageIndex == 1) { // On Username Input Page
      if (!_usernameFormKey.currentState!.validate()) {
        return; // Don't proceed if validation fails
      }
    }

    if (_currentPageIndex < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeIn,
      );
    }
  }

  void _goToPreviousPage() {
    if (_currentPageIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeIn,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<CustomUser?>(context);

    // Do not return LoadingSpinner directly here to avoid dismounting PageView
    List<Widget> pages = [
      _AvatarSelectionPage(
        currentPickedImage: _pickedImageFile,
        currentSelectedAvatarUrl: _finalProfileImageUrl,
        defaultAvatars: _defaultAvatars,
        onImagePicked: (file) {
          setState(() {
            _pickedImageFile = file;
            _finalProfileImageUrl = null; // Clear default if custom is picked
          });
        },
        onDefaultAvatarSelected: (avatarPath) {
          setState(() {
            _finalProfileImageUrl = avatarPath;
            _pickedImageFile = null; // Clear custom if default is selected
          });
        },
      ),
      _UsernameInputPage(
        controller: _usernameController,
        formKey: _usernameFormKey,
      ),
      _DarkModeEnablePage(
        isDarkMode: _isDarkMode,
        onToggle: (value) {
          setState(() {
            _isDarkMode = value;
          });
        },
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Setup Your Profile'),
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentPageIndex = index;
                });
              },
              children: pages,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (_currentPageIndex > 0)
                  ElevatedButton(
                    onPressed: _goToPreviousPage,
                    child: const Text('Back'),
                  ),
                const Spacer(),
                ElevatedButton(
                  onPressed: () async {
                    if (_currentPageIndex == pages.length - 1) {
                      if (user != null) {
                        // Ensure an avatar is selected or default to the first one if none is selected
                        final avatarToSave = _finalProfileImageUrl ?? _defaultAvatars[0];

                        // Update user data in Firestore
                        await DatabaseService(uid: user.uid).updateUserData(
                          profileImageUrl: avatarToSave,
                          name: _usernameController.text.trim(),
                          isDarkMode: _isDarkMode,
                          onboardingCompleted: true, // Mark onboarding as complete
                        );

                        // Set onboarding completed flag in SharedPreferences
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setBool('onboarding_completed', true);

                        // Navigate to home and remove all previous routes
                        Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
                      }
                    } else {
                      _goToNextPage();
                    }
                  },
                  child: Text(_currentPageIndex == pages.length - 1 ? 'Finish' : 'Next'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Avatar Selection Page - Refactored from _ChooseProfilePage
class _AvatarSelectionPage extends StatefulWidget {
  final File? currentPickedImage;
  final String? currentSelectedAvatarUrl;
  final List<String> defaultAvatars;
  final ValueChanged<File?> onImagePicked;
  final ValueChanged<String> onDefaultAvatarSelected;

  const _AvatarSelectionPage({
    Key? key,
    required this.currentPickedImage,
    required this.currentSelectedAvatarUrl,
    required this.defaultAvatars,
    required this.onImagePicked,
    required this.onDefaultAvatarSelected,
  }) : super(key: key);

  @override
  State<_AvatarSelectionPage> createState() => _AvatarSelectionPageState();
}

class _AvatarSelectionPageState extends State<_AvatarSelectionPage> {
  Future _pickImage(ImageSource source) async {
    final pickedFile = await ImagePicker().pickImage(source: source);
    if (pickedFile != null) {
      widget.onImagePicked(File(pickedFile.path));
    }
  }

  void _selectDefaultAvatar(String avatarPath) {
    widget.onDefaultAvatarSelected(avatarPath);
  }

  @override
  Widget build(BuildContext context) {
    ImageProvider<Object>? backgroundImage;

    if (widget.currentPickedImage != null) {
      backgroundImage = FileImage(widget.currentPickedImage!); // Use custom picked image
    } else if (widget.currentSelectedAvatarUrl != null) {
      if (widget.currentSelectedAvatarUrl!.startsWith('assets')) {
        backgroundImage = AssetImage(widget.currentSelectedAvatarUrl!); // Use default asset
      } else if (Uri.tryParse(widget.currentSelectedAvatarUrl!)?.hasAbsolutePath == true) {
        backgroundImage = NetworkImage(widget.currentSelectedAvatarUrl!); // Use uploaded URL
      }
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Choose Your Profile Picture',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () => _pickImage(ImageSource.gallery), // Tapping avatar picks from gallery
              child: CircleAvatar(
                radius: 80,
                backgroundColor: Colors.grey[300],
                backgroundImage: backgroundImage,
                child: backgroundImage == null
                    ? Icon(
                        Icons.camera_alt,
                        size: 50,
                        color: Colors.grey[600],
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton.icon(
                  onPressed: () => _pickImage(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Take Photo'),
                ),
                const SizedBox(width: 10),
                TextButton.icon(
                  onPressed: () => _pickImage(ImageSource.gallery),
                  icon: const Icon(Icons.image),
                  label: const Text('Choose from Gallery'),
                ),
              ],
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
                itemCount: widget.defaultAvatars.length,
                itemBuilder: (context, index) {
                  final avatarPath = widget.defaultAvatars[index];
                  return GestureDetector(
                    onTap: () => _selectDefaultAvatar(avatarPath),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: CircleAvatar(
                        radius: 30,
                        backgroundImage: AssetImage(avatarPath),
                        backgroundColor: widget.currentSelectedAvatarUrl == avatarPath
                            ? Colors.red.withOpacity(0.5) // Highlight selected default avatar
                            : Colors.transparent,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Username Input Page - remains largely the same
class _UsernameInputPage extends StatelessWidget {
  final TextEditingController controller;
  final GlobalKey<FormState> formKey;

  const _UsernameInputPage({Key? key, required this.controller, required this.formKey}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'What\'s Your Name?',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: controller,
                decoration: const InputDecoration(
                  labelText: 'Username',
                  hintText: 'e.g., JohnDoe',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Username cannot be empty';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              const Text(
                'This username will be displayed to others.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Dark Mode Enable Page - remains largely the same
class _DarkModeEnablePage extends StatelessWidget {
  final bool isDarkMode;
  final ValueChanged<bool> onToggle;

  const _DarkModeEnablePage({Key? key, required this.isDarkMode, required this.onToggle}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Choose Your Theme',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            SwitchListTile(
              title: const Text('Enable Dark Mode'),
              value: isDarkMode,
              onChanged: onToggle,
              secondary: Icon(isDarkMode ? Icons.dark_mode : Icons.light_mode),
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 10),
            const Text(
              'You can always change your theme preference later in settings.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

