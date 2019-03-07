// http://86.125.113.218:61978/html/timpi/first.php
var BASE_URL = Uri.http("86.125.113.218:61978", "");

abstract class RemoteConfig {
  Uri baseURL;

  Uri arrivalURL(int transporterId);
}

class RemoteConfigImpl implements RemoteConfig {
  @override
  var baseURL = BASE_URL;

  @override
  Uri arrivalURL(int transporterId) =>
      BASE_URL.replace(
          path: "html/timpi/trasee.php",
          queryParameters: { "param1": transporterId.toString()}
      );
}
