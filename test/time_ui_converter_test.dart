import 'package:stpt_arrivals/presentation/time_ui_converter.dart';
import 'package:stpt_arrivals/services/parser/time_converter.dart';
import 'package:test_api/test_api.dart';

import 'mocks.dart';

void main(){

  test('should show right proximity colors', (){
    final timeline = TimelineTimeProvider();
    TimeUIConverterImpl converter = TimeUIConverterImpl(closeColor : 1, mediumFarColor: 2);
    final now = timeline.time();
    timeline.advance(Duration(minutes: 3));
    var time = Time(timeline.time().millisecondsSinceEpoch, timeline.diff(now).inMilliseconds, true);
    var timeUI = converter.toUI(time);
    expect(timeUI.color, 1);
    timeline.advance(Duration(minutes: 6));
    time = Time(timeline.time().millisecondsSinceEpoch, timeline.diff(now).inMilliseconds, true);
    timeUI = converter.toUI(time);
    expect(timeUI.color, 2);
  });
}