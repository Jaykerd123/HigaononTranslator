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
    print('Wrapper: _checkOnboardingStatus started.');
    final prefs = await SharedPreferences.getInstance();
    final onboardingCompleted = prefs.getBool('onboarding_completed') ?? false;
    setState(() {
      _showOnboarding = !onboardingCompleted;
      _isLoading = false;
      print('Wrapper: _checkOnboardingStatus completed. _showOnboarding: $_showOnboarding, _isLoading: $_isLoading');
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<CustomUser?>(context);
    print('Wrapper: build method called. user: ${user?.uid}, _isLoading: $_isLoading, _showOnboarding: $_showOnboarding');

    if (_isLoading) {
      print('Wrapper: Returning CircularProgressIndicator (initial loading).');
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (user == null) {
      print('Wrapper: User is null. Returning InitialPage.');
      return const InitialPage();
    } else {
      print('Wrapper: User is logged in. Checking onboarding status from Firestore.');
      // When user is logged in, use a StreamBuilder to get real-time UserData from Firestore
      // This will ensure we get the onboardingCompleted status from the database
      return StreamBuilder<UserData?>(
        stream: DatabaseService(uid: user.uid).userData,
        builder: (BuildContext context, AsyncSnapshot<UserData?> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            print('Wrapper: StreamBuilder waiting for UserData. Showing CircularProgressIndicator.');
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          } else if (snapshot.hasData && snapshot.data != null) {
            final userData = snapshot.data!;
            print('Wrapper: UserData received. onboardingCompleted from Firestore: ${userData.onboardingCompleted}');
            if (!userData.onboardingCompleted) {
              print('Wrapper: UserData indicates onboarding NOT completed. Showing UsernameThemeScreen.');
              return const UsernameThemeScreen();
            } else {
              print('Wrapper: UserData indicates onboarding COMPLETED. Showing Home.');
              return const Home();
            }
          } else {
            // This case might happen for a brand new user who just signed up
            // and their UserData document hasn't been created in Firestore yet.
            // In this scenario, they must go through onboarding.
            print('Wrapper: No UserData found. Assuming onboarding NOT completed for new user. Showing UsernameThemeScreen.');
            return const UsernameThemeScreen();
          }
        },
      );
    }
  }
}
