import 'dart:io';
import 'dart:math';

import 'package:dart_bones/dart_bones.dart';
import 'package:path/path.dart' as path;

import 'helper.dart';

class History {
  final int maxEntries;
  final String name;
  final String label;
  final entries = <String>[];
  bool isInitialized = false;

  /// Constructor:
  History(this.name, this.label, {this.maxEntries = 10});

  /// Adds an entry to the last recently stack with a given maximum length.
  void addEntry(String path) {
    final index = entries.indexOf(path);
    if (index >= 0) {
      entries.removeAt(index);
    }
    if (entries.length >= maxEntries) {
      entries.removeAt(entries.length - 1);
    }
    entries.insert(0, path);
  }

  List<String> asList() => entries;

  /// Reads the history from a configuration file.
  void read(Settings settings) {
    if (!isInitialized) {
      isInitialized = true;
      final count =
          min(maxEntries, settings.asInt('$name.count', defaultValue: 0) ?? 0);
      for (var ix = 0; ix < count; ix++) {
        final value = settings.asString('$name.$ix');
        if (value != null) {
          entries.add(value);
        }
      }
    }
  }

  /// Write the history into a configuration file.
  void write(Settings settings) {
    settings.addLine('$name.count=${entries.length}');
    for (var ix = 0; ix < entries.length; ix++) {
      settings.addLine('$name.$ix=${entries[ix]}');
    }
  }
}

class Settings {
  final FileSync fileSync = FileSync(globalLogger);
  final String filename;
  final variables = <String, String>{};
  final listVariables = [];

  Settings(this.filename) {
    if (File(filename).existsSync()) {
      read();
    }
  }

  void addLine(String s) {
    listVariables.add(s);
  }

  int? asInt(String key, {int? defaultValue}) {
    int? rc = defaultValue;
    final value = asString(key);
    if (value != null) {
      rc = int.tryParse(value);
      if (rc == null && defaultValue != null) {
        globalLogger.error('asInt(): unknown key $key');
      }
    }
    return rc;
  }

  String? asString(String key, {String? defaultValue}) {
    String? rc = defaultValue;
    if (variables.containsKey(key)) {
      rc = variables[key];
    }
    return rc;
  }

  void clear() {
    variables.clear();
    listVariables.clear();
  }

  void read() {
    final regExpVariable = RegExp(r'([\w.-]+)\s*=\s*(.*)');
    final lines = readAsLines(filename);
    globalLogger.log('$filename: ${lines.length} Zeilen');
    var lineNo = 0;
    for (var line in lines) {
      lineNo++;
      final matcher = regExpVariable.firstMatch(line);
      if (matcher != null) {
        final key = matcher.group(1)!;
        if (variables.containsKey(key)) {
          globalLogger.error('$filename-$lineNo: key $key already defined');
        } else {
          variables[key] = matcher.group(2)!;
        }
      }
    }
  }

  void set(String key, String value) => variables[key] = value;

  void store() {
    final content = listVariables.isNotEmpty
        ? listVariables.join('\n')
        : variables.keys.map((key) => '$key=${variables[key]}\n').join('');
    final parent = path.dirname(filename);
    final aDir = Directory(parent);
    if (!aDir.existsSync()) {
      aDir.createSync(recursive: true);
    }
    fileSync.toFile(filename, content);
  }
}
