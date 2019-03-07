import 'dart:async';

import 'package:http/http.dart';
import 'package:stpt_arrivals/models/arrival.dart';
import 'package:stpt_arrivals/services/parser/route_arrival_parser.dart';
import 'package:stpt_arrivals/services/remote_config.dart';

class RouteArrivalFetcher {
  RouteArrivalParser _parser;

  RemoteConfig _config;

  Client _client;

  RouteArrivalFetcher(this._parser, this._config, this._client);

  Future<Route> getRouteArrivals(int transporterId) async {
    Uri uri = _config.arrivalURL(transporterId);
    Response response = await _client.get(uri);
    if (response.statusCode == 200) {
      return _parser.parse(response.body);
    } else {
      throw Exception(response.statusCode);
    }
  }
}