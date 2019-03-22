import 'dart:async';

import 'package:rxdart/rxdart.dart';
import 'package:stpt_arrivals/data/cool_down_data_source.dart';
import 'package:stpt_arrivals/services/parser/time_converter.dart';

abstract class RestoringCoolDownManager {
  static const Duration coolDownThreshold = const Duration(seconds: 30);

  Stream<CoolDownData> streamLastCoolDown();

  Future<bool> isInCoolDown(String transporterId);

  Future<void> saveLastCoolDown(String transporterId);

  void switchLastCoolDown(String transporterId);

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
  CoolDownDataSource _coolDownDataSource;

  TimeProvider _timeProvider;

  BehaviorSubject<String> _subjectCoolDownSwitch = BehaviorSubject()
    ..add("");


  RestoringCoolDownManagerImpl(this._coolDownDataSource, this._timeProvider);

  @override
  Stream<CoolDownData> streamLastCoolDown() =>
      _subjectCoolDownSwitch.switchMap((id) => Observable(_coolDownDataSource.streamLastCoolDown(id)));

  @override
  void switchLastCoolDown(String transporterId) {
    _subjectCoolDownSwitch.add(transporterId);
  }

  @override
  Future<void> saveLastCoolDown(String transporterId) async {
    await _coolDownDataSource.retainLastCoolDown(CoolDownData(transporterId,
        _timeProvider.timeMillis()));
  }

  @override
  Future<bool> isInCoolDown(String transporterId) async {
    final cd = await _coolDownDataSource.loadLastCoolDown(transporterId);
    return timeRemainingSeconds(cd.timeMillis, _timeProvider.timeMillis()) > 0;
  }

  @override
  void dispose() {
    _subjectCoolDownSwitch.close();
  }
}
