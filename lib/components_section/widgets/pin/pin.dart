import 'dart:math' as math;

import 'package:app_wallet/library_section/main_library.dart';

const Color _kCream = Color(0xFFF7F3EA);

class PinInput extends StatefulWidget {
  final int digits;
  final ValueChanged<String> onCompleted;
  final bool autoComplete;
  final ValueChanged<int>? onChanged;
  final double dotSize;
  final double dotSpacing;
  final Color filledColor;
  final Color borderColor;

  const PinInput({
    Key? key,
    this.digits = 4,
    required this.onCompleted,
    this.autoComplete = true,
    this.onChanged,
    this.dotSize = AwSize.s20,
    this.dotSpacing = AwSize.s12,
    this.filledColor = AwColors.white,
    this.borderColor = AwColors.appBarColor,
  }) : super(key: key);

  @override
  State<PinInput> createState() => PinInputState();
}

class PinInputState extends State<PinInput> with TickerProviderStateMixin {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  late final AnimationController _shakeController;
  late final Animation<double> _shakeAnim;

  // per-dot animations: small scale when filled
  late final List<AnimationController> _dotControllers;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _focusNode = FocusNode();
    _controller.addListener(_onChange);

    _shakeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _shakeAnim = CurvedAnimation(parent: _shakeController, curve: Curves.linear);

    _dotControllers = List.generate(widget.digits, (_) {
      return AnimationController(vsync: this, duration: const Duration(milliseconds: 180));
    });
  }

  void _onChange() {
    final v = _controller.text;
    // trigger per-dot animation when a digit is added
    for (var i = 0; i < widget.digits; i++) {
      final filled = i < v.length;
      final ctrl = _dotControllers[i];
      if (filled && ctrl.status != AnimationStatus.forward && ctrl.status != AnimationStatus.completed) {
        ctrl.forward();
      } else if (!filled && ctrl.value > 0) {
        ctrl.reverse();
      }
    }

    if (v.length >= widget.digits) {
      final pin = v.substring(0, widget.digits);
      if (v.length != widget.digits) {
        _controller.text = pin;
        _controller.selection = TextSelection.collapsed(offset: pin.length);
      }
      if (widget.autoComplete) {
        Future.microtask(() {
          if (mounted) widget.onCompleted(pin);
        });
      }
    }
    setState(() {});
    widget.onChanged?.call(_controller.text.length);
  }

  void clear() {
    _controller.text = '';
    _controller.selection = const TextSelection.collapsed(offset: 0);
    for (final c in _dotControllers) {
      c.value = 0;
    }
    setState(() {});
  }

  void appendDigit(String d) {
    if (_controller.text.length >= widget.digits) return;
    _controller.text = '${_controller.text}$d';
    _controller.selection = TextSelection.collapsed(offset: _controller.text.length);
    setState(() {});
  }

  void deleteDigit() {
    if (_controller.text.isEmpty) return;
    _controller.text = _controller.text.substring(0, _controller.text.length - 1);
    _controller.selection = TextSelection.collapsed(offset: _controller.text.length);
    setState(() {});
  }

  int get currentLength => _controller.text.length;

  String get currentPin => _controller.text;

  /// Public method to trigger the shake error animation
  void triggerErrorAnimation() {
    _shakeController.forward(from: 0.0);
  }

  @override
  void dispose() {
    _controller.removeListener(_onChange);
    _controller.dispose();
    _focusNode.dispose();
    _shakeController.dispose();
    for (final c in _dotControllers) c.dispose();
    super.dispose();
  }

  Widget _buildDots() {
    final chars = _controller.text.split('');
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(widget.digits, (i) {
        final filled = i < chars.length;
        final ctrl = _dotControllers[i];
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: widget.dotSpacing / 2),
          child: AnimatedBuilder(
            animation: ctrl,
            builder: (context, child) {
              final scale = 0.9 + 0.1 * ctrl.value; // gentle pop
              final opacity = 0.6 + 0.4 * ctrl.value;
              return Transform.scale(
                scale: scale,
                child: Opacity(
                  opacity: opacity,
                  child: Container(
                    width: widget.dotSize,
                    height: widget.dotSize,
                    decoration: BoxDecoration(
                      color: filled ? widget.filledColor : AwColors.white,
                      border: Border.all(color: AwColors.white, width: 1.0),
                      boxShadow: [
                        BoxShadow(
                          color: const Color.fromARGB(255, 208, 207, 207),
                          blurRadius: 2,
                          offset: const Offset(0, 0),
                        ),
                      ],
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              );
            },
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shakeAnim,
      builder: (context, child) {
        // Compose a shaking offset using a sine wave multiplied by a decay
        final progress = _shakeAnim.value;
        final double shakes = 6; // number of back-and-forths
        final double amplitude = 8.0; // max pixels
        final dx = math.sin(progress * math.pi * shakes) * amplitude * (1 - progress);
        return Transform.translate(
          offset: Offset(dx, 0),
          child: GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDots(),
                AwSpacing.s,
                SizedBox(
                  width: 0,
                  height: 0,
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    readOnly: true,
                    showCursor: false,
                    enableInteractiveSelection: false,
                    obscureText: true,
                    enableSuggestions: false,
                    autocorrect: false,
                    maxLength: widget.digits,
                    decoration: const InputDecoration(counterText: ''),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
