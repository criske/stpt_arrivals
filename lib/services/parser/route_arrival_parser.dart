import 'package:html/dom.dart';
import 'package:html/parser.dart' as html;
import 'package:stpt_arrivals/models/arrival.dart';

import 'time_converter.dart';

abstract class RouteArrivalParser {
  Route parse(String rawData);
}

class RouteArrivalParserImpl implements RouteArrivalParser {
  ArrivalTimeConverter _timeConverter;

  RouteArrivalParserImpl(this._timeConverter);

  @override
  Route parse(String rawData) {
    final doc = html.parse(rawData);

    final tables = doc.getElementsByTagName("table");

    Way way1;
    Way way2;
    Way currentWay;
    var wayCount = 0;

    tables.forEach((Element t) {
      final isWay = t.attributes.containsKey("style");
      if (isWay) {
        if (wayCount == 0) {
          way1 = Way(List<Arrival>(), _extractTextFromColumn(t, 0).split("spre")[1].trim());
          currentWay = way1;
        } else {
          way2 = Way(List<Arrival>(), _extractTextFromColumn(t, 0).split("spre")[1].trim());
          currentWay = way2;
        }
        wayCount++;
      } else if (!_isHeader(t)) {
        final arrival = Arrival(Station(0, _extractTextFromColumn(t, 0)),
            _timeConverter.toTime(_extractTextFromColumn(t, 1)));
        currentWay.arrivals.add(arrival);
      }
    });

    final way1PrettyDir = "${way2.name}\u{2192}${way1.name}";
    final way2PrettyDir = "${way1.name}\u{2192}${way2.name}";
    return Route(Way(way1.arrivals, way1PrettyDir), Way(way2.arrivals, way2PrettyDir));
  }

  bool _isHeader(Element t) => _extractTextFromColumn(t, 1).trim() == "Sosire";

  String _extractTextFromColumn(Element table, int index) => table
      .getElementsByTagName("td")[index]
      .getElementsByTagName("b")
      .first
      .text
      .trim();
}
