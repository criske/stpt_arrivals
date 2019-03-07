import 'package:intl/intl.dart';
import 'package:mockito/mockito.dart';
import 'package:stpt_arrivals/services/parser/time_converter.dart';
import 'package:test/test.dart';

void main() {
  TimeProvider provider;
  ArrivalTimeConverter converter;
  DateFormat format;

  setUp(() {
    format = DateFormat("yyyy-MM-dd HH:mm");
    provider = MockTimeProvider();
    converter = ArrivalTimeConverterImpl(provider);
    when(provider.time())
        .thenReturn(format.parse("2019-03-07 17:00").millisecondsSinceEpoch);
  });

  test("should get time when ':' time format is provided", () {
    final formatted = converter.toReadableTime(
        converter.toAbsoluteTime("19:00"), format.pattern);
    expect(formatted, "2019-03-07 19:00");
  });

  test("should get time when '.min' time format is provided", () {
    final formatted = converter.toReadableTime(
        converter.toAbsoluteTime("6 min."), format.pattern);
    expect(formatted, "2019-03-07 17:06");
  });

  test("should get time when '>>' time format is provided", () {
    final formatted = converter.toReadableTime(
        converter.toAbsoluteTime(">>"), format.pattern);
    expect(formatted, "2019-03-07 17:00");
  });

  test("should throw when '*' or unkown time format is provided", () {
     try{
       converter.toAbsoluteTime("*");
       fail("Should fail");
     }catch(e){}
     try{
       converter.toAbsoluteTime("foo");
       fail("Should fail");
     }catch(e){}
  });

}

class MockTimeProvider extends Mock implements TimeProvider {}
