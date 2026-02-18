import 'package:flutter/material.dart';
import 'package:fireb/screens/services/database.dart';
import 'package:provider/provider.dart';
import 'package:fireb/models/user.dart';

class AvatarSelectionScreen extends StatefulWidget {
  const AvatarSelectionScreen({super.key});

  @override
  State<AvatarSelectionScreen> createState() => _AvatarSelectionScreenState();
}

class _AvatarSelectionScreenState extends State<AvatarSelectionScreen> {
  final List<String> _avatars = [
    'assets/avatar/anby.webp',
    'assets/avatar/billy.webp',
    'assets/avatar/corin.webp',
    'assets/avatar/miyabi.webp',
    'assets/avatar/nicole.webp',
    'assets/avatar/lighter.webp',
    'assets/avatar/harumasa.webp',
    'assets/avatar/nekomata.webp',
  ];

  String? _selectedAvatar;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final userData = Provider.of<UserData?>(context);
    _selectedAvatar = userData?.avatarUrl;
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<CustomUser?>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Avatar'),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16.0),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 16.0,
          mainAxisSpacing: 16.0,
        ),
        itemCount: _avatars.length,
        itemBuilder: (context, index) {
          final avatar = _avatars[index];
          final isSelected = avatar == _selectedAvatar;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedAvatar = avatar;
              });
            },
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: isSelected
                    ? Border.all(color: Colors.blue, width: 3)
                    : null,
              ),
              child: CircleAvatar(
                radius: 40,
                backgroundImage: AssetImage(avatar),
                onBackgroundImageError: (exception, stackTrace) {
                    print('[AvatarSelectionScreen] Error loading avatar image: $exception');
                },
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          if (_selectedAvatar != null) {
            await DatabaseService(uid: user?.uid).updateUserData(
              profileImageUrl: _selectedAvatar,
            );
            Navigator.pop(context);
          }
        },
        child: const Icon(Icons.save),
      ),
    );
  }
}
