import 'package:flutter/material.dart';
import 'package:app_wallet/library_section/main_library.dart';

class TicketCardHome extends StatelessWidget {
  final Widget child;
  final List<Widget> overlays;
  final Color color;
  final double elevation;
  final double borderRadius;

  /// Single opacity parameter that controls layered shadow intensity.
  /// Set to 0 to disable shadows.
  final double shadowOpacity;
  final EdgeInsetsGeometry padding;

  const TicketCardHome({
    Key? key,
    required this.child,
    this.overlays = const [],
    this.color = Colors.white,
    this.elevation = 4.0,
    this.borderRadius = 12.0,
    this.shadowOpacity = 0.22,
    this.padding = const EdgeInsets.all(12.0),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Build a three-layer shadow using a single opacity parameter. If
    // `shadowOpacity` is <= 0 treat as no shadow.
    final boxShadow = (shadowOpacity > 0)
        ? [
            BoxShadow(
              color: Colors.black.withOpacity(shadowOpacity),
              blurRadius: 10.0,
              spreadRadius: 0,
              offset: const Offset(0, 3),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(shadowOpacity * 0.6),
              blurRadius: 28.0,
              spreadRadius: 0,
              offset: const Offset(0, 12),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(shadowOpacity * 0.35),
              blurRadius: 48.0,
              spreadRadius: 0,
              offset: const Offset(0, 24),
            ),
          ]
        : null;

    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: boxShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Padding(
              padding: padding,
              child: child,
            ),
            ...overlays,
          ],
        ),
      ),
    );
  }
}
