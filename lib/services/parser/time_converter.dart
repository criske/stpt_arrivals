import 'package:intl/intl.dart';

abstract class ArrivalTimeConverter {
  int toAbsoluteTime(String timeStr);

  String toReadableTime(int time, [String format = "yyyy-MM-dd HH:mm"]);
}

abstract class TimeProvider {
  int timeMillis();

  DateTime time();
}

class SystemTimeProvider implements TimeProvider {
  const SystemTimeProvider();

  @override
  int timeMillis() => DateTime.now().millisecondsSinceEpoch;

  @override
  DateTime time() => DateTime.now();

}

class ArrivalTimeConverterImpl implements ArrivalTimeConverter {
  TimeProvider _provider;

  ArrivalTimeConverterImpl([this._provider = const SystemTimeProvider()]);

  @override
  int toAbsoluteTime(String timeStr) {
    final now = _provider.time();
    if (timeStr == ">>") {
      return now.millisecondsSinceEpoch;
    } else if (timeStr.endsWith("min.")) {
      final minutes =
          int.parse(timeStr.substring(0, timeStr.indexOf("min.")).trim());
      return now.add(Duration(minutes: minutes)).millisecondsSinceEpoch;
    } else if (timeStr.contains(":")) {
      final split = timeStr.split(":");
      assert(split.length == 2);
      try {
        final hour = int.parse(split[0]);
        final minutes = int.parse(split[1]);
        return DateTime
            .utc(now.year, now.month, now.day, hour, minutes)
            .subtract(Duration(
                hours: 2)) // compensate for romanian time zone relative to utc
            .millisecondsSinceEpoch;
      } catch (_) {
        return 0;
      }
    } else {
      return 0;
    }
  }

  @override
  String toReadableTime(int timeMillis, [String pattern]) => DateFormat(pattern)
      .format(DateTime.fromMillisecondsSinceEpoch(timeMillis));
}
