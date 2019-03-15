import 'package:stpt_arrivals/data/transporter_encoder.dart';
import 'package:stpt_arrivals/models/transporter.dart';
import 'package:test_api/test_api.dart';

void main(){

  final list = [
    Transporter("1", "foo1", TransporterType.bus),
    Transporter("2", "foo2", TransporterType.tram),
  ];

  test("should encode and decode json", (){
    var encoder = TransporterEncoder();
    var json = encoder.encodeJSON(list);
    expect(encoder.decodeJSON(json), list);
  });


}