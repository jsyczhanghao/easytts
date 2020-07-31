import 'dart:async';

import 'package:flutter/services.dart';

// didCancelSpeechUtterance:已经取消说话
// didContinueSpeechUtterance:已经继续说话
// didFinishSpeechUtterance: 已经说完
// didPauseSpeechUtterance:已经暂停
// didStartSpeechUtterance:已经开始
// willSpeakRangeOfSpeechString将要说某段话

enum EasyttsEvent {
  SPEAKING,
  PAUSE,
  CANCEL,
  FINISH,
  RESUME,
  WILL,
}


class Easytts {
  static final MethodChannel _channel = const MethodChannel('easytts')..setMethodCallHandler(_handleMethodCall);
  static List<Function(EasyttsEvent, [dynamic])> listeners = List();

  static Future<String> get platformVersion async {
    final String version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }

  static Future<bool> isLanguageAvailable(String language) async {
    final bool languageAvailable = await _channel.invokeMethod(
        'isLanguageAvailable', <String, Object>{'language': language});
    return languageAvailable;
  }

  static Future<bool> setLanguage(String language) async {
    final bool isSet = await _channel
        .invokeMethod('setLanguage', <String, Object>{'language': language});
    return isSet;
  }

  static Future<List<String>> getAvailableLanguages() =>
      _channel.invokeMethod('getAvailableLanguages').then((result) {
        return result.cast();
      });

  static void speak(String text) {
    _channel.invokeMethod('speak', {'text': text});
  }

  static void pause() async {
    _channel.invokeMethod('pause');
  }

  static void resume() async {
    _channel.invokeMethod('resume');
  }

  static void stop() async {
    _channel.invokeMethod('stop');
  }

  static void shutdown() async {
    _channel.invokeMethod('shutdown');
  }

  static void setSpeechRate(double rate) async {
    _channel.invokeMethod(
        'setSpeechRate', <String, Object>{'rate': rate.toString()});
  }

  static Future<dynamic> _handleMethodCall(MethodCall methodCall) {
    EasyttsEvent event;

    switch(methodCall.method) {
      case 'onComplete':
        event = EasyttsEvent.FINISH;
        break;

      case 'onSpeak':
        event = EasyttsEvent.SPEAKING;
        break;

      case 'onPause':
        event = EasyttsEvent.PAUSE;
        break;

      case 'onResume':
        event = EasyttsEvent.RESUME;
        break;

      case 'onCancel':
        event = EasyttsEvent.CANCEL;
        break;

      case 'onWill':
        event = EasyttsEvent.WILL;
        break;
    }

    for (Function listener in listeners) {
      listener(event, methodCall.arguments);
    }
  }

  static on(Function(EasyttsEvent, [dynamic]) listener) {
    listeners.add(listener);
  }

  static off(Function(EasyttsEvent, [dynamic]) listener) {
    listeners.remove(listener);
  }
}
