import 'package:shared_preferences/shared_preferences.dart';

abstract class FavoritesDataSource {
  Future<Set<int>> getAll();

  Future<void> insert(int id);

  Future<void> delete(int id);
}

class FavoritesDataSourceImpl implements FavoritesDataSource {
  static const _favoritesKey = "FAVORITES_KEY";

  @override
  Future<void> delete(int id) async {
    final prefs = await SharedPreferences.getInstance();
    final filtered = _getAll(prefs).where((i) => id != i).toSet();
    _save(prefs, filtered);
  }

  @override
  Future<Set<int>> getAll() async {
    final prefs = await SharedPreferences.getInstance();
    return _getAll(prefs);
  }

  @override
  Future<void> insert(int id) async {
    final prefs = await SharedPreferences.getInstance();
    final all = _getAll(prefs);
    all.add(id);
    _save(prefs, all);
  }

  _save(SharedPreferences prefs, Set<int> ids) async {
    await prefs.setStringList(
        _favoritesKey, ids.map((id) => id.toString()).toList());
  }

  Set<int> _getAll(SharedPreferences prefs) {
    final all = prefs.getStringList(_favoritesKey);
    if (all == null || all.isEmpty) {
      return Set<int>();
    } else {
      return all.map((idStr) => int.parse(idStr)).toSet();
    }
  }
}
