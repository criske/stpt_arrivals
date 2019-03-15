import 'package:shared_preferences/shared_preferences.dart';

abstract class FavoritesDataSource {
  Future<Set<String>> getAll();

  Future<void> insert(String id);

  Future<void> delete(String id);
}

class FavoritesDataSourceImpl implements FavoritesDataSource {
  static const _favoritesKey = "FAVORITES_KEY";

  @override
  Future<void> delete(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final filtered = _getAll(prefs).where((i) => id != i).toSet();
    _save(prefs, filtered);
  }

  @override
  Future<Set<String>> getAll() async {
    final prefs = await SharedPreferences.getInstance();
    return _getAll(prefs);
  }

  @override
  Future<void> insert(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final all = _getAll(prefs);
    all.add(id);
    _save(prefs, all);
  }

  _save(SharedPreferences prefs, Set<String> ids) async {
    await prefs.setStringList(
        _favoritesKey, ids.toList());
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
