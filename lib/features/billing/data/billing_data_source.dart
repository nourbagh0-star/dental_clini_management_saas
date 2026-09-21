abstract class BillingDataSource {
  Future<List<Map<String, dynamic>>> invoiceRows({
    required String clinicId,
    String? patientId,
  });
  Future<List<Map<String, dynamic>>> itemRows(String invoiceId);
  Future<List<Map<String, dynamic>>> procedureRows(String clinicId);
  Future<List<Map<String, dynamic>>> paymentRows(String invoiceId);
  Future<Map<String, dynamic>?> creditRow(
    String patientId,
    String currencyCode,
  );
  Future<Map<String, dynamic>> invokeBilling(Map<String, dynamic> request);
  Future<Map<String, dynamic>> invokePdf(Map<String, dynamic> request);
}
