import '../../../core/value/money.dart';
import '../../appointment/domain/appointment_models.dart';

class DashboardCapabilities {
  const DashboardCapabilities({
    required this.canViewCompletedTreatments,
    required this.canViewFinancialSummary,
  });

  final bool canViewCompletedTreatments;
  final bool canViewFinancialSummary;
}

class DashboardPeriod {
  const DashboardPeriod({
    required this.todayStart,
    required this.tomorrowStart,
    required this.upcomingEnd,
    required this.weekStart,
    required this.weekEnd,
    required this.monthStart,
    required this.nextMonthStart,
  });

  final DateTime todayStart;
  final DateTime tomorrowStart;
  final DateTime upcomingEnd;
  final DateTime weekStart;
  final DateTime weekEnd;
  final DateTime monthStart;
  final DateTime nextMonthStart;
}

class DashboardFinancialSummary {
  const DashboardFinancialSummary({
    required this.outstandingInvoiceCount,
    required this.outstandingAmount,
    required this.currencyCode,
  });

  final int outstandingInvoiceCount;
  final Money outstandingAmount;
  final String currencyCode;
}

class DashboardMetrics {
  const DashboardMetrics({
    required this.totalPatients,
    required this.appointmentsThisWeek,
    this.completedTreatmentsThisMonth,
    this.financial,
  });

  final int totalPatients;
  final int appointmentsThisWeek;
  final int? completedTreatmentsThisMonth;
  final DashboardFinancialSummary? financial;
}

class DashboardAppointmentPreview {
  const DashboardAppointmentPreview({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.patientNumber,
    required this.dentistMemberId,
    required this.dentistLabel,
    required this.startsAt,
    required this.endsAt,
    required this.status,
  });

  final String id;
  final String patientId;
  final String patientName;
  final String patientNumber;
  final String dentistMemberId;
  final String dentistLabel;
  final DateTime startsAt;
  final DateTime endsAt;
  final AppointmentStatus status;
}

class DashboardAppointmentSection {
  const DashboardAppointmentSection({
    required this.totalCount,
    required this.hasMore,
    required this.items,
  });

  final int totalCount;
  final bool hasMore;
  final List<DashboardAppointmentPreview> items;
}

class DashboardSnapshot {
  const DashboardSnapshot({
    required this.clinicId,
    required this.clinicTimeZone,
    required this.generatedAt,
    required this.period,
    required this.capabilities,
    required this.metrics,
    required this.todayAppointments,
    required this.upcomingAppointments,
  });

  final String clinicId;
  final String clinicTimeZone;
  final DateTime generatedAt;
  final DashboardPeriod period;
  final DashboardCapabilities capabilities;
  final DashboardMetrics metrics;
  final DashboardAppointmentSection todayAppointments;
  final DashboardAppointmentSection upcomingAppointments;
}
