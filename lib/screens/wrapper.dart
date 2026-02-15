import 'package:fireb/models/user.dart';
import 'package:fireb/screens/authenticate/initial_page.dart';
import 'package:fireb/screens/home/home.dart';
import 'package:fireb/screens/onboarding/username_theme_screen.dart';
import 'package:fireb/screens/services/database.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Wrapper extends StatefulWidget {
  const Wrapper({super.key});

  @override
  State<Wrapper> createState() => _WrapperState();
}

class _WrapperState extends State<Wrapper> {
  bool _showOnboarding = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkOnboardingStatus();
  }

  Future<void> _checkOnboardingStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final onboardingCompleted = prefs.getBool('onboarding_completed') ?? false;
    setState(() {
      _showOnboarding = !onboardingCompleted;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<CustomUser?>(context);

    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (user == null) {
      return const InitialPage();
    } else {
      if (_showOnboarding) {
        return const UsernameThemeScreen(avatar: '');
      } else {
        return StreamBuilder<UserData?>(
          stream: DatabaseService(uid: user.uid).userData,
          builder: (BuildContext context, AsyncSnapshot<UserData?> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            } else if (snapshot.hasData && snapshot.data != null) {
              return const Home();
            } else {
              return const Home();
            }
          },
        );
      }
    }
  }
}
