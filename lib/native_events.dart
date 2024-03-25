import 'dart:async';

import 'package:flutter/services.dart';

/// Main plugin class
class NativeEvent {
  static const MethodChannel methodChannel = MethodChannel('nativeEvent');
  static const EventChannel _eventChannel = EventChannel('timeHandlerEvent');

  /// The event channel you can subscribe to with
  /// Chime.eventChannel.receiveBroadcastStream().listen()
  static EventChannel get eventChannel => _eventChannel;

  static final StreamController<int> _dateTimeStreamController = StreamController<int>.broadcast();

  /// Notification received
  static Stream<int> get onNativeEvent => _dateTimeStreamController.stream;

  static Future<void> initializeChannel() async {
    methodChannel.setMethodCallHandler(_methodHandler);
  }

  static Future<void> _methodHandler(MethodCall call) async {
    final arg = call.arguments;
    switch (call.method) {
      case "dateTimeHandler":
        _dateTimeStreamController.add(arg);
        break;
      default:
        print('No method handler for method:: ${call.method}');
    }
  }
}
