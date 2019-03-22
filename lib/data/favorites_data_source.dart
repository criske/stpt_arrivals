import 'package:rxdart/rxdart.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class FavoritesDataSource {
  Stream<Set<String>> streamAll();

  Future<Set<String>> getAll();

  Future<void> insert(String id);

  Future<void> delete(String id);
}

class FavoritesDataSourceImpl implements FavoritesDataSource {
  static const _favoritesKey = "FAVORITES_KEY";

  static final Object _triggerEv = Object();

  static final FavoritesDataSourceImpl _singleton =
      FavoritesDataSourceImpl._internal();

  factory FavoritesDataSourceImpl() => _singleton;

  FavoritesDataSourceImpl._internal();

  PublishSubject<Object> _trigger = PublishSubject<Object>();

  @override
  Future<Set<String>> getAll() async {
    final prefs = await SharedPreferences.getInstance();
    return _getAll(prefs);
  }

  @override
  Stream<Set<String>> streamAll() {
    return Observable.just(_triggerEv).mergeWith([_trigger]).switchMap(
        (_) => Observable.fromFuture(getAll()));
  }

  @override
  Future<void> insert(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final all = _getAll(prefs)..add(id);
    _save(prefs, all);
  }

  @override
  Future<void> delete(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final filtered = _getAll(prefs).where((i) => id != i).toSet();
    _save(prefs, filtered);
  }

  _save(SharedPreferences prefs, Set<String> ids) async {
    await prefs.setStringList(_favoritesKey, ids.toList());
    _trigger.add(_triggerEv);
  }

  Set<String> _getAll(SharedPreferences prefs) {
    final all = prefs.getStringList(_favoritesKey);
    if (all == null || all.isEmpty) {
      return Set<String>();
    } else {
      return all.toSet();
    }
  }
}
