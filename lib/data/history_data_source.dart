import 'package:rxdart/rxdart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stpt_arrivals/data/string_data_source.dart';

abstract class HistoryDataSource {
  Stream<List<String>> streamAll();

  Future<void> addToHistory(String transporterId);
}

class HistoryDataSourceImpl extends ObservableDataSource implements HistoryDataSource {
  static const _historyKey = "HISTORY_KEY";

  static final int _maxSize = 5;

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
    notifyTrigger();
  }

  @override
  Stream<List<String>> streamAll() {
    return triggerSource.switchMap((_) =>
        Observable.fromFuture(_getAll()).map((l) {
          return l.reversed.toList();
        }));
  }

  Future<List<String>> _getAll() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_historyKey) ?? [];
  }
}
