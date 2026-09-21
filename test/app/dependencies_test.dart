import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:dental_clini_management_saas/app/bootstrap/dependencies.dart';
import 'package:dental_clini_management_saas/app/theme/appearance_cubit.dart';
import 'package:dental_clini_management_saas/core/config/app_config.dart';
import 'package:dental_clini_management_saas/core/network/dio_client.dart';
import 'package:dental_clini_management_saas/core/network/session_token_provider.dart';
import 'package:dental_clini_management_saas/core/storage/preferences_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'generated graph resolves lazily without credentials or network',
    () async {
      final container = configureDependencies(
        GetIt.asNewInstance(),
        AppConfig.parse(),
      );
      addTearDown(container.reset);
      expect(container<PreferencesStore>(), isA<PreferencesStore>());
      expect(container<SessionTokenProvider>().accessToken, isNull);
      expect(container<DioClient>(), same(container<DioClient>()));
      final cubit = container<AppearanceCubit>();
      expect(cubit.state.storageFailed, isFalse);
      await cubit.close();
    },
  );
}
