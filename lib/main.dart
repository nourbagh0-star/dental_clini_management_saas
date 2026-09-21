import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'app/app.dart';
import 'app/bootstrap/bootstrap.dart';
import 'app/bootstrap/startup_error_app.dart';
import 'core/config/app_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Never log arbitrary framework errors containing form values or tokens.
  FlutterError.onError = (details) {
    debugPrint('Flutter framework error: ${details.exceptionAsString()}');
    if (kDebugMode) debugPrintStack(stackTrace: details.stack);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('Unhandled application error.');
    return true;
  };
  await _start();
}

Future<void> _start() async {
  try {
    final runtime = await bootstrap();
    runApp(
      DentaFlowApp(
        appearance: runtime.appearance,
        router: runtime.router,
        auth: runtime.auth,
        clinic: runtime.clinic,
        staff: runtime.staff,
        schedule: runtime.schedule,
        patient: runtime.patient,
        patientMedical: runtime.patientMedical,
        appointment: runtime.appointment,
        odontogram: runtime.odontogram,
        treatmentPlan: runtime.treatmentPlan,
        clinicalSession: runtime.clinicalSession,
        patientFile: runtime.patientFile,
        billing: runtime.billing,
        dashboard: runtime.dashboard,
        audit: runtime.audit,
        auditAccess: runtime.auditAccess,
      ),
    );
  } on Object catch (error) {
    runApp(
      StartupErrorApp(
        configurationError: error is ConfigurationException,
        onRetry: () => unawaited(_start()),
      ),
    );
  }
}
