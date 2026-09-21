abstract interface class AuditDataSource {
  Future<Map<String, dynamic>> page(Map<String, dynamic> query);
  Future<Map<String, dynamic>> recordAccess(Map<String, dynamic> body);
}
