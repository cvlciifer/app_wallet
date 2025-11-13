import 'package:app_wallet/library_section/main_library.dart';
import 'dart:math';

class TicketCard extends StatelessWidget {
  final Widget child;
  final List<Widget>? overlays;
  final double notchDepth;
  final bool compactNotches;
  final bool roundTopCorners;
  final double topCornerRadius;
  final EdgeInsets padding;
  final double elevation;
  final Color color;
  final bool boxShadowAll;

  const TicketCard({
    Key? key,
    required this.child,
    this.overlays,
    this.notchDepth = 12,
    this.compactNotches = false,
    this.roundTopCorners = false,
    this.topCornerRadius = 12,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
    this.elevation = 8,
    this.color = Colors.white,
    this.boxShadowAll = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ticket = PhysicalShape(
      clipper: _TicketClipper(
        notchDepth: notchDepth,
        compactNotches: compactNotches,
        roundTopCorners: roundTopCorners,
        topRadius: topCornerRadius,
      ),
      elevation: elevation,
      color: color,
      shadowColor: Colors.black54,
      child: Padding(
        padding: padding,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            child,
            if (overlays != null) ...overlays!,
          ],
        ),
      ),
    );

    if (boxShadowAll) {
      return Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: const Color.fromARGB(66, 105, 105, 105),
              blurRadius: elevation,
              spreadRadius: elevation > 0 ? (elevation / 6) : 0,
              offset: Offset(0, elevation > 0 ? elevation / 3 : 1),
            ),
          ],
        ),
        child: ticket,
      );
    }

    return ticket;
  }
}

class _TicketClipper extends CustomClipper<Path> {
  final double notchDepth;
  final bool compactNotches;
  final bool roundTopCorners;
  final double topRadius;

  const _TicketClipper({
    this.notchDepth = 12,
    this.compactNotches = false,
    this.roundTopCorners = false,
    this.topRadius = 12,
  });

  @override
  Path getClip(Size size) {
    final path = Path();
    // Ajusta la profundidad de la muesca y la separación/cantidad de segmentos
    final d = notchDepth * (compactNotches ? 0.6 : 1.0);
    final baseSegmentWidth = compactNotches ? 18 : 30;
    final segments = (size.width / baseSegmentWidth).floor().clamp(4, 80);
    final segW = size.width / segments;

    // Top corner radius seguro
    final r = roundTopCorners ? min(topRadius, min(size.width / 2, size.height / 2)) : 0.0;

    // Start at top-left respecting radius
    if (r > 0) {
      path.moveTo(0, r);
      path.quadraticBezierTo(0, 0, r, 0);
    } else {
      path.moveTo(0, 0);
    }

    // Top edge to top-right
    if (r > 0) {
      path.lineTo(size.width - r, 0);
      path.quadraticBezierTo(size.width, 0, size.width, r);
    } else {
      path.lineTo(size.width, 0);
    }

    // Right edge down to before notches
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
    // Close left edge back to start; if r>0 we should connect to (0,r)
    if (r > 0) {
      path.lineTo(0, r);
    }
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
