import 'package:flutter/material.dart';
import 'package:medlistapp/screens/dashboard.dart';
import 'package:medlistapp/screens/medication_list_page.dart';
import 'package:medlistapp/screens/expiry_management_page.dart';
import 'package:medlistapp/screens/settings_page.dart';
import 'package:medlistapp/utils/app_colors.dart';
import 'package:medlistapp/widgets/blue_transition_widget.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 2; // Home is active by default (matching image)
  int _previousIndex = 2;
  late AnimationController _transitionController;
  late Animation<double> _transitionAnimation;
  bool _isTransitioning = false;

  final List<Widget> _screens = [
    const SettingsPage(), // Profile (using Settings for now)
    const ExpiryManagementPage(), // Expiry
    const Dashboard(), // Home (active)
    const MedicationListPage(), // Medicine
    const SettingsPage(), // Settings
  ];

  @override
  void initState() {
    super.initState();
    _transitionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _transitionAnimation = CurvedAnimation(
      parent: _transitionController,
      curve: Curves.easeInOutCubic, // Smoother curve for more fluid animation
    );
  }

  @override
  void dispose() {
    _transitionController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    if (index != _currentIndex && !_isTransitioning) {
      setState(() {
        _isTransitioning = true;
        _previousIndex = _currentIndex;
        // Don't change screen yet - wait for transition to trigger it
      });
      
      // Listen to animation to change screen when curtain is fully down (at 0.5)
      late VoidCallback animationListener;
      animationListener = () {
        // Change screen when curtain is fully down (at 0.5) - transition triggers screen change
        if (_transitionAnimation.value >= 0.5 && _isTransitioning && _currentIndex != index) {
          if (mounted) {
            setState(() {
              _currentIndex = index;
            });
            // Remove listener after screen change
            _transitionAnimation.removeListener(animationListener);
          }
        }
      };
      _transitionAnimation.addListener(animationListener);
      
      // Start transition animation - this is the loading trigger
      _transitionController.forward().then((_) {
        if (mounted) {
          setState(() {
            _isTransitioning = false;
          });
          // Reset animation for next transition
          _transitionController.reset();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Previous screen (visible during phase 1, fades out as curtain comes down)
          if (_isTransitioning && _transitionAnimation.value < 0.4)
            Opacity(
              opacity: 1.0 - (_transitionAnimation.value / 0.4), // Fade out as curtain comes down
              child: _screens[_previousIndex],
            ),
          // New screen (fades in during loading period, fully visible when curtain goes up)
          Opacity(
            opacity: _isTransitioning
                ? (_transitionAnimation.value >= 0.5
                    ? (_transitionAnimation.value <= 0.7
                        ? ((_transitionAnimation.value - 0.5) / 0.2) // Fade in 0.5 -> 0.7 (during loading)
                        : 1.0) // Fully visible at 0.7 and beyond (when curtain goes up)
                    : 0.0)
                : 1.0,
            child: _screens[_currentIndex],
          ),
          // Blue transition overlay
          if (_isTransitioning)
            BlueTransitionWidget(
              animation: _transitionAnimation,
              showChild: false, // Don't show child, we handle screens separately
            ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.skyBlue,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(28),
            topRight: Radius.circular(28),
          ),
          border: const Border(
            top: BorderSide(
              color: AppColors.pureWhite,
              width: 2,
            ),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onTabTapped,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: AppColors.pureWhite,
          unselectedItemColor: AppColors.pureWhite.withOpacity(0.6),
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedFontSize: 12,
          unselectedFontSize: 11,
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w400,
          ),
          items: [
            BottomNavigationBarItem(
              icon: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _currentIndex == 0
                      ? AppColors.pureWhite
                      : Colors.transparent,
                  shape: BoxShape.circle,
                  border: _currentIndex == 0
                      ? Border.all(
                          color: AppColors.skyBlue,
                          width: 2,
                        )
                      : null,
                ),
                child: Icon(
                  Icons.person_outline,
                  color: _currentIndex == 0
                      ? AppColors.skyBlue
                      : AppColors.pureWhite.withOpacity(0.6),
                  size: 22,
                ),
              ),
              label: 'Profile',
            ),
            BottomNavigationBarItem(
              icon: Icon(
                Icons.calendar_today_outlined,
                color: _currentIndex == 1
                    ? AppColors.pureWhite
                    : AppColors.pureWhite.withOpacity(0.6),
                size: 22,
              ),
              label: 'Expiry',
            ),
            BottomNavigationBarItem(
              icon: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _currentIndex == 2
                      ? AppColors.pureWhite
                      : Colors.transparent,
                  shape: BoxShape.circle,
                  border: _currentIndex == 2
                      ? Border.all(
                          color: AppColors.skyBlue,
                          width: 2,
                        )
                      : null,
                ),
                child: Icon(
                  Icons.home,
                  color: _currentIndex == 2
                      ? AppColors.skyBlue
                      : AppColors.pureWhite.withOpacity(0.6),
                  size: 22,
                ),
              ),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(
                Icons.medication_outlined,
                color: _currentIndex == 3
                    ? AppColors.pureWhite
                    : AppColors.pureWhite.withOpacity(0.6),
                size: 22,
              ),
              label: 'Medicine',
            ),
            BottomNavigationBarItem(
              icon: Icon(
                Icons.settings_outlined,
                color: _currentIndex == 4
                    ? AppColors.pureWhite
                    : AppColors.pureWhite.withOpacity(0.6),
                size: 22,
              ),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}
