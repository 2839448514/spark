import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

import 'dart:io';
import 'dart:async';

class Category {
  final int? id;
  final String name;
  final String? description;
  final String? createdAt;

  Category({
    this.id,
    required this.name,
    this.description,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'createdAt': createdAt ?? DateTime.now().toIso8601String(),
    };
  }

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      createdAt: map['createdAt'],
    );
  }
}

class Note {
  final int? id;
  final String title;
  final String content;
  final int? categoryId;
  final String? createdAt;
  final String? updatedAt;

  Note({
    this.id,
    required this.title,
    required this.content,
    this.categoryId,
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'categoryId': categoryId,
      'createdAt': createdAt ?? DateTime.now().toIso8601String(),
      'updatedAt': updatedAt ?? DateTime.now().toIso8601String(),
    };
  }

  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(
      id: map['id'],
      title: map['title'],
      content: map['content'],
      categoryId: map['categoryId'],
      createdAt: map['createdAt'],
      updatedAt: map['updatedAt'],
    );
  }
}

class NoteDatabase {
  static Database? _db;
  static final NoteDatabase instance = NoteDatabase._init();
  
  NoteDatabase._init();
  
  static Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDB('notes.db');
    return _db!;
  }  static Future<Database> _initDB(String filePath) async {
    String path;
    try {
      if (Platform.isWindows || Platform.isLinux) {
        // Windows 和 Linux 上使用应用程序目录
        final appDir = Directory.current;
        path = join(appDir.path, 'data', filePath);
        // 确保目录存在
        final dbDirectory = Directory(join(appDir.path, 'data'));
        if (!await dbDirectory.exists()) {
          await dbDirectory.create(recursive: true);
        }
      } else {
        // Android 和 iOS 可以使用path_provider
        Directory documentsDirectory = await getApplicationDocumentsDirectory();
        path = join(documentsDirectory.path, filePath);
      }
    } catch (e) {
      // 备用方法
      print('path_provider 不可用，使用备用方法: $e');
      try {
        path = join(await getDatabasesPath(), filePath);
      } catch (e) {
        // 如果仍然失败，使用临时目录
        final Directory tempDir = await Directory.systemTemp.createTemp('db_');
        path = join(tempDir.path, filePath);
        print('使用临时目录: $path');
      }
    }
    
    print('数据库路径: $path');
      try {
      return await openDatabase(
        path,
        version: 3,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      );
    } catch (e) {
      print('打开数据库失败: $e');
      rethrow; // 重新抛出异常以便上层处理
    }
  }

  static Future _onCreate(Database db, int version) async {
    // 创建分类表
    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        description TEXT,
        createdAt TEXT NOT NULL
      )
    ''');
    
    // 创建笔记表
    await db.execute('''
      CREATE TABLE notes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        content TEXT NOT NULL,
        categoryId INTEGER,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL,
        FOREIGN KEY (categoryId) REFERENCES categories (id) ON DELETE SET NULL      )
    ''');
    
    // 创建默认分类
    await db.insert('categories', {
      'name': '默认分类',
      'description': '默认的笔记分类',
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  static Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // 创建分类表
      await db.execute('''
        CREATE TABLE categories (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL UNIQUE,
          description TEXT,
          createdAt TEXT NOT NULL
        )
      ''');
        // 为笔记表添加categoryId列
      await db.execute('ALTER TABLE notes ADD COLUMN categoryId INTEGER');
      
      // 创建默认分类
      await db.insert('categories', {
        'name': '默认分类',
        'description': '默认的笔记分类',
        'createdAt': DateTime.now().toIso8601String(),
      });
    }
    
    if (oldVersion < 3) {
      // 删除预设的"工作"和"生活"分类
      await db.delete('categories', where: 'name = ?', whereArgs: ['工作']);
      await db.delete('categories', where: 'name = ?', whereArgs: ['生活']);
      
      // 将这些分类下的笔记移动到"未分类"（null）
      await db.update(
        'notes',
        {'categoryId': null},
        where: 'categoryId IN (SELECT id FROM categories WHERE name IN (?, ?))',
        whereArgs: ['工作', '生活'],
      );
    }
  }

  // 初始化应用时调用，创建一些示例笔记
  static Future<void> initializeDatabase() async {
    final db = await database;
    final notes = await db.query('notes');
    
    // 如果数据库为空，添加一些示例笔记
    if (notes.isEmpty) {
      await addSampleNotes();
    }
  }
  
  static Future<void> addSampleNotes() async {
    final sampleNotes = [
      Note(
        title: '欢迎使用笔记应用',
        content: '这是您的第一个笔记。您可以在此记录重要信息、想法和任务。\n\n点击底部的 + 按钮添加新笔记。',
      ),
      Note(
        title: '使用技巧',
        content: '1. 长按笔记可以删除\n2. 点击笔记可以编辑\n3. 使用搜索功能快速找到笔记',
      ),
    ];
    
    for (var note in sampleNotes) {
      await insertNote(note);
    }
  }

  // 插入一个新笔记
  static Future<int> insertNote(Note note) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    
    final noteMap = note.toMap();
    // 确保时间戳已设置
    noteMap['createdAt'] = noteMap['createdAt'] ?? now;
    noteMap['updatedAt'] = noteMap['updatedAt'] ?? now;
    
    return await db.insert('notes', noteMap);
  }

  // 获取所有笔记
  static Future<List<Note>> getAllNotes() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'notes',
      orderBy: 'updatedAt DESC',
    );
    
    return List.generate(maps.length, (i) {
      return Note.fromMap(maps[i]);
    });
  }

  // 根据ID获取笔记
  static Future<Note?> getNoteById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'notes',
      where: 'id = ?',
      whereArgs: [id],
    );
    
    if (maps.isNotEmpty) {
      return Note.fromMap(maps.first);
    }
    return null;
  }
  // 更新笔记
  static Future<int> updateNote(Note note) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    
    return await db.update(
      'notes',
      {
        'title': note.title,
        'content': note.content,
        'categoryId': note.categoryId,
        'updatedAt': now,
      },
      where: 'id = ?',
      whereArgs: [note.id],
    );
  }

  // 删除笔记
  static Future<int> deleteNote(int id) async {
    final db = await database;
    return await db.delete(
      'notes',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
  // 搜索笔记
  static Future<List<Note>> searchNotes(String query) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'notes',
      where: 'title LIKE ? OR content LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'updatedAt DESC',
    );
    
    return List.generate(maps.length, (i) {
      return Note.fromMap(maps[i]);
    });
  }

  // 根据分类获取笔记
  static Future<List<Note>> getNotesByCategory(int? categoryId) async {
    final db = await database;
    List<Map<String, dynamic>> maps;
    
    if (categoryId == null) {
      // 获取未分类的笔记
      maps = await db.query(
        'notes',
        where: 'categoryId IS NULL',
        orderBy: 'updatedAt DESC',
      );
    } else {
      maps = await db.query(
        'notes',
        where: 'categoryId = ?',
        whereArgs: [categoryId],
        orderBy: 'updatedAt DESC',
      );
    }
    
    return List.generate(maps.length, (i) {
      return Note.fromMap(maps[i]);
    });
  }

  // ==================== 分类管理方法 ====================
  
  // 插入新分类
  static Future<int> insertCategory(Category category) async {
    final db = await database;
    final categoryMap = category.toMap();
    categoryMap.remove('id');
    return await db.insert('categories', categoryMap);
  }

  // 获取所有分类
  static Future<List<Category>> getAllCategories() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'categories',
      orderBy: 'name ASC',
    );
    
    return List.generate(maps.length, (i) {
      return Category.fromMap(maps[i]);
    });
  }

  // 根据ID获取分类
  static Future<Category?> getCategoryById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'categories',
      where: 'id = ?',
      whereArgs: [id],
    );
    
    if (maps.isNotEmpty) {
      return Category.fromMap(maps.first);
    }
    return null;
  }

  // 更新分类
  static Future<int> updateCategory(Category category) async {
    final db = await database;
    
    return await db.update(
      'categories',
      {
        'name': category.name,
        'description': category.description,
      },
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  // 删除分类
  static Future<int> deleteCategory(int id) async {
    final db = await database;
    // 删除分类时，将该分类下的笔记设为未分类
    await db.update(
      'notes',
      {'categoryId': null},
      where: 'categoryId = ?',
      whereArgs: [id],
    );
    
    return await db.delete(
      'categories',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // 获取分类及其包含的笔记数量
  static Future<List<Map<String, dynamic>>> getCategoriesWithCount() async {
    final db = await database;
    final List<Map<String, dynamic>> result = await db.rawQuery('''
      SELECT c.*, COUNT(n.id) as noteCount
      FROM categories c
      LEFT JOIN notes n ON c.id = n.categoryId
      GROUP BY c.id, c.name, c.description, c.createdAt
      ORDER BY c.name ASC
    ''');
    
    return result;
  }
}
