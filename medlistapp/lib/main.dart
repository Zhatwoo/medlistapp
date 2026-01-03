import 'package:flutter/material.dart';
import 'package:medlistapp/utils/apptheme.dart';
import 'package:medlistapp/screens/loginscreen.dart';
import 'package:medlistapp/utils/routegenerator.dart';
import 'package:medlistapp/services/notificationservice.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    // If Firebase initialization fails, check configuration files
    debugPrint('Firebase initialization error: $e');
    debugPrint('Please ensure google-services.json (Android) and GoogleService-Info.plist (iOS) are properly configured.');
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
    return MaterialApp(
      title: 'MedList App',
      theme: AppTheme.lightTheme,
      home: const LoginScreen(),
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
