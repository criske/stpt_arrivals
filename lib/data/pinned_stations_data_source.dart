import 'package:stpt_arrivals/data/simple_string_data_source.dart';

abstract class PinnedStationsDataSource extends StringDataSource{}

class PinnedStationsDataSourceImpl extends StringDataSourceImpl implements PinnedStationsDataSource{
  @override
  String get key => "PINNED_STATIONS_KEY";
}