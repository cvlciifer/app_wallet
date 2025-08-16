import 'package:app_wallet/Library/main_library.dart';

class AwSpacing {
  AwSpacing._();

  // Size: 4px
  static const SizedBox xs = SizedBox(height: 4);

  /// Size: 8 px
  static const SizedBox s = SizedBox(height: 8);

  /// Size: 16 px
  static const SizedBox m = SizedBox(height: 16);

  /// Size: 32 px
  static const SizedBox l = SizedBox(height: 32);

  /// Size: 64 px
  static const SizedBox xl = SizedBox(height: 64);

  /// Size: 128 px
  static const SizedBox xxl = SizedBox(height: 128);

  /// Size: 256 px
  static const SizedBox xxxl = SizedBox(height: 256);

  /// symmetric : horizontal = 16,
  static const EdgeInsetsGeometry paddingPage = EdgeInsets.symmetric(
    horizontal: AwSize.s16,
  );
}
