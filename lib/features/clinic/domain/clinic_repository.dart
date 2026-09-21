import 'clinic_models.dart';

abstract interface class ClinicRepository {
  Future<List<ClinicMembership>> getMyActiveMemberships();

  Future<Clinic> createClinic({
    required String name,
    required String ownerDisplayName,
    required String currencyCode,
    required String timeZone,
  });
}
