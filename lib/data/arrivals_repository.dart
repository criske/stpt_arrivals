import 'package:stpt_arrivals/data/cool_down_data_source.dart';
import 'package:stpt_arrivals/models/arrival.dart';

//todo implement
abstract class ArrivalsRepository{

  Future<Route> getRoute(String transporterId);

  /***
   * Collect history and and the number of hits for transporterId
   */
  Future<void> collectMetrics(String transporterId);

}