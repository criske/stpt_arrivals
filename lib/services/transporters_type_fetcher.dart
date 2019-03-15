import 'package:http/http.dart';
import 'package:stpt_arrivals/models/transporter.dart';
import 'package:stpt_arrivals/services/parser/transporter_parser.dart';
import 'package:stpt_arrivals/services/remote_config.dart';

abstract class TransportersTypeFetcher {
  Future<List<Transporter>> fetchTransporters(TransporterType type);
}

class TransportersTypeFetcherImpl implements TransportersTypeFetcher {

  RemoteConfig _config;

  Client _client;

  TransporterParser _parser;

  TransportersTypeFetcherImpl(this._config, this._client, this._parser);

  @override
  Future<List<Transporter>> fetchTransporters(TransporterType type) async {
    final url = _config.transportersURL(type);
    final response = await _client.get(url);
    if (response.statusCode == 200) {
      return _parser.parse(type, response.body);
    } else {
      throw Exception(response.statusCode);
    }
  }
}
