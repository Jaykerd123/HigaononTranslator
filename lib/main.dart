import 'package:fireb/models/user.dart';
import 'package:fireb/screens/home/home.dart';
import 'package:fireb/screens/services/auth.dart';
import 'package:fireb/screens/services/database.dart';
import 'package:fireb/screens/services/history_service.dart';
import 'package:fireb/screens/splash/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthService>(
          create: (_) => AuthService(),
        ),
        StreamProvider<CustomUser?>(
          create: (context) => context.read<AuthService>().user,
          initialData: null,
        ),
      ],
      child: Consumer<CustomUser?>(
        builder: (context, user, _) {
          return MultiProvider(
            providers: [
              ChangeNotifierProvider<HistoryService>(
                key: ValueKey(user?.uid),
                create: (_) => HistoryService(),
              ),
              StreamProvider<UserData?>.value(
                value: user != null ? DatabaseService(uid: user.uid).userData : null,
                initialData: null,
              ),
            ],
            child: Consumer<UserData?>(
              builder: (context, userData, _) {
                final isLoggedIn = user != null;
                final isDarkMode = isLoggedIn && (userData?.isDarkMode ?? false);

                return MaterialApp(
                  title: 'fireb',
                  theme: ThemeData.light(),
                  darkTheme: ThemeData.dark(),
                  themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
                  home: const SplashScreen(),
                  routes: {
                    '/home': (context) => Home(key: ValueKey(user?.uid)),
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}
