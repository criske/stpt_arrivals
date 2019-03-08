class Arrival {
  final Station station;

  final int time;

  final int time2;

  const Arrival(this.station, this.time, [this.time2 = 0]);
}

class Way {
  final List<Arrival> arrivals;

  final String way;

  const Way(this.arrivals, this.way);
}

class Route {
  final Way way1;

  final Way way2;

  const Route(this.way1, this.way2);
}

class Station {
  final int id;

  final String name;

  const Station(this.id, this.name);
}
