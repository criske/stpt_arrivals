import 'dart:ui';

class ErrorUI extends Error {
  final String message;
  final bool canRetry;

  ErrorUI(this.message, [this.canRetry = false]);
}

class ArrivalUI {
  final int stationId;
  final String stationName;
  final TimeUI time1;
  final TimeUI time2;

  ArrivalUI(this.stationId, this.stationName, this.time1, this.time2);

}

class TimeUI {
  final String value;
  final Color color;

  const TimeUI(this.value, [this.color = const Color(0x0)]);

  static TimeUI none = TimeUI("**:**");
}
