import 'package:shared_preferences/shared_preferences.dart';
import 'package:stpt_arrivals/models/transporter.dart';

abstract class TransportersDataSource {
  Future<List<Transporter>> findAll();

  Future<void> save(List<Transporter> transporters);
}

class TransportersDataSourceImpl extends TransportersDataSource {

  static const _transportersKey = "TRANSPORTERS_KEY";

  static const _map_id = "id";
  static const _map_name = "name";
  static const _map_fav = "fav";
  static const _map_type = "type";

  @override
  Future<List<Transporter>> findAll() async {
    final prefs = await SharedPreferences.getInstance();
    return _decodeJSON(prefs.getString(_transportersKey));
  }

  @override
  Future<void> save(List<Transporter> transporters) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_transportersKey, _encodeJSON(transporters));
  }

  String _encodeJSON(List<Transporter> transporters) {

  };

  List<Transporter> _decodeJSON(String json) => List<Transporter>();

}
