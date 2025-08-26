import 'package:app_wallet/Library/main_library.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.money_off, // Icono de "sin dinero"
            size: AwSize.s64,
            color: AwColors.grey,
          ),
          AwSpacing.m,
          AwText(
            text: 'No se encontraron gastos.\n¡Empieza a agregar algunos!',
            textAlign: TextAlign.center,
            size: AwSize.s18,
            color: AwColors.grey,
          ),
        ],
      ),
    );
  }
}
