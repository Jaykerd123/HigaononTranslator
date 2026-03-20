import 'package:Higa/screens/authenticate/sign_up.dart';
import 'package:Higa/screens/authenticate/login_page.dart';
import 'package:flutter/material.dart';

class Authenticate extends StatefulWidget {
  const Authenticate({super.key});

  @override
  State<Authenticate> createState() => _AuthenticateState();
}

class _AuthenticateState extends State<Authenticate> {

  bool showSignIn = true;

  void toggleView() {
    setState(() => showSignIn = !showSignIn);
  }

  @override
  Widget build(BuildContext context) {
    if (showSignIn) {
      return LoginPage(onBackPressed: () {}, onSignUpPressed: toggleView);
    } else {
      return SignUp(onBackPressed: toggleView, onLogInPressed: toggleView);
    }
  }
}

