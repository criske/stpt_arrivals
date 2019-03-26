import 'package:rxdart/rxdart.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class StringDataSource {
  Stream<Set<String>> streamAll();

  Future<Set<String>> getAll();

  Future<void> insert(String id);

  Future<void> resetAndInsert(Set<String> ids);

  Future<void> delete(String id);
}

abstract class ObservableDataSource{

  static final Object _triggerEv = Object();

  PublishSubject<Object> _trigger = PublishSubject<Object>();

  void notifyTrigger() {
    _trigger.add(_trigger);
  }

  Observable<Object> get triggerSource => Observable.just(_triggerEv).mergeWith([_trigger]);

}

abstract class StringDataSourceImpl extends ObservableDataSource implements StringDataSource {

  Stream<Set<String>> streamAll() {
    return triggerSource.switchMap(
            (_) => Observable.fromFuture(getAll()));
  }

  Future<Set<String>> getAll() async {
    final prefs = await SharedPreferences.getInstance();
    return _getAll(prefs);
  }

  Future<void> insert(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final all = _getAll(prefs)..add(id);
    _save(prefs, all);
  }

  Future<void> delete(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final filtered = _getAll(prefs).where((i) => id != i).toSet();
    _save(prefs, filtered);
  }

  Future<void> resetAndInsert(Set<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    _save(prefs, ids);
  }

  _save(SharedPreferences prefs, Set<String> ids) async {
    await prefs.setStringList(key, ids.toList());
    notifyTrigger();
  }

  Set<String> _getAll(SharedPreferences prefs) {
    final all = prefs.getStringList(key);
    if (all == null || all.isEmpty) {
      return Set<String>();
    } else {
      return all.toSet();
    }
  }

  String get key;
}
