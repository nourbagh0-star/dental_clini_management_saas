abstract class PatientFileDataSource {
  Future<List<Map<String, dynamic>>> fileRows({
    required String patientId,
    required bool includeArchived,
    required String? category,
    required int offset,
    required int limit,
  });

  Future<Map<String, dynamic>> invokeAction(Map<String, dynamic> request);
}
