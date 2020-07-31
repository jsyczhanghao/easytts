import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:easytts/easytts.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _platformVersion = 'Unknown';

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    String platformVersion;
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      platformVersion = await Easytts.platformVersion;
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
    }

    Easytts.on((EasyttsEvent event, [dynamic data]) {
      print(event);
      print(data);
    });
    Easytts.setLanguage('zh-CN');
    String str = '发动机开发，的收款方几点开始。复健科电视剧非看电视今飞，凯达几十块附近的时\n刻复健科电视剧。非看电视讲课费的就是，hello！';
    int len = str.length;
    Easytts.speak(str);

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _platformVersion = platformVersion;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Center(
          child: Text('Running on: $_platformVersion\n'),
        ),
      ),
    );
  }
}
