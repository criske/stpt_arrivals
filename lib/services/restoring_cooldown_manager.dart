import 'dart:async';

import 'package:rxdart/rxdart.dart';
import 'package:stpt_arrivals/data/cool_down_data_source.dart';

abstract class RestoringCoolDownManager {
  static const Duration coolDownThreshold = const Duration(seconds: 30);

  Stream<CoolDownData> getLastCoolDown();

  Future<bool> isInCoolDown(String transporterId, int nowMillis);

  Future<void> saveLastCoolDown(CoolDownData data);

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
  CoolDownDataSource coolDownDataSource;

  BehaviorSubject<String> _subjectCoolDownSwitch = BehaviorSubject()
    ..add("");


  RestoringCoolDownManagerImpl(CoolDownDataSource coolDownDataSource) {
    this.coolDownDataSource = coolDownDataSource;
  }

  @override
  Stream<CoolDownData> getLastCoolDown() =>
      _subjectCoolDownSwitch.switchMap((id) => Observable(coolDownDataSource.streamLastCoolDown(id)));

  @override
  void switchLastCoolDown(String transporterId) {
    _subjectCoolDownSwitch.add(transporterId);
  }

  @override
  Future<void> saveLastCoolDown(CoolDownData data) async {
    await coolDownDataSource.retainLastCoolDown(data);
  }

  @override
  Future<bool> isInCoolDown(String transporterId, int nowMillis) async {
    final cd = await coolDownDataSource.loadLastCoolDown(transporterId);
    return timeRemainingSeconds(cd.timeMillis, nowMillis) > 0;
  }

  @override
  void dispose() {
    _subjectCoolDownSwitch.close();
  }
}
