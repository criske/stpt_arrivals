import 'package:rxdart/rxdart.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class StringDataSource {
  Stream<Set<String>> streamAll();

  Future<Set<String>> getAll();

  Future<void> insert(String id);

  Future<void> delete(String id);
}

abstract class StringDataSourceImpl implements StringDataSource {

  static final Object _triggerEv = Object();

  PublishSubject<Object> _trigger = PublishSubject<Object>();

  Future<Set<String>> getAll() async {
    final prefs = await SharedPreferences.getInstance();
    return _getAll(prefs);
  }

  Stream<Set<String>> streamAll() {
    return Observable.just(_triggerEv).mergeWith([_trigger]).switchMap(
            (_) => Observable.fromFuture(getAll()));
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

  _save(SharedPreferences prefs, Set<String> ids) async {
    await prefs.setStringList(key, ids.toList());
    _trigger.add(_triggerEv);
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
