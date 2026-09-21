abstract interface class StaffDataSource {
  Future<List<Map<String, dynamic>>> getStaffMemberRows(String clinicId);

  Future<List<Map<String, dynamic>>> getInvitationRows(String clinicId);

  Future<Map<String, dynamic>> invokeStaffAction(Map<String, dynamic> request);
}
