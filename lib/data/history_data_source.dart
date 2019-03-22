import 'package:rxdart/rxdart.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class HistoryDataSource {
  Stream<List<String>> streamAll();

  Future<void> addToHistory(String transporterId);
}

class HistoryDataSourceImpl implements HistoryDataSource {
  static const _historyKey = "HISTORY_KEY";

  static final int _maxSize = 5;

  static final Object _triggerEv = Object();

  BehaviorSubject<Object> _trigger = BehaviorSubject<Object>()
        ..add(_triggerEv);

  @override
  Future<void> addToHistory(String transporterId) async {
    final prefs = await SharedPreferences.getInstance();
    final history = await _getAll();
    final index = history.indexOf(transporterId);
    if (index != -1) {
      history.removeAt(index);
    } else if (history.length == _maxSize) {
      history.removeAt(0);
    }
    history.add(transporterId);
    await prefs.setStringList(_historyKey, history);
    _trigger.add(_triggerEv);
  }

  @override
  Stream<List<String>> streamAll() {
    return _trigger.switchMap((_) =>
        Observable.fromFuture(_getAll()).map((l) {
          return l.reversed.toList();
        }));
  }

  Future<List<String>> _getAll() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_historyKey) ?? [];
  }
}
