import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DBHelper {
  static const int _dbVersion = 2;
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
        uid_correo TEXT NOT NULL,
        fecha INTEGER NOT NULL,
        ingreso_fijo INTEGER DEFAULT 0,
        ingreso_imprevisto INTEGER DEFAULT 0,
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
  }

  FutureOr<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      try {
        await db.execute('ALTER TABLE gastos ADD COLUMN subcategoria TEXT;');
      } catch (e) {}
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
