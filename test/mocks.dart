import 'package:http/http.dart';
import 'package:mockito/mockito.dart';
import 'package:stpt_arrivals/data/favorites_data_source.dart';
import 'package:stpt_arrivals/data/transporters_data_source.dart';
import 'package:stpt_arrivals/services/parser/route_arrival_parser.dart';
import 'package:stpt_arrivals/services/parser/time_converter.dart';
import 'package:stpt_arrivals/services/restoring_cooldown_manager.dart';
import 'package:stpt_arrivals/services/route_arrival_fetcher.dart';
import 'package:stpt_arrivals/services/transporters_type_fetcher.dart';

class MockRouteArrivalFetcher extends Mock implements RouteArrivalFetcher {}

class MockParser extends Mock implements RouteArrivalParser {}

class MockClient extends Mock implements Client {}

class MockTimeProvider extends Mock implements TimeProvider {}

class MockRestoringCoolDownManager extends Mock implements RestoringCoolDownManager{}

class MockArrivalTimeConverter extends Mock implements ArrivalTimeConverter {}

class MockFavoritesDataSource extends Mock implements FavoritesDataSource{}

class MockTransportersDataSource extends Mock implements TransportersDataSource{}

class MockTransportersTypeFetcher extends Mock implements TransportersTypeFetcher {}

class TimelineTimeProvider implements TimeProvider {
  DateTime _timeline;

  TimelineTimeProvider([int seedMillis = 0]) {
    _timeline = DateTime.fromMillisecondsSinceEpoch(seedMillis);
  }

  @override
  DateTime time() => _timeline;

  @override
  int timeMillis() => _timeline.millisecondsSinceEpoch;

  void advance(Duration duration) {
    _timeline = _timeline.add(duration);
  }

  Duration diff(DateTime date) =>
      Duration(milliseconds: timeMillis()) - Duration(milliseconds: date.millisecondsSinceEpoch);
}
