import 'dart:io';

import 'package:dart_bones/dart_bones.dart';

enum DirectoryType { theHome, theConfiguration, theData }

class OsInfo {
  /// Should be replaced with [setGlobal()] to set the correct application name.
  static OsInfo _instance = OsInfo.internal('app');
  String homeDirectory = '';
  String configurationDirectory = '';
  String dataDirectory = '';
  final String applicationName;
  final String separator = Platform.pathSeparator;
  final isLinux = Platform.isLinux;
  final isAndroid = Platform.isAndroid;
  final isWindows = Platform.isWindows;
  factory OsInfo() => _instance;
  OsInfo.internal(this.applicationName, {BaseLogger? logger}) {
    if (isLinux) {
      configurationDirectory = '/etc/de.hamatoma';
      if (Platform.environment['HOME'] != null) {
        homeDirectory = Platform.environment['HOME']!;
      } else if (Platform.environment['LOGNAME'] != null) {
        homeDirectory = '/home/${Platform.environment['LOGNAME']!}';
      } else if (Platform.environment['USER'] != null) {
        homeDirectory = '/home/${Platform.environment['HOME']!}';
      } else {
        homeDirectory = '/home/currentuser';
      }
      dataDirectory = '$homeDirectory/.config/de.hamatoma';
    } else if (isWindows) {
      configurationDirectory = 'c:\\de.hamatoma';
      if (Platform.environment['LOCALAPPDATA'] != null) {
        homeDirectory = Platform.environment['LOCALAPPDATA']!;
      } else {
        homeDirectory = 'c:\\currentuser}';
      }
      dataDirectory = '$homeDirectory/de.hamatoma';
    } else if (isAndroid) {
      if (logger != null) {
        logger.error('not implemented: Android paths in OsInfo');
      }
    } else {
      if (logger != null) {
        logger.error('not implemented: unknown OS in OsInfo');
      }
    }
  }
  String pathOf(DirectoryType what, {String? node}) {
    String rc;
    switch (what) {
      case DirectoryType.theHome:
        rc = node == null ? homeDirectory : '$homeDirectory$separator$node';
        break;
      case DirectoryType.theConfiguration:
        rc = node == null
            ? configurationDirectory
            : '$configurationDirectory$separator$node';
        break;
      case DirectoryType.theData:
        rc = node == null ? dataDirectory : '$dataDirectory$separator$node';
        break;
    }
    return rc;
  }

  static void setGlobal(OsInfo info) => _instance = info;
}
