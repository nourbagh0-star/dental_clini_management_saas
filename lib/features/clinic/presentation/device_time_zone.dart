import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:injectable/injectable.dart';

/// Reads the operating system's IANA time-zone identifier, such as
/// `Europe/Moscow`. The form remains editable because a clinic can operate in
/// a different zone from the device used during setup.
abstract interface class DeviceTimeZone {
  Future<String> current();
}

@LazySingleton(as: DeviceTimeZone)
class FlutterDeviceTimeZone implements DeviceTimeZone {
  @override
  Future<String> current() async {
    try {
      return (await FlutterTimezone.getLocalTimezone()).identifier;
    } on Object {
      // Valid universal fallback; the UI tells the owner that it is editable.
      return 'Etc/UTC';
    }
  }
}
