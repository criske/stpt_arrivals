import 'package:html/dom.dart';
import 'package:html/parser.dart' as html;
import 'package:stpt_arrivals/models/transporter.dart';

abstract class TransporterParser {
  List<Transporter> parse(TransporterType type, String rawData);
}

class TransporterParserImpl implements TransporterParser {
  @override
  List<Transporter> parse(TransporterType type, String rawData) {
    return html
        .parse(rawData)
        .getElementsByTagName("a")
        .map((a) => Transporter(_extractId(a), _extractName(a, type), type))
        .toList();
  }

  String _extractId(Element a) {
    var attribute = a.attributes["onclick"];
    try {
      return attribute.split("param1=")[1].split('\'')[0];
    } catch (e) {
      return attribute
          .split("parent.dreapta1.location.href=")[1]
          .split('.php')[0]
          .split('\'')[1];
    }
  }

  String _extractName(Element a, TransporterType type) {
    var splitter;
    switch (type) {
      case TransporterType.bus:
        splitter = "auto";
        break;
      case TransporterType.tram:
        splitter = "tram";
        break;
      case TransporterType.trolley:
        splitter = "trol";
        break;
      default:
        throw Exception("Not implemented parser for $type");
    }
    return a
        .querySelector("img")
        .attributes["src"]
        .split(".")[0]
        .split(splitter)[1]
        .toUpperCase();
  }
}
