abstract class TreatmentPlanDataSource {
  Future<List<Map<String, dynamic>>> procedureRows(String clinicId);
  Future<List<Map<String, dynamic>>> planRows(String patientId);
  Future<List<Map<String, dynamic>>> itemRows(String planId);
  Future<Map<String, dynamic>> invokeAction(Map<String, dynamic> request);
}
