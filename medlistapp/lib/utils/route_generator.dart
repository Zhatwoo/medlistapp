import 'package:flutter/material.dart';
import 'package:medlistapp/utils/custom_page_route.dart';

class CustomRouteGenerator {
  static Route<dynamic>? generateRoute(RouteSettings settings) {
    // Handle named routes if needed
    switch (settings.name) {
      default:
        // For now, return null to use default MaterialPageRoute
        // This will be handled by the onGenerateRoute in main.dart
        return null;
    }
  }

  static Route<T> buildRoute<T extends Object?>(
    WidgetBuilder builder, {
    RouteSettings? settings,
  }) {
    return BlueSlidePageRoute<T>(
      child: Builder(builder: builder),
    );
  }
}

// Extension to easily use custom route with Navigator
extension CustomNavigator on Navigator {
  static Future<T?> pushWithTransition<T extends Object?>(
    BuildContext context,
    WidgetBuilder builder,
  ) {
    return Navigator.of(context).push<T>(
      BlueSlidePageRoute<T>(
        child: Builder(builder: builder),
      ),
    );
  }
}

