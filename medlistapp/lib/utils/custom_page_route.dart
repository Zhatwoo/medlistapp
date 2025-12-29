import 'package:flutter/material.dart';
import 'package:medlistapp/widgets/blue_transition_widget.dart';

class BlueSlidePageRoute<T> extends PageRouteBuilder<T> {
  final Widget child;

  BlueSlidePageRoute({required this.child})
      : super(
          transitionDuration: const Duration(milliseconds: 1800),
          reverseTransitionDuration: const Duration(milliseconds: 1800),
          pageBuilder: (context, animation, secondaryAnimation) => child,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return BlueTransitionWidget(
              animation: animation,
              child: child,
            );
          },
        );
}

