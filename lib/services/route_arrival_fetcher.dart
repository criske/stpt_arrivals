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

  Future<Route> getRouteArrivals(String transporterId) async {
    Response response = await _client.get(_config.routeURL(transporterId));
    if (response.statusCode == 200) {
      try {
        return _parser.parse(response.body);
      } catch (e) {
        if (e is RouteNotFoundError) {
          response =
              await _client.get(_config.routeURLSpecialId(transporterId));
          if (response.statusCode == 200) {
            return _parser.parse(response.body);
          } else {
            throw Exception(response.statusCode);
          }
        } else
          throw e;
      }
    } else {
      throw Exception(response.statusCode);
    }
  }
}
