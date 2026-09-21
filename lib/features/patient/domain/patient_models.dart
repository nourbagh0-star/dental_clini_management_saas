enum BirthDatePrecision {
  exact,
  approximate,
  unknown;

  String get apiValue => name;
  static BirthDatePrecision? fromApi(Object? value) => switch (value) {
    'exact' => BirthDatePrecision.exact,
    'approximate' => BirthDatePrecision.approximate,
    'unknown' => BirthDatePrecision.unknown,
    _ => null,
  };
}

class Patient {
  const Patient({
    required this.id,
    required this.clinicId,
    required this.patientNumber,
    required this.firstName,
    required this.lastName,
    required this.birthDatePrecision,
    required this.isMinorDeclared,
    required this.isArchived,
    this.middleName,
    this.phone,
    this.email,
    this.birthDate,
    this.approximateAgeYears,
    this.ageAssessedAt,
    this.guardianName,
    this.guardianPhone,
    this.guardianEmail,
    this.administrativeNotes,
  });

  final String id;
  final String clinicId;
  final String patientNumber;
  final String firstName;
  final String lastName;
  final BirthDatePrecision birthDatePrecision;
  final bool isMinorDeclared;
  final bool isArchived;
  final String? middleName;
  final String? phone;
  final String? email;
  final String? birthDate;
  final int? approximateAgeYears;
  final String? ageAssessedAt;
  final String? guardianName;
  final String? guardianPhone;
  final String? guardianEmail;
  final String? administrativeNotes;

  String get fullName => [
    firstName,
    middleName,
    lastName,
  ].whereType<String>().where((part) => part.isNotEmpty).join(' ');
}

class PatientMedicalProfile {
  const PatientMedicalProfile({
    this.allergies,
    this.currentMedications,
    this.chronicConditions,
    this.importantMedicalNotes,
  });

  final String? allergies;
  final String? currentMedications;
  final String? chronicConditions;
  final String? importantMedicalNotes;

  bool get hasAlerts =>
      (allergies?.trim().isNotEmpty ?? false) ||
      (chronicConditions?.trim().isNotEmpty ?? false) ||
      (importantMedicalNotes?.trim().isNotEmpty ?? false);

  bool get isEmpty =>
      (allergies?.trim().isEmpty ?? true) &&
      (currentMedications?.trim().isEmpty ?? true) &&
      (chronicConditions?.trim().isEmpty ?? true) &&
      (importantMedicalNotes?.trim().isEmpty ?? true);

  bool get isNotEmpty => !isEmpty;
}

class PatientDraft {
  const PatientDraft({
    required this.firstName,
    required this.lastName,
    required this.birthDatePrecision,
    this.middleName,
    this.phone,
    this.email,
    this.birthDate,
    this.approximateAgeYears,
    this.ageAssessedAt,
    this.isMinorDeclared = false,
    this.guardianName,
    this.guardianPhone,
    this.guardianEmail,
    this.administrativeNotes,
  });

  final String firstName;
  final String lastName;
  final BirthDatePrecision birthDatePrecision;
  final String? middleName;
  final String? phone;
  final String? email;
  final String? birthDate;
  final int? approximateAgeYears;
  final String? ageAssessedAt;
  final bool isMinorDeclared;
  final String? guardianName;
  final String? guardianPhone;
  final String? guardianEmail;
  final String? administrativeNotes;
}

enum PatientOperationIssue { invalidInput, forbidden, unavailable }

class PatientOperationException implements Exception {
  const PatientOperationException(this.issue);
  final PatientOperationIssue issue;
}
