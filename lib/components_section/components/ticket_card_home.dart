import 'package:flutter/material.dart';
import 'package:app_wallet/library_section/main_library.dart';

class TicketCardHome extends StatelessWidget {
  final Widget child;
  final List<Widget> overlays;
  final Color color;
  final double elevation;
  final double borderRadius;
  final bool boxShadowAll;
  final EdgeInsetsGeometry padding;

  const TicketCardHome({
    Key? key,
    required this.child,
    this.overlays = const [],
    this.color = Colors.white,
    this.elevation = 4.0,
    this.borderRadius = 12.0,
    this.boxShadowAll = true,
    this.padding = const EdgeInsets.all(12.0),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final boxShadow = boxShadowAll
        ? [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: elevation * 10.0,
              spreadRadius: 0,
              offset: const Offset(0, 3),
            ),
          ]
        : null;

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: boxShadow,
        ),
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
