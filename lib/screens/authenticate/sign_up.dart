import 'package:Higa/screens/services/auth.dart';
import 'package:flutter/material.dart';
import 'package:Higa/shared/constants.dart';
import 'package:Higa/shared/loading.dart';

class SignUp extends StatefulWidget {
  const SignUp({
    super.key,
    required this.onBackPressed,
    required this.onLogInPressed,
  });

  final Function onBackPressed;
  final Function onLogInPressed;

  @override
  State<SignUp> createState() => _SignUpState();
}

class _SignUpState extends State<SignUp> {
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  bool loading = false;

  // text field state
  String fullName = '';
  String email = '';
  String password = '';
  String confirmPassword = '';
  String error = '';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return loading
        ? const LoadingSpinner()
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
                          'Create Account',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Join us to start learning Higaonon',
                          style: TextStyle(fontSize: 16, color: theme.hintColor),
                        ),
                        const SizedBox(height: 40),
                        TextFormField(
                          textCapitalization: TextCapitalization.words,
                          decoration: textInputDecoration.copyWith(
                            labelText: 'Full Name',
                            prefixIcon: const Icon(Icons.person_outline_rounded, color: Colors.grey),
                          ),
                          validator: (val) {
                            if (val == null || val.isEmpty) return 'Enter your full name';
                            if (RegExp(r'[0-9]').hasMatch(val)) return 'Name should not contain numbers';
                            return null;
                          },
                          onChanged: (val) {
                            setState(() => fullName = val);
                          },
                        ),
                        const SizedBox(height: 20),
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
                        const SizedBox(height: 20),
                        TextFormField(
                          decoration: textInputDecoration.copyWith(
                            labelText: 'Confirm Password',
                            prefixIcon: const Icon(Icons.lock_reset_rounded, color: Colors.grey),
                          ),
                          obscureText: true,
                          validator: (val) => val != password ? 'Passwords do not match' : null,
                          onChanged: (val) {
                            setState(() => confirmPassword = val);
                          },
                        ),
                        const SizedBox(height: 30),
                        ElevatedButton(
                          onPressed: () async {
                            if (_formKey.currentState!.validate()) {
                              setState(() => loading = true);
                              dynamic result = await _authService.registerWithEmailAndPassword(email, password);
                              if (result == "success") {
                                widget.onLogInPressed(); // Navigate to login
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text("Account created! Please check your email inbox to verify your account before logging in."),
                                      duration: Duration(seconds: 5),
                                    ),
                                  );
                                }
                              } else if (result is String) {
                                setState(() {
                                  error = result;
                                  loading = false;
                                });
                              } else {
                                setState(() {
                                  error = 'Please supply a valid email';
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
                            'Sign Up',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(height: 30),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text("Already have an account? ", style: TextStyle(color: theme.hintColor)),
                            GestureDetector(
                              onTap: () => widget.onLogInPressed(),
                              child: const Text(
                                'Log in',
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

