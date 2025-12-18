import 'package:app_wallet/library_section/main_library.dart';

double responsiveFontSize(BuildContext ctx, double base,
    {double min = AwSize.s8, double max = AwSize.s14}) {
  // ignore: deprecated_member_use
  final ts = MediaQuery.of(ctx).textScaleFactor;
  final scale = (ts <= 0 ? 1.0 : ts);
  final computed = (base * scale).clamp(min, max);
  return computed.toDouble();
}
