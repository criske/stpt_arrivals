import 'dart:async';

import 'package:meta/meta.dart';
import 'package:stpt_arrivals/data/favorites_data_source.dart';
import 'package:stpt_arrivals/models/error.dart';
import 'package:stpt_arrivals/models/transporter.dart';

abstract class TransporterRepository {
  Future<List<Transporter>> findAll();

  Future<List<Transporter>> findAllByType(TransporterType type);

  Future<List<Transporter>> findAllByFavorites();

  Future<void> save(List<Transporter> transporters);

  Future<void> update(Transporter transporter);
}

class TransporterRepositoryImpl implements TransporterRepository {
  List<Transporter> _transporters = List<Transporter>();

  FavoritesDataSource _favoritesDataSource;

  TransporterRepositoryImpl(this._favoritesDataSource);

  bool _isSynced = false;

  TransporterRepositoryImpl.withData(FavoritesDataSource favDs, List<Transporter> data)
      : _transporters = data.toList(),
        _favoritesDataSource = favDs;

  @override
  Future<List<Transporter>> findAll() async {
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
  Future<List<Transporter>> findAllByFavorites() async {
    //todo use "when" for the functional approach?
    final out = List<Transporter>();
    _transporters.forEach((t) {
      if (t.isFavorite) {
        out.add(t);
      }
    });
    return out;
  }

  @override
  Future<List<Transporter>> findAllByType(TransporterType type) async {
    //todo use "when" for the functional approach?
    final out = List<Transporter>();
    _transporters.forEach((t) {
      if (t.type == type) {
        out.add(t);
      }
    });
    return out;
  }

  @override
  Future<void> save(List<Transporter> transporters) async {
    _transporters.clear();
    _transporters.addAll(transporters);
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
