import 'dart:ui';

import 'package:meta/meta.dart';
import 'package:rxdart/rxdart.dart';
import 'package:stpt_arrivals/data/cool_down_data_source.dart';
import 'package:stpt_arrivals/data/transporters_repository.dart';
import 'package:stpt_arrivals/services/parser/time_converter.dart';
import 'package:stpt_arrivals/services/restoring_cooldown_manager.dart';

class ApplicationStateBloc {
  final RestoringCoolDownManager coolDownManager;

  final TimeProvider timeProvider;

  final TransportersRepository transportersRepository;

  ApplicationStateBloc(
      this.coolDownManager, this.timeProvider, this.transportersRepository);

  Stream<CoolDownUI> remainingCoolDownStream() =>
      Observable(coolDownManager.getLastCoolDown())
          .switchMap((cd) => Observable.fromFuture(
                  transportersRepository.findById(cd.transporterId))
              .map((t) => t.name)
              .flatMap((name) => Observable.periodic(Duration(milliseconds: 1),
                      (_) => _createCoolDownFromData(name, cd))
                  .startWith(_createCoolDownFromData(name, cd))
                  .takeWhile((cd) => cd.remainingSeconds >= 0)))
          .share();

  CoolDownUI _createCoolDownFromData(String name, CoolDownData data) {
    final now = timeProvider.timeMillis();
    final remainingSeconds =
        coolDownManager.timeRemainingSeconds(data.timeMillis, now);
    final percent = coolDownManager.timeRemainingPercent(data.timeMillis, now);
    return CoolDownUI(name, remainingSeconds, percent);
  }

  switchLastCoolDown([String transporterId = ""]) {
    coolDownManager.switchLastCoolDown(transporterId);
  }

  Future<bool> isInCoolDown(String transporterId) async => await coolDownManager
      .isInCoolDown(transporterId, timeProvider.timeMillis());

  void dispose() {
    coolDownManager.dispose();
  }
}

@immutable
class CoolDownUI {
  static const noCoolDown = const CoolDownUI("", -1, -1.0);

  final String transporterName;
  final int remainingSeconds;
  final double percent;

  const CoolDownUI(this.transporterName, this.remainingSeconds, this.percent);

  @override
  String toString() =>
      "CoolDown [name:$transporterName, remSec:$remainingSeconds, %:$percent]";

  @override
  bool operator ==(other) =>
      other is CoolDownUI &&
      transporterName == other.transporterName &&
      remainingSeconds == other.remainingSeconds &&
      percent == other.percent;

  @override
  int get hashCode => hashValues(transporterName, remainingSeconds, percent);
}
