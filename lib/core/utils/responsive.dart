import 'package:flutter/material.dart';

enum DeviceScreenType { mobile, tablet, desktop }

class Responsive {
  static const double mobileBreakpoint = 600.0;
  static const double desktopBreakpoint = 1024.0;

  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < mobileBreakpoint;

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= mobileBreakpoint && width < desktopBreakpoint;
  }

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= desktopBreakpoint;

  static DeviceScreenType getDeviceType(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < mobileBreakpoint) return DeviceScreenType.mobile;
    if (width < desktopBreakpoint) return DeviceScreenType.tablet;
    return DeviceScreenType.desktop;
  }
}

class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(BuildContext context) mobile;
  final Widget Function(BuildContext context)? tablet;
  final Widget Function(BuildContext context)? desktop;

  const ResponsiveBuilder({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= Responsive.desktopBreakpoint && desktop != null) {
      return desktop!(context);
    }
    if (width >= Responsive.mobileBreakpoint && tablet != null) {
      return tablet!(context);
    }
    return mobile(context);
  }
}
