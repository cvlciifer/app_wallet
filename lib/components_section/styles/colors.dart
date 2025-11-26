import 'package:flutter/material.dart';

class AwColors {
  static const Color appBarColor = Color(0xFF62597C);
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF595B5A);
  static const Color blue = Color(0xFF006FB9);
  static const Color indigo = Color(0xFF4B0082);
  static const Color black54 = Color(0x8A000000);
  static const Color black26 = Color(0x42000000);
  static const Color black45 = Color(0x73000000);
  static const Color black87 = Color(0xDD000000);

  static const Color cyan = Color(0xFF00B8D4);
  static const Color lightBlue = Color(0xFF40C4FF);
  static const Color darkBlue = Color(0xFF01579B);
  static const Color blueGrey = Color(0xFF90A4AE);
  static const Color purple = Color(0xFF6F00B8);
  static const Color indigoInk = Color(0xFF3F51B5);
  static const Color grey = Color(0xFF979797);
  static const Color greyLight = Color(0xFFF4F4F4);
  // Material grey shades used across the app
  static const Color grey100 = Color(0xFFF5F5F5);
  static const Color grey300 = Color(0xFFE0E0E0);
  static const Color grey400 = Color(0xFFBDBDBD);
  static final Color grey600 = Colors.grey.shade600;
  static final Color grey800 = Colors.grey.shade800;

  static const Color green = Color(0xFF00953A);
  static const Color red = Color(0xFFF40034);
  static const Color redAccent = Colors.redAccent;
  static const Color orange = Color(0xFFFFA500);
  static const Color yellow = Color(0xFFF7D700);
  static const Color orangeDark = Color(0xFFF57C00);
  static const Color lightOrange = Color(0xFFFFB514);
  static const Color notificationGrey = Color(0xF4F4F4F4);
  static const Color boldBlack = Color(0xFF000000);
  static const Color transparent = Colors.transparent;

  static const Color modalRed = Color(0xFFEF3742);
  static const Color modalBlue = Color(0xFF007AFF);
  static const Color modalGrey = Color(0xFF444444);
  static const Color modalPurple = Color(0xFF6750A4);
  static const Color borderGrey = Color.fromARGB(232, 255, 234, 232);

  static final Map<String, Color> colorMap = {
    'blue': AwColors.blue,
    'indigo': AwColors.indigo,
    'white': AwColors.white,
    'black26': AwColors.black26,
    'grey100': AwColors.grey100,
    'grey300': AwColors.grey300,
    'grey400': AwColors.grey400,
    'grey600': AwColors.grey600,
    'yellow': AwColors.yellow,
    'lightOrange': AwColors.lightOrange,
    'black54': AwColors.black54,
    'black45': AwColors.black45,
    'grey': AwColors.grey,
    'green': AwColors.green,
    'black': AwColors.black,
    'indigoInk': AwColors.indigoInk,
    'cyan': AwColors.cyan,
    'transparent': AwColors.transparent,
    'lightBlue': AwColors.lightBlue,
    'darkBlue': AwColors.darkBlue,
    'blueGrey': AwColors.blueGrey,
    'purple': AwColors.purple,
    'red': AwColors.red,
    'redAccent': AwColors.redAccent,
    'orange': AwColors.orange,
    'notificationGrey': AwColors.notificationGrey,
    'orangeDark': AwColors.orangeDark,
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
