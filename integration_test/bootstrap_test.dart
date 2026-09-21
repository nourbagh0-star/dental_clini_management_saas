import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:dental_clini_management_saas/app/app.dart';
import 'package:dental_clini_management_saas/app/bootstrap/bootstrap.dart';
import 'package:dental_clini_management_saas/core/config/app_config.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('credential-free bootstrap opens the demo workspace', (
    tester,
  ) async {
    final runtime = await bootstrap(config: AppConfig.parse());
    await tester.pumpWidget(
      DentaFlowApp(appearance: runtime.appearance, router: runtime.router),
    );
    await tester.pumpAndSettle();
    expect(find.text('DentaFlow'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await runtime.dispose();
  });
}
