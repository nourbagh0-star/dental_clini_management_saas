import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';

import '../../core/config/app_config.dart';
import 'dependencies.config.dart';

// AppConfig is validated and supplied by the composition root before init.
@InjectableInit(ignoreUnregisteredTypes: [AppConfig])
GetIt configureDependencies(GetIt container, AppConfig config) {
  container.registerSingleton<AppConfig>(config);
  return container.init();
}
