import 'package:dental_clini_management_saas/app/theme/app_theme.dart';
import 'package:dental_clini_management_saas/core/widgets/responsive_record_view.dart';
import 'package:dental_clini_management_saas/core/widgets/responsive_state_panel.dart';
import 'package:dental_clini_management_saas/core/widgets/workspace_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('breakpoints use the approved boundary values', () {
    expect(AppBreakpoints.fromWidth(599), AppLayoutClass.mobile);
    expect(AppBreakpoints.fromWidth(600), AppLayoutClass.tablet);
    expect(AppBreakpoints.fromWidth(1024), AppLayoutClass.tablet);
    expect(AppBreakpoints.fromWidth(1025), AppLayoutClass.desktop);
  });

  testWidgets('record view switches at its local available width', (
    tester,
  ) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: SizedBox(
            width: 400,
            child: ResponsiveRecordView(
              compact: Text('compact'),
              expanded: Text('expanded'),
            ),
          ),
        ),
      ),
    );
    expect(find.text('compact'), findsOneWidget);

    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: SizedBox(
            width: 600,
            child: ResponsiveRecordView(
              compact: Text('compact'),
              expanded: Text('expanded'),
            ),
          ),
        ),
      ),
    );
    expect(find.text('expanded'), findsOneWidget);
  });

  testWidgets('shared page and state panel fit a narrow RTL large-text view', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 760);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Directionality(
          textDirection: TextDirection.rtl,
          child: WorkspacePage(
            title: Text('الحالة'),
            scrollable: true,
            child: ResponsiveStatePanel(
              title: 'لا توجد سجلات',
              message: 'يمكنك إنشاء السجل الأول عندما تكون جاهزًا.',
              actionLabel: 'إنشاء سجل',
              onAction: _noop,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(
      Directionality.of(tester.element(find.byType(ResponsiveStatePanel))),
      TextDirection.rtl,
    );
    expect(
      tester.getSize(find.byType(FilledButton)).height,
      greaterThanOrEqualTo(AppSizing.minimumTouchTarget),
    );
  });
}

void _noop() {}
