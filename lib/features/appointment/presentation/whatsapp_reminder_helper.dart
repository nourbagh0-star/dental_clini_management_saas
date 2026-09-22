import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../../app/localization/generated/app_localizations.dart';
import '../../../core/utils/communication_launcher.dart';
import '../../clinic/domain/clinic_models.dart';
import '../../clinic/presentation/clinic_cubit.dart';
import '../../patient/domain/patient_models.dart';
import '../../patient/presentation/patient_cubit.dart';

/// Helper to trigger 1-Tap WhatsApp appointment reminders with clinic branding.
class WhatsAppReminderHelper {
  const WhatsAppReminderHelper._();

  /// Formats and launches WhatsApp message for [patientId] regarding an appointment at [startsAt].
  static Future<bool> sendReminder({
    required BuildContext context,
    required String patientId,
    required String patientName,
    required String dentistName,
    required DateTime startsAt,
    required String clinicId,
    tz.Location? location,
  }) async {
    final l = AppLocalizations.of(context);

    // Resolve patient phone number
    PatientCubit? patientCubit;
    try {
      patientCubit = context.read<PatientCubit>();
    } catch (_) {
      patientCubit = null;
    }

    final patient = patientCubit?.state.patients
        .where((Patient p) => p.id == patientId)
        .firstOrNull;

    final phone = patient?.phone;
    if (phone == null || phone.trim().isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l.noPhoneForPatient),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return false;
    }

    // Resolve clinic name
    final clinic = context
        .read<ClinicCubit>()
        .state
        .memberships
        .where((ClinicMembership m) => m.clinic.id == clinicId)
        .firstOrNull
        ?.clinic;

    final clinicName = (clinic != null && clinic.name.trim().isNotEmpty)
        ? clinic.name
        : l.clinicSectionTitle;

    final locale = Localizations.localeOf(context).toLanguageTag();
    final effectiveLocation = location ?? tz.local;
    final localStart = tz.TZDateTime.from(startsAt, effectiveLocation);
    final dateStr = DateFormat.yMMMMEEEEd(locale).format(localStart);
    final timeStr = DateFormat.jm(locale).format(localStart);

    final message = l.reminderMessageTemplate(
      patientName,
      clinicName,
      dentistName,
      dateStr,
      timeStr,
    );

    final success = await CommunicationLauncher.launchWhatsApp(
      phone: phone,
      message: message,
    );

    if (!success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l.communicationLaunchFailed),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
    return success;
  }
}
