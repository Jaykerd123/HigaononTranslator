import 'package:fireb/models/user.dart';
import 'package:fireb/screens/authenticate/initial_page.dart';
import 'package:fireb/screens/home/home.dart';
import 'package:fireb/screens/onboarding/onboarding_flow.dart'; // Import the new OnboardingFlow
import 'package:fireb/screens/services/database.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class Wrapper extends StatelessWidget {
  const Wrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<CustomUser?>(context);

    if (user == null) {
      return const InitialPage();
    } else {
      // Listen to UserData stream for onboarding completion status
      return StreamBuilder<UserData?>(
        stream: DatabaseService(uid: user.uid).userData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          } else if (snapshot.hasData && snapshot.data != null) {
            final userData = snapshot.data!;
            if (userData.onboardingCompleted) {
              return const Home();
            } else {
              return const OnboardingFlow();
            }
          } else {
            // If there's no user data, it implies onboarding is not completed or is new user
            return const OnboardingFlow();
          }
        },
      );
    }
  }
}
