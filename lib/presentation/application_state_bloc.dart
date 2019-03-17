import 'dart:ui';

import 'package:meta/meta.dart';
import 'package:rxdart/rxdart.dart';
import 'package:stpt_arrivals/services/parser/time_converter.dart';
import 'package:stpt_arrivals/services/restoring_cooldown_manager.dart';

class ApplicationStateBloc {

  final RestoringCoolDownManager coolDownManager;

  final TimeProvider timeProvider;

  ApplicationStateBloc(this.coolDownManager, this.timeProvider);

  bool _isInCoolDown = false;

  Stream<CoolDown> remainingCoolDownStream() =>
      Observable(coolDownManager.getLastCoolDown()).switchMap((time) {
        return Observable.periodic(Duration(seconds: 1), (_) => createCoolDownFromTimeMillis(time))
            .startWith(createCoolDownFromTimeMillis(time))
            .takeWhile((cd) => cd.remainingSeconds >= 0)
            .doOnData((_) => _isInCoolDown = true)
            .doOnDone(() => _isInCoolDown = false);
      }).share();

  CoolDown createCoolDownFromTimeMillis(int time) {
    final now = timeProvider.timeMillis();
    final remainingSeconds =
        coolDownManager.timeRemainingSeconds(time, now);
    final percent = coolDownManager.timeRemainingPercent(time, now);
    return CoolDown(remainingSeconds, percent);
  }

  bool isInCoolDown() => _isInCoolDown;

  void dispose(){
    coolDownManager.dispose();
  }

}

@immutable
class CoolDown {
  static const noCoolDown = const CoolDown(-1, -1.0);

  final int remainingSeconds;
  final double percent;

  const CoolDown(this.remainingSeconds, this.percent);

  @override
  String toString() => "CoolDown [remSec:$remainingSeconds, %:$percent]";

  @override
  bool operator ==(other) =>
      other is CoolDown &&
      remainingSeconds == other.remainingSeconds &&
      percent == other.percent;

  @override
  int get hashCode => hashValues(remainingSeconds, percent);
}
