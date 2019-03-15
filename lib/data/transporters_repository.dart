import 'dart:async';

import 'package:stpt_arrivals/data/favorites_data_source.dart';
import 'package:stpt_arrivals/data/transporters_data_source.dart';
import 'package:stpt_arrivals/models/error.dart';
import 'package:stpt_arrivals/models/transporter.dart';
import 'package:stpt_arrivals/services/transporters_type_fetcher.dart';

abstract class TransportersRepository {
  Future<List<Transporter>> findAll();

  Future<List<Transporter>> findAllByType(TransporterType type);

  Future<List<Transporter>> findAllByFavorites();

  Future<void> save(List<Transporter> transporters);

  Future<void> update(Transporter transporter);
}

class TransportersRepositoryImpl implements TransportersRepository {
  List<Transporter> _transporters = List<Transporter>();

  FavoritesDataSource _favoritesDataSource;

  TransportersDataSource _transportersDataSource;

  TransportersTypeFetcher _transportersTypeFetcher;

  TransportersRepositoryImpl(this._favoritesDataSource,
      this._transportersDataSource, this._transportersTypeFetcher);

  bool _isSynced = false;

  TransportersRepositoryImpl.withData(
      FavoritesDataSource favDs, List<Transporter> data)
      : _transporters = data.toList(),
        _favoritesDataSource = favDs;

  @override
  Future<List<Transporter>> findAll() async {
    if (_transporters.isEmpty) {
      final localTransporters = await _transportersDataSource.findAll();
      if (localTransporters.isEmpty) {
        final buses = await _transportersTypeFetcher
            .fetchTransporters(TransporterType.bus);
        final trams = await _transportersTypeFetcher
            .fetchTransporters(TransporterType.tram);
        final trolleys = await _transportersTypeFetcher
            .fetchTransporters(TransporterType.trolley);

        final remoteTransporters = [buses, trams, trolleys].expand((t) => t).toList();

        await _transportersDataSource.save(remoteTransporters);
        _transporters = remoteTransporters;
      } else {
        _transporters = localTransporters;
      }
    }
    if (!_isSynced) {
      final favIds = await _favoritesDataSource.getAll();
      final updatedTransporters = List<Transporter>();
      _transporters.forEach((t) {
        updatedTransporters.add(favIds.contains(t.id) ? t.favorite(true) : t);
      });
      _isSynced = true;
      _transporters = updatedTransporters;
    }
    return List.unmodifiable(_transporters);
  }

  @override
  Future<List<Transporter>> findAllByFavorites() async =>
      _transporters.where((t) => t.isFavorite).toList();

  @override
  Future<List<Transporter>> findAllByType(TransporterType type) async =>
      _transporters.where((t) => t.type == type).toList();

  @override
  Future<void> save(List<Transporter> transporters) async {
    _transporters.clear();
    _transporters.addAll(transporters);
    _transportersDataSource.save(transporters);
  }

  @override
  Future<void> update(Transporter transporter) async {
    final index = _transporters.indexWhere((t) => t.id == transporter.id);
    if (index == -1) throw MessageError("Transporter not found");
    final oldTransporter = _transporters[index];
    if (oldTransporter.isFavorite != transporter.isFavorite) {
      if (transporter.isFavorite) {
        await _favoritesDataSource.insert(transporter.id);
      } else {
        await _favoritesDataSource.delete(transporter.id);
      }
    }
    _transporters.removeAt(index);
    _transporters.insert(index, transporter);
  }
}
