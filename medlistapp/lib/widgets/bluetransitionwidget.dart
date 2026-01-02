import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:medlistapp/utils/appcolors.dart';

class BlueTransitionWidget extends StatelessWidget {
  final Animation<double> animation;
  final Widget? child;
  final bool showChild;

  const BlueTransitionWidget({
    super.key,
    required this.animation,
    this.child,
    this.showChild = true,
  });

  // Smooth easing function for more natural animation
  static double _easeInOutCubic(double t) {
    return t < 0.5
        ? 4 * t * t * t
        : 1 - math.pow(-2 * t + 2, 3) / 2;
  }

  // Smooth easing for opacity transitions
  static double _easeInOutQuad(double t) {
    return t < 0.5
        ? 2 * t * t
        : 1 - math.pow(-2 * t + 2, 2) / 2;
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final animValue = animation.value;
        
        // Calculate blue background position with smooth easing (curtain effect)
        // 0.0 -> 0.4: curtain slides down (from top to bottom)
        // 0.4 -> 0.7: curtain STAYS at bottom (loading screen - waiting for screen to change)
        // 0.7 -> 1.0: curtain slides up (from bottom to top) - only after screen is ready
        double bluePosition;
        if (animValue <= 0.4) {
          // Phase 1: Curtain sliding down (0.0 -> 0.4) with smooth easing
          double normalized = animValue / 0.4; // 0.0 -> 1.0
          bluePosition = _easeInOutCubic(normalized);
        } else if (animValue <= 0.7) {
          // Phase 2: Curtain STAYS at bottom (0.4 -> 0.7) - loading screen period
          bluePosition = 1.0; // Fully down, shows loading screen
        } else {
          // Phase 3: Curtain sliding up (0.7 -> 1.0) with smooth easing - after screen is ready
          double normalized = (animValue - 0.7) / 0.3; // 0.0 -> 1.0
          bluePosition = 1.0 - _easeInOutCubic(normalized);
        }

        // Calculate logo opacity with smooth fade
        // Logo visible while curtain is at bottom (loading screen period)
        double logoOpacity = 0.0;
        if (animValue >= 0.3 && animValue <= 0.7) {
          if (animValue <= 0.4) {
            // Fading in (0.3 -> 0.4) with smooth easing
            double normalized = (animValue - 0.3) / 0.1; // 0.0 -> 1.0
            logoOpacity = _easeInOutQuad(normalized);
          } else if (animValue <= 0.65) {
            // Fully visible (0.4 -> 0.65) while curtain stays at bottom (loading)
            logoOpacity = 1.0;
          } else {
            // Fading out (0.65 -> 0.7) with smooth easing
            double normalized = (animValue - 0.65) / 0.05; // 0.0 -> 1.0
            logoOpacity = 1.0 - _easeInOutQuad(normalized);
          }
        }

        // Calculate child opacity with smooth fade
        // Start fading in at 0.3, fully visible by 0.5 (when blue is fully down)
        double childOpacity = 0.0;
        if (animValue >= 0.3) {
          if (animValue <= 0.5) {
            // Fading in during down phase (0.3 -> 0.5) with smooth easing
            double normalized = (animValue - 0.3) / 0.2; // 0.0 -> 1.0
            childOpacity = _easeInOutQuad(normalized);
          } else {
            // Fully visible during up phase (0.5 -> 1.0)
            childOpacity = 1.0;
          }
        }

        return Stack(
          children: [
            // New screen (child) - fades in during phase 2 (only if showChild is true)
            if (showChild && child != null)
              Opacity(
                opacity: childOpacity,
                child: child!,
              ),
            // Curtain effect - Blue background that slides down and up like a theater curtain
            Positioned(
              top: -screenHeight + (bluePosition * screenHeight),
              left: 0,
              right: 0,
              height: screenHeight,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.skyBlue,
                  // Add subtle gradient for curtain effect
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.skyBlue,
                      AppColors.skyBlueDark,
                    ],
                  ),
                  // Add shadow for depth
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // Curtain folds effect (subtle lines)
                    ...List.generate(5, (index) {
                      return Positioned(
                        top: (screenHeight / 5) * index,
                        left: 0,
                        right: 0,
                        height: 2,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.1),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                    // Loading screen content in center
                    Center(
                      child: Opacity(
                        opacity: logoOpacity,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // App logo/icon
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: AppColors.pureWhite.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.medication,
                                color: AppColors.pureWhite,
                                size: 48,
                              ),
                            ),
                            const SizedBox(height: 24),
                            // App name
                            Text(
                              'MedList',
                              style: TextStyle(
                                color: AppColors.pureWhite,
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 3,
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 10,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Loading indicator (visible while curtain is down)
                            if (animValue >= 0.4 && animValue <= 0.8)
                              SizedBox(
                                width: 40,
                                height: 40,
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    AppColors.pureWhite,
                                  ),
                                  strokeWidth: 3,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

