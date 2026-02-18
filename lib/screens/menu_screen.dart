import 'dart:io';

import 'package:fireb/models/user.dart';
import 'package:fireb/screens/about_screen.dart';
import 'package:fireb/screens/dictionary_screen.dart';
import 'package:fireb/screens/learning_history_screen.dart';
import 'package:fireb/screens/onboarding/avatar_selection_screen.dart';
import 'package:fireb/screens/profile_screen.dart';
import 'package:fireb/screens/services/auth.dart';
import 'package:fireb/screens/services/database.dart';
import 'package:fireb/screens/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  XFile? _selectedImage;

  ImageProvider _getAvatarImage(String? avatarUrl) {
    print('[MenuScreen] _getAvatarImage called with avatarUrl: $avatarUrl');
    if (_selectedImage != null) {
      return FileImage(File(_selectedImage!.path));
    }
    if (avatarUrl == null || avatarUrl.isEmpty) {
      print('[MenuScreen] No avatarUrl, using default avatar.');
      return const AssetImage('assets/sagiri.jpg'); // Default avatar
    }
    if (avatarUrl.startsWith('assets/')) {
       print('[MenuScreen] avatarUrl is an asset, using AssetImage');
      return AssetImage(avatarUrl);
    } else if (avatarUrl.startsWith('http')) {
      print('[MenuScreen] avatarUrl is a network image, using NetworkImage');
      return NetworkImage(avatarUrl);
    } else {
      print('[MenuScreen] avatarUrl is a file path, using FileImage');
      return FileImage(File(avatarUrl));
    }
  }

  void _showAvatarSelection(BuildContext context) {
    print('[MenuScreen] _showAvatarSelection called');
    final user = Provider.of<CustomUser?>(context, listen: false);

    showModalBottomSheet(
      context: context,
      builder: (BuildContext modalContext) {
        return Wrap(
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Select Profile Picture'),
              onTap: () async {
                print('[MenuScreen] Select Profile Picture tapped');
                Navigator.pop(modalContext);
                final picker = ImagePicker();
                final XFile? image = await picker.pickImage(source: ImageSource.gallery);
                if (image != null) {
                  print('[MenuScreen] Image selected from gallery: ${image.path}');
                  setState(() {
                    _selectedImage = image;
                  });
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.face),
              title: const Text('Change Avatar'),
              onTap: () {
                print('[MenuScreen] Change Avatar tapped');
                Navigator.pop(modalContext);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AvatarSelectionScreen()),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveProfilePicture() async {
    print('[MenuScreen] _saveProfilePicture (local path method) called');
    if (_selectedImage == null) {
      print('[MenuScreen] No image selected, aborting save.');
      return;
    }

    final user = Provider.of<CustomUser?>(context, listen: false);
    if (user != null) {
      final localPath = _selectedImage!.path;
      print('[MenuScreen] User found, saving local image path to Firestore: $localPath');
      final dbService = DatabaseService(uid: user.uid);
      try {
        await dbService.updateUserData(
          profileImageUrl: localPath,
        );
        print('[MenuScreen] User data updated successfully with local path.');
        setState(() {
          _selectedImage = null;
        });
        print('[MenuScreen] Selected image reset.');
      } catch (e) {
        print('[MenuScreen] Failed to update user data with local path: $e');
      }
    } else {
      print('[MenuScreen] User not found, cannot save profile picture.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final userData = Provider.of<UserData?>(context);
    final auth = Provider.of<AuthService>(context);
    print('[MenuScreen] build called. UserData avatarUrl: ${userData?.avatarUrl}');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Menu'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          if (_selectedImage != null)
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveProfilePicture,
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              // User Container
              GestureDetector(
                onTap: () => _showAvatarSelection(context),
                child: CircleAvatar(
                  radius: 50,
                  backgroundImage: _getAvatarImage(userData?.avatarUrl),
                  onBackgroundImageError: (exception, stackTrace) {
                    print('[MenuScreen] Error loading avatar image: $exception');
                  },
                ),
              ),
              const SizedBox(height: 12),
              Text(
                userData?.name ?? 'User',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              TextButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ProfileScreen()),
                  );
                },
                icon: const Icon(Icons.person_outline, size: 18),
                label: const Text(
                  'Profile',
                  style: TextStyle(fontSize: 14),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).textTheme.bodySmall?.color,
                ),
              ),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 10),

              // Menu Items
              _buildMenuListItem(
                context: context,
                icon: Icons.show_chart,
                title: 'Track Your Progress',
                subtitle: 'Track your learning',
                onTap: () {
                  // TODO: Implement navigation
                },
              ),
              _buildMenuListItem(
                context: context,
                icon: Icons.book_outlined,
                title: 'Dictionary',
                subtitle: 'Browse all words',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const DictionaryScreen()),
                  );
                },
              ),
              _buildMenuListItem(
                context: context,
                icon: Icons.history,
                title: 'Learning History',
                subtitle: 'View studied words',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const LearningHistoryScreen()),
                  );
                },
              ),
              _buildMenuListItem(
                context: context,
                icon: Icons.settings_outlined,
                title: 'Settings',
                subtitle: 'App preferences',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SettingsScreen()),
                  );
                },
              ),
              _buildMenuListItem(
                context: context,
                icon: Icons.info_outline,
                title: 'About',
                subtitle: 'App information',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AboutScreen()),
                  );
                },
              ),

              const SizedBox(height: 24),

              // Logout Button
              Center(
                child: TextButton.icon(
                  onPressed: () async {
                    final bool? shouldLogout = await showDialog<bool>(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: const Text('Confirm Logout'),
                          content:
                              const Text('Are you sure you want to log out?'),
                          actions: <Widget>[
                            TextButton(
                              child: const Text('Cancel'),
                              onPressed: () {
                                Navigator.of(context).pop(false);
                              },
                            ),
                            TextButton(
                              child: const Text('Logout'),
                              onPressed: () {
                                Navigator.of(context).pop(true);
                              },
                            ),
                          ],
                        );
                      },
                    );

                    if (shouldLogout == true) {
                      await auth.signOut();
                    }
                  },
                  icon: const Icon(Icons.logout, color: Colors.red),
                  label: const Text(
                    'Logout',
                    style: TextStyle(color: Colors.red),
                  ),
                  style: TextButton.styleFrom(
                      backgroundColor: Colors.red.withOpacity(0.1),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 40, vertical: 12)),
                ),
              ),
              const SizedBox(height: 20),
               const Column(
                children: [
                  Text(
                    'Higa - Language Learning Platform',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Version 1.0.0',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuListItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
        ),
      ),
      onTap: onTap,
    );
  }
}
