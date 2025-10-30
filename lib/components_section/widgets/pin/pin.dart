import 'package:app_wallet/library_section/main_library.dart';

class PinInput extends StatefulWidget {
  final int digits;
  final ValueChanged<String> onCompleted;
  // Configuracion de pin visual
  final double dotSize;
  final double dotSpacing;
  final Color filledColor;
  final Color borderColor;

  const PinInput({
    Key? key,
    this.digits = 4,
    required this.onCompleted,
    this.dotSize = AwSize.s16,
    this.dotSpacing = AwSize.s12,
    this.filledColor = AwColors.appBarColor,
    this.borderColor = AwColors.appBarColor,
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

  /// Añade un dígito al PIN (usado por el teclado numérico en pantalla)
  void appendDigit(String d) {
    if (_controller.text.length >= widget.digits) return;
    _controller.text = '${_controller.text}$d';
    _controller.selection =
        TextSelection.collapsed(offset: _controller.text.length);
    setState(() {});
  }

  /// Elimina el último dígito (retroceso)
  void deleteDigit() {
    if (_controller.text.isEmpty) return;
    _controller.text =
        _controller.text.substring(0, _controller.text.length - 1);
    _controller.selection =
        TextSelection.collapsed(offset: _controller.text.length);
    setState(() {});
  }

  int get currentLength => _controller.text.length;

  String get currentPin => _controller.text;

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
              border: Border.all(color: widget.borderColor, width: 2.0),
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
