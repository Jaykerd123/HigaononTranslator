
import 'dart:io';

import 'package:fireb/models/user.dart';
import 'package:fireb/screens/about_screen.dart';
import 'package:fireb/screens/dictionary_screen.dart';
import 'package:fireb/screens/learning_history_screen.dart';
import 'package:fireb/screens/profile_screen.dart';
import 'package:fireb/screens/services/auth.dart';
import 'package:fireb/screens/services/database.dart';
import 'package:fireb/screens/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  ImageProvider _getAvatarImage(String? avatarUrl) {
    if (avatarUrl == null || avatarUrl.isEmpty) {
      return const AssetImage('assets/sagiri.jpg'); // Default avatar
    }
    if (avatarUrl.startsWith('assets/')) {
      return AssetImage(avatarUrl);
    } else {
      return FileImage(File(avatarUrl));
    }
  }

  @override
  Widget build(BuildContext context) {
    final userData = Provider.of<UserData?>(context);
    final auth = Provider.of<AuthService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Menu'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              // User Container
              CircleAvatar(
                radius: 50,
                backgroundImage: _getAvatarImage(userData?.avatarUrl),
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
