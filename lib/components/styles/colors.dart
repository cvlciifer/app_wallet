import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';

class AwColors {
  static const Color appBarColor = Color(0xFF62597C);
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF595B5A);
  static const Color blue = Color(0xFF006FB9);
  static const Color indigo = Color(0xFF4B0082);
  static const Color cyan = Color(0xFF00B8D4);
  static const Color lightBlue = Color(0xFF40C4FF);
  static const Color darkBlue = Color(0xFF01579B);
  static const Color blueGrey = Color(0xFF90A4AE);
  static const Color purple = Color(0xFF6F00B8);
  static const Color grey = Color(0xFF979797);
  static const Color greyLight = Color(0xFFF4F4F4);
  static const Color green = Color(0xFF00953A);
  static const Color red = Color(0xFFF40034);
  static const Color orange = Color(0xFFFFA500);
  static const Color yellow = Color(0xFFF7D700);
  static const Color lightOrange = Color(0xFFFFB514);
  static const Color notificationGrey = Color(0xF4F4F4F4);
  static const Color boldBlack = Color(0xFF000000);

  static const Color modalRed = Color(0xFFEF3742);
  static const Color modalBlue = Color(0xFF007AFF);
  static const Color modalGrey = Color(0xFF444444);
  static const Color modalPurple = Color(0xFF6750A4);

  static final Map<String, Color> colorMap = {
    'blue': AwColors.blue,
    'indigo': AwColors.indigo,
    'white': AwColors.white,
    'yellow': AwColors.yellow,
    'lightOrange': AwColors.lightOrange,
    'grey': AwColors.grey,
    'green': AwColors.green,
    'black': AwColors.black,
    'cyan': AwColors.cyan,
    'lightBlue': AwColors.lightBlue,
    'darkBlue': AwColors.darkBlue,
    'blueGrey': AwColors.blueGrey,
    'purple': AwColors.purple,
    'red': AwColors.red,
    'orange': AwColors.orange,
    'notificationGrey': AwColors.notificationGrey,
    'modalRed': AwColors.modalRed,
    'modalBlue': AwColors.modalBlue,
    'modalGrey': AwColors.modalGrey,
    'modalPurple': AwColors.modalPurple,
    'blueAppBar': AwColors.appBarColor,
  };

  // final Map<String, Color> colorMapWithOpacity = {
  //   'blue': AwColors.blue.withOpacity(BciSize.p10),
  //   'white': AwColors.white.withOpacity(BciSize.p10),
  //   'yellow': AwColors.yellow.withOpacity(BciSize.p10),
  //   'grey': AwColors.grey.withOpacity(BciSize.p10),
  //   'green': AwColors.green.withOpacity(BciSize.p10),
  // };

  static Color getColor(String colorName) {
    return colorMap[colorName] ?? AwColors.black;
  }
}
