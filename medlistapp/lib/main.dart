import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:medlistapp/utils/apptheme.dart';
import 'package:medlistapp/screens/loginscreen.dart';
import 'package:medlistapp/screens/loadingscreen.dart';
import 'package:medlistapp/utils/routegenerator.dart';
import 'package:medlistapp/services/notificationservice.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase (skip on web to avoid JS interop exception bugs)
  if (!kIsWeb) {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } catch (e) {
      debugPrint('Firebase initialization error: $e');
    }
  }

  // Initialize notification service
  final notificationService = NotificationService();
  await notificationService.initialize();
  await notificationService.requestPermissions();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // On web: skip Firebase Auth (known JS interop bug). Go straight to LoadingScreen.
    // On mobile: show LoginScreen for auth.
    final home = kIsWeb ? const LoadingScreen() : LoginScreen();

    return MaterialApp(
      title: 'MedList App',
      theme: AppTheme.lightTheme,
      home: home,
      debugShowCheckedModeBanner: false,
      onGenerateRoute: (settings) {
        // Use custom route generator for all navigation
        return CustomRouteGenerator.buildRoute(
          (context) {
            // Handle named routes if needed
            switch (settings.name) {
              default:
                // For now, return empty container
                // This will be handled by Navigator.push with BlueSlidePageRoute
                return const SizedBox.shrink();
            }
          },
          settings: settings,
        );
      },
    );
  }
}
