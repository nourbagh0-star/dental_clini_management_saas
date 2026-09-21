abstract class ClinicalSessionDataSource {
  Future<List<Map<String, dynamic>>> sessionRows({
    required String patientId,
    required int offset,
    required int limit,
  });

  Future<List<Map<String, dynamic>>> amendmentRows(String sessionId);

  Future<List<Map<String, dynamic>>> eligibleAppointmentRows(String patientId);

  Future<Map<String, dynamic>> invokeAction(Map<String, dynamic> request);
}
