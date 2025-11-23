import 'package:app_wallet/library_section/main_library.dart';

typedef ZoomAwareBuilder = Widget Function(
    BuildContext context, bool isZoomed, Widget? child);

class ZoomAware extends StatelessWidget {
  final ZoomAwareBuilder builder;
  final Widget? child;

  const ZoomAware({super.key, required this.builder, this.child});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool?>(
      valueListenable: ZoomService().isZoomed,
      builder: (ctx, val, ch) => builder(ctx, val == true, ch),
      child: child,
    );
  }
}
