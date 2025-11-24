import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:app_wallet/library_section/main_library.dart';

/// HeaderLabel ahora soporta un giro horizontal al tocar (flip) mostrando una
/// `backChild` opcional. Mantiene las opciones de estilo previas.
class HeaderLabel extends StatefulWidget {
  final Widget child;
  final Widget? backChild;
  final double? fixedHeight;
  final List<Widget> overlays;
  final bool cardStyle;
  final Color color;
  final double elevation;
  final double borderRadius;
  final double shadowOpacity;
  final EdgeInsetsGeometry padding;
  final Duration flipDuration;
  final bool enableFlipOnTap;

  const HeaderLabel({
    Key? key,
    required this.child,
    this.backChild,
    this.overlays = const [],
    this.cardStyle = false,
    this.color = Colors.white,
    this.elevation = 4.0,
    this.borderRadius = 12.0,
    this.shadowOpacity = 0.22,
    this.padding = const EdgeInsets.all(12.0),
    this.flipDuration = const Duration(milliseconds: 600),
    this.enableFlipOnTap = true,
    this.fixedHeight,
  }) : super(key: key);

  @override
  State<HeaderLabel> createState() => _HeaderLabelState();
}

class _HeaderLabelState extends State<HeaderLabel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;
  bool _showBack = false;
  final GlobalKey _frontKey = GlobalKey();
  double? _cardHeight;
  static const double _kDefaultHeaderHeight = 140.0;
  double? _lastTextScale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.flipDuration);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final double ts = MediaQuery.textScaleFactorOf(context);
    if (_lastTextScale == null) {
      _lastTextScale = ts;
      return;
    }

    if (_lastTextScale != ts) {
      _lastTextScale = ts;
      if (_cardHeight != null) {
        setState(() {
          _cardHeight = null;
        });
      }
    }
  }

  void _toggleFlip() {
    if (!widget.enableFlipOnTap) return;
    if (_showBack) {
      _ctrl.reverse();
    } else {
      _ctrl.forward();
    }
    setState(() {
      _showBack = !_showBack;
    });
  }

  void _measureFront() {
    try {
      final ctx = _frontKey.currentContext;
      if (ctx == null) return;
      final rb = ctx.findRenderObject() as RenderBox?;
      if (rb == null) return;
      final h = rb.size.height;
      if (h > 0 && _cardHeight != h) {
        setState(() {
          _cardHeight = h;
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final effectiveOpacity =
        widget.shadowOpacity > 0 ? widget.shadowOpacity : 0.22;
    final boxShadow = [
      BoxShadow(
        color: Colors.black.withOpacity(effectiveOpacity),
        blurRadius: 10.0,
        spreadRadius: 0,
        offset: const Offset(0, 3),
      ),
      BoxShadow(
        color: Colors.black.withOpacity(effectiveOpacity * 0.6),
        blurRadius: 28.0,
        spreadRadius: 0,
        offset: const Offset(0, 12),
      ),
      BoxShadow(
        color: Colors.black.withOpacity(effectiveOpacity * 0.35),
        blurRadius: 48.0,
        spreadRadius: 0,
        offset: const Offset(0, 24),
      ),
    ];

    final decoration = widget.cardStyle
        ? BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color.fromARGB(255, 108, 136, 198),
                Color.fromARGB(255, 85, 111, 143)
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(widget.borderRadius),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.22),
                  blurRadius: 18,
                  offset: const Offset(0, 8)),
            ],
          )
        : BoxDecoration(
            color: widget.color,
            borderRadius: BorderRadius.circular(widget.borderRadius),
            boxShadow: boxShadow,
          );

    final List<Widget> mergedOverlays = []..addAll(widget.overlays);
    if (widget.cardStyle) {
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

    Widget front = Padding(
      padding: widget.cardStyle
          ? const EdgeInsets.symmetric(horizontal: 20.0, vertical: 38.0)
          : widget.padding,
      child: widget.child,
    );

    // backContent variable is used below (backContent) - remove unused 'back'

    // Build front decorated container (includes overlays)
    final Widget decoratedFront = Container(
      key: _frontKey,
      decoration: decoration,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            SizedBox(width: double.infinity, child: front),
            ...mergedOverlays,
          ],
        ),
      ),
    );

    // Back content should occupy full width. We'll render it inside the same
    // decoration so the back side keeps the HeaderLabel style.
    final Widget backContent = Padding(
      padding: widget.cardStyle
          ? const EdgeInsets.symmetric(horizontal: 20.0, vertical: 38.0)
          : widget.padding,
      child: SizedBox(
          width: double.infinity,
          child: widget.backChild ?? const SizedBox.shrink()),
    );

    final Widget decoratedBack = Container(
      decoration: decoration,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            SizedBox(width: double.infinity, child: backContent),
          ],
        ),
      ),
    );

    // measure front after layout to enforce equal heights for front/back
    WidgetsBinding.instance.addPostFrameCallback((_) => _measureFront());

    final bool enforceFallback =
        widget.fixedHeight != null || _cardHeight == null;
    final double fallbackHeight = widget.fixedHeight ?? _kDefaultHeaderHeight;

    final Widget innerFront = AnimatedSize(
      alignment: Alignment.topCenter,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeInOut,
      child: decoratedFront,
    );

    final Widget innerBack = AnimatedSize(
      alignment: Alignment.topCenter,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeInOut,
      child: decoratedBack,
    );

    final Widget frontWidget = enforceFallback
        ? ConstrainedBox(
            constraints: BoxConstraints(minHeight: fallbackHeight),
            child: innerFront)
        : innerFront;

    final Widget backWidget = enforceFallback
        ? ConstrainedBox(
            constraints: BoxConstraints(minHeight: fallbackHeight),
            child: innerBack)
        : innerBack;

    return SizedBox(
      width: double.infinity,
      child: GestureDetector(
        onTap: _toggleFlip,
        child: AnimatedBuilder(
          animation: _anim,
          builder: (context, child) {
            final value = _anim.value;
            final angle = value * math.pi;
            final Matrix4 transform = Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(angle);
            if (angle <= (math.pi / 2)) {
              // show front with decoration
              return Transform(
                alignment: Alignment.center,
                transform: transform,
                child: frontWidget,
              );
            } else {
              // show decorated back, rotate so it's readable
              return Transform(
                alignment: Alignment.center,
                transform: transform,
                child: Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()..rotateY(math.pi),
                  child: backWidget,
                ),
              );
            }
          },
        ),
      ),
    );
  }
}
