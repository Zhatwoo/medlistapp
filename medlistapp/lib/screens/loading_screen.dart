import 'dart:async';
import 'package:flutter/material.dart';
import 'package:medlistapp/services/data_initialization_service.dart';
import 'package:medlistapp/screens/main_navigation.dart';
import 'package:medlistapp/utils/app_colors.dart';

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  String _statusMessage = 'Initializing...';
  bool _canSkip = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
    // Allow skipping after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() => _canSkip = true);
      }
    });
  }

  Future<void> _initializeApp() async {
    try {
      setState(() => _statusMessage = 'Checking database...');
      
      // Check if data is already initialized
      final isInitialized = await DataInitializationService.isDataInitialized();
      
      if (!isInitialized) {
        setState(() => _statusMessage = 'Loading MOH data...\nThis may take a few minutes...');
        
        // Add timeout to prevent infinite loading
        try {
          await DataInitializationService.initializeData()
              .timeout(
                const Duration(minutes: 5),
                onTimeout: () {
                  throw TimeoutException('Data loading timed out. You can load data later from settings.');
                },
              );
          setState(() => _statusMessage = 'Data loaded successfully!');
          await Future.delayed(const Duration(seconds: 1));
        } on TimeoutException catch (e) {
          // If timeout, skip initialization and proceed
          setState(() => _statusMessage = 'Skipping data load for now...');
          await Future.delayed(const Duration(seconds: 1));
        } catch (e) {
          // If error, skip initialization and proceed
          setState(() => _statusMessage = 'Skipping data load. You can load it later from settings.');
          await Future.delayed(const Duration(seconds: 1));
        }
      } else {
        setState(() => _statusMessage = 'Loading app...');
        await Future.delayed(const Duration(milliseconds: 500));
      }

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainNavigation()),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _statusMessage = 'Error: $e\nProceeding to app...');
        await Future.delayed(const Duration(seconds: 2));
        // Still navigate to main app even if initialization fails
        // User can retry from settings
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const MainNavigation()),
          );
        }
      }
    }
  }

  void _skipLoading() {
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainNavigation()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.aliceBlue,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _statusMessage,
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
            ),
            if (_canSkip) ...[
              const SizedBox(height: 32),
              TextButton(
                onPressed: _skipLoading,
                child: const Text('Skip for now'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

