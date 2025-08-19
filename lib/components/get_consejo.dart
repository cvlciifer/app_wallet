import 'package:flutter/material.dart';
import 'package:app_wallet/services_bd/firebase_Service.dart';

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

  static Future<void> _mostrarDialogConConsejo(
      BuildContext context, String? error) async {
    try {
      var consejo = await obtenerConsejoDelDia();
      if (!context.mounted) return;

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Tu consejo diario'),
          content: Text(consejo),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cerrar'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Error'),
          content: Text(error ?? 'No se pudo obtener el consejo.'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cerrar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Cerrar el diálogo antes de reintentar
                _mostrarDialogConConsejo(context, 'Reintentando obtener el consejo...');
              },
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }
  }
}
