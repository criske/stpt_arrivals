import 'package:rxdart/rxdart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stpt_arrivals/data/string_data_source.dart';
import 'package:stpt_arrivals/data/transporter_encoder.dart';
import 'package:stpt_arrivals/models/transporter.dart';

abstract class TransportersDataSource {
  Future<Transporter> findById(String id);

  Stream<List<Transporter>> streamAll();

  Future<void> save(List<Transporter> transporters);

  Future<void> update(Transporter transporter);
}

class TransportersDataSourceImpl extends ObservableDataSource implements TransportersDataSource {
  static const _transportersKey = "TRANSPORTERS_KEY";

  static final TransportersDataSourceImpl _singleton =
      TransportersDataSourceImpl._internal();

  factory TransportersDataSourceImpl() => _singleton;

  TransportersDataSourceImpl._internal();

  final TransporterEncoder encoder = TransporterEncoder();

  @override
  Stream<List<Transporter>> streamAll() =>
      triggerSource.switchMap((_) => Observable.fromFuture(_findAll()));

  Future<List<Transporter>> _findAll() async {
    final prefs = await SharedPreferences.getInstance();
    var data = prefs.getString(_transportersKey);
    return data != null ? encoder.decodeJSON(data) : [];
  }

  @override
  Future<void> save(List<Transporter> transporters) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_transportersKey, encoder.encodeJSON(transporters));
    notifyTrigger();
  }

  @override
  Future<void> update(Transporter transporter) async {
    // TODO: implement update
    print("TransportersDataSourceImpl => update not implemented");
  }

  @override
  Future<Transporter> findById(String id) async =>
      (await _findAll()).firstWhere((t) => t.id == id);
}
