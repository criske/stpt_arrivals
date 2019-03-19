import 'package:shared_preferences/shared_preferences.dart';

abstract class CoolDownDataSource {
  Future<CoolDownData> loadLastCoolDown([String transporterId = ""]);

  Future<void> retainLastCoolDown(CoolDownData data);
}

class CoolDownDataSourceImpl implements CoolDownDataSource {
  //static const _restoringCoolDownKey = "RESTORING_COOLDOWN_KEY";
  static const _restoringCoolDownKey = "RESTORING_COOLDOWN_LIST_KEY";

  @override
  Future<CoolDownData> loadLastCoolDown([String transporterId = ""]) async {
    final prefs = await SharedPreferences.getInstance();
    final list = _getAll(prefs).toList();
    final id = transporterId.trim();
    if (id.isEmpty) {
      //sort descending => b compareTo a (asc will a compare to b
      list.sort((a, b) =>  b.timeMillis.compareTo(a.timeMillis));
      return list.isEmpty ? CoolDownData.no_data : list.first;
    } else {
      return list.firstWhere((cd) => cd.transporterId == id,
          orElse: () => CoolDownData(transporterId, 0));
    }
  }

  @override
  Future<void> retainLastCoolDown(CoolDownData data) async {
    final prefs = await SharedPreferences.getInstance();
    final list = _getAll(prefs)
        .where((cd) => cd.transporterId != data.transporterId)
        .toList();
    list.add(data);
    await prefs.setStringList(
        _restoringCoolDownKey, list.map(_encode).toList());
  }

  Iterable<CoolDownData> _getAll(SharedPreferences prefs) =>
      (prefs.getStringList(_restoringCoolDownKey) ?? []).map(_decode);

  String _encode(CoolDownData data) =>
      "${data.transporterId}:${data.timeMillis}";

  CoolDownData _decode(String data) {
    final split = data.split(":");
    return CoolDownData(split[0], int.parse(split[1]));
  }
}

class CoolDownData {
  static const no_data = CoolDownData("", 0);

  final String transporterId;
  final int timeMillis;

  const CoolDownData(this.transporterId, this.timeMillis);

  @override
  String toString() => "CoolDownData[id:$transporterId, time:$timeMillis]";
}
