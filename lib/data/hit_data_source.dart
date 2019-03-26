import 'package:meta/meta.dart';
import 'package:rxdart/rxdart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stpt_arrivals/data/string_data_source.dart';

abstract class HitDataSource {
  Stream<Set<Hit>> streamAll();

  Future<Set<Hit>> getAll();

  Future<void> incrementHit(String transporterId);
}

class HitDataSourceImpl extends ObservableDataSource implements HitDataSource {
  static const _hitsKey = "HITS_KEY";

  static final HitDataSourceImpl _singleton = HitDataSourceImpl._internal();

  factory HitDataSourceImpl() => _singleton;

  HitDataSourceImpl._internal();

  @override
  Future<void> incrementHit(String transporterId) async {
    final prefs = await SharedPreferences.getInstance();
    final hits = _getAll(prefs);
    final incrementedHit = hits
        .firstWhere((h) => h.transporterId == transporterId,
            orElse: () => Hit(transporterId, 0))
        .increment();
    hits.removeWhere((h) => h.transporterId == transporterId);
    hits.add(incrementedHit);
    await prefs.setStringList(_hitsKey, hits.map((h) => h.toString()).toList());
    notifyTrigger();
  }

  @override
  Stream<Set<Hit>> streamAll() =>
      triggerSource.switchMap((_) => Observable.fromFuture(getAll()));

  Future<Set<Hit>> getAll() async {
    final prefs = await SharedPreferences.getInstance();
    return _getAll(prefs);
  }

  Set<Hit> _getAll(SharedPreferences prefs) {
    final hits = prefs.getStringList(_hitsKey)?.map(_toHit)?.toList() ?? []
      ..sort((a, b) => b.hit.compareTo(a.hit));
    return hits.toSet();
  }

  Hit _toHit(String data) {
    final split = data.split(":");
    return Hit(split[0], int.parse(split[1]));
  }
}

@immutable
class Hit {
  final String transporterId;

  final int hit;

  const Hit(this.transporterId, this.hit);

  Hit increment() => Hit(transporterId, hit + 1);

  @override
  String toString() => "$transporterId:$hit";
}
