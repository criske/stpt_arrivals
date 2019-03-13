enum TransporterType { tram, trolley, bus, boat }

class Transporter {
  final int id;

  final String name;

  final TransporterType type;

  const Transporter(this.id, this.name, this.type);
}
