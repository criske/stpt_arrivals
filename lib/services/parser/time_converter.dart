abstract class TimeConverter {

  int toAbsoluteTime(String timeStr);


  String toReadableTime(int time);
}

abstract class TimeProvider {

  int time();

}

class TimeConverterImpl implements TimeConverter {

  TimeProvider _provider;

  TimeConverterImpl(TimeProvider this._provider);

  @override
  int toAbsoluteTime(String timeStr) {
    // TODO: implement toAbsoluteTime
  }

  @override
  String toReadableTime(int time) {
    // TODO: implement toReadableTime
  }

}