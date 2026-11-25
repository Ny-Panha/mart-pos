import 'package:flutter/material.dart';

/// Professional Motion & Animation tokens for MART POS.
///
/// Follows modern micro-interaction principles (150ms-240ms duration) with
/// smooth ease-out curves and built-in reduced motion accessibility.
class PosMotion {
  // Micro durations
  static const Duration fast = Duration(milliseconds: 140);
  static const Duration normal = Duration(milliseconds: 200);
  static const Duration smooth = Duration(milliseconds: 280);
  static const Duration sheet = Duration(milliseconds: 320);

  // Easing curves
  static const Curve easeOut = Curves.easeOutCubic;
  static const Curve easeInOut = Curves.easeInOutCubic;
  static const Curve standard = Cubic(0.16, 1.0, 0.3, 1.0); // Apple-style fluid curve
  static const Curve bouncy = Curves.easeOutBack;

  /// Check whether animations should be disabled based on user preference
  static bool isReducedMotion(BuildContext context) {
    return MediaQuery.maybeDisableAnimationsOf(context) ?? false;
  }

  /// Page route transition with subtle slide and fade
  static PageRouteBuilder<T> pageRoute<T>({
    required WidgetBuilder builder,
    RouteSettings? settings,
  }) {
    return PageRouteBuilder<T>(
      settings: settings,
      transitionDuration: normal,
      reverseTransitionDuration: fast,
      pageBuilder: (context, animation, secondaryAnimation) => builder(context),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        if (isReducedMotion(context)) return child;
        final curved = CurvedAnimation(parent: animation, curve: standard);
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.03),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );
      },
    );
  }
}
