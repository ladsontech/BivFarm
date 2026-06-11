import 'package:flutter/material.dart';

/// A reusable responsive wrapper that constrains content width on desktop
/// while allowing it to fill the screen on mobile.
class ResponsiveWrapper extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry? padding;

  const ResponsiveWrapper({
    super.key,
    required this.child,
    this.maxWidth = 700,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: padding != null ? Padding(padding: padding!, child: child) : child,
      ),
    );
  }
}

/// Returns a responsive crossAxisCount for grids based on screen width.
int responsiveGridColumns(BuildContext context, {int mobileColumns = 2, int tabletColumns = 3, int desktopColumns = 4}) {
  final width = MediaQuery.of(context).size.width;
  if (width >= 1200) return desktopColumns;
  if (width >= 800) return tabletColumns;
  return mobileColumns;
}

/// Returns a responsive childAspectRatio based on screen width.
double responsiveAspectRatio(BuildContext context, {double mobile = 1.1, double desktop = 1.4}) {
  final width = MediaQuery.of(context).size.width;
  return width >= 800 ? desktop : mobile;
}
