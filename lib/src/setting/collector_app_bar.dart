import 'package:flutter/material.dart';

class CollectorAppBar extends AppBar {
  CollectorAppBar({String title = ''}) : super(title: Text(title));
  static CollectorAppBar builder(String title) => CollectorAppBar(title: title);
}
