import 'package:flutter/material.dart';

import './MainPage.dart';

void main() => runApp(new ExampleApplication());

class ExampleApplication extends StatelessWidget {

  static const PrimaryColor = const Color(0xFF3E50B4);
  static const AccentColor = const Color(0xFFFFFFFF);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primaryColor: PrimaryColor,
      ),
      home: MainPage()
    );
  }
}
