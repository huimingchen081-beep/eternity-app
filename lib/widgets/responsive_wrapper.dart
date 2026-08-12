import 'package:flutter/material.dart';

/// Helper widget that constrains child content to a maximum width
/// and centers it on larger screens (iPad / tablets).
///
/// Usage:
///   ResponsiveWidth(maxWidth: 500, child: ...)
class ResponsiveWidth extends StatelessWidget {
  final double maxWidth;
  final Widget child;

  const ResponsiveWidth({
    super.key,
    required this.maxWidth,
    required this.child,
  });

  /// Returns true if the current screen is tablet-sized (>= 600pt wide).
  static bool isTablet(BuildContext context) {
    return MediaQuery.of(context).size.width >= 600;
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
