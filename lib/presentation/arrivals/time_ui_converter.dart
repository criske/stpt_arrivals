import 'package:intl/intl.dart';
import 'package:stpt_arrivals/presentation/arrivals/arrival_ui.dart';
import 'package:stpt_arrivals/services/parser/time_converter.dart';

abstract class TimeUIConverter {
  TimeUI toUI(Time time);
}

class TimeUIConverterImpl implements TimeUIConverter {
  final int defaultColor;
  final int closeColor;
  final int mediumFarColor;

  TimeUIConverterImpl({
    this.defaultColor = 0xFF000000,
    this.closeColor = 0xFF32CD32,
    this.mediumFarColor = 0xFFFFA700
  });

  @override
  TimeUI toUI(Time time) {
    if (time == null) return TimeUI.none("**:**");
    var proximityColor = defaultColor;
    var proximityColorBg = 0x00FFFFFF;
    if (time.isInProximity) {
      final time1Diff = Duration(milliseconds: time.offsetToNowMillis).inMinutes;
      if (time1Diff < 5) {
        proximityColor = 0xFFFFFFFF;
        proximityColorBg = closeColor;
      } else if (time1Diff >= 5 && time1Diff < 10) {
        proximityColor = 0xFFFFFFFF;
        proximityColorBg = mediumFarColor;
      }
    }
    return TimeUI(_toReadableTime(time.millis, "HH:mm"), proximityColor,  proximityColorBg);
  }

  String _toReadableTime(int timeMillis,
          [String pattern = "yyyy-MM-dd HH:mm"]) =>
      DateFormat(pattern)
          .format(DateTime.fromMillisecondsSinceEpoch(timeMillis));
}
