import 'dart:ui';

import 'package:flutter/material.dart';



class ErrorUI extends Error {
  final String message;
  final bool canRetry;

  ErrorUI(this.message, [this.canRetry = false]);
}

class ArrivalUI {
  final int stationId;
  final String stationName;
  final TimeUI time1;
  final TimeUI time2;

  ArrivalUI(this.stationId, this.stationName, this.time1, this.time2);

}

class TimeUI {
  final String value;
  final int color;

  const TimeUI(this.value, [this.color = 0xFF000000]);

  factory TimeUI.none([String nonValue = "**:**"]) => TimeUI(nonValue);
}
