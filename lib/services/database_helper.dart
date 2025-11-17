import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:faustina/models/models.dart';



class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'finance.db');
    
    // Delete existing database to force recreation
    // await deleteDatabase(path);
    
    return await openDatabase(
      path,
      version: 3, // Increment version to force recreation
      onCreate: _createTables,
      onUpgrade: _upgradeDatabase,
      onDowngrade: _onDowngrade,
    );
  }

  // Method to force delete and recreate database
  Future<void> resetDatabase() async {
    String path = join(await getDatabasesPath(), 'finance.db');
    await deleteDatabase(path);
    _database = null;
    await database; // This will recreate the database
  }

  Future<void> _createTables(Database db, int version) async {
    print('Creating tables for version: $version');
    
    // Drop existing tables if they exist
    //await db.execute('DROP TABLE IF EXISTS business_owner');
    //await db.execute('DROP TABLE IF EXISTS sales');
    //await db.execute('DROP TABLE IF EXISTS expenses');

    // Create business_owner table
    await db.execute('''
      CREATE TABLE business_owner(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        email TEXT,
        phone TEXT,
        businessName TEXT NOT NULL,
        address TEXT,
        createdAt TEXT NOT NULL
      )
    ''');

    // Create sales table
    await db.execute('''
      CREATE TABLE sales(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT,
        description TEXT,
        amount REAL,
        category TEXT
      )
    ''');

    // Create expenses table
    await db.execute('''
      CREATE TABLE expenses(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT,
        description TEXT,
        amount REAL,
        category TEXT
      )
    ''');

    print('All tables created successfully');
  }

  Future<void> _upgradeDatabase(Database db, int oldVersion, int newVersion) async {
    print('Upgrading database from version $oldVersion to $newVersion');
    
    if (oldVersion < 3) {
      // Force recreate all tables for versions less than 3
      await _createTables(db, newVersion);
    }
  }

  Future<void> _onDowngrade(Database db, int oldVersion, int newVersion) async {
    print('Downgrading database from version $oldVersion to $newVersion');
    await _createTables(db, newVersion);
  }

  // ==================== BUSINESS OWNER CRUD OPERATIONS ====================

  Future<int> insertBusinessOwner(BusinessOwner owner) async {
    try {
      final db = await database;
      return await db.insert('business_owner', owner.toMap());
    } catch (e) {
      print('Error inserting business owner: $e');
      rethrow;
    }
  }

  Future<BusinessOwner?> getBusinessOwner(int id) async {
    try {
      final db = await database;
      final maps = await db.query(
        'business_owner',
        where: 'id = ?',
        whereArgs: [id],
      );

      if (maps.isNotEmpty) {
        return BusinessOwner.fromMap(maps.first);
      }
      return null;
    } catch (e) {
      print('Error getting business owner: $e');
      return null;
    }
  }

  Future<List<BusinessOwner>> getAllBusinessOwners() async {
    try {
      final db = await database;
      final maps = await db.query('business_owner', orderBy: 'id DESC');
      return maps.map((map) => BusinessOwner.fromMap(map)).toList();
    } catch (e) {
      print('Error getting all business owners: $e');
      return [];
    }
  }

  Future<BusinessOwner?> getPrimaryBusinessOwner() async {
    try {
      final db = await database;
      final maps = await db.query('business_owner', limit: 1);
      if (maps.isNotEmpty) {
        return BusinessOwner.fromMap(maps.first);
      }
      return null;
    } catch (e) {
      print('Error getting primary business owner: $e');
      return null;
    }
  }

  Future<int> updateBusinessOwner(BusinessOwner owner) async {
    try {
      final db = await database;
      if (owner.id == null) {
        throw Exception('Cannot update business owner without ID');
      }
      return await db.update(
        'business_owner',
        owner.toMap(),
        where: 'id = ?',
        whereArgs: [owner.id],
      );
    } catch (e) {
      print('Error updating business owner: $e');
      rethrow;
    }
  }

  Future<int> deleteBusinessOwner(int id) async {
    try {
      final db = await database;
      return await db.delete(
        'business_owner',
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      print('Error deleting business owner: $e');
      rethrow;
    }
  }

  Future<bool> businessOwnerExists() async {
    try {
      final db = await database;
      final count = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM business_owner')
      );
      return count != null && count > 0;
    } catch (e) {
      print('Error checking if business owner exists: $e');
      return false;
    }
  }

  // ==================== SALES CRUD OPERATIONS ====================

  Future<int> insertSale(Map<String, dynamic> sale) async {
    try {
      final db = await database;
      return await db.insert('sales', sale);
    } catch (e) {
      print('Error inserting sale: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getSales() async {
    try {
      final db = await database;
      return await db.query('sales', orderBy: 'date DESC');
    } catch (e) {
      print('Error getting sales: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getSalesByDateRange(DateTime start, DateTime end) async {
    try {
      final db = await database;
      return await db.query(
        'sales',
        where: 'date BETWEEN ? AND ?',
        whereArgs: [start.toIso8601String(), end.toIso8601String()],
        orderBy: 'date DESC',
      );
    } catch (e) {
      print('Error getting sales by date range: $e');
      return [];
    }
  }

  Future<int> updateSale(int id, Map<String, dynamic> sale) async {
    try {
      final db = await database;
      return await db.update(
        'sales',
        sale,
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      print('Error updating sale: $e');
      rethrow;
    }
  }

  Future<int> deleteSale(int id) async {
    try {
      final db = await database;
      return await db.delete(
        'sales',
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      print('Error deleting sale: $e');
      rethrow;
    }
  }

  // ==================== EXPENSES CRUD OPERATIONS ====================

  Future<int> insertExpense(Map<String, dynamic> expense) async {
    try {
      final db = await database;
      return await db.insert('expenses', expense);
    } catch (e) {
      print('Error inserting expense: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getExpenses() async {
    try {
      final db = await database;
      return await db.query('expenses', orderBy: 'date DESC');
    } catch (e) {
      print('Error getting expenses: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getExpensesByDateRange(DateTime start, DateTime end) async {
    try {
      final db = await database;
      return await db.query(
        'expenses',
        where: 'date BETWEEN ? AND ?',
        whereArgs: [start.toIso8601String(), end.toIso8601String()],
        orderBy: 'date DESC',
      );
    } catch (e) {
      print('Error getting expenses by date range: $e');
      return [];
    }
  }

  Future<int> updateExpense(int id, Map<String, dynamic> expense) async {
    try {
      final db = await database;
      return await db.update(
        'expenses',
        expense,
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      print('Error updating expense: $e');
      rethrow;
    }
  }

  Future<int> deleteExpense(int id) async {
    try {
      final db = await database;
      return await db.delete(
        'expenses',
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      print('Error deleting expense: $e');
      rethrow;
    }
  }

  // ==================== SUMMARY METHODS ====================

  Future<double> getTotalSalesByDateRange(DateTime start, DateTime end) async {
    try {
      final db = await database;
      final result = await db.rawQuery('''
        SELECT SUM(amount) as total FROM sales 
        WHERE date BETWEEN ? AND ?
      ''', [start.toIso8601String(), end.toIso8601String()]);
      return result.first['total'] as double? ?? 0.0;
    } catch (e) {
      print('Error getting total sales by date range: $e');
      return 0.0;
    }
  }

  Future<double> getTotalExpensesByDateRange(DateTime start, DateTime end) async {
    try {
      final db = await database;
      final result = await db.rawQuery('''
        SELECT SUM(amount) as total FROM expenses 
        WHERE date BETWEEN ? AND ?
      ''', [start.toIso8601String(), end.toIso8601String()]);
      return result.first['total'] as double? ?? 0.0;
    } catch (e) {
      print('Error getting total expenses by date range: $e');
      return 0.0;
    }
  }

  Future<double> getTotalSales() async {
    try {
      final db = await database;
      final result = await db.rawQuery('SELECT SUM(amount) as total FROM sales');
      return result.first['total'] as double? ?? 0.0;
    } catch (e) {
      print('Error getting total sales: $e');
      return 0.0;
    }
  }

  Future<double> getTotalExpenses() async {
    try {
      final db = await database;
      final result = await db.rawQuery('SELECT SUM(amount) as total FROM expenses');
      return result.first['total'] as double? ?? 0.0;
    } catch (e) {
      print('Error getting total expenses: $e');
      return 0.0;
    }
  }
}