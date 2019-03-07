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
    var formatted = converter.toReadableTime(
        converter.toAbsoluteTime("6 min."), format.pattern);
    expect(formatted, "2019-03-07 17:06");
    formatted = converter.toReadableTime(
        converter.toAbsoluteTime("66 min."), format.pattern);
    expect(formatted, "2019-03-07 18:06");
  });

  test("should get time when '>>' time format is provided", () {
    final formatted = converter.toReadableTime(
        converter.toAbsoluteTime(">>"), format.pattern);
    expect(formatted, "2019-03-07 17:00");
  });

  test("should get 0 when '*' or unkown time format is provided", () {
    expect(converter.toAbsoluteTime("*"), 0);
    expect(converter.toAbsoluteTime("foo"), 0);
  });
}

class MockTimeProvider extends Mock implements TimeProvider {}
