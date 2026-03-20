
import 'package:Higa/screens/services/auth.dart';
import 'package:flutter/material.dart';
import 'package:Higa/shared/constants.dart';
import 'package:Higa/shared/simple_loading.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import FirebaseAuthException

class ForgotPasswordScreen extends StatefulWidget {
  final Function onBackPressed;

  const ForgotPasswordScreen({super.key, required this.onBackPressed});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final AuthService _auth = AuthService();
  final _formKey = GlobalKey<FormState>();
  bool loading = false;
  String email = '';
  String? _emailError; // To manage email input field specific error
  String _generalError = ''; // For general errors like network issues

  @override
  Widget build(BuildContext context) {
    return loading
        ? const SimpleLoading()
        : Scaffold(
            backgroundColor: Colors.white,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () => widget.onBackPressed(),
              ),
            ),
            body: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 40),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Text(
                        'Reset Password',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Enter your email to receive a password reset link.',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                      const SizedBox(height: 40),
                      TextFormField(
                        decoration: textInputDecoration.copyWith(
                          labelText: 'Email',
                          errorText: _emailError, // Display specific email error
                        ),
                        validator: (val) =>
                            val!.isEmpty ? 'Enter an email' : null,
                        onChanged: (val) {
                          setState(() {
                            email = val;
                            _emailError = null; // Clear error on change
                          });
                        },
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () async {
                          if (_formKey.currentState!.validate()) {
                            setState(() {
                              loading = true;
                              _generalError = ''; // Clear general errors
                              _emailError = null; // Clear email specific error
                            });

                            try {
                              // Check if the email exists
                              final List<String> signInMethods = await FirebaseAuth.instance.fetchSignInMethodsForEmail(email);

                              if (signInMethods.isEmpty) {
                                // Email not found
                                setState(() {
                                  _emailError = 'Email not found';
                                });
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Email not found.'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              } else {
                                // Email exists, send reset link
                                await _auth.sendPasswordResetEmail(email);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Password reset link sent to your email!'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                                widget.onBackPressed(); // Navigate back after showing the message
                              }
                            } on FirebaseAuthException catch (e) {
                              setState(() {
                                if (e.code == 'invalid-email') {
                                  _emailError = 'Please enter a valid email address.';
                                } else {
                                  _generalError = 'Error: ${e.message}';
                                }
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(_emailError ?? _generalError),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            } catch (e) {
                              setState(() {
                                _generalError = 'An unexpected error occurred.';
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(_generalError),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            } finally {
                              setState(() => loading = false);
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                        child: const Text('Send Reset Email'),
                      ),
                      const SizedBox(height: 12),
                      if (_generalError.isNotEmpty) // Only show general error if present
                        Text(
                          _generalError,
                          style: const TextStyle(color: Colors.red, fontSize: 14),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
  }
}

