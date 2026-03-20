import 'package:Higa/models/user.dart';
import 'package:Higa/shared/loading.dart';
import 'package:flutter/material.dart';
import 'package:Higa/shared/constants.dart';
import 'package:provider/provider.dart';

import '../services/database.dart';

class SettingsForm extends StatefulWidget {
  const SettingsForm({super.key});

  @override
  State<SettingsForm> createState() => _SettingsFormState();
}

class _SettingsFormState extends State<SettingsForm> {
  final _formKey = GlobalKey<FormState>();

  String? _currentName;

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<CustomUser?>(context);

    if (user == null) {
      return const LoadingSpinner(); // Or some other placeholder
    }

    return StreamBuilder<UserData>(
        stream: DatabaseService(uid: user.uid).userData,
        builder: (context, asyncSnapshot) {
          if (asyncSnapshot.hasData) {
            UserData? userData = asyncSnapshot.data;
            if (userData != null) {
              return Form(
                  key: _formKey,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          const Text(
                            'Profile Settings',
                            style: TextStyle(
                                fontSize: 18.0, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 20.0),
                          TextFormField(
                            initialValue: _currentName ?? userData.name ?? '',
                            decoration:
                                textInputDecoration.copyWith(labelText: 'Name'),
                            validator: (val) =>
                                (val == null || val.isEmpty)
                                    ? 'Please enter a name'
                                    : null,
                            onChanged: (val) =>
                                setState(() => _currentName = val),
                          ),
                          const SizedBox(height: 20.0),
                          SwitchListTile(
                            title: const Text('Dark Mode'),
                            value: userData.isDarkMode ?? false,
                            onChanged: (value) async {
                              await DatabaseService(uid: user.uid)
                                  .updateUserData(isDarkMode: value);
                            },
                            secondary: const Icon(Icons.dark_mode_outlined),
                          ),
                          const SizedBox(height: 20.0),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.pink[400],
                            ),
                            child: const Text(
                              'Update',
                              style: TextStyle(color: Colors.white),
                            ),
                            onPressed: () async {
                              if (_formKey.currentState?.validate() ?? false) {
                                await DatabaseService(uid: user.uid)
                                    .updateUserData(
                                  sugar: userData.sugar ?? '0',
                                  name: _currentName ?? userData.name ?? 'new crew member',
                                  strength: userData.strength ?? 100,
                                );
                                Navigator.pop(context);
                              }
                            },
                          )
                        ]),
                  ));
            } else {
              return const LoadingSpinner();
            }
          } else {
            return const LoadingSpinner();
          }
        });
  }
}

