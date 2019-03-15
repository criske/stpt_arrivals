import 'package:shared_preferences/shared_preferences.dart';
import 'package:stpt_arrivals/data/transporter_encoder.dart';
import 'package:stpt_arrivals/models/transporter.dart';

abstract class TransportersDataSource {
  Future<List<Transporter>> findAll();

  Future<void> save(List<Transporter> transporters);

  Future<void> update(Transporter transporter);
}

class TransportersDataSourceImpl extends TransportersDataSource {
  static const _transportersKey = "TRANSPORTERS_KEY";

  final TransporterEncoder encoder = TransporterEncoder();

  @override
  Future<List<Transporter>> findAll() async {
    final prefs = await SharedPreferences.getInstance();
    var data = prefs.getString(_transportersKey);
    return data != null ? encoder.decodeJSON(data) : [];
  }

  @override
  Future<void> save(List<Transporter> transporters) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_transportersKey, encoder.encodeJSON(transporters));
  }

  @override
  Future<void> update(Transporter transporter) async {
    // TODO: implement update
    print("TransportersDataSourceImpl => update not implemented");
  }
}
