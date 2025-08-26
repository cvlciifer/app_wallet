import 'package:app_wallet/Library/main_library.dart';

class ConsejoProvider {
  static String? _consejoDelDiaCache;
  static DateTime? _fechaUltimoConsejo;

  static Future<String> obtenerConsejoDelDia() async {
    final hoy = DateTime.now();

    if (_fechaUltimoConsejo != null &&
        _fechaUltimoConsejo!.day == hoy.day &&
        _fechaUltimoConsejo!.month == hoy.month &&
        _fechaUltimoConsejo!.year == hoy.year) {
      return _consejoDelDiaCache!;
    }
    try {
      var consejoDelDia = await getConsejoDelDia();
      _consejoDelDiaCache = consejoDelDia['consejo'] ?? 'Consejo no disponible';
      _fechaUltimoConsejo = hoy;
      return _consejoDelDiaCache!;
    } catch (e) {
      throw ('Error al obtener el consejo: $e');
    }
  }

  static Future<void> mostrarConsejoDialog(BuildContext context) async {
    await _mostrarDialogConConsejo(context, null);
  }

  static Future<void> _mostrarDialogConConsejo(BuildContext context, String? error) async {
    try {
      var consejo = await obtenerConsejoDelDia();
      if (!context.mounted) return;

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const AwText.bold('Tu consejo diario', color: AwColors.boldBlack,),
          content: AwText(text: consejo),
          actions: <Widget>[
            WalletButton.primaryButton(
                buttonText: 'Cerrar',
                onPressed: () {
                  Navigator.of(context).pop();
                }),
          ],
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const AwText(text: 'Error'),
          content: AwText(text: error ?? 'No se pudo obtener el consejo.'),
          actions: <Widget>[
            WalletButton.primaryButton(
              buttonText: 'Cerrar',
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            WalletButton.textButton(
              buttonText: 'Reintentar',
              onPressed: () {
                Navigator.of(context).pop();
                _mostrarDialogConConsejo(context, 'Reintentando obtener el consejo...');
              },
            ),
          ],
        ),
      );
    }
  }
}
