import 'dart:convert';

import 'package:stpt_arrivals/models/transporter.dart';

class TransporterEncoder {
  static const _map_id = "id";
  static const _map_name = "name";
  static const _map_fav = "fav";
  static const _map_type = "type";

  String encodeJSON(List<Transporter> transporters) {
    final mappedTransporters = transporters
        .map((t) =>
    {
      _map_id: t.id,
      _map_name: t.name,
      _map_type: t.type.index,
      _map_fav: t.isFavorite ? 1 : 0
    })
        .toList(growable: false);
    return jsonEncode(mappedTransporters);
  }

  List<Transporter> decodeJSON(String json) {
    return (jsonDecode(json) as List).map((m) {
      return Transporter(m[_map_id], m[_map_name],
          TransporterType.values[m[_map_type]],
          m[_map_fav] == 1 ? true : false);
    }).toList();
  }
}
