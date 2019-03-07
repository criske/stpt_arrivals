enum Type { tram, trolley, bus, boat }

class Transporter {
  final int id;

  final Type type;

  const Transporter(this.id, this.type);
}
