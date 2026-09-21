import 'package:injectable/injectable.dart';

import '../domain/clinic_models.dart';
import '../domain/clinic_repository.dart';
import 'supabase_clinic_data_source.dart';

@LazySingleton(as: ClinicRepository)
class SupabaseClinicRepository implements ClinicRepository {
  SupabaseClinicRepository(this._source);
  final SupabaseClinicDataSource _source;

  @override
  Future<List<ClinicMembership>> getMyActiveMemberships() async {
    final memberships = await _source.getMyActiveMembershipRows();
    final clinics = await _source.getClinicsByIds(
      memberships.map((row) => row['clinic_id'] as String).toList(),
    );
    final roles = await _source.getRolesForMembershipIds(
      memberships.map((row) => row['id'] as String).toList(),
    );
    final clinicsById = {
      for (final row in clinics) (row['id'] as String): _clinicFromRow(row),
    };
    final rolesByMembershipId = <String, Set<String>>{};
    for (final row in roles) {
      final membershipId = row['clinic_member_id'] as String;
      rolesByMembershipId
          .putIfAbsent(membershipId, () => <String>{})
          .add(row['role'] as String);
    }
    return memberships
        .map(
          (row) => ClinicMembership(
            clinic: clinicsById[row['clinic_id'] as String]!,
            memberId: row['id'] as String,
            roles: Set.unmodifiable(
              rolesByMembershipId[row['id'] as String] ?? const <String>{},
            ),
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<Clinic> createClinic({
    required String name,
    required String ownerDisplayName,
    required String currencyCode,
    required String timeZone,
  }) => _source
      .createClinic(
        name: name,
        ownerDisplayName: ownerDisplayName,
        currencyCode: currencyCode,
        timeZone: timeZone,
      )
      .then(_clinicFromRow);

  Clinic _clinicFromRow(Map<String, dynamic> row) => Clinic(
    id: row['id'] as String,
    name: row['name'] as String,
    currencyCode: row['currency_code'] as String,
    timeZone: row['time_zone'] as String,
  );
}
