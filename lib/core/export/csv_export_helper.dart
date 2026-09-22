import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../app/localization/generated/app_localizations.dart';
import '../../features/appointment/domain/appointment_models.dart';
import '../../features/billing/domain/billing_models.dart';
import '../../features/patient/domain/patient_models.dart';

/// Helper to generate standard CSV data formats and export clinic records.
class CsvExportHelper {
  const CsvExportHelper._();

  static String _escape(Object? val) {
    if (val == null) return '';
    final str = val.toString();
    if (str.contains(',') || str.contains('"') || str.contains('\n') || str.contains('\r')) {
      return '"${str.replaceAll('"', '""')}"';
    }
    return str;
  }

  /// Converts a list of [patients] into CSV string format.
  static String exportPatients(List<Patient> patients) {
    final buffer = StringBuffer();
    buffer.writeln('ID,Patient Number,Full Name,Phone,Email,Birth Date,Status');

    for (final p in patients) {
      buffer.writeln([
        _escape(p.id),
        _escape(p.patientNumber),
        _escape(p.fullName),
        _escape(p.phone),
        _escape(p.email),
        _escape(p.birthDate ?? ''),
        _escape(p.isArchived ? 'Archived' : 'Active'),
      ].join(','));
    }

    return buffer.toString();
  }

  /// Converts a list of [appointments] into CSV string format.
  static String exportAppointments(List<Appointment> appointments) {
    final buffer = StringBuffer();
    buffer.writeln(
      'ID,Patient ID,Patient Number,Patient Name,Dentist,Starts At,Ends At,Duration (min),Status,Purpose',
    );

    for (final a in appointments) {
      buffer.writeln([
        _escape(a.id),
        _escape(a.patientId),
        _escape(a.patientNumber),
        _escape(a.patientName),
        _escape(a.dentistName),
        _escape(DateFormat('yyyy-MM-dd HH:mm').format(a.startsAt)),
        _escape(DateFormat('yyyy-MM-dd HH:mm').format(a.endsAt)),
        _escape(a.duration.inMinutes),
        _escape(a.status.name),
        _escape(a.purpose ?? ''),
      ].join(','));
    }

    return buffer.toString();
  }

  /// Converts a list of [invoices] into CSV string format.
  static String exportInvoices(List<BillingInvoice> invoices) {
    final buffer = StringBuffer();
    buffer.writeln(
      'Invoice ID,Invoice Number,Patient ID,Patient Name,Document Status,Payment Status,Currency,Subtotal,Tax,Discount,Total,Paid Amount,Outstanding Balance,Created At',
    );

    for (final inv in invoices) {
      buffer.writeln([
        _escape(inv.id),
        _escape(inv.invoiceNumber ?? ''),
        _escape(inv.patientId),
        _escape(inv.patientDisplayName ?? ''),
        _escape(inv.documentStatus.name),
        _escape(inv.paymentStatus.name),
        _escape(inv.currencyCode),
        _escape(inv.subtotal.toDecimalString()),
        _escape(inv.taxAmount.toDecimalString()),
        _escape(inv.discountAmount.toDecimalString()),
        _escape(inv.total.toDecimalString()),
        _escape(inv.paidAmount.toDecimalString()),
        _escape(inv.outstandingBalance.toDecimalString()),
        _escape(DateFormat('yyyy-MM-dd HH:mm').format(inv.createdAt)),
      ].join(','));
    }

    return buffer.toString();
  }

  /// Copies [csvContent] to system clipboard and displays a success SnackBar.
  static Future<void> copyToClipboard(
    BuildContext context,
    String csvContent,
  ) async {
    final l = AppLocalizations.of(context);
    await Clipboard.setData(ClipboardData(text: csvContent));
    await HapticFeedback.mediumImpact();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l.csvCopiedSuccess),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
}
