import 'package:flutter/material.dart';

class AWIconData {
  const AWIconData(
    this.assetPath, {
    String? package,
  }) : package = package ?? 'icon_section';

  final String assetPath;
  final String package;
}

// class AWIcon {
//   const AWIcon._();

//   static const menu = AWIconData('svg/menu.svg');

//   static AWIconData getIcon(String iconName, {bool normal = false}) {
//     final Map<String, AWIconData> circledIcons = {
//       'menu': AWIcon.menu,
//     };
//     final Map<String, AWIconData> icons = {
//       'menu': AWIcon.menu,
//     };
//     if (normal) {
//       return icons[iconName] ?? AWIcon.menu;
//     } else {
//       return circledIcons[iconName] ?? AWIcon.menu;
//     }
//   }
// }

class AWImage {
  const AWImage._();
  static const settings = AssetImage('lib/icon_section/png/settings.png');
  static const ghost = AssetImage('lib/icon_section/png/ghost.png');
}
