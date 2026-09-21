import 'dashboard_models.dart';

abstract class DashboardRepository {
  Future<DashboardSnapshot> load(String clinicId);
}
