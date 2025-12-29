import 'package:flutter/material.dart';
import 'package:medlistapp/utils/app_theme.dart';
import 'package:medlistapp/screens/loading_screen.dart';
import 'package:medlistapp/utils/route_generator.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MedList App',
      theme: AppTheme.lightTheme,
      home: const LoadingScreen(),
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
