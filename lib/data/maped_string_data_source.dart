import 'package:shared_preferences/shared_preferences.dart';
import 'package:stpt_arrivals/data/string_data_source.dart';

abstract class MappedStringDataSource {

  Stream<Set<String>> streamAllByKey(String key);

  Future<Set<String>> getAllByKey(String key);

  Future<void> insert(String key, String value);

  Future<void> delete(String key);
}

abstract class MappedStringDataSourceImpl extends ObservableDataSource implements MappedStringDataSource{

  @override
  Future<void> delete(String key) {
    // TODO: implement delete
    return null;
  }


  Set<String> _getAll(SharedPreferences prefs) {
    final all = prefs.getStringList(sourceKey);
    if (all == null || all.isEmpty) {
      return Set<String>();
    } else {
      return all.toSet();
    }
  }

  String _getValue(String entry) => entry.split(":")[1];
  String _getKey(String entry) => entry.split(":")[0];
  String _createEntry(String key, String value) => "$key:$value";

  @override
  Future<Set<String>> getAllByKey(String key) async{
    return _getAll(await SharedPreferences.getInstance())
        .where((entry) => _getKey(entry) == key);
  }

  @override
  Future<void> insert(String key, String value) async{

    notifyTrigger();
  }

  String get sourceKey;

}