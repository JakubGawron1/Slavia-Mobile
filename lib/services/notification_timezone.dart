import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Inicjalizacja strefy dla `zonedSchedule` (przypomnienia o startach).
Future<void> ensureLocalTimezoneInitialized() async {
  tz_data.initializeTimeZones();
  final name = await FlutterTimezone.getLocalTimezone();
  try {
    tz.setLocalLocation(tz.getLocation(name));
  } catch (_) {
    tz.setLocalLocation(tz.getLocation('Europe/Warsaw'));
  }
}
