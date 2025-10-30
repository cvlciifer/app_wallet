import 'package:app_wallet/library_section/main_library.dart';

/// Teclado numérico reutilizable para PINs
class NumericKeypad extends StatelessWidget {
  final void Function(String) onDigit;
  final VoidCallback onBackspace;

  const NumericKeypad(
      {Key? key, required this.onDigit, required this.onBackspace})
      : super(key: key);

  Widget _buildKey(String label, {VoidCallback? onTap}) {
    if (label.isEmpty && onTap == null) {
      return const Expanded(child: SizedBox());
    }

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Center(
          child: SizedBox(
            width: 80,
            height: 80,
            child: OutlinedButton(
              onPressed: onTap,
              style: OutlinedButton.styleFrom(
                shape: const CircleBorder(),
                // ignore: deprecated_member_use
                side: BorderSide(
                    color: AwColors.indigoInk.withOpacity(0.3), width: 2),
                padding: EdgeInsets.zero,
                // ignore: deprecated_member_use
                backgroundColor: AwColors.indigoInk.withOpacity(0.3),
              ),
              child: Text(label,
                  style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AwColors.boldBlack)),
            ),
          ),
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
              padding: const EdgeInsets.all(8.0),
              child: Center(
                child: SizedBox(
                  width: 80,
                  height: 80,
                  child: OutlinedButton(
                    onPressed: onBackspace,
                    style: OutlinedButton.styleFrom(
                      shape: const CircleBorder(),
                      side: BorderSide(
                          color: AwColors.indigoInk.withOpacity(0.3), width: 2),
                      padding: EdgeInsets.zero,
                      backgroundColor: AwColors.indigoInk.withOpacity(0.3),
                    ),
                    child:
                        const Icon(Icons.backspace, color: AwColors.boldBlack),
                  ),
                ),
              ),
            ),
          ),
        ]),
      ],
    );
  }
}
