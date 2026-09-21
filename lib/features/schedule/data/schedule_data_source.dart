abstract interface class ScheduleDataSource {
  Future<List<Map<String, dynamic>>> getScheduleVersionRows(String clinicId);

  Future<List<Map<String, dynamic>>> getScheduleExceptionRows(String clinicId);

  Future<List<Map<String, dynamic>>> getManageableDentistRows(String clinicId);

  Future<Map<String, dynamic>> invokeScheduleAction(
    Map<String, dynamic> request,
  );
}
