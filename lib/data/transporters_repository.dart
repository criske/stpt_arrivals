import 'dart:async';

import 'package:rxdart/rxdart.dart';
import 'package:stpt_arrivals/data/favorites_data_source.dart';
import 'package:stpt_arrivals/data/history_data_source.dart';
import 'package:stpt_arrivals/data/hit_data_source.dart';
import 'package:stpt_arrivals/data/transporters_data_source.dart';
import 'package:stpt_arrivals/models/transporter.dart';
import 'package:stpt_arrivals/services/transporters_type_fetcher.dart';

abstract class TransportersRepository {
  Stream<List<Transporter>> streamAll();

  Stream<List<Transporter>> streamAllByType(TransporterType type);

  Stream<List<Transporter>> streamAllByFavorites();

  Stream<List<Transporter>> streamAllContaining(String input);

  Stream<List<Transporter>> streamHistory();

  Future<Transporter> findById(String transporterId);

  Future<void> save(List<Transporter> transporters);

  Future<void> update(Transporter transporter);
}

class TransportersRepositoryImpl implements TransportersRepository {
  FavoritesDataSource _favoritesDataSource;

  TransportersDataSource _transportersDataSource;

  HistoryDataSource _historyDataSource;

  HitDataSource _hitDataSource;

  TransportersTypeFetcher _transportersTypeFetcher;

  TransportersRepositoryImpl(
      this._favoritesDataSource,
      this._transportersDataSource,
      this._historyDataSource,
      this._hitDataSource,
      this._transportersTypeFetcher);

  @override
  Stream<List<Transporter>> streamAll() {
    return Observable.combineLatest([
      Observable(_transportersDataSource.streamAll()),
      Observable(_favoritesDataSource.streamAll()),
      Observable(_hitDataSource.streamAll())
    ], (sources) {
      final transporters = sources[0] as List<Transporter>;
      if (transporters.isEmpty) {
        return transporters;
      } else {
        final favIds = sources[1] as Set<String>;
        final transportersWithFav = List<Transporter>();
        transporters.forEach((t) {
          transportersWithFav.add(favIds.contains(t.id) ? t.favorite(true) : t);
        });
        final hitIds = sources[2] as Set<Hit>;
        return _sortByHits(transportersWithFav, hitIds);
      }
    }).switchMap((transporters) {
      if (transporters.isEmpty) {
        return Observable.fromFuture(_getAllRemote())
            .doOnData((remoteTransporters) async {
          _transportersDataSource.save(remoteTransporters);
        });
      } else {
        return Observable.just(transporters);
      }
    }).share();
  }

  List<Transporter> _sortByHits(List<Transporter> l, Set<Hit> hits) {
    //todo: 2*n^2  un-efficient algorithm ahead
    final out = List<Transporter>();
    final leftOut = l
        .where((t) =>
            hits.firstWhere((h) => h.transporterId == t.id,
                orElse: () => null) ==
            null)
        .toList();
    hits.forEach((h) {
      final transporterHit =
          l.firstWhere((t) => h.transporterId == t.id, orElse: () => null);
      if (transporterHit != null) {
        out.add(transporterHit);
      }
    });
    out.addAll(leftOut);
    return out;
  }

  Future<List<Transporter>> _getAllRemote() async {
    final buses =
        await _transportersTypeFetcher.fetchTransporters(TransporterType.bus);
    final trams =
        await _transportersTypeFetcher.fetchTransporters(TransporterType.tram);
    final trolleys = await _transportersTypeFetcher
        .fetchTransporters(TransporterType.trolley);
    return [buses, trams, trolleys].expand((t) => t).toList();
  }

  @override
  Stream<List<Transporter>> streamAllContaining(String input) =>
      streamAll().map((l) => input.isEmpty
          ? l
          : l
              .where((t) =>
                  t.name.toLowerCase().contains(input.toLowerCase().trim()))
              .toList());

  @override
  Stream<List<Transporter>> streamAllByFavorites() =>
      streamAll().map((l) => l.where((l) => l.isFavorite).toList());

  @override
  Stream<List<Transporter>> streamAllByType(TransporterType type) =>
      streamAll().map((l) => l.where((l) => l.type == type).toList());

  @override
  Stream<List<Transporter>> streamHistory() {
    return Observable.combineLatest(
        [streamAll(), _historyDataSource.streamAll()], (sources) {
      final transporters = sources[0] as List<Transporter>;
      if (transporters.isEmpty) {
        return transporters;
      } else {
        final historyIds = sources[1] as List<String>;
        final transportersWithHistory = List<Transporter>();
        historyIds.forEach((id) {
          final t = transporters.firstWhere((t) => t.id == id, orElse: null);
          if (t != null) {
            transportersWithHistory.add(t);
          }
        });
        return transportersWithHistory;
      }
    });
  }

  @override
  Future<void> save(List<Transporter> transporters) async {
    await _transportersDataSource.save(transporters);
  }

  @override
  Future<void> update(Transporter transporter) async {
    if (transporter.isFavorite) {
      await _favoritesDataSource.insert(transporter.id);
    } else {
      await _favoritesDataSource.delete(transporter.id);
    }
  }

  @override
  Future<Transporter> findById(String transporterId) async =>
      _transportersDataSource.findById(transporterId);
}
