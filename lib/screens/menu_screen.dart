import 'dart:io';

import 'package:Higa/models/user.dart';
import 'package:Higa/screens/about_screen.dart';
import 'package:Higa/screens/dictionary_screen.dart';
import 'package:Higa/screens/learning_history_screen.dart';
import 'package:Higa/screens/onboarding/avatar_selection_screen.dart';
import 'package:Higa/screens/profile_screen.dart';
import 'package:Higa/screens/services/auth.dart';
import 'package:Higa/screens/services/database.dart';
import 'package:Higa/screens/settings_screen.dart';
import 'package:Higa/screens/your_progress_screen.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> with AutomaticKeepAliveClientMixin {
  XFile? _selectedImage;

  @override
  bool get wantKeepAlive => true;

  void _navigateToScreen(Widget screen) {
    // Dismiss keyboard before navigating
    FocusScope.of(context).unfocus();
    Navigator.push(context, MaterialPageRoute(builder: (context) => screen));
  }

  ImageProvider _getAvatarImage(String? avatarUrl) {
    if (_selectedImage != null) {
      return FileImage(File(_selectedImage!.path));
    }
    if (avatarUrl == null || avatarUrl.isEmpty) {
      return const AssetImage('assets/sagiri.jpg');
    }
    if (avatarUrl.startsWith('assets/')) {
      return AssetImage(avatarUrl);
    } else if (avatarUrl.startsWith('http')) {
      return NetworkImage(avatarUrl);
    } else {
      return FileImage(File(avatarUrl));
    }
  }

  void _showAvatarSelection(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (BuildContext modalContext) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Wrap(
            children: <Widget>[
              const Center(
                child: Text('Update Profile Picture', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const CircleAvatar(backgroundColor: Colors.blueAccent, child: Icon(Icons.photo_library, color: Colors.white)),
                title: const Text('Select from Gallery'),
                onTap: () async {
                  Navigator.pop(modalContext);
                  final picker = ImagePicker();
                  final XFile? image = await picker.pickImage(source: ImageSource.gallery);
                  if (image != null) {
                    setState(() => _selectedImage = image);
                  }
                },
              ),
              ListTile(
                leading: const CircleAvatar(backgroundColor: Colors.orangeAccent, child: Icon(Icons.face, color: Colors.white)),
                title: const Text('Choose Character Avatar'),
                onTap: () {
                  Navigator.pop(modalContext);
                  _navigateToScreen(const AvatarSelectionScreen());
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _saveProfilePicture() async {
    if (_selectedImage == null) return;
    final user = Provider.of<CustomUser?>(context, listen: false);
    if (user != null) {
      final dbService = DatabaseService(uid: user.uid);
      try {
        await dbService.updateUserData(profileImageUrl: _selectedImage!.path);
        setState(() => _selectedImage = null);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile picture updated!')));
      } catch (e) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final userData = Provider.of<UserData?>(context);
    final auth = Provider.of<AuthService>(context);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: Colors.redAccent,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.redAccent, Colors.orangeAccent],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    GestureDetector(
                      onTap: () => _showAvatarSelection(context),
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundColor: Colors.white,
                            child: CircleAvatar(
                              radius: 46,
                              backgroundImage: _getAvatarImage(userData?.avatarUrl),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: CircleAvatar(
                              radius: 15,
                              backgroundColor: Colors.white,
                              child: Icon(Icons.camera_alt, size: 16, color: Colors.redAccent),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      userData?.name ?? 'User',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              if (_selectedImage != null)
                IconButton(icon: const Icon(Icons.check, color: Colors.white), onPressed: _saveProfilePicture),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildMenuSection(theme, 'Learning', [
                    _MenuData(Icons.show_chart_rounded, 'Your Progress', 'Track your growth', () => _navigateToScreen(const YourProgressScreen()), Colors.blue),
                    _MenuData(Icons.book_rounded, 'Dictionary', 'All Higaonon words', () => _navigateToScreen(const DictionaryScreen()), Colors.green),
                    _MenuData(Icons.history_rounded, 'Learning History', 'Recently studied', () => _navigateToScreen(const LearningHistoryScreen()), Colors.orange),
                  ]),
                  const SizedBox(height: 24),
                  _buildMenuSection(theme, 'Settings', [
                    _MenuData(Icons.settings_rounded, 'App Settings', 'Theme and notifications', () => _navigateToScreen(const SettingsScreen()), Colors.blueGrey),
                    _MenuData(Icons.info_rounded, 'About Higa', 'App and developer info', () => _navigateToScreen(const AboutScreen()), Colors.teal),
                  ]),
                  const SizedBox(height: 40),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final bool? shouldLogout = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Logout'),
                          content: const Text('Are you sure you want to exit?'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                            TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Logout', style: TextStyle(color: Colors.red))),
                          ],
                        ),
                      );
                      if (shouldLogout == true) await auth.signOut();
                    },
                    icon: const Icon(Icons.logout_rounded),
                    label: const Text('Logout'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.withOpacity(0.1),
                      foregroundColor: Colors.red,
                      elevation: 0,
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuSection(ThemeData theme, String title, List<_MenuData> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 12),
          child: Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: theme.disabledColor)),
        ),
        Container(
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            children: items.map((item) => _buildMenuItem(item, theme, items.last == item)).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItem(_MenuData item, ThemeData theme, bool isLast) {
    return ListTile(
      onTap: item.onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: item.color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
        child: Icon(item.icon, color: item.color),
      ),
      title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(item.subtitle, style: TextStyle(fontSize: 12, color: theme.disabledColor)),
      trailing: const Icon(Icons.chevron_right_rounded, size: 20),
      shape: isLast ? null : Border(bottom: BorderSide(color: theme.dividerColor.withOpacity(0.05))),
    );
  }
}

class _MenuData {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color color;
  _MenuData(this.icon, this.title, this.subtitle, this.onTap, this.color);
}

