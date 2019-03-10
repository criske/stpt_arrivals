import 'dart:ui';

import 'package:collection/collection.dart';
import 'package:meta/meta.dart';
import 'package:stpt_arrivals/services/parser/time_converter.dart';

@immutable
class Arrival {
  final Station station;

  final Time time;

  final Time time2;

  const Arrival(this.station, this.time, [this.time2]);

  @override
  int get hashCode => hashValues(station, time, time2);

  @override
  bool operator ==(other) =>
      other is Arrival &&
      this.station == other.station &&
      this.time == other.time &&
      this.time2 == other.time2;

  @override
  String toString() => "Arrival:[station: $station, time1:$time, time2:$time2]";


}

@immutable
class Way {
  final List<Arrival> arrivals;

  final String name;

  const Way(this.arrivals, this.name);

  @override
  int get hashCode => name.hashCode ^ hashList(arrivals);

  @override
  bool operator ==(other) =>
      other is Way &&
      this.name == other.name &&
      ListEquality().equals(arrivals, other.arrivals);

  @override
  String toString() => "Way[arrivals:${arrivals.join(",")}, name:$name]";
}

@immutable
class Route {
  final Way way1;

  final Way way2;

  const Route(this.way1, this.way2);

  @override
  int get hashCode => hashValues(way1, way2);

  @override
  bool operator ==(other) =>
      other is Route && this.way1 == other.way1 && this.way2 == other.way2;

  @override
  String toString() => "Way:[way1:$way1, way2:$way2]";
}

@immutable
class Station {
  final int id;

  final String name;

  const Station(this.id, this.name);

  @override
  int get hashCode => hashValues(id, name);

  @override
  bool operator ==(other) =>
      other is Station && this.id == other.id && this.name == other.name;

  @override
  String toString() => "Station:[id:$id, name, $name]";
}
