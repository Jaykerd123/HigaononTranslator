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
      FocusScope.of(context).unfocus();
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
          _buildStepIconAndLabel(1, 'Avatar', _currentPageIndex == 0, _currentPageIndex > 0),
          _buildLine(_currentPageIndex >= 1),
          _buildStepIconAndLabel(2, 'Username', _currentPageIndex == 1, _currentPageIndex > 1),
          _buildLine(_currentPageIndex >= 2),
          _buildStepIconAndLabel(3, 'Theme', _currentPageIndex == 2, _currentPageIndex > 2),
        ],
      ),
    );
  }

  Widget _buildStepIconAndLabel(int stepNum, String title, bool isActive, bool isCompleted) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive || isCompleted ? const Color(0xFFF73B46) : const Color(0xFFE5E7EB),
          ),
          child: Center(
            child: isCompleted
                ? const Icon(Icons.check, color: Colors.white, size: 24)
                : Text(
                    '$stepNum',
                    style: TextStyle(
                      color: isActive || isCompleted ? Colors.white : const Color(0xFF6B7280),
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
            color: isActive || isCompleted ? const Color(0xFF111827) : const Color(0xFF9CA3AF),
            fontSize: 12,
            fontWeight: isActive || isCompleted ? FontWeight.bold : FontWeight.w500,
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

    // Provide the selected avatar down to the Username page
    final String? currentSelectedAvatar = _finalProfileImageUrl ?? 
        (_pickedImageFile != null ? _pickedImageFile!.path : _defaultAvatars[0]);

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
        selectedAvatar: currentSelectedAvatar,
      ),
      _DarkModeEnablePage(
        isDarkMode: _isDarkMode,
        onToggle: (value) {
          setState(() {
            _isDarkMode = value;
          });
        },
        selectedAvatar: currentSelectedAvatar,
        username: _usernameController.text,
      ),
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
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
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Row(
                children: [
                  if (_currentPageIndex > 0) ...[
                    Expanded(
                      flex: 1,
                      child: OutlinedButton(
                        onPressed: _goToPreviousPage,
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 56),
                          side: const BorderSide(color: Color(0xFFE5E7EB), width: 1.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.arrow_back, color: Colors.black87, size: 18),
                            SizedBox(width: 8),
                            Flexible(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text('Back', style: TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                  ],
                  Expanded(
                    flex: 1,
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
                        minimumSize: const Size(0, 56),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                _currentPageIndex == pages.length - 1 ? 'Get Started' : 'Continue',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(_currentPageIndex == pages.length - 1 ? Icons.check : Icons.arrow_forward, size: 18),
                        ],
                      ),
                    ),
                  ),
                ],
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
  final String? selectedAvatar;

  const _UsernameInputPage({
    Key? key, 
    required this.controller, 
    required this.formKey,
    this.selectedAvatar,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    ImageProvider<Object>? avatarImage;
    if (selectedAvatar != null) {
      if (selectedAvatar!.startsWith('assets')) {
         avatarImage = AssetImage(selectedAvatar!);
      } else {
         avatarImage = FileImage(File(selectedAvatar!));
      }
    }

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              const Center(
                child: Text(
                  'Set Your Username',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 8),
              const Center(
                child: Text(
                  'Choose a unique username for your profile',
                  style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 48),

              if (avatarImage != null)
                Center(
                  child: Container(
                    decoration: BoxDecoration(
                       shape: BoxShape.circle,
                       boxShadow: [
                         BoxShadow(
                           color: Colors.black.withOpacity(0.05),
                           blurRadius: 10,
                           spreadRadius: 2,
                         )
                       ]
                    ),
                    child: CircleAvatar(
                      radius: 46,
                      backgroundColor: Colors.white,
                      child: CircleAvatar(
                        radius: 44,
                        backgroundImage: avatarImage,
                        backgroundColor: Colors.transparent,
                      ),
                    ),
                  ),
                ),
              
              const SizedBox(height: 48),
              
              const Text(
                'Username',
                style: TextStyle(color: Color(0xFF111827), fontWeight: FontWeight.w600, fontSize: 14),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: 'michael',
                  hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
                  prefixText: '@  ',
                  prefixStyle: const TextStyle(color: Color(0xFF6B7280), fontSize: 16),
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
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
                'Only lowercase letters, numbers, and underscores',
                style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
              ),
              const SizedBox(height: 24),
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
  final String? selectedAvatar;
  final String username;

  const _DarkModeEnablePage({
    Key? key,
    required this.isDarkMode,
    required this.onToggle,
    this.selectedAvatar,
    required this.username,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    ImageProvider<Object>? avatarImage;
    if (selectedAvatar != null) {
      if (selectedAvatar!.startsWith('assets')) {
         avatarImage = AssetImage(selectedAvatar!);
      } else {
         avatarImage = FileImage(File(selectedAvatar!));
      }
    }

    final displayName = username.isNotEmpty ? username[0].toUpperCase() + username.substring(1) : 'User';

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          children: [
            const SizedBox(height: 16),
            const Center(
              child: Text(
                'Choose Your Theme',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 8),
            const Center(
              child: Text(
                'Select your preferred app appearance',
                style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 32),
            
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => onToggle(false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(
                          color: !isDarkMode ? const Color(0xFFF73B46) : const Color(0xFFE5E7EB),
                          width: !isDarkMode ? 3 : 1.5,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.center,
                        children: [
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: Colors.grey[50],
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.wb_sunny_outlined, color: Colors.amber, size: 28),
                              ),
                              const SizedBox(height: 16),
                              const Text('Light Mode', style: TextStyle(color: Color(0xFF111827), fontWeight: FontWeight.w600, fontSize: 16)),
                            ],
                          ),
                          if (!isDarkMode)
                            const Positioned(
                              top: -12,
                              right: 12,
                              child: CircleAvatar(
                                radius: 12,
                                backgroundColor: Color(0xFFF73B46),
                                child: Icon(Icons.check, color: Colors.white, size: 16),
                              ),
                            )
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: GestureDetector(
                    onTap: () => onToggle(true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      decoration: BoxDecoration(
                        color: const Color(0xFF111827),
                        border: Border.all(
                          color: isDarkMode ? const Color(0xFFF73B46) : Colors.transparent,
                          width: isDarkMode ? 3 : 1.5,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.center,
                        children: [
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 56,
                                height: 56,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF1F2937),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.nightlight_round, color: Colors.lightBlueAccent, size: 26),
                              ),
                              const SizedBox(height: 16),
                              const Text('Dark Mode', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16)),
                            ],
                          ),
                          if (isDarkMode)
                            const Positioned(
                              top: -12,
                              right: 12,
                              child: CircleAvatar(
                                radius: 12,
                                backgroundColor: Color(0xFFF73B46),
                                child: Icon(Icons.check, color: Colors.white, size: 16),
                              ),
                            )
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 32),
            
            Container(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.white,
                    child: avatarImage != null 
                        ? CircleAvatar(radius: 26, backgroundImage: avatarImage, backgroundColor: Colors.transparent)
                        : const Icon(Icons.person, color: Color(0xFF9CA3AF), size: 30),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          style: const TextStyle(color: Color(0xFF111827), fontWeight: FontWeight.w600, fontSize: 16),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '@${username.toLowerCase()}',
                          style: const TextStyle(color: Color(0xFF4B5563), fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

