import 'dart:io';
import 'package:dart_bones/dart_bones.dart';
import 'package:flutter/material.dart';

import 'src/helper/os_info.dart';
import 'src/page/application_data.dart';
import 'src/page/page_scalator.dart';

class ScalatorApp extends StatefulWidget {
  @override
  ScalatorAppState createState() {
    final logger = MemoryLogger(LEVEL_SUMMERY);
    OsInfo.setGlobal(OsInfo.internal('scalator', logger: logger));
    final osInfo = OsInfo();
    String history = osInfo.pathOf(DirectoryType.theData);
    final mapWidgetData = <String, dynamic>{
      'form.card.padding': '16.0',
      'form.gap.field_button.height': '16.0',
      'history.directory': history
    };
    final configFile =
        osInfo.pathOf(DirectoryType.theConfiguration, node: 'scalator.conf');
    final configuration = File(configFile).existsSync()
        ? BaseConfiguration(mapWidgetData, logger)
        : Configuration.fromFile(configFile, logger);
    ApplicationData.create(configuration, logger);
    return ScalatorAppState();
  }
}

class ScalatorAppState extends State<ScalatorApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: true,
      title: 'Flutter Collector Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      initialRoute: '/collection',
      //initialRoute: '/async',
      onGenerateRoute: _getRoute,
    );
  }
}

Route<dynamic> _getRoute(RouteSettings settings) {
  MaterialPageRoute? route;
  StatefulWidget? page;
  switch (settings.name) {
    case '/collection':
      page = PageScalator(ApplicationData());
      break;
  }
  if (page != null) {
    route = MaterialPageRoute<void>(
      settings: settings,
      builder: (BuildContext context) => page!,
      fullscreenDialog: false,
    );
  } else {
    route = MaterialPageRoute<void>(
      settings: settings,
      builder: (BuildContext context) => PageScalator(ApplicationData()),
      fullscreenDialog: false,
    );
  }
  return route;
}
