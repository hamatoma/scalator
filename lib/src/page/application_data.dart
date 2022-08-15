import 'dart:io';

import 'package:dart_bones/dart_bones.dart';
import 'package:flutter/material.dart';

import '../helper/file_supplier_async.dart';
import '../helper/settings.dart';
import '../helper/os_info.dart';
import '../page/page_controller_collector.dart';
import '../setting/collector_app_bar.dart';
import '../setting/collector_drawer.dart';
import '../setting/collector_footer.dart';

typedef AppBarBuilder = Function(String);

typedef DrawerBuilder = Function(dynamic);

typedef FooterBuilder = FooterInterface Function();

/// Speicherung globaler Resourcen. Ist ein Singleton.
class ApplicationData implements ErrorHandlerCollector {
  static ApplicationData? _instance;
  final BaseConfiguration configuration;
  final BaseLogger logger;
  static const applicationVersion = '1.0.0';

  /// Signature: AppBar func(String title)
  final AppBarBuilder appBarBuilder;
  final DrawerBuilder drawerBuilder;
  final FooterBuilder footerBuilder;
  DirInfo sourceDirectory = DirInfo('Quellverzeichnis', Directory.current.path);
  DirInfo targetDirectory =
      DirInfo('Zielverzeichnis', Directory.systemTemp.path);
  String? extensions;
  final messageController = TextEditingController();
  ImageDimensions portrait = ImageDimensions(800, 600);
  ImageDimensions landscape = ImageDimensions(800, 600);
  ImageDimensions square = ImageDimensions(600, 600);
  int quality = 75;
  bool recursive = false;
  bool isRunning = false;
  PageControllerCollector? currentPageController;
  final listLines = <String>[];
  int maxListLines = 200;
  int convertedBytes = 0;
  int processedBytes = 0;
  int processedFiles = 0;
  int copiedFiles = 0;
  FileSupplierAsync? currentSupplier;
  final historySources = History('sources', 'Historie Quellverzeichnis');
  final historyTargets = History('targets', 'Historie Zielverzeichnis');
  final historyRanges = History('ranges', 'Historie Format');
  Settings settings = Settings('');

  /// <page_full_name>: <last_error_message>
  final _lastErrorMessageMap = <String, String>{};

  String rootDirectory =
      Directory.systemTemp.path.startsWith('/') ? '/' : 'c:\\';

  factory ApplicationData() => _instance!;

  /// [configuration]: allgemeine Konfigurationen
  /// [appBarBuilder] eine "Factory" zur Erzeugung des "Hamburger-Menüs"
  /// [footerBuilder] eine "Factory" zur Erzeugung des Footer-Bereichs
  ApplicationData.internal(this.configuration, this.appBarBuilder,
      this.drawerBuilder, this.footerBuilder, this.logger) {
    final osInfo = OsInfo();
    final theDir = configuration.asString('history.directory',
            defaultValue: osInfo.pathOf(DirectoryType.theData)) ??
        '';
    final thePath = '$theDir${osInfo.separator}scalator.history.txt';
    settings = Settings(thePath);
    var value = settings.asString('sources.0');
    if (value != null) {
      sourceDirectory.path = value;
    }
    value = settings.asString('targets.0');
    if (value != null) {
      targetDirectory.path = value;
    }
  }

  /// Resets the statistic data.
  void clear() {
    listLines.clear();
    convertedBytes = 0;
    processedBytes = 0;
    processedFiles = 0;
    copiedFiles = 0;
  }

  @override
  bool criticalError(String errorMessage,
      {String? caller, String? customParameter}) {
    if (caller != null && caller == 'RestPersistance.runRequest') {
      if (errorMessage.contains('SocketException: OS Error')) {
        setLastErrorMessage(null, 'Keine Verbindung zum Server');
      }
    }
    return false;
  }

  /// Liefert den letzten schweren Fehler von Seite [page] oder null.
  String? lastErrorMessage(String page) {
    final rc = _lastErrorMessageMap.containsKey(page)
        ? _lastErrorMessageMap[page]
        : null;
    return rc;
  }

  /// Speichert den letzten Fehler der [page]. [message] kann null sein (kein Fehler).
  /// Wenn [page] null: Die aktuelle Seite wird genommen.
  void setLastErrorMessage(String? page, String message) {
    if (page == null && currentPageController != null) {
      page = currentPageController!.pageName;
    }
    if (page != null) {
      _lastErrorMessageMap[page] = message;
    }
  }

  void readHistories() {
    historyRanges.read(settings);
    historySources.read(settings);
    historyTargets.read(settings);
    if (historyRanges.entries.length < 3) {
      historyRanges.addEntry('1920x1080');
      historyRanges.addEntry('1024x768');
      historyRanges.addEntry('800x600');
    }
  }

  void storeHistories() {
    settings.clear();
    historySources.write(settings);
    historyTargets.write(settings);
    historyRanges.write(settings);
    settings.store();
  }

  /// Adds a line to the listbox.
  void toList(String line) {
    if (listLines.length >= maxListLines) {
      listLines.removeAt(0);
    }
    listLines.add(line);
  }

  static ApplicationData create(
      BaseConfiguration configuration, BaseLogger logger) {
    _instance = ApplicationData.internal(configuration, CollectorAppBar.builder,
        CollectorDrawer.builder, CollectorFooter.builder, logger);
    return _instance!;
  }
}

class DirInfo {
  final String label;
  String? path;

  DirInfo(this.label, this.path);
}

abstract class ErrorHandlerCollector {
  /// Handles a critical error: "translate" a technical message into a user
  /// readable message...
  /// Returns false (for chaining)
  bool criticalError(String errorMessage,
      {String caller, String customParameter});
}

abstract class FooterInterface {
  Widget widget(PageControllerCollector controller);
}

class ImageDimensions {
  static final regExpr = RegExp(r'(\d+)\s*x\s*(\d+)');
  final int maxWidth;
  final int maxHeight;

  ImageDimensions(this.maxWidth, this.maxHeight);

  ImageDimensions.fromString(String input)
      : this(int.parse(regExpr.firstMatch(input)!.group(1)!),
            int.parse(regExpr.firstMatch(input)!.group(2)!));
}

enum Layout { aPortrait, aLandscape, aSquare }

enum RedrawReason {
  custom,
  callback,
  fetchList,
  fetchRecord,
  redraw,
  setError,
}
