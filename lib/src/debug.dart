import 'package:flutter/foundation.dart';

const isDebugMode = kDebugMode || bool.hasEnvironment('debug');

void lDebug(Object triggerer, [Object? message = '']) {
  final prefix =
      triggerer is String ? triggerer : triggerer.runtimeType.toString();
  log(type: 'DEBUG', prefix: prefix, message: message);
}

void lError(Object triggerer, [Object? message = '']) {
  final prefix =
      triggerer is String ? triggerer : triggerer.runtimeType.toString();
  log(type: 'ERROR', prefix: prefix, message: message);
}

void log({
  required Object type,
  required Object prefix,
  required Object? message,
}) {
  if (isDebugMode) {
    // ignore: avoid_print
    print('[${type.toString().toUpperCase()}] $prefix | $message');
  }
}
