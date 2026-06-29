import 'package:flutter/material.dart';

abstract final class AppBreakpoints {
  static const double compact = 600;
  static const double desktop = 900;
  static const double wide = 1200;
  static const double maxContentWidth = 1440;
}

extension ResponsiveContext on BuildContext {
  double get viewportWidth => MediaQuery.sizeOf(this).width;
  bool get isCompact => viewportWidth < AppBreakpoints.compact;
  bool get isDesktop => viewportWidth >= AppBreakpoints.desktop;
  bool get isWide => viewportWidth >= AppBreakpoints.wide;

  EdgeInsets get pageInsets {
    if (isWide) return const EdgeInsets.symmetric(horizontal: 32, vertical: 24);
    if (isDesktop) {
      return const EdgeInsets.symmetric(horizontal: 24, vertical: 20);
    }
    return const EdgeInsets.symmetric(horizontal: 16, vertical: 16);
  }
}

/// Centers page content, applies consistent web gutters, and prevents desktop
/// pages from stretching controls across the entire browser window.
class ResponsiveWrapper extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry? padding;
  final bool applyDefaultPadding;

  const ResponsiveWrapper({
    super.key,
    required this.child,
    this.maxWidth = AppBreakpoints.maxContentWidth,
    this.padding,
    this.applyDefaultPadding = false,
  });

  @override
  Widget build(BuildContext context) {
    final effectivePadding =
        padding ?? (applyDefaultPadding ? context.pageInsets : EdgeInsets.zero);

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(padding: effectivePadding, child: child),
      ),
    );
  }
}

/// A grid delegate that maintains useful card widths at every browser size.
SliverGridDelegate responsiveGridDelegate(
  BuildContext context, {
  double compactExtent = 180,
  double desktopExtent = 240,
  double compactAspectRatio = 0.62,
  double desktopAspectRatio = 0.72,
  double spacing = 16,
}) {
  return SliverGridDelegateWithMaxCrossAxisExtent(
    maxCrossAxisExtent: context.isDesktop ? desktopExtent : compactExtent,
    childAspectRatio:
        context.isDesktop ? desktopAspectRatio : compactAspectRatio,
    crossAxisSpacing: spacing,
    mainAxisSpacing: spacing,
  );
}

int responsiveGridColumns(
  BuildContext context, {
  int mobileColumns = 2,
  int tabletColumns = 3,
  int desktopColumns = 4,
}) {
  final width = context.viewportWidth;
  if (width >= AppBreakpoints.wide) return desktopColumns;
  if (width >= AppBreakpoints.desktop) return tabletColumns;
  return mobileColumns;
}

double responsiveAspectRatio(
  BuildContext context, {
  double mobile = 1.1,
  double desktop = 1.4,
}) {
  return context.isDesktop ? desktop : mobile;
}
