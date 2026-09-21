abstract class OdontogramDataSource {
  Future<List<Map<String, dynamic>>> activeRows(String patientId);
  Future<List<Map<String, dynamic>>> historyRows({
    required String patientId,
    required int offset,
    required int limit,
  });
  Future<Map<String, dynamic>> invokeAction(Map<String, dynamic> request);
}
