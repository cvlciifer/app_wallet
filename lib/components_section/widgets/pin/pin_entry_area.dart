import 'package:app_wallet/library_section/main_library.dart';

// Área de entrada de PIN que combina el PIN y el teclado numérico.

class PinEntryArea extends StatefulWidget {
  final int digits;
  final void Function(String) onCompleted;
  final bool autoComplete;
  final ValueChanged<int>? onChanged;
  final Widget? actions;

  const PinEntryArea({
    Key? key,
    this.digits = 4,
    required this.onCompleted,
    this.autoComplete = true,
    this.onChanged,
    this.actions,
  }) : super(key: key);

  @override
  PinEntryAreaState createState() => PinEntryAreaState();
}

class PinEntryAreaState extends State<PinEntryArea> {
  final GlobalKey<PinInputState> _internalPinKey = GlobalKey<PinInputState>();

  void clear() => _internalPinKey.currentState?.clear();
  void appendDigit(String d) => _internalPinKey.currentState?.appendDigit(d);
  void deleteDigit() => _internalPinKey.currentState?.deleteDigit();

  String get currentPin => _internalPinKey.currentState?.currentPin ?? '';

  int get currentLength => _internalPinKey.currentState?.currentLength ?? 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        PinInput(
            key: _internalPinKey,
            digits: widget.digits,
            onCompleted: widget.onCompleted,
            autoComplete: widget.autoComplete,
            onChanged: widget.onChanged),
        AwSpacing.s12,
        NumericKeypad(
          onDigit: (d) => appendDigit(d),
          onBackspace: () => deleteDigit(),
        ),
        if (widget.actions != null) ...[
          AwSpacing.s12,
          widget.actions!,
        ],
      ],
    );
  }
}
