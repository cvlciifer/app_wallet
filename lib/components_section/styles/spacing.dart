import 'package:app_wallet/library_section/main_library.dart';

class AwSpacing {
  AwSpacing._();

  // Size: 4px
  static const SizedBox xs = SizedBox(height: 4);

  /// Size: 6 px
  static const SizedBox s6 = SizedBox(height: 6);

  /// Size: 8 px
  static const SizedBox s = SizedBox(height: 8);

  /// Size: 10 px
  static const SizedBox s10 = SizedBox(height: 10);

  /// Size: 12 px
  static const SizedBox s12 = SizedBox(height: 12);

  /// Size: 16 px
  static const SizedBox m = SizedBox(height: 16);

  /// Size: 18 px
  static const SizedBox s18 = SizedBox(height: 18);

  /// Size: 20 px
  static const SizedBox s20 = SizedBox(height: 20);

  /// Size: 30 px
  static const SizedBox s30 = SizedBox(height: 30);

  /// Size: 32 px
  static const SizedBox l = SizedBox(height: 32);

  /// Size: 48 px
  static const SizedBox s40 = SizedBox(height: 40);

  /// Size: 50 px
  static const SizedBox s50 = SizedBox(height: 50);

  /// Size: 64 px
  static const SizedBox xl = SizedBox(height: 64);

  /// Size: 128 px
  static const SizedBox xxl = SizedBox(height: 128);

  /// Size: 256 px
  static const SizedBox xxxl = SizedBox(height: 256);

  /// SizedBox de ancho 300 que acepta un child
  static Widget box300({required Widget child}) {
    return SizedBox(width: 300, child: child);
  }

  /// symmetric : horizontal = 16,
  static const EdgeInsetsGeometry paddingPage = EdgeInsets.symmetric(
    horizontal: AwSize.s16,
  );
}
