import 'dart:ui';

import 'package:meta/meta.dart';

enum TransporterType { tram, trolley, bus, boat }

@immutable
class Transporter {
  final int id;

  final String name;

  final TransporterType type;

  final bool isFavorite;

  const Transporter(this.id, this.name, this.type, [this.isFavorite = false]);

  Transporter toggleFavorite() => Transporter(id, name, type, !isFavorite);

  Transporter favorite(bool newFavorite) => Transporter(id, name, type, newFavorite);

  @override
  String toString() =>
      "Transporter[id:$id, name:$name, type:$type, favorite:$isFavorite]";

  @override
  int get hashCode => hashValues(id, name, type, isFavorite);

  @override
  bool operator ==(other) =>
      other is Transporter &&
      id == other.id &&
      name == other.name &&
      type == other.type &&
      isFavorite == other.isFavorite;
}
