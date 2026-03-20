import 'package:Higa/screens/services/auth.dart';
import 'package:flutter/material.dart';
import 'package:Higa/shared/constants.dart';
import 'package:Higa/shared/simple_loading.dart';
import 'package:Higa/screens/authenticate/forgot_password_screen.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({
    super.key,
    required this.onBackPressed,
    required this.onSignUpPressed,
  });

  final Function onBackPressed;
  final Function onSignUpPressed;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final AuthService _auth = AuthService();
  final _formKey = GlobalKey<FormState>();
  bool loading = false;

  // text field state
  String email = '';
  String password = '';
  String error = '';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return loading
        ? const SimpleLoading()
        : Scaffold(
            backgroundColor: theme.scaffoldBackgroundColor,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_rounded, color: Colors.redAccent, size: 20),
                  onPressed: () => widget.onBackPressed(),
                ),
              ),
            ),
            body: SafeArea(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const SizedBox(height: 20),
                        const Text(
                          'Welcome Back',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Log in to continue learning Higaonon',
                          style: TextStyle(fontSize: 16, color: theme.hintColor),
                        ),
                        const SizedBox(height: 40),
                        TextFormField(
                          keyboardType: TextInputType.emailAddress,
                          decoration: textInputDecoration.copyWith(
                            labelText: 'Email',
                            prefixIcon: const Icon(Icons.email_outlined, color: Colors.grey),
                          ),
                          validator: (val) {
                            if (val == null || val.isEmpty) return 'Enter an email';
                            bool emailValid = RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+").hasMatch(val);
                            return emailValid ? null : 'Enter a valid email address';
                          },
                          onChanged: (val) {
                            setState(() => email = val);
                          },
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          decoration: textInputDecoration.copyWith(
                            labelText: 'Password',
                            prefixIcon: const Icon(Icons.lock_outline_rounded, color: Colors.grey),
                          ),
                          obscureText: true,
                          validator: (val) => val!.length < 6 ? 'Enter a password 6+ chars long' : null,
                          onChanged: (val) {
                            setState(() => password = val);
                          },
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ForgotPasswordScreen(
                                    onBackPressed: () => Navigator.pop(context),
                                  ),
                                ),
                              );
                            },
                            child: const Text(
                              'Forgot Password?',
                              style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () async {
                            if (_formKey.currentState!.validate()) {
                              setState(() => loading = true);
                              dynamic result = await _auth.signInWithEmailAndPassword(email, password);
                              if (result is String) {
                                setState(() {
                                  error = result;
                                  loading = false;
                                });
                              } else if (result == null) {
                                setState(() {
                                  error = 'Could not sign in with those credentials';
                                  loading = false;
                                });
                              }
                            }
                          },
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
                        const SizedBox(height: 30),
                        Row(
                          children: [
                            Expanded(child: Divider(color: theme.dividerColor)),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Text('OR', style: TextStyle(color: theme.hintColor, fontWeight: FontWeight.bold, fontSize: 12)),
                            ),
                            Expanded(child: Divider(color: theme.dividerColor)),
                          ],
                        ),
                        const SizedBox(height: 30),
                        OutlinedButton.icon(
                          onPressed: () async {
                            setState(() => loading = true);
                            dynamic result = await _auth.signInWithGoogle();
                            if (result == null) {
                              setState(() {
                                error = 'Could not sign in with Google';
                                loading = false;
                              });
                            }
                          },
                          icon: Image.asset('assets/social_icons/google.png', height: 24),
                          label: const Text(
                            'Continue with Google',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: theme.textTheme.bodyLarge?.color,
                            side: BorderSide(color: theme.dividerColor),
                            minimumSize: const Size(double.infinity, 56),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text("Don't have an account? ", style: TextStyle(color: theme.hintColor)),
                            GestureDetector(
                              onTap: () => widget.onSignUpPressed(),
                              child: const Text(
                                'Sign up',
                                style: TextStyle(
                                  color: Colors.redAccent,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        if (error.isNotEmpty)
                          Center(
                            child: Text(
                              error,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.red, fontSize: 14),
                            ),
                          ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
  }
}

