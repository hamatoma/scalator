import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart';
import 'package:sprintf/sprintf.dart';

/// Tests whether a file named [filename] is a binary file.
/// Returns true if ASCII control characters lower than ' ' are greater than 25%
bool isBinary(String filename) {
  final file = File(filename);
  var rc = false;
  if (file.existsSync()) {
    final handle = file.openSync();
    final buffer = handle.readSync(4096);
    handle.close();
    var countControl = 0;
    for (var ix = 0; ix < buffer.lengthInBytes; ix++) {
      final byte = buffer[ix];
      if (byte == 0) {
        rc = true;
        break;
      }
      if (byte < 8 /* TAB */ || byte > 13 /* LF */ && byte < 32 /* ' '*/) {
        countControl++;
      }
    }
    rc = rc || countControl * 4 > buffer.lengthInBytes;
  }
  return rc;
}

/// Converts a string [value] into an int.
/// Returns null on null or invalid numbers.
int? intValue(String value) {
  return int.tryParse(value);
}

/// Returns the content of a file named [filename] as string.
String readAsString(String filename) {
  final rc = File(filename).readAsStringSync();
  return rc;
}

/// Returns the content of a file named [filename] as list of lines.
List<String> readAsLines(String filename) {
  final rc = File(filename).readAsLinesSync();
  return rc;
}

/// Escapes all meta characters in [string] for a regular expression string.
/// Returns [string] with all meta characters escaped by a preceding backslash.
/// Note: the algorithm is taken from the Python standard library.
String? regExpEscape(String? string) {
  String? rc;
  if (string != null) {
    rc = '';
    for (var ii = 0; ii < string.length; ii++) {
      final cc = string[ii];
      if ('()[]{}?*+-|^\$\\.&~# \t\n'.contains(cc)) {
        rc = rc! + r'\';
      }
      rc = rc! + cc;
    }
  }
  return rc;
}

/// Returns a human readable string of a given file size.
String humanSize(int bytes) {
  String rc;
  if (bytes > 1000000000) {
    rc = sprintf("%.3f GByte", [bytes / 10E9]);
  } else if (bytes >= 1000000) {
    rc = sprintf("%.3f MByte", [bytes / 10E6]);
  } else if (bytes >= 1000) {
    rc = sprintf("%.3f KByte", [bytes / 10E3]);
  } else {
    rc = sprintf("%d Byte", [bytes]);
  }
  return rc;
}

/// Translates a unix shell pattern into a regular expression pattern.
/// Example: '*.txt' is translated into r'.*\.txt'
/// Note: the algorithm is a simplified version of the algorithm in the Python standard library.
/// [addBeginOfString]: true: the result starts with '^'.
/// [addEndOfString]: true: the result ends with r'$'.
String shellPatternToRegExp(String pattern,
    {bool addBeginOfString = true, bool addEndOfString = true}) {
  String? rc;
  var i = 0;
  var length = pattern.length;
  rc = '';
  while (i < length) {
    final c = pattern[i++];
    if (c == '*') {
      rc = '${rc!}.*';
    } else if (c == '?') {
      rc = '${rc!}.';
    } else if (c == '[') {
      var j = i;
      if (j < length && pattern[j] == '!') {
        j++;
      }
      if (j < length && pattern[j] == ']') {
        j++;
      }
      while (j < length && pattern[j] != ']') {
        j++;
      }
      if (j >= length) {
        rc = rc! + r'\[' + pattern.substring(i);
        break;
      }
      var stuff = pattern.substring(i, j);
      if (stuff[0] == '!') {
        stuff = '^${stuff.substring(1)}';
      }
      stuff = stuff.replaceAll(r'\', r'\\').replaceAll(']', r'\]');
      rc = '${rc!}[$stuff]';
      i = j + 1;
    } else {
      rc = rc! + (regExpEscape(c) ?? '');
    }
  }
  if (addBeginOfString) {
    rc = '^${rc!}';
  }
  if (addEndOfString) {
    rc = rc! + r'$';
  }
  return rc!;
}

/// Tests whether the [options] are integers. If not the callback usage is called.
/// Returns true if all arguments are integers.
bool testIntArguments(
    ArgResults argResults, List<String> options, Function usage) {
  var rc = true;
  for (var opt in options) {
    if (argResults[opt] != null && int.tryParse(argResults[opt]) == null) {
      usage('$opt is not an integer: ${argResults[opt]}');
      rc = false;
      break;
    }
  }
  return rc;
}

/// Tests whether the [options] are integers. If not the callback usage is called.
/// Returns true if all arguments are integers.
bool testRegExpArguments(
    ArgResults argResults, List<String> options, Function usage) {
  var rc = true;
  for (var opt in options) {
    try {
      if (argResults[opt] != null) {
        RegExp(argResults[opt]);
      }
    } on FormatException catch (exc) {
      usage('$opt: error in regular expression "${argResults[opt]}": $exc');
      rc = false;
      break;
    }
  }
  return rc;
}

/// Writes a [string] or a [list] into a [file].
/// The path is
void writeString(String filename, {String? string, List<String>? list}) {
  try {
    final base = dirname(filename);
    if (base.isNotEmpty) {
      Directory(base).createSync(recursive: true);
    }
    if (list != null) {
      string = list.join('\n');
    }
    File(filename).writeAsStringSync(string ?? '');
  } on FileSystemException catch (exc) {
    print('+++ $exc');
  }
}
