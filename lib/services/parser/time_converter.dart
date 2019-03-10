import 'dart:ui';

import 'package:intl/intl.dart';
import 'package:meta/meta.dart';

abstract class ArrivalTimeConverter {
  int toTimeMillis(String timeStr);

  Time toTime(String timeStr);

  String toReadableTime(int time, [String format = "yyyy-MM-dd HH:mm"]);
}

@immutable
class Time {
  final int millis;

  final int offsetToNowMillis;

  const Time(this.millis, this.offsetToNowMillis);

  @override
  int get hashCode => hashValues(millis, offsetToNowMillis);

  @override
  bool operator ==(other) =>
      other is Time &&
      this.millis == other.millis &&
      this.offsetToNowMillis == other.offsetToNowMillis;

  @override
  String toString() => "Time:[millis:$millis, offset:$offsetToNowMillis]";
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
  int toTimeMillis(String timeStr) {
    return _toTimeMillisInternal(timeStr, _provider.time());
  }

  int _toTimeMillisInternal(String timeStr, DateTime now) {
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
        return DateTime.utc(now.year, now.month, now.day, hour, minutes)
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

  @override
  Time toTime(String timeStr) {
    final now = _provider.time();
    final millis = _toTimeMillisInternal(timeStr, now);
    final offset = (now.millisecondsSinceEpoch - millis).abs();
    return Time(millis, offset);
  }
}
