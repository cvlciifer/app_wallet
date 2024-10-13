import 'package:flutter/material.dart';
import 'package:app_wallet/services_bd/firebase_Service.dart';

class ConsejoProvider {
  static String? _consejoDelDiaCache;
  static DateTime? _fechaUltimoConsejo;

  // Función que obtiene el consejo del día, solo una vez al día
  static Future<String> obtenerConsejoDelDia() async {
    final hoy = DateTime.now();

    // Si ya obtuvimos el consejo hoy, lo devolvemos desde el caché
    if (_fechaUltimoConsejo != null &&
        _fechaUltimoConsejo!.day == hoy.day &&
        _fechaUltimoConsejo!.month == hoy.month &&
        _fechaUltimoConsejo!.year == hoy.year) {
      return _consejoDelDiaCache!;
    }

    // Intentamos obtener el consejo desde Firebase
    try {
      var consejoDelDia = await getConsejoDelDia();
      _consejoDelDiaCache = consejoDelDia['consejo'] ?? 'Consejo no disponible';
      _fechaUltimoConsejo = hoy;
      return _consejoDelDiaCache!;
    } catch (e) {
      throw ('Error al obtener el consejo: $e');
    }
  }

  // Función para mostrar el diálogo del consejo
  static Future<void> mostrarConsejoDialog(BuildContext context) async {
    await _mostrarDialogConConsejo(context, null);
  }

  // Función para mostrar el diálogo con manejo de errores y reintentar
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
      // Si hay un error, mostramos un diálogo con la opción de reintentar
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
