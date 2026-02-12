import 'package:fireb/models/user.dart';
import 'package:fireb/screens/services/database.dart';
import 'package:fireb/shared/constants.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class UsernameSetupScreen extends StatefulWidget {
  final VoidCallback onNext;

  const UsernameSetupScreen({Key? key, required this.onNext}) : super(key: key);

  @override
  _UsernameSetupScreenState createState() => _UsernameSetupScreenState();
}

class _UsernameSetupScreenState extends State<UsernameSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  String _username = '';
  bool _isButtonEnabled = false;

  @override
  void initState() {
    super.initState();
    _checkUsernameValidity(); // Initial check for button state
  }

  void _onUsernameChanged(String value) {
    setState(() {
      _username = value;
      _checkUsernameValidity();
    
    });
  }

  void _checkUsernameValidity() {
    setState(() {
      _isButtonEnabled = _username.trim().isNotEmpty;
    });
  }

  Future<void> _saveUsername() async {
    if (_formKey.currentState!.validate()) {
      final user = Provider.of<CustomUser?>(context, listen: false);
      if (user == null) return;

      await DatabaseService(uid: user.uid).updateUserData(name: _username);
      widget.onNext();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Username Setup'),
        backgroundColor: Colors.red,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildProgressIndicator(),
              const SizedBox(height: 40),
              const Text(
                'Choose your username',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                decoration: textInputDecoration.copyWith(labelText: 'Username'),
                validator: (val) =>
                    val!.isEmpty ? 'Enter a username' : null,
                onChanged: _onUsernameChanged,
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: _isButtonEnabled ? _saveUsername : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                child: const Text('Next'),
              ),
            ],
          ),
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
                color: index <= 1 ? Colors.red : Colors.grey,
                boxShadow: index <= 1
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
                color: index < 1 ? Colors.red : Colors.grey,
              ),
          ],
        );
      }),
    );
  }
}
