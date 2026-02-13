import 'package:HigaononTranslator/models/user.dart';
import 'package:HigaononTranslator/screens/services/database.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class UsernameThemeScreen extends StatefulWidget {
  final String avatar; // This will be the initially chosen avatar, perhaps from a previous screen.
  const UsernameThemeScreen({super.key, required this.avatar});

  @override
  State<UsernameThemeScreen> createState() => _UsernameThemeScreenState();
}

class _UsernameThemeScreenState extends State<UsernameThemeScreen> {
  final PageController _pageController = PageController();
  int _currentPageIndex = 0;
  final _usernameController = TextEditingController();
  bool _isDarkMode = false;
  late String _selectedAvatar; // To hold the avatar potentially selected on the first page.

  @override
  void initState() {
    super.initState();
    _selectedAvatar = widget.avatar; // Initialize with the avatar passed in.
  }

  @override
  void dispose() {
    _pageController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  void _goToNextPage() {
    if (_currentPageIndex < 2) { // Assuming 3 pages (0, 1, 2)
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

    List<Widget> pages = [
      // Page 1: Choose Profile Page
      _ChooseProfilePage(
        currentAvatar: _selectedAvatar,
        onAvatarSelected: (newAvatar) {
          setState(() {
            _selectedAvatar = newAvatar;
          });
        },
      ),
      // Page 2: Username Input Page
      _UsernameInputPage(controller: _usernameController),
      // Page 3: Dark Mode Enable Page
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
                // Spacer will push buttons to the ends if only one is present, or space them out
                // if both are present and not aligned to ends.
                // A better approach for flexible spacing could be Expanded with Spacer.
                if (_currentPageIndex > 0)
                  const SizedBox(width: 8.0), // Add some spacing between buttons
                // Only show Next/Finish button
                ElevatedButton(
                  onPressed: () async {
                    if (_currentPageIndex == pages.length - 1) {
                      // This is the last page, act as 'Finish'
                      if (user != null) {
                        await DatabaseService(uid: user.uid).updateOnboardingData(
                          _selectedAvatar, // Use _selectedAvatar
                          _usernameController.text,
                          _isDarkMode,
                        );
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

// Helper Widgets for each page
class _ChooseProfilePage extends StatelessWidget {
  final String currentAvatar;
  final ValueChanged<String> onAvatarSelected; // Callback for when an avatar is selected

  const _ChooseProfilePage({
    Key? key,
    required this.currentAvatar,
    required this.onAvatarSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Placeholder for avatar selection.
    // In a real app, this would be a grid of avatars to choose from.
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
              onTap: () {
                // Simulate selecting a new avatar
                // In a real app, this would open an image picker or avatar gallery
                onAvatarSelected('https://picsum.photos/id/${(DateTime.now().millisecond % 100).toString()}/200/300'); // Example new avatar URL
              },
              child: CircleAvatar(
                radius: 60,
                backgroundColor: Colors.grey[300],
                backgroundImage: currentAvatar.isNotEmpty && Uri.tryParse(currentAvatar)?.hasAbsolutePath == true
                    ? NetworkImage(currentAvatar) as ImageProvider<Object>?
                    : null,
                child: currentAvatar.isEmpty || Uri.tryParse(currentAvatar)?.hasAbsolutePath == false
                    ? const Icon(Icons.person, size: 60, color: Colors.grey)
                    : null,
              ),
            ),
            const SizedBox(height: 10),
            Text(currentAvatar.isNotEmpty ? 'Tap to change avatar' : 'Tap to select an avatar'),
            const SizedBox(height: 20),
            const Text(
              'Select an avatar to represent yourself. You can change this later.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class _UsernameInputPage extends StatelessWidget {
  final TextEditingController controller;

  const _UsernameInputPage({Key? key, required this.controller}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'What's Your Name?',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Username',
                hintText: 'e.g., JohnDoe',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person_outline),
              ),
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
              contentPadding: EdgeInsets.zero, // Remove default padding
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