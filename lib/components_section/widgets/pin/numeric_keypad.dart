import 'package:app_wallet/library_section/main_library.dart';

/// Teclado numérico reutilizable para PINs
class NumericKeypad extends StatelessWidget {
  final void Function(String) onDigit;
  final VoidCallback onBackspace;

  const NumericKeypad({Key? key, required this.onDigit, required this.onBackspace}) : super(key: key);

  Widget _buildKey(String label, {VoidCallback? onTap}) {
    if (label.isEmpty && onTap == null) {
      return const Expanded(child: SizedBox());
    }
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 8.0),
        child: _KeyButton(
          label: label,
          onTap: onTap,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(children: [
          for (var i in ['1', '2', '3']) _buildKey(i, onTap: () => onDigit(i))
        ]),
        Row(children: [
          for (var i in ['4', '5', '6']) _buildKey(i, onTap: () => onDigit(i))
        ]),
        Row(children: [
          for (var i in ['7', '8', '9']) _buildKey(i, onTap: () => onDigit(i))
        ]),
        Row(children: [
          _buildKey('', onTap: null),
          _buildKey('0', onTap: () => onDigit('0')),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 8.0),
              child: _KeyButton(
                label: null,
                icon: Icons.backspace,
                onTap: onBackspace,
              ),
            ),
          ),
        ]),
      ],
    );
  }
}

class _KeyButton extends StatefulWidget {
  final String? label;
  final IconData? icon;
  final VoidCallback? onTap;

  const _KeyButton({Key? key, this.label, this.icon, this.onTap}) : super(key: key);

  @override
  State<_KeyButton> createState() => _KeyButtonState();
}

class _KeyButtonState extends State<_KeyButton> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  double _scale = 1.0;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 100));
    _ctrl.addListener(() {
      setState(() => _scale = 1.0 - 0.1 * _ctrl.value);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) {
    _ctrl.forward();
  }

  void _onTapUp(TapUpDetails _) async {
    await Future.delayed(const Duration(milliseconds: 100));
    _ctrl.reverse();
  }

  void _onTapCancel() {
    _ctrl.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTapDown: widget.onTap != null ? _onTapDown : null,
      onTapUp: widget.onTap != null ? _onTapUp : null,
      onTapCancel: widget.onTap != null ? _onTapCancel : null,
      onTap: widget.onTap,
      child: Transform.scale(
        scale: _scale,
        child: Container(
          height: 76,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: AwColors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Color.fromARGB(255, 208, 206, 206),
                blurRadius: 5,
                offset: Offset(0, 0),
              ),
            ],
          ),
          child: widget.label != null
              ? Text(
                  widget.label!,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: AwColors.boldBlack,
                  ),
                )
              : Icon(
                  widget.icon,
                  color: AwColors.boldBlack,
                ),
        ),
      ),
    );
  }
}
