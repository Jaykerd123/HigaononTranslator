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
  const UsernameThemeScreen({super.key});

  @override
  State<UsernameThemeScreen> createState() => _UsernameThemeScreenState();
}

class _UsernameThemeScreenState extends State<UsernameThemeScreen> {
  final PageController _pageController = PageController();
  int _currentPageIndex = 0;
  final _usernameController = TextEditingController();
  bool _isDarkMode = false;

  File? _pickedImageFile;
  String? _finalProfileImageUrl;

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
    if (mounted) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeIn,
      );
    }

    try {
      if (_pickedImageFile != null) {
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
      if (_finalProfileImageUrl == null && _pickedImageFile == null) {
        // If neither custom nor selection, don't force it to 0 if it already has one?
        // Actually we do force a default if both are empty natively
        if (_finalProfileImageUrl == null) {
          _finalProfileImageUrl = _defaultAvatars[0];
        }
      }
    }
  }

  void _goToNextPage() {
    if (_currentPageIndex == 0) {
      final user = Provider.of<CustomUser?>(context, listen: false);
      if (user != null) {
        if (_pickedImageFile != null) {
          _uploadImageAndProceed(user.uid);
          return;
        } else if (_finalProfileImageUrl == null) {
          _finalProfileImageUrl = _defaultAvatars[0];
        }
      }
    } else if (_currentPageIndex == 1) {
      if (!_usernameFormKey.currentState!.validate()) {
        return;
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

  Widget _buildStepper() {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0, bottom: 24.0, left: 32.0, right: 32.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepIconAndLabel(1, 'Avatar', _currentPageIndex >= 0),
          _buildLine(_currentPageIndex >= 1),
          _buildStepIconAndLabel(2, 'Username', _currentPageIndex >= 1),
          _buildLine(_currentPageIndex >= 2),
          _buildStepIconAndLabel(3, 'Theme', _currentPageIndex >= 2),
        ],
      ),
    );
  }

  Widget _buildStepIconAndLabel(int stepNum, String title, bool isActive) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? const Color(0xFFF73B46) : const Color(0xFFE5E7EB),
          ),
          child: Center(
            child: Text(
              '$stepNum',
              style: TextStyle(
                color: isActive ? Colors.white : const Color(0xFF6B7280),
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          title,
          style: TextStyle(
            color: isActive ? const Color(0xFF111827) : const Color(0xFF9CA3AF),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildLine(bool isActive) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.only(top: 22.0),
        child: Container(
          height: 2,
          color: isActive ? const Color(0xFFF73B46) : const Color(0xFFE5E7EB),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<CustomUser?>(context);

    List<Widget> pages = [
      _AvatarSelectionPage(
        currentPickedImage: _pickedImageFile,
        currentSelectedAvatarUrl: _finalProfileImageUrl,
        defaultAvatars: _defaultAvatars,
        onImagePicked: (file) {
          setState(() {
            _pickedImageFile = file;
            _finalProfileImageUrl = null;
          });
        },
        onDefaultAvatarSelected: (avatarPath) {
          setState(() {
            _finalProfileImageUrl = avatarPath;
            _pickedImageFile = null;
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
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Row(
              children: [
                if (_currentPageIndex > 0)
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.black87),
                    onPressed: _goToPreviousPage,
                  )
                else
                  const SizedBox(width: 48, height: 48), // Spacer to offset back button
                const Spacer(),
              ],
            ),
            _buildStepper(),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(), // user uses buttons to navigate
                onPageChanged: (index) {
                  setState(() {
                    _currentPageIndex = index;
                  });
                },
                children: pages,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: ElevatedButton(
                onPressed: () async {
                  if (_currentPageIndex == pages.length - 1) {
                    if (user != null) {
                      final avatarToSave = _finalProfileImageUrl ?? _defaultAvatars[0];

                      await DatabaseService(uid: user.uid).updateUserData(
                        profileImageUrl: avatarToSave,
                        name: _usernameController.text.trim(),
                        isDarkMode: _isDarkMode,
                        onboardingCompleted: true,
                      );

                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setBool('onboarding_completed', true);

                      Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
                    }
                  } else {
                    _goToNextPage();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF73B46),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _currentPageIndex == pages.length - 1 ? 'Finish' : 'Continue',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          children: [
            const SizedBox(height: 16),
            const Text(
              'Choose Your Avatar',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Color(0xFF111827),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Pick an avatar or upload your own',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            if (widget.currentPickedImage != null)
              Container(
                margin: const EdgeInsets.only(bottom: 24),
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFF73B46), width: 4),
                  image: DecorationImage(
                    image: FileImage(widget.currentPickedImage!),
                    fit: BoxFit.cover,
                  ),
                ),
              ),

            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: widget.defaultAvatars.length,
              itemBuilder: (context, index) {
                final avatarPath = widget.defaultAvatars[index];
                final isSelected = widget.currentSelectedAvatarUrl == avatarPath && widget.currentPickedImage == null;

                return GestureDetector(
                  onTap: () => widget.onDefaultAvatarSelected(avatarPath),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? const Color(0xFFF73B46) : const Color(0xFFE5E7EB),
                        width: isSelected ? 3 : 1.5,
                      ),
                      boxShadow: [
                        if (isSelected)
                          BoxShadow(
                            color: const Color(0xFFF73B46).withOpacity(0.2),
                            blurRadius: 10,
                            spreadRadius: 2,
                          )
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Image.asset(avatarPath, fit: BoxFit.contain),
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 32),
            OutlinedButton.icon(
              onPressed: () => _pickImage(ImageSource.gallery),
              icon: const Icon(Icons.camera_alt_outlined, color: Colors.black87),
              label: const Text(
                'Upload Custom Photo',
                style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 16),
              ),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 56),
                side: const BorderSide(color: Color(0xFFE5E7EB), width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _UsernameInputPage extends StatelessWidget {
  final TextEditingController controller;
  final GlobalKey<FormState> formKey;

  const _UsernameInputPage({Key? key, required this.controller, required this.formKey}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'What\'s Your Name?',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: controller,
                decoration: InputDecoration(
                  labelText: 'Username',
                  hintText: 'e.g., JohnDoe',
                  labelStyle: const TextStyle(color: Color(0xFF6B7280)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 1.5),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFFF73B46), width: 2),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  prefixIcon: const Icon(Icons.person_outline, color: Color(0xFF9CA3AF)),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Username cannot be empty';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              const Text(
                'This username will be displayed to others.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF6B7280)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DarkModeEnablePage extends StatelessWidget {
  final bool isDarkMode;
  final ValueChanged<bool> onToggle;

  const _DarkModeEnablePage({Key? key, required this.isDarkMode, required this.onToggle}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Choose Your Theme',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFE5E7EB), width: 1.5),
                borderRadius: BorderRadius.circular(16),
              ),
              child: SwitchListTile(
                title: const Text('Enable Dark Mode', style: TextStyle(fontWeight: FontWeight.w600)),
                value: isDarkMode,
                onChanged: onToggle,
                activeColor: const Color(0xFFF73B46),
                secondary: Icon(isDarkMode ? Icons.dark_mode : Icons.light_mode, color: isDarkMode ? const Color(0xFFF73B46) : const Color(0xFF9CA3AF)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'You can always change your theme preference later in settings.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF6B7280)),
            ),
          ],
        ),
      ),
    );
  }
}

