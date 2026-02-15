import 'package:fireb/models/user.dart';
import 'package:fireb/screens/services/database.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Import SharedPreferences

class UsernameThemeScreen extends StatefulWidget {
  final String avatar;
  const UsernameThemeScreen({super.key, required this.avatar});

  @override
  State<UsernameThemeScreen> createState() => _UsernameThemeScreenState();
}

class _UsernameThemeScreenState extends State<UsernameThemeScreen> {
  final PageController _pageController = PageController();
  int _currentPageIndex = 0;
  final _usernameController = TextEditingController();
  bool _isDarkMode = false;
  late String _selectedAvatar;
  final GlobalKey<FormState> _usernameFormKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _selectedAvatar = widget.avatar;
  }

  @override
  void dispose() {
    _pageController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  void _goToNextPage() {
    if (_currentPageIndex == 1) {
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

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<CustomUser?>(context);

    List<Widget> pages = [
      _ChooseProfilePage(
        currentAvatar: _selectedAvatar,
        onAvatarSelected: (newAvatar) {
          setState(() {
            _selectedAvatar = newAvatar;
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
                    print('Finish button pressed. Current page index: $_currentPageIndex');
                    if (_currentPageIndex == pages.length - 1) {
                      if (user != null) {
                        print('User is not null. Attempting to update data and navigate.');
                        try {
                          // Update user data in Firestore using the existing updateUserData method
                          await DatabaseService(uid: user.uid).updateUserData(
                            profileImageUrl: _selectedAvatar,
                            name: _usernameController.text.trim(),
                            isDarkMode: _isDarkMode,
                            onboardingCompleted: true, // Mark onboarding as complete
                          );
                          print('Firestore data updated.');

                          // Set onboarding completed flag in SharedPreferences
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.setBool('onboarding_completed', true);
                          print('SharedPreferences updated. Navigating to home.');

                          // Navigate to home and remove all previous routes
                          Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
                          print('Navigation initiated.');
                        } catch (e) {
                          print('Error during onboarding finish: $e');
                          // Optionally, show a SnackBar or AlertDialog to the user
                        }
                      } else {
                        print('User is null. Cannot update data or navigate.');
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

class _ChooseProfilePage extends StatelessWidget {
  final String currentAvatar;
  final ValueChanged<String> onAvatarSelected;

  const _ChooseProfilePage({
    Key? key,
    required this.currentAvatar,
    required this.onAvatarSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
                onAvatarSelected('https://picsum.photos/id/${(DateTime.now().millisecond % 100).toString()}/200/300');
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