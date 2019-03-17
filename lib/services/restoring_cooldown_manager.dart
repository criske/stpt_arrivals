import 'package:rxdart/rxdart.dart';
import 'package:stpt_arrivals/data/cool_down_data_source.dart';

abstract class RestoringCoolDownManager {
  static const Duration coolDownThreshold = const Duration(seconds: 30);

  Stream<int> getLastCoolDown();

  Stream<Duration> getLastCoolDownDuration();

  Future<void> saveLastCoolDown(int timeMillis);

  void dispose();

  int timeRemainingSeconds(int lastTimeMillis, int nowMillis) {
    var remaining = RestoringCoolDownManager.coolDownThreshold.inSeconds -
        (Duration(milliseconds: nowMillis) -
                Duration(milliseconds: lastTimeMillis))
            .inSeconds;
    return remaining;
  }

  double timeRemainingPercent(int lastTimeMillis, int nowMillis) =>
      timeRemainingSeconds(lastTimeMillis, nowMillis) /
      coolDownThreshold.inSeconds;
}

class RestoringCoolDownManagerImpl extends RestoringCoolDownManager {
  final CoolDownDataSource coolDownDataSource;

  RestoringCoolDownManagerImpl(this.coolDownDataSource);

  BehaviorSubject<int> _subjectLastCoolDown = BehaviorSubject();

  @override
  Stream<int> getLastCoolDown() => RaceStream([
        _subjectLastCoolDown.stream,
        Observable.fromFuture(coolDownDataSource.loadLastCoolDown())
      ]);

  @override
  Stream<Duration> getLastCoolDownDuration() =>
      getLastCoolDown().map((timeMillis) => Duration(milliseconds: timeMillis));

  @override
  Future<void> saveLastCoolDown(int timeMillis) async {
    await coolDownDataSource.retainLastCoolDown(timeMillis);
    _subjectLastCoolDown.add(timeMillis);
  }

  @override
  void dispose() {
    _subjectLastCoolDown.close();
  }
}
