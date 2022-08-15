import 'dart:io';

//import 'package:dart_bones/dart_bones.dart';

final regExprDimensions = RegExp(r'^\d+\s*x\s*\d+$');
final regExprNat = RegExp(r'^\d+$');

/// Tests whether an [input] is a dimension expression (width x height).
/// Returns null if yes or an error message if not.
String? checkDimensions(String? input) {
  String? rc;
  if (input == null) {
    rc = 'Keine Eingabe';
  } else if (regExprDimensions.firstMatch(input) == null) {
    rc = 'Keine korrekte Dimensiosangabe: $input Korrektes Beispiel: 800x600';
  }
  return rc;
}

/// Tests whether [input] is a directory.
/// Returns null if yes or an error message if not.
String? checkDirectory(String? input) {
  String? rc;
  if (input == null) {
    rc = 'Keine Eingabe';
  } else if (!Directory(input).existsSync()) {
    rc = 'Kein Verzeichnis: $input';
  }
  return rc;
}

/// Tests whether [input] is a number and a given [check] is suscessful.
/// Returns null on success and the error message if not.
/// [check] is a callback which checks a condition and returns null on success
/// or the error message if not.
String? checkIntWithCondition(
    String? input, String? Function(int number) check) {
  var rc = checkNat(input);
  if (rc == null && input != null) {
    rc = check(int.parse(input));
  }
  return rc;
}

/// Tests whether [input] is a not negative integer (nat).
/// Returns null if yes or an error message if not.
String? checkNat(String? input) {
  String? rc;
  if (input == null) {
    rc = 'Leere Eingabe';
  } else if (regExprNat.firstMatch(input) == null) {
    rc = 'Keine Ganzzahl: $input';
  }
  return rc;
}
