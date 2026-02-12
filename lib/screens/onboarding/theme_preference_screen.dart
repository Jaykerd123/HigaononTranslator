import 'package:fireb/models/user.dart';
import 'package:fireb/screens/services/database.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemePreferenceScreen extends StatefulWidget {
  final VoidCallback onNext;

  const ThemePreferenceScreen({Key? key, required this.onNext}) : super(key: key);

  @override
  _ThemePreferenceScreenState createState() => _ThemePreferenceScreenState();
}

class _ThemePreferenceScreenState extends State<ThemePreferenceScreen> {
  bool _isDarkModeEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadThemePreference();
  }

  Future<void> _loadThemePreference() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkModeEnabled = prefs.getBool('isDarkModeEnabled') ?? false;
    });
  }

  Future<void> _saveThemePreference(bool value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkModeEnabled', value);
    setState(() {
      _isDarkModeEnabled = value;
    });

    // Update Firestore with theme preference and mark onboarding as complete
    final user = Provider.of<CustomUser?>(context, listen: false);
    if (user == null) return;

    await DatabaseService(uid: user.uid)
        .updateUserData(isDarkMode: value, onboardingCompleted: true);

    // Immediately proceed to next step/complete onboarding after selection
    widget.onNext();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Theme Preference'),
        backgroundColor: Colors.red,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildProgressIndicator(),
            const SizedBox(height: 40),
            const Text(
              'Choose your theme preference',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            SwitchListTile(
              title: const Text('Enable Dark Mode'),
              value: _isDarkModeEnabled,
              onChanged: _saveThemePreference,
              activeColor: Colors.red,
            ),
            const Spacer(),
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
                color: index <= 2 ? Colors.red : Colors.grey,
                boxShadow: index <= 2
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
                color: index < 2 ? Colors.red : Colors.grey,
              ),
          ],
        );
      }),
    );
  }
}
