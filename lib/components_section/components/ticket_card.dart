import 'package:app_wallet/library_section/main_library.dart';

class TicketCard extends StatelessWidget {
  final Widget child;
  final List<Widget>? overlays;
  final double notchDepth;
  final EdgeInsets padding;
  final double elevation;
  final Color color;

  const TicketCard({
    Key? key,
    required this.child,
    this.overlays,
    this.notchDepth = 12,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
    this.elevation = 8,
    this.color = Colors.white,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return PhysicalShape(
      clipper: _TicketClipper(notchDepth: notchDepth),
      elevation: elevation,
      color: color,
      shadowColor: Colors.black54,
      child: Padding(
        padding: padding,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // contenido principal
            child,
            // overlays encima del contenido
            if (overlays != null) ...overlays!,
          ],
        ),
      ),
    );
  }
}

class _TicketClipper extends CustomClipper<Path> {
  final double notchDepth;
  const _TicketClipper({this.notchDepth = 12});

  @override
  Path getClip(Size size) {
    final path = Path();
    final d = notchDepth;
    final segments = (size.width / 30).floor().clamp(4, 40);
    final segW = size.width / segments;

    path.moveTo(0, 0);
    path.lineTo(size.width, 0);
    path.lineTo(size.width, size.height - d);

    // draw triangular notches along bottom from right to left
    for (int i = segments - 1; i >= 0; i--) {
      final x0 = i * segW;
      final xm = x0 + segW / 2;
      final x1 = x0 + segW;
      path.lineTo(x1, size.height - d);
      path.lineTo(xm, size.height);
      path.lineTo(x0, size.height - d);
    }

    path.lineTo(0, size.height - d);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
