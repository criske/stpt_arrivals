import 'dart:async';

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

  TransporterRepositoryImpl();

  TransporterRepositoryImpl.withData(List<Transporter> data)
      : _transporters = data.toList();

  @override
  Future<List<Transporter>> findAll() async {
    return List.unmodifiable(_transporters);
  }

  @override
  Future<List<Transporter>> findAllByFavorites() async {
    //todo takeWhile not working?
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
    //todo takeWhile not working?
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
    _transporters.removeAt(index);
    _transporters.insert(index, transporter);
  }
}
