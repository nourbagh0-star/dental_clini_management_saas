abstract interface class AppointmentDataSource {
  Future<List<Map<String, dynamic>>> listRows({
    required String clinicId,
    required DateTime from,
    required DateTime until,
  });
  Future<Map<String, dynamic>> invokeAction(Map<String, dynamic> request);
}
