import 'package:stpt_arrivals/data/string_data_source.dart';
import 'package:stpt_arrivals/models/arrival.dart';

abstract class PinnedStationsDataSource extends StringDataSource{}

class PinnedStationsDataSourceImpl extends StringDataSourceImpl implements PinnedStationsDataSource{
  @override
  String get key => "PINNED_STATIONS_KEY";

  @override
  Future<void> insert(String id) async {
    final transporterId = Station.extractTransporterId(id);
    final ids = (await getAll())
        .where((stationId) => Station.extractTransporterId(stationId) != transporterId)
        .toSet()
        ..add(id);
    await resetAndInsert(ids);
  }


}