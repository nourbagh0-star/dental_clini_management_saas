import 'package:dental_clini_management_saas/core/export/csv_export_helper.dart';
import 'package:dental_clini_management_saas/core/value/money.dart';
import 'package:dental_clini_management_saas/features/appointment/domain/appointment_models.dart';
import 'package:dental_clini_management_saas/features/billing/domain/billing_models.dart';
import 'package:dental_clini_management_saas/features/patient/domain/patient_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CsvExportHelper', () {
    test('exports patients to valid CSV with proper headers and escaping', () {
      final patients = [
        const Patient(
          id: 'p-1',
          clinicId: 'c-1',
          patientNumber: '001',
          firstName: 'John',
          lastName: 'Doe, Jr.',
          birthDatePrecision: BirthDatePrecision.exact,
          birthDate: '1990-05-15',
          isMinorDeclared: false,
          isArchived: false,
          phone: '+123456789',
          email: 'john@example.com',
        ),
      ];

      final csv = CsvExportHelper.exportPatients(patients);
      expect(
        csv,
        contains('ID,Patient Number,Full Name,Phone,Email,Birth Date,Status'),
      );
      expect(csv, contains('p-1,001,"John Doe, Jr.",+123456789,john@example.com,1990-05-15,Active'));
    });

    test('exports appointments to valid CSV', () {
      final now = DateTime(2026, 9, 22, 10, 0);
      final appointments = [
        Appointment(
          id: 'apt-1',
          clinicId: 'c-1',
          patientId: 'p-1',
          patientName: 'Jane Smith',
          patientNumber: '002',
          dentistMemberId: 'd-1',
          dentistName: 'Dr. Sarah',
          startsAt: now,
          endsAt: now.add(const Duration(minutes: 45)),
          status: AppointmentStatus.confirmed,
          purpose: 'Cleaning, Exam',
        ),
      ];

      final csv = CsvExportHelper.exportAppointments(appointments);
      expect(
        csv,
        contains('ID,Patient ID,Patient Number,Patient Name,Dentist,Starts At,Ends At,Duration (min),Status,Purpose'),
      );
      expect(csv, contains('apt-1,p-1,002,Jane Smith,Dr. Sarah'));
      expect(csv, contains('confirmed,"Cleaning, Exam"'));
    });

    test('exports invoices to valid CSV', () {
      final now = DateTime(2026, 9, 22, 11, 0);
      final invoices = [
        BillingInvoice(
          id: 'inv-1',
          clinicId: 'c-1',
          patientId: 'p-1',
          patientDisplayName: 'Jane Smith',
          invoiceNumber: 'INV-2026-001',
          documentStatus: InvoiceDocumentStatus.finalized,
          paymentStatus: InvoicePaymentStatus.paid,
          currencyCode: 'USD',
          discountType: InvoiceDiscountType.none,
          discountValue: Money.zero,
          discountAmount: Money.zero,
          taxRate: Money.zero,
          subtotal: const Money.fromMinorUnits(15000),
          taxAmount: Money.zero,
          total: const Money.fromMinorUnits(15000),
          paidAmount: const Money.fromMinorUnits(15000),
          outstandingBalance: Money.zero,
          locale: InvoiceLocale.english,
          preparedBy: 'm-1',
          revision: 1,
          financialRevision: 1,
          createdAt: now,
          updatedAt: now,
        ),
      ];

      final csv = CsvExportHelper.exportInvoices(invoices);
      expect(csv, contains('Invoice ID,Invoice Number,Patient ID,Patient Name'));
      expect(csv, contains('inv-1,INV-2026-001,p-1,Jane Smith,finalized,paid,USD,150.00,0.00,0.00,150.00,150.00,0.00'));
    });
  });
}
