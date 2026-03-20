import 'package:Higa/screens/authenticate/sign_up.dart';
import 'package:Higa/screens/authenticate/login_page.dart';
import 'package:flutter/material.dart';

class InitialPage extends StatefulWidget {
  const InitialPage({super.key});

  @override
  State<InitialPage> createState() => _InitialPageState();
}

class _InitialPageState extends State<InitialPage> {
  String _view = 'initial'; // 'initial', 'signin', 'register'

  void _showSignIn() {
    setState(() => _view = 'signin');
  }

  void _showRegister() {
    setState(() => _view = 'register');
  }

  void _showInitial() {
    setState(() => _view = 'initial');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    switch (_view) {
      case 'initial':
        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          body: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Image.asset('assets/app_logo/logo_black.png', height: 120),
                    ),
                    const SizedBox(height: 40),
                    const Text(
                      'Higa',
                      style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'A Higaonon Language Translator',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: theme.hintColor, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 60),
                    ElevatedButton(
                      onPressed: _showSignIn,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 56),
                        elevation: 2,
                        shadowColor: Colors.redAccent.withOpacity(0.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Login',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton(
                      onPressed: _showRegister,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: theme.textTheme.bodyLarge?.color,
                        side: BorderSide(color: theme.dividerColor, width: 2),
                        minimumSize: const Size(double.infinity, 56),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Sign Up',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      case 'signin':
        return LoginPage(
          onBackPressed: _showInitial,
          onSignUpPressed: _showRegister,
        );
      case 'register':
        return SignUp(
          onBackPressed: _showInitial,
          onLogInPressed: _showSignIn,
        );
      default:
        return Container();
    }
  }
}

