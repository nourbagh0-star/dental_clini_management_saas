import 'package:flutter/widgets.dart';

enum AppLayoutClass { mobile, tablet, desktop }

abstract final class AppBreakpoints {
  static const mobile = 600.0;
  static const desktop = 1024.0;

  static AppLayoutClass fromWidth(double width) {
    if (width < mobile) return AppLayoutClass.mobile;
    if (width <= desktop) return AppLayoutClass.tablet;
    return AppLayoutClass.desktop;
  }

  static AppLayoutClass of(BuildContext context) =>
      fromWidth(MediaQuery.sizeOf(context).width);
}

abstract final class AppSpacing {
  static const extraSmall = 4.0;
  static const small = 8.0;
  static const compact = 12.0;
  static const medium = 16.0;
  static const large = 24.0;
  static const extraLarge = 40.0;
  static const contentWidth = 960.0;
  static const wideContentWidth = 1200.0;
  static const radius = 16.0;
}

abstract final class AppSizing {
  static const minimumTouchTarget = 48.0;
  static const controlRadius = 12.0;
  static const cardRadius = 16.0;
  static const desktopSidebarWidth = 256.0;
  static const tabletRailWidth = 80.0;
}

abstract final class AppInsets {
  static EdgeInsets page(AppLayoutClass layout) => switch (layout) {
    AppLayoutClass.mobile => const EdgeInsets.all(AppSpacing.medium),
    AppLayoutClass.tablet => const EdgeInsets.all(AppSpacing.large),
    AppLayoutClass.desktop => const EdgeInsets.symmetric(
      horizontal: AppSpacing.extraLarge,
      vertical: AppSpacing.large,
    ),
  };
}
