// http://86.125.113.218:61978/html/timpi/first.php
import 'package:stpt_arrivals/models/transporter.dart';

var BASE_URL = Uri.http("86.125.113.218:61978", "");

abstract class RemoteConfig {
  Uri baseURL;

  Uri routeURL(String transporterId);

  Uri routeURLSpecialId(String transporterId);

  Uri transportersURL(TransporterType type);
}

class RemoteConfigImpl implements RemoteConfig {

  @override
  var baseURL = BASE_URL;

  @override
  Uri routeURL(String transporterId) => BASE_URL.replace(
      path: "html/timpi/trasee.php",
      queryParameters: {"param1": transporterId});

  @override
  Uri routeURLSpecialId(String specialId) => BASE_URL.replace(
      path: "html/timpi/$specialId.php"
  );

  @override
  Uri transportersURL(TransporterType type) {
    var page;
    switch (type) {
      case TransporterType.bus:
        page = "auto.php";
        break;
      case TransporterType.tram:
        page = "tram.php";
        break;
      case TransporterType.trolley:
        page = "trol.php";
        break;
      case TransporterType.boat:
        page = "boat.php";
        break;
    }
    return BASE_URL.replace(path: "html/timpi/$page");
  }
}
