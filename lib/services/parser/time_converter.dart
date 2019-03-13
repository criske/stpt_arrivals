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

  final bool isInProximity;

  const Time(this.millis, this.offsetToNowMillis, [this.isInProximity = false]);

  @override
  int get hashCode => hashValues(millis, isInProximity, offsetToNowMillis);

  @override
  bool operator ==(other) =>
      other is Time &&
      this.millis == other.millis &&
      this.isInProximity == other.isInProximity &&
      this.offsetToNowMillis == other.offsetToNowMillis;

  @override
  String toString() => "Time:[millis:$millis, offset:$offsetToNowMillis]";

  Time makeItInProximity() => Time(millis, offsetToNowMillis, true);
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
    return _toTimeMillisInternal(timeStr, _provider.time()).millis;
  }

  _ProxyMillis _toTimeMillisInternal(String timeStr, DateTime now) {
    if (timeStr == ">>") {
      return _ProxyMillis(now.millisecondsSinceEpoch, true);
    } else if (timeStr.endsWith("min.")) {
      final minutes =
          int.parse(timeStr.substring(0, timeStr.indexOf("min.")).trim());
      return _ProxyMillis(now.add(Duration(minutes: minutes)).millisecondsSinceEpoch, true);
    } else if (timeStr.contains(":")) {
      final split = timeStr.split(":");
      assert(split.length == 2);
      try {
        final hour = int.parse(split[0]);
        final minutes = int.parse(split[1]);
        final millis = DateTime.utc(now.year, now.month, now.day, hour, minutes)
            .subtract(Duration(
                hours: 2)) // compensate for romanian time zone relative to utc
            .millisecondsSinceEpoch;
        return _ProxyMillis(millis, false);
      } catch (_) {
        return _ProxyMillis._zero;
      }
    } else {
      return _ProxyMillis._zero;
    }
  }

  @override
  String toReadableTime(int timeMillis, [String pattern]) => DateFormat(pattern)
      .format(DateTime.fromMillisecondsSinceEpoch(timeMillis));

  @override
  Time toTime(String timeStr) {
    final now = _provider.time();
    final proxyMillis = _toTimeMillisInternal(timeStr, now);
    final offset = (now.millisecondsSinceEpoch - proxyMillis.millis).abs();
    return Time(proxyMillis.millis, offset, proxyMillis.inProximity);
  }
}

class _ProxyMillis{
   final int millis;
   final bool inProximity;
  _ProxyMillis(this.millis, [this.inProximity = false]);
  static _ProxyMillis _zero = _ProxyMillis(0);
}