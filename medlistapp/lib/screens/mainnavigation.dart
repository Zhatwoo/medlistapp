import 'package:flutter/material.dart';
import 'package:medlistapp/models/userrole.dart';
import 'package:medlistapp/screens/dashboard.dart';
import 'package:medlistapp/screens/medicationlistpage.dart';
import 'package:medlistapp/screens/expirymanagementpage.dart';
import 'package:medlistapp/screens/settingspage.dart';
import 'package:medlistapp/screens/profilesettingspage.dart';
import 'package:medlistapp/services/authservice.dart';
import 'package:medlistapp/services/backgroundnotificationservice.dart';
import 'package:medlistapp/utils/appcolors.dart';
import 'package:medlistapp/widgets/bluetransitionwidget.dart';

class _NavItem {
  final String label;
  final IconData icon;
  final Widget screen;
  final bool iconCircle;
  final List<UserRole> roles;

  _NavItem(this.label, this.icon, this.screen,
      {this.iconCircle = false, this.roles = const []});
}

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
  UserRole _role = UserRole.pharmacist;
  final AuthService _authService = AuthService();

  List<_NavItem> get _allItems => [
        _NavItem('Profile', Icons.person_outline, const ProfileSettingsPage(),
            iconCircle: true),
        _NavItem('Alerts', Icons.notifications_active_outlined,
            const ExpiryManagementPage(),
            roles: [UserRole.pharmacist, UserRole.inventoryManager, UserRole.admin]),
        _NavItem('Home', Icons.home, const Dashboard(), iconCircle: true),
        _NavItem('Medicine', Icons.medication_outlined, const MedicationListPage()),
        _NavItem('Settings', Icons.settings_outlined, const SettingsPage()),
      ];

  List<_NavItem> get _visibleItems =>
      _allItems.where((i) => i.roles.isEmpty || i.roles.contains(_role)).toList();

  List<Widget> get _screens => _visibleItems.map((i) => i.screen).toList();

  @override
  void initState() {
    super.initState();
    _loadRole();
    _runDailyChecks();
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

  Future<void> _runDailyChecks() async {
    try {
      await BackgroundNotificationService().runDailyChecks();
    } catch (_) {}
  }

  Future<void> _loadRole() async {
    final role = await _authService.getUserRole();
    if (!mounted) return;
    setState(() {
      _role = role;
      final len = _visibleItems.length;
      if (_currentIndex >= len) _currentIndex = len > 0 ? len - 1 : 0;
    });
  }

  BottomNavigationBarItem _buildNavItem(int index, _NavItem item) {
    final selected = _currentIndex == index;
    final color = selected ? AppColors.pureWhite : AppColors.pureWhite.withOpacity(0.6);
    final iconColor = item.iconCircle && selected ? AppColors.skyBlue : color;
    Widget iconWidget;
    if (item.iconCircle) {
      iconWidget = Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: selected ? AppColors.pureWhite : Colors.transparent,
          shape: BoxShape.circle,
          border: selected ? Border.all(color: AppColors.skyBlue, width: 2) : null,
        ),
        child: Icon(item.icon, color: iconColor, size: 22),
      );
    } else {
      iconWidget = Icon(item.icon, color: color, size: 22);
    }
    return BottomNavigationBarItem(icon: iconWidget, label: item.label);
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
            for (int i = 0; i < _visibleItems.length; i++)
              _buildNavItem(i, _visibleItems[i]),
          ],
        ),
      ),
    );
  }
}
