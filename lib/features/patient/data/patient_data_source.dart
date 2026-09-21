abstract interface class PatientDataSource {
  Future<List<Map<String, dynamic>>> searchRows({
    required String clinicId,
    required String query,
    required int offset,
    required int limit,
  });

  Future<Map<String, dynamic>?> medicalProfileRow(String patientId);

  Future<Map<String, dynamic>> invokePatientAction(
    Map<String, dynamic> request,
  );
}
