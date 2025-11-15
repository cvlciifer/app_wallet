import 'package:flutter/material.dart';
import 'package:app_wallet/library_section/main_library.dart';

class HeaderLabel extends StatelessWidget {
  final Widget child;
  final List<Widget> overlays;
  final bool cardStyle;
  final Color color;
  final double elevation;
  final double borderRadius;
  final double shadowOpacity;
  final EdgeInsetsGeometry padding;

  const HeaderLabel({
    Key? key,
    required this.child,
    this.overlays = const [],
    this.cardStyle = false,
    this.color = Colors.white,
    this.elevation = 4.0,
    this.borderRadius = 12.0,
    this.shadowOpacity = 0.22,
    this.padding = const EdgeInsets.all(12.0),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
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

    final decoration = cardStyle
        ? BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF62597C), Color(0xFF7B7295)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(borderRadius),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.22), blurRadius: 18, offset: const Offset(0, 8)),
            ],
          )
        : BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(borderRadius),
            boxShadow: boxShadow,
          );

    final List<Widget> mergedOverlays = []..addAll(overlays);
    if (cardStyle) {
      mergedOverlays.addAll([
        Positioned(
          top: 12,
          left: 12,
          child: Container(
            width: 44,
            height: 28,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.85),
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ),
        Positioned(
          top: 10,
          right: 12,
          child: Opacity(
            opacity: 0.9,
            child: Icon(
              Icons.wallet,
              color: Colors.white.withOpacity(0.9),
              size: 28,
            ),
          ),
        ),
      ]);
    }

    return Container(
      decoration: decoration,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Padding(
              padding: cardStyle ? const EdgeInsets.symmetric(horizontal: 20.0, vertical: 38.0) : padding,
              child: child,
            ),
            ...mergedOverlays,
          ],
        ),
      ),
    );
  }
}
