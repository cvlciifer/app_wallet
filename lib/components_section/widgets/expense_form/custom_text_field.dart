import 'package:app_wallet/library_section/main_library.dart';

class CustomTextField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final int? maxLength;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final Function(String)? onChanged;
  final String? prefixText;
  final bool hideCounter;
  final TextAlign? textAlign;
  final TextAlignVertical? textAlignVertical;
  final bool flat;
  final double? textSize;
  final String? hintText;

  const CustomTextField({
    super.key,
    required this.controller,
    required this.label,
    this.maxLength,
    this.keyboardType,
    this.inputFormatters,
    this.onChanged,
    this.prefixText,
    this.hideCounter = false,
    this.textAlign,
    this.textAlignVertical,
    this.flat = false,
    this.textSize,
    this.hintText,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
    widget.controller.addListener(_onTextChange);
  }

  @override
  void didUpdateWidget(covariant CustomTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onTextChange);
      widget.controller.addListener(_onTextChange);
    }
  }

  void _onFocusChange() => setState(() {});

  void _onTextChange() => setState(() {});

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    widget.controller.removeListener(_onTextChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final flat = widget.flat;
    final InputBorder effectiveBorder = flat
        ? UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.grey.shade400),
          )
        : OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
          );

    final effectiveTextSize = widget.textSize ?? 16.0;

    final showHint = !_focusNode.hasFocus && widget.controller.text.isEmpty;

    return SizedBox(
      height: 75,
      child: TextField(
        focusNode: _focusNode,
        controller: widget.controller,
        maxLength: widget.maxLength,
        keyboardType: widget.keyboardType,
        inputFormatters: widget.inputFormatters,
        onChanged: widget.onChanged,
        textAlign: widget.textAlign ?? TextAlign.start,
        textAlignVertical: widget.textAlignVertical,
        style: TextStyle(fontSize: effectiveTextSize),
        decoration: InputDecoration(
          labelText: widget.label.isNotEmpty ? widget.label : null,
          labelStyle: widget.label.isNotEmpty ? TextStyle(color: Colors.black, fontSize: effectiveTextSize) : null,
          hintText: showHint ? widget.hintText : null,
          hintStyle: TextStyle(fontSize: effectiveTextSize, color: AwColors.grey),
          prefixText: widget.prefixText,
          counterText: widget.hideCounter ? '' : null,
          border: effectiveBorder,
          enabledBorder: effectiveBorder,
          focusedBorder: flat
              ? UnderlineInputBorder(borderSide: BorderSide(color: AwColors.appBarColor))
              : OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AwColors.appBarColor),
                ),
          contentPadding: EdgeInsets.symmetric(
            horizontal: 16,
            vertical: flat ? 18 : 18,
          ),
        ),
      ),
    );
  }
}
