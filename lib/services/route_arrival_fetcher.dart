import 'dart:async';

import 'package:http/http.dart';
import 'package:stpt_arrivals/data/history_data_source.dart';
import 'package:stpt_arrivals/models/arrival.dart';
import 'package:stpt_arrivals/services/parser/route_arrival_parser.dart';
import 'package:stpt_arrivals/services/remote_config.dart';
import 'package:stpt_arrivals/services/restoring_cooldown_manager.dart';

abstract class IRouteArrivalFetcher {
  Future<Route> getRouteArrivals(String transporterId);
}

class RouteArrivalFetcher implements IRouteArrivalFetcher {
  RouteArrivalParser _parser;

  RemoteConfig _config;

  Client _client;

  RouteArrivalFetcher(this._parser, this._config, this._client);

  Future<Route> getRouteArrivals(String transporterId) async {
    Response response = await _client.get(_config.routeURL(transporterId));
    if (response.statusCode == 200) {
      try {
        return _parser.parse(transporterId, response.body);
      } catch (e) {
        if (e is RouteNotFoundError) {
          response =
              await _client.get(_config.routeURLSpecialId(transporterId));
          if (response.statusCode == 200) {
            return _parser.parse(transporterId, response.body);
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

class CachedRouteArrivalFetcher implements IRouteArrivalFetcher {
  static Map<String, Route> _cache = Map<String, Route>();

  RestoringCoolDownManager _coolDownManager;
  RouteArrivalFetcher _routeArrivalFetcher;
  HistoryDataSource _historyDataSource;

  CachedRouteArrivalFetcher(
      this._routeArrivalFetcher,
      this._coolDownManager,
      this._historyDataSource
      );

  @override
  Future<Route> getRouteArrivals(String transporterId) async {
    bool isInCoolDown = await _coolDownManager.isInCoolDown(transporterId);
    var route;
    if (isInCoolDown) {
      route = _cache[transporterId] ?? Route(Way([], "??"), Way([], "??"));
    } else {
      route = await _routeArrivalFetcher.getRouteArrivals(transporterId);
      _cache[transporterId] = route;
      await _coolDownManager.saveLastCoolDown(transporterId);
    }
    await _historyDataSource.addToHistory(transporterId);
    _coolDownManager.switchLastCoolDown(transporterId);
    return route;
  }
}
