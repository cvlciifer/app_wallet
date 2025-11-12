import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DBHelper {
  static const int _dbVersion = 5;
  static const String _dbName = 'adminwallet.db';

  DBHelper._privateConstructor();
  static final DBHelper instance = DBHelper._privateConstructor();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, _dbName);

    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onConfigure: _onConfigure,
    );
  }

  FutureOr<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  FutureOr<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE usuarios (
        uid TEXT PRIMARY KEY,
        correo TEXT NOT NULL UNIQUE
      );
    ''');

    await db.execute('''
      CREATE TABLE ingresos (
        uid_ingreso INTEGER PRIMARY KEY AUTOINCREMENT,
        id TEXT,
        uid_correo TEXT NOT NULL,
        fecha INTEGER NOT NULL,
        ingreso_fijo INTEGER DEFAULT 0,
        ingreso_imprevisto INTEGER DEFAULT 0,
        ingreso_total INTEGER DEFAULT 0,
        sync_status INTEGER DEFAULT 0,
        FOREIGN KEY (uid_correo) REFERENCES usuarios(uid) ON DELETE CASCADE
      );
    ''');

    await db.execute('CREATE INDEX idx_ingresos_uid_fecha ON ingresos(uid_correo, fecha);');

    await db.execute('''
      CREATE TABLE gastos (
        uid_gasto INTEGER PRIMARY KEY AUTOINCREMENT,
        id TEXT,
        uid_correo TEXT NOT NULL,
        fecha INTEGER NOT NULL,
        cantidad INTEGER NOT NULL,
        nombre TEXT,
        categoria TEXT,
        subcategoria TEXT,
        recurrence_id TEXT,
        recurrence_index INTEGER,
        sync_status INTEGER DEFAULT 0,
        FOREIGN KEY (uid_correo) REFERENCES usuarios(uid) ON DELETE CASCADE
      );
    ''');

    await db.execute('CREATE INDEX idx_gastos_uid_fecha ON gastos(uid_correo, fecha);');
    await db.execute('CREATE INDEX idx_gastos_uid_categoria ON gastos(uid_correo, categoria);');

    await db.execute('''
      CREATE TABLE pending_ops (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        table_name TEXT NOT NULL,
        operation TEXT NOT NULL, -- INSERT, UPDATE, DELETE
        record_id TEXT,         -- id del registro afectado (puede ser string UUID o entero en texto)
        payload TEXT,           -- json con los datos para aplicar en la nube
        created_at INTEGER NOT NULL
      );
    ''');

    await db.execute('CREATE INDEX idx_pending_ops_created_at ON pending_ops(created_at);');

    // Tabla para manejar gastos recurrentes (metadatos)
    await db.execute('''
      CREATE TABLE gastos_recurrentes (
        uid_recurrente INTEGER PRIMARY KEY AUTOINCREMENT,
        id TEXT,
        uid_correo TEXT NOT NULL,
        nombre TEXT,
        cantidad INTEGER NOT NULL,
        categoria TEXT,
        subcategoria TEXT,
        dia INTEGER NOT NULL,
        meses INTEGER NOT NULL,
        start_year INTEGER NOT NULL,
        start_month INTEGER NOT NULL,
        created_at INTEGER NOT NULL,
        sync_status INTEGER DEFAULT 0,
        FOREIGN KEY (uid_correo) REFERENCES usuarios(uid) ON DELETE CASCADE
      );
    ''');

    await db.execute('CREATE INDEX idx_recurrentes_uid ON gastos_recurrentes(uid_correo);');

    // Tabla para mapear items generados por una recurrencia a los gastos creados
    await db.execute('''
      CREATE TABLE gastos_recurrentes_items (
        uid_item INTEGER PRIMARY KEY AUTOINCREMENT,
        recurrence_id TEXT NOT NULL,
        expense_id TEXT NOT NULL,
        fecha INTEGER NOT NULL,
        cantidad INTEGER NOT NULL,
        month_index INTEGER NOT NULL,
        mutable INTEGER DEFAULT 0,
        sync_status INTEGER DEFAULT 0
      );
    ''');
    await db.execute('CREATE INDEX idx_recurrentes_items_recurrence ON gastos_recurrentes_items(recurrence_id);');
  }

  FutureOr<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      try {
        await db.execute('ALTER TABLE gastos ADD COLUMN subcategoria TEXT;');
      } catch (e) {}
    }
    if (oldVersion < 3) {
      try {
        await db.execute('ALTER TABLE ingresos ADD COLUMN id TEXT;');
      } catch (e) {}
      try {
        await db.execute('ALTER TABLE ingresos ADD COLUMN ingreso_total INTEGER DEFAULT 0;');
      } catch (e) {}
      try {
        await db.execute('ALTER TABLE ingresos ADD COLUMN sync_status INTEGER DEFAULT 0;');
      } catch (e) {}
    }
    if (oldVersion < 5) {
      // Add recurrence columns to gastos (if not already present) and create
      // recurrent tables. Use try/catch to be safe across different upgrade paths.
      try {
        await db.execute('ALTER TABLE gastos ADD COLUMN recurrence_id TEXT;');
      } catch (e) {}
      try {
        await db.execute('ALTER TABLE gastos ADD COLUMN recurrence_index INTEGER;');
      } catch (e) {}

      try {
        await db.execute('''
      CREATE TABLE gastos_recurrentes (
        uid_recurrente INTEGER PRIMARY KEY AUTOINCREMENT,
        id TEXT,
        uid_correo TEXT NOT NULL,
        nombre TEXT,
        cantidad INTEGER NOT NULL,
        categoria TEXT,
        subcategoria TEXT,
        dia INTEGER NOT NULL,
        meses INTEGER NOT NULL,
        start_year INTEGER NOT NULL,
        start_month INTEGER NOT NULL,
        created_at INTEGER NOT NULL,
        sync_status INTEGER DEFAULT 0,
        FOREIGN KEY (uid_correo) REFERENCES usuarios(uid) ON DELETE CASCADE
      );
    ''');
      } catch (_) {}
      try {
        await db.execute('CREATE INDEX idx_recurrentes_uid ON gastos_recurrentes(uid_correo);');
      } catch (_) {}
      try {
        await db.execute('''
      CREATE TABLE gastos_recurrentes_items (
        uid_item INTEGER PRIMARY KEY AUTOINCREMENT,
        recurrence_id TEXT NOT NULL,
        expense_id TEXT NOT NULL,
        fecha INTEGER NOT NULL,
        cantidad INTEGER NOT NULL,
        month_index INTEGER NOT NULL,
        mutable INTEGER DEFAULT 0,
        sync_status INTEGER DEFAULT 0
      );
    ''');
      } catch (_) {}
      try {
        await db.execute('CREATE INDEX idx_recurrentes_items_recurrence ON gastos_recurrentes_items(recurrence_id);');
      } catch (_) {}
    }
  }

  Future<void> upsertUsuario({required String uid, required String correo}) async {
    final db = await database;
    await db.insert('usuarios', {'uid': uid, 'correo': correo}, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<Map<String, dynamic>?> getUsuarioPorUid(String uid) async {
    final db = await database;
    final rows = await db.query(
      'usuarios',
      where: 'uid = ?',
      whereArgs: [uid],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first;
  }

  Future<Map<String, dynamic>?> getUsuarioPorEmail(String email) async {
    final db = await database;
    final rows = await db.query(
      'usuarios',
      where: 'correo = ?',
      whereArgs: [email.toLowerCase()],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first;
  }

  Future<bool> existeUsuarioPorUid(String uid) async {
    final usuario = await getUsuarioPorUid(uid);
    return usuario != null;
  }

  Future<bool> existeUsuarioPorEmail(String email) async {
    final usuario = await getUsuarioPorEmail(email);
    return usuario != null;
  }

  Future<List<Map<String, dynamic>>> getTodosLosUsuarios() async {
    final db = await database;
    return await db.query('usuarios', orderBy: 'correo');
  }

  Future close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
