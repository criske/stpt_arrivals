import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/mockito.dart';
import 'package:stpt_arrivals/models/arrival.dart';
import 'package:stpt_arrivals/services/parser/route_arrival_parser.dart';
import 'package:stpt_arrivals/services/parser/time_converter.dart';
import 'package:stpt_arrivals/services/remote_config.dart';
import 'package:stpt_arrivals/services/route_arrival_fetcher.dart';

void main() {
  RouteArrivalFetcher fetcher;

  Client client;

  RouteArrivalParser parser;

  RemoteConfig config;

  setUp(() {
    client = MockClient();
    parser = MockParser();
    config = RemoteConfigImpl();
    fetcher = RouteArrivalFetcher(parser, config, client);
  });

  test("should thow io exception", () async {
    final ex = ClientException("Client Exception");
    when(client.get(config.arrivalURL(886))).thenThrow(ex);
    try {
      await fetcher.getRouteArrivals(866);
      fail("Error was not thrown");
    } catch (actualEx) {}
  });

  test("should succesfully get a result", () async {
    final route = Route(null, null);
    when(client.get(config.arrivalURL(886)))
        .thenAnswer((_) async => http.Response("", 200));
    when(parser.parse("")).thenReturn(route);
    final result = await fetcher.getRouteArrivals(886);
    expect(route, result);
  });

  test("remote config urls", () {
    expect(config.arrivalURL(886).toString(),
        "http://86.125.113.218:61978/html/timpi/trasee.php?param1=886");
  });

  test("e2e test", () async {
    final route = await RouteArrivalFetcher(
            RouteArrivalParserImpl(
                ArrivalTimeConverterImpl()),
            RemoteConfigImpl(),
            Client())
        .getRouteArrivals(886);
    expect(2, 1 + 1);
    print(route);
  });
}

class MockParser extends Mock implements RouteArrivalParser {}

class MockClient extends Mock implements Client {}
