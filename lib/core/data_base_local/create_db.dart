import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

/// DB helper singleton para Flutter + sqflite
/// Crea la base de datos si no existe y expone métodos básicos de inicialización
class DBHelper {
  // versión de la base de datos - incrementa cuando realices cambios en las tablas
  // Se incrementó a 2 para añadir la columna 'subcategoria' en la tabla 'gastos'
  static const int _dbVersion = 2;
  static const String _dbName = 'adminwallet.db';

  // Singleton
  DBHelper._privateConstructor();
  static final DBHelper instance = DBHelper._privateConstructor();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // Inicializa la base de datos
  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, _dbName);

    // Abre la base de datos (la crea si no existe)
    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onConfigure: _onConfigure,
    );
  }

  // Enable foreign keys
  FutureOr<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  // Se ejecuta la primera vez que se crea la BD
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

    // Tabla opcional para operaciones pendientes (sync queue)
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

  // Migraciones futuras
  FutureOr<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Migraciones entre versiones
    if (oldVersion < 2) {
      // Añadimos la columna subcategoria para guardar el id de la subcategoría
      try {
        await db.execute('ALTER TABLE gastos ADD COLUMN subcategoria TEXT;');
      } catch (e) {
        // En caso de error (por ejemplo, si la columna ya existe) lo ignoramos
      }
    }
    // agrega migraciones aquí cuando subas _dbVersion
  }

  // Upsert usuario (inserta o reemplaza)
  Future<void> upsertUsuario({required String uid, required String correo}) async {
    final db = await database;
    await db.insert(
      'usuarios',
      {'uid': uid, 'correo': correo},
      conflictAlgorithm: ConflictAlgorithm.replace, // reemplaza si ya existía
    );
  }

  // Obtener usuario por uid
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

  // Obtener usuario por email
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

  // Verificar si un usuario existe por UID
  Future<bool> existeUsuarioPorUid(String uid) async {
    final usuario = await getUsuarioPorUid(uid);
    return usuario != null;
  }

  // Verificar si un usuario existe por email
  Future<bool> existeUsuarioPorEmail(String email) async {
    final usuario = await getUsuarioPorEmail(email);
    return usuario != null;
  }

  // Obtener todos los usuarios (para debug)
  Future<List<Map<String, dynamic>>> getTodosLosUsuarios() async {
    final db = await database;
    return await db.query('usuarios', orderBy: 'correo');
  }

  /// Cierra la base de datos
  Future close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
