import 'package:flutter/material.dart';

class SimpleLoading extends StatelessWidget {
  const SimpleLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white, // A plain background
      body: Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.red), // A non-thematic color
        ),
      ),
    );
  }
}