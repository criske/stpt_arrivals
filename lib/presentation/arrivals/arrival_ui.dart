import 'dart:ui';

import 'package:flutter/material.dart';



class ErrorUI extends Error {
  final String message;
  final bool canRetry;

  ErrorUI(this.message, [this.canRetry = false]);
}

class ArrivalUI {
  final String stationId;
  final String stationName;
  final TimeUI time1;
  final TimeUI time2;
  final bool pinned;

  ArrivalUI(this.stationId, this.stationName, this.time1, this.time2, this.pinned);

  static final ArrivalUI noArrival = ArrivalUI("", "", TimeUI.none(), TimeUI.none(), false);

}

class TimeUI {
  final String value;
  final int color;
  final int backgroundColor;

  const TimeUI(this.value, [this.color = 0xFF000000, this.backgroundColor = 0x00FFFFFF]);

  factory TimeUI.none([String nonValue = "**:**"]) => TimeUI(nonValue);
}
