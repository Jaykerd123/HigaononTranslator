import 'dart:async';
import 'package:Higa/screens/wrapper.dart';
import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _logoMoved = false;
  bool _textVisible = false;

  @override
  void initState() {
    super.initState();
    _startAnimation();
  }

  void _startAnimation() async {
    // Initial pause before starting animations
    await Future.delayed(const Duration(milliseconds: 1000));
    if (!mounted) return;
    setState(() {
      _logoMoved = true;
    });
    
    // Delay before showing the greeting text
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    setState(() {
      _textVisible = true;
    });
    
    // Final pause to let the user read the text (about 2 seconds)
    await Future.delayed(const Duration(milliseconds: 2000));
    if (!mounted) return;
    
    if (context.mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (BuildContext context) => const Wrapper(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(seconds: 1),
              curve: Curves.easeInOut,
              margin: EdgeInsets.only(bottom: _logoMoved ? 100.0 : 0.0),
              child: Image.asset('assets/app_logo/logo_black.png', height: 150),
            ),
            AnimatedOpacity(
              duration: const Duration(seconds: 1),
              opacity: _textVisible ? 1.0 : 0.0,
              child: const Column(
                children: [
                  Text(
                    'GOOD DAY!',
                    style: TextStyle(fontSize: 18),
                  ),
                  Text(
                    'MAAYAD HA ADLAW',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

