import 'dart:developer';
import 'package:app_wallet/core/data_base_local/create_db.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DBDebugHelper {
  /// Imprime la ubicación de la base de datos
  static Future<void> printDatabasePath() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'adminwallet.db');
    log('Ubicación de la BD: $path');
  }

  /// Muestra todos los usuarios en la base de datos
  static Future<void> showAllUsers() async {
    try {
      final db = await DBHelper.instance.database;
      final users = await db.query('usuarios');
      log('Usuarios en la BD:');
      for (var user in users) {
        log('   - UID: ${user['uid']}, Email: ${user['correo']}');
      }
      if (users.isEmpty) {
        log('No hay usuarios registrados');
      }
    } catch (e) {
      log('Error al consultar usuarios: $e');
    }
  }

  /// Muestra todos los gastos en la base de datos
  static Future<void> showAllExpenses() async {
    try {
      final db = await DBHelper.instance.database;
      final expenses = await db.query('gastos', orderBy: 'fecha DESC');
      log('Gastos en la BD:');
      for (var expense in expenses) {
        final fecha = DateTime.fromMillisecondsSinceEpoch(expense['fecha'] as int);
        log('${expense['uid_gasto']}, Usuario: ${expense['uid_correo']}, Nombre: ${expense['nombre']}, Cantidad: ${expense['cantidad']}, Categoría: ${expense['categoria']}, Fecha: $fecha');
      }
      if (expenses.isEmpty) {
        log('No hay gastos registrados');
      }
    } catch (e) {
      log('Error al consultar gastos: $e');
    }
  }

  /// Función completa de debug - muestra todo
  static Future<void> debugDatabase() async {
    log('=== DEBUG DE BASE DE DATOS ===');
    await printDatabasePath();
    await showAllUsers();
    await showAllExpenses();
    log('=== FIN DEBUG ===');
  }

  /// Cuenta los registros en cada tabla
  static Future<void> showTableCounts() async {
    try {
      final db = await DBHelper.instance.database;

      final userCount = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM usuarios')) ?? 0;
      final expenseCount = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM gastos')) ?? 0;
      final pendingCount = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM pending_ops')) ?? 0;

      log('Conteo de registros:');
      log('   - Usuarios: $userCount');
      log('   - Gastos: $expenseCount');
      log('   - Operaciones pendientes: $pendingCount');
    } catch (e) {
      log('Error al contar registros: $e');
    }
  }
}
