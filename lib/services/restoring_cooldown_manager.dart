import 'dart:async';

import 'package:rxdart/rxdart.dart';
import 'package:stpt_arrivals/data/cool_down_data_source.dart';

abstract class RestoringCoolDownManager {
  static const Duration coolDownThreshold = const Duration(seconds: 30);

  Stream<CoolDownData> getLastCoolDown();

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

  BehaviorSubject<String> _subjectLastCoolDown = BehaviorSubject()..add("");

  StreamSubscription<CoolDownData> _subscriptionLastCoolDown;

  RestoringCoolDownManagerImpl(CoolDownDataSource coolDownDataSource) {
    this.coolDownDataSource = coolDownDataSource;
  }

  @override
  Stream<CoolDownData> getLastCoolDown() => _subjectLastCoolDown.switchMap(
      (id) {
        return Observable.fromFuture(coolDownDataSource.loadLastCoolDown(id))
            .doOnData((print));
      });

  @override
  void switchLastCoolDown(String transporterId) {
    _subjectLastCoolDown.add(transporterId);
  }

  @override
  Future<void> saveLastCoolDown(CoolDownData data) async {
    await coolDownDataSource.retainLastCoolDown(data);
    _subjectLastCoolDown.add(data.transporterId);
  }

  @override
  void dispose() {
    _subjectLastCoolDown.close();
    _subscriptionLastCoolDown.cancel();
  }
}
