import 'package:app_wallet/library_section/main_library.dart';

/// Simple PIN input widget used by SetPinPage / ConfirmPinPage.
/// - digits: number of digits to collect
/// - onCompleted: called when collected length == digits
class PinInput extends StatefulWidget {
  final int digits;
  final ValueChanged<String> onCompleted;

  /// Tamaño del punto en píxeles lógicos. `AwSize.s16`.
  final double dotSize;

  /// Espaciado horizontal entre puntos en píxeles lógicos. `AwSize.s8`.
  final double dotSpacing;

  /// Color utilizado cuando un punto está lleno.
  final Color filledColor;

  /// Color utilizado para el borde del punto cuando no está lleno.
  final Color borderColor;

  const PinInput({
    Key? key,
    this.digits = 4,
    required this.onCompleted,
    this.dotSize = AwSize.s16,
    this.dotSpacing = AwSize.s8,
    this.filledColor = AwColors.black,
    this.borderColor = Colors.black54,
  }) : super(key: key);

  @override
  State<PinInput> createState() => PinInputState();
}

class PinInputState extends State<PinInput> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _focusNode = FocusNode();
    _controller.addListener(_onChange);
  }

  void _onChange() {
    final v = _controller.text;
    if (v.length >= widget.digits) {
      final pin = v.substring(0, widget.digits);
      if (v.length != widget.digits) {
        _controller.text = pin;
        _controller.selection = TextSelection.collapsed(offset: pin.length);
      }
      Future.microtask(() {
        if (mounted) widget.onCompleted(pin);
      });
    }
    setState(() {});
  }

  void clear() {
    _controller.text = '';
    _controller.selection = const TextSelection.collapsed(offset: 0);
    setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_onChange);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Widget _buildDots() {
    final chars = _controller.text.split('');
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(widget.digits, (i) {
        final filled = i < chars.length;
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: widget.dotSpacing),
          child: Container(
            width: widget.dotSize,
            height: widget.dotSize,
            decoration: BoxDecoration(
              color: filled ? widget.filledColor : AwColors.transparent,
              border: Border.all(color: widget.borderColor),
              borderRadius: BorderRadius.circular(widget.dotSize / 2),
            ),
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: () => _focusNode.requestFocus(),
          child: _buildDots(),
        ),
        AwSpacing.s,
        SizedBox(
          width: 0,
          height: 0,
          child: TextField(
            controller: _controller,
            focusNode: _focusNode,
            keyboardType: TextInputType.number,
            obscureText: true,
            enableSuggestions: false,
            autocorrect: false,
            maxLength: widget.digits,
            decoration: const InputDecoration(counterText: ''),
          ),
        ),
      ],
    );
  }
}
