import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../models/flashcard_model.dart';
import '../models/curriculum_model.dart';
import '../models/note_model.dart';
import '../models/ai_content_model.dart';
import '../models/worksheet_model.dart';
import '../models/game_model.dart';
import '../models/activity_model.dart';
import '../models/story_model.dart';

/// Central SQLite Database Access Layer for PALASH
/// Handles offline-first persistence for all educational and teacher data.
class AppDatabase {
  static final AppDatabase instance = AppDatabase._internal();
  static Database? _database;

  AppDatabase._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    String dbPath;
    if (Platform.isAndroid || Platform.isIOS) {
      final appDocDir = await getApplicationDocumentsDirectory();
      dbPath = p.join(appDocDir.path, 'palash_app.db');
    } else {
      final appDocDir = await getApplicationSupportDirectory();
      dbPath = p.join(appDocDir.path, 'palash_app.db');
    }

    return await openDatabase(
      dbPath,
      version: 3,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // 1. Flashcards Table
    await db.execute('''
      CREATE TABLE flashcards (
        id TEXT PRIMARY KEY,
        category TEXT NOT NULL,
        subcategory TEXT NOT NULL,
        hindi TEXT NOT NULL,
        santali TEXT NOT NULL,
        santaliOlChiki TEXT,
        imagePath TEXT,
        iconName TEXT,
        pronunciation TEXT,
        linguistNote TEXT,
        isDefault INTEGER NOT NULL DEFAULT 1,
        isTeacherCreated INTEGER NOT NULL DEFAULT 0,
        isPublished INTEGER NOT NULL DEFAULT 1,
        createdAt TEXT NOT NULL
      )
    ''');

    // 2. Curriculum Lessons Table
    await db.execute('''
      CREATE TABLE curriculum (
        id TEXT PRIMARY KEY,
        gradeClass INTEGER NOT NULL,
        subject TEXT NOT NULL,
        titleHindi TEXT NOT NULL,
        titleSantali TEXT NOT NULL,
        description TEXT NOT NULL
      )
    ''');

    // 3. Teacher Notes Table
    await db.execute('''
      CREATE TABLE notes (
        id TEXT PRIMARY KEY,
        lessonId TEXT NOT NULL,
        gradeClass INTEGER NOT NULL,
        subject TEXT NOT NULL,
        title TEXT NOT NULL,
        hindiContent TEXT NOT NULL,
        santaliContent TEXT NOT NULL,
        santaliOlChiki TEXT,
        author TEXT NOT NULL DEFAULT 'Teacher',
        isDraft INTEGER NOT NULL DEFAULT 0,
        isApproved INTEGER NOT NULL DEFAULT 0,
        isPublished INTEGER NOT NULL DEFAULT 0,
        createdAt TEXT NOT NULL
      )
    ''');

    // 4. AI Generated Contents Table
    await db.execute('''
      CREATE TABLE ai_contents (
        id TEXT PRIMARY KEY,
        noteId TEXT NOT NULL,
        noteTitle TEXT NOT NULL,
        explanationHindi TEXT NOT NULL,
        explanationSantali TEXT NOT NULL,
        translationSantali TEXT NOT NULL,
        payloadJson TEXT NOT NULL,
        state TEXT NOT NULL DEFAULT 'draft',
        createdAt TEXT NOT NULL
      )
    ''');

    // 5. Worksheets Table
    await db.execute('''
      CREATE TABLE worksheets (
        id TEXT PRIMARY KEY,
        gradeClass INTEGER NOT NULL,
        subject TEXT NOT NULL,
        titleHindi TEXT NOT NULL,
        titleSantali TEXT NOT NULL,
        payloadJson TEXT NOT NULL
      )
    ''');

    // 6. Games Table
    await db.execute('''
      CREATE TABLE games (
        id TEXT PRIMARY KEY,
        category TEXT NOT NULL,
        gameType TEXT NOT NULL,
        titleHindi TEXT NOT NULL,
        titleSantali TEXT NOT NULL,
        descriptionHindi TEXT NOT NULL,
        descriptionSantali TEXT NOT NULL,
        isAvailableOffline INTEGER NOT NULL DEFAULT 1,
        isComingSoon INTEGER NOT NULL DEFAULT 0,
        payloadJson TEXT NOT NULL
      )
    ''');

    // 7. Activities Table
    await db.execute('''
      CREATE TABLE activities (
        id TEXT PRIMARY KEY,
        category TEXT NOT NULL,
        type TEXT NOT NULL,
        titleHindi TEXT NOT NULL,
        titleSantali TEXT NOT NULL,
        instructionsHindi TEXT NOT NULL,
        instructionsSantali TEXT NOT NULL,
        payloadJson TEXT NOT NULL
      )
    ''');

    // 8. Stories Table
    await db.execute('''
      CREATE TABLE stories (
        id TEXT PRIMARY KEY,
        titleHindi TEXT NOT NULL,
        titleSantali TEXT NOT NULL,
        coverImage TEXT NOT NULL,
        author TEXT NOT NULL,
        payloadJson TEXT NOT NULL
      )
    ''');

    // 9. Sync Metadata Table
    await db.execute('''
      CREATE TABLE sync_records (
        id TEXT PRIMARY KEY,
        entityType TEXT NOT NULL,
        entityId TEXT NOT NULL,
        syncStatus TEXT NOT NULL DEFAULT 'synced',
        lastSyncedAt TEXT NOT NULL
      )
    ''');
  }

  // Migration strategy
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add isApproved column to notes table with default 0
      await db.execute('ALTER TABLE notes ADD COLUMN isApproved INTEGER NOT NULL DEFAULT 0');
    }
    if (oldVersion < 3) {
      // Version 3: Preserve existing data and ensure non-null constraint compliance
      // Safe no-op migration maintaining built-in default content & publication flags
    }
  }

  // Flashcards CRUD
  Future<List<FlashcardItem>> getAllFlashcards() async {
    final db = await database;
    final maps = await db.query('flashcards', orderBy: 'createdAt DESC');
    return maps.map((m) => FlashcardItem(
      id: m['id'] as String,
      category: m['category'] as String,
      subcategory: m['subcategory'] as String,
      hindi: m['hindi'] as String,
      santali: m['santali'] as String,
      santaliOlChiki: m['santaliOlChiki'] as String?,
      image: m['imagePath'] as String?,
      iconName: m['iconName'] as String?,
      pronunciation: m['pronunciation'] as String?,
      linguistNote: m['linguistNote'] as String?,
      isDefault: (m['isDefault'] as int) == 1,
      isTeacherCreated: (m['isTeacherCreated'] as int) == 1,
      isPublished: (m['isPublished'] as int) == 1,
      createdAt: DateTime.parse(m['createdAt'] as String),
    )).toList();
  }

  Future<void> insertFlashcard(FlashcardItem item) async {
    final db = await database;
    await db.insert(
      'flashcards',
      {
        'id': item.id,
        'category': item.category,
        'subcategory': item.subcategory,
        'hindi': item.hindi,
        'santali': item.santali,
        'santaliOlChiki': item.santaliOlChiki,
        'imagePath': item.image,
        'iconName': item.iconName,
        'pronunciation': item.pronunciation,
        'linguistNote': item.linguistNote,
        'isDefault': item.isDefault ? 1 : 0,
        'isTeacherCreated': item.isTeacherCreated ? 1 : 0,
        'isPublished': item.isPublished ? 1 : 0,
        'createdAt': item.createdAt.toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteFlashcard(String id) async {
    final db = await database;
    await db.delete('flashcards', where: 'id = ?', whereArgs: [id]);
  }

  // Curriculum & Lessons CRUD
  Future<List<CurriculumLesson>> getCurriculum() async {
    final db = await database;
    final lessonMaps = await db.query('curriculum');
    final noteMaps = await db.query('notes', where: 'isPublished = 1');

    Map<String, List<TeacherNote>> notesByLesson = {};
    for (var m in noteMaps) {
      final note = TeacherNote(
        id: m['id'] as String,
        lessonId: m['lessonId'] as String,
        gradeClass: m['gradeClass'] as int,
        subject: m['subject'] as String,
        title: m['title'] as String,
        hindiContent: m['hindiContent'] as String,
        santaliContent: m['santaliContent'] as String,
        santaliOlChiki: m['santaliOlChiki'] as String?,
        author: m['author'] as String,
        isDraft: (m['isDraft'] as int) == 1,
        isApproved: (m['isApproved'] as int? ?? 0) == 1,
        isPublished: (m['isPublished'] as int) == 1,
        createdAt: DateTime.parse(m['createdAt'] as String),
      );
      notesByLesson.putIfAbsent(note.lessonId, () => []).add(note);
    }

    return lessonMaps.map((m) {
      final id = m['id'] as String;
      return CurriculumLesson(
        id: id,
        gradeClass: m['gradeClass'] as int,
        subject: m['subject'] as String,
        titleHindi: m['titleHindi'] as String,
        titleSantali: m['titleSantali'] as String,
        description: m['description'] as String,
        notes: notesByLesson[id] ?? [],
      );
    }).toList();
  }

  Future<void> insertCurriculumLesson(CurriculumLesson lesson) async {
    final db = await database;
    await db.insert(
      'curriculum',
      {
        'id': lesson.id,
        'gradeClass': lesson.gradeClass,
        'subject': lesson.subject,
        'titleHindi': lesson.titleHindi,
        'titleSantali': lesson.titleSantali,
        'description': lesson.description,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    for (var note in lesson.notes) {
      await insertNote(note);
    }
  }

  // Notes CRUD
  Future<List<TeacherNote>> getAllNotes() async {
    final db = await database;
    final maps = await db.query('notes', orderBy: 'createdAt DESC');
    return maps.map((m) => TeacherNote(
      id: m['id'] as String,
      lessonId: m['lessonId'] as String,
      gradeClass: m['gradeClass'] as int,
      subject: m['subject'] as String,
      title: m['title'] as String,
      hindiContent: m['hindiContent'] as String,
      santaliContent: m['santaliContent'] as String,
      santaliOlChiki: m['santaliOlChiki'] as String?,
      author: m['author'] as String,
      isDraft: (m['isDraft'] as int) == 1,
      isApproved: (m['isApproved'] as int) == 1,
      isPublished: (m['isPublished'] as int) == 1,
      createdAt: DateTime.parse(m['createdAt'] as String),
    )).toList();
  }

  Future<void> insertNote(TeacherNote note) async {
    final db = await database;
    await db.insert(
        'notes',
        {
          'id': note.id,
          'lessonId': note.lessonId,
          'gradeClass': note.gradeClass,
          'subject': note.subject,
          'title': note.title,
          'hindiContent': note.hindiContent,
          'santaliContent': note.santaliContent,
          'santaliOlChiki': note.santaliOlChiki,
          'author': note.author,
          'isDraft': note.isDraft ? 1 : 0,
          'isApproved': note.isApproved ? 1 : 0,
          'isPublished': note.isPublished ? 1 : 0,
          'createdAt': note.createdAt.toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
  }

  Future<void> updateNote(TeacherNote note) async {
    final db = await database;
    await db.update(
        'notes',
        {
          'lessonId': note.lessonId,
          'gradeClass': note.gradeClass,
          'subject': note.subject,
          'title': note.title,
          'hindiContent': note.hindiContent,
          'santaliContent': note.santaliContent,
          'santaliOlChiki': note.santaliOlChiki,
          'author': note.author,
          'isDraft': note.isDraft ? 1 : 0,
          'isApproved': note.isApproved ? 1 : 0,
          'isPublished': note.isPublished ? 1 : 0,
        },
        where: 'id = ?',
        whereArgs: [note.id],
      );
  }

  Future<void> deleteNote(String id) async {
    final db = await database;
    await db.delete('notes', where: 'id = ?', whereArgs: [id]);
  }

  // AI Generated Content CRUD
  Future<List<AIGeneratedContent>> getAllAIContents() async {
    final db = await database;
    final maps = await db.query('ai_contents', orderBy: 'createdAt DESC');
    return maps.map((m) {
      final stateStr = m['state'] as String;
      ContentState state = ContentState.draft;
      if (stateStr == 'approved') state = ContentState.approved;
      if (stateStr == 'published') state = ContentState.published;

      final payload = jsonDecode(m['payloadJson'] as String) as Map<String, dynamic>;
      
      List<FlashcardItem> fcs = [];
      if (payload['flashcards'] != null) {
        fcs = (payload['flashcards'] as List)
            .map((f) => FlashcardItem.fromJson(f as Map<String, dynamic>))
            .toList();
      }

      List<AIPracticeQuestion> questions = [];
      if (payload['practiceQuestions'] != null) {
        questions = (payload['practiceQuestions'] as List).map((q) => AIPracticeQuestion(
          questionHindi: q['questionHindi'] ?? '',
          questionSantali: q['questionSantali'] ?? '',
          optionsHindi: (q['optionsHindi'] as List? ?? []).map((e) => e.toString()).toList(),
          optionsSantali: (q['optionsSantali'] as List? ?? []).map((e) => e.toString()).toList(),
          correctIndex: q['correctIndex'] ?? 0,
          explanation: q['explanation'] ?? '',
        )).toList();
      }

      List<AIActivityIdea> acts = [];
      if (payload['activities'] != null) {
        acts = (payload['activities'] as List).map((a) => AIActivityIdea(
          titleHindi: a['titleHindi'] ?? '',
          titleSantali: a['titleSantali'] ?? '',
          descriptionHindi: a['descriptionHindi'] ?? '',
          descriptionSantali: a['descriptionSantali'] ?? '',
        )).toList();
      }

      return AIGeneratedContent(
        id: m['id'] as String,
        noteId: m['noteId'] as String,
        noteTitle: m['noteTitle'] as String,
        explanationHindi: m['explanationHindi'] as String,
        explanationSantali: m['explanationSantali'] as String,
        translationSantali: m['translationSantali'] as String,
        flashcards: fcs,
        practiceQuestions: questions,
        activities: acts,
        state: state,
        createdAt: DateTime.parse(m['createdAt'] as String),
      );
    }).toList();
  }

  Future<void> insertAIContent(AIGeneratedContent content) async {
    final db = await database;
    final payload = {
      'flashcards': content.flashcards.map((f) => f.toJson()).toList(),
      'practiceQuestions': content.practiceQuestions.map((q) => {
        'questionHindi': q.questionHindi,
        'questionSantali': q.questionSantali,
        'optionsHindi': q.optionsHindi,
        'optionsSantali': q.optionsSantali,
        'correctIndex': q.correctIndex,
        'explanation': q.explanation,
      }).toList(),
      'activities': content.activities.map((a) => {
        'titleHindi': a.titleHindi,
        'titleSantali': a.titleSantali,
        'descriptionHindi': a.descriptionHindi,
        'descriptionSantali': a.descriptionSantali,
      }).toList(),
    };

    await db.insert(
      'ai_contents',
      {
        'id': content.id,
        'noteId': content.noteId,
        'noteTitle': content.noteTitle,
        'explanationHindi': content.explanationHindi,
        'explanationSantali': content.explanationSantali,
        'translationSantali': content.translationSantali,
        'payloadJson': jsonEncode(payload),
        'state': content.state.name,
        'createdAt': content.createdAt.toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateAIContentState(String id, ContentState state) async {
    final db = await database;
    await db.update(
      'ai_contents',
      {'state': state.name},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Worksheets CRUD
  Future<List<WorksheetItem>> getAllWorksheets() async {
    final db = await database;
    final maps = await db.query('worksheets');
    return maps.map((m) {
      final payload = jsonDecode(m['payloadJson'] as String) as Map<String, dynamic>;
      return WorksheetItem.fromJson(payload);
    }).toList();
  }

  Future<void> insertWorksheet(WorksheetItem item) async {
    final db = await database;
    await db.insert(
      'worksheets',
      {
        'id': item.id,
        'gradeClass': item.gradeClass,
        'subject': item.subject,
        'titleHindi': item.titleHindi,
        'titleSantali': item.titleSantali,
        'payloadJson': jsonEncode(item.toJson()),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Games CRUD
  Future<List<GameItem>> getAllGames() async {
    final db = await database;
    final maps = await db.query('games');
    return maps.map((m) {
      final payload = jsonDecode(m['payloadJson'] as String) as Map<String, dynamic>;
      return GameItem.fromJson(payload);
    }).toList();
  }

  Future<void> insertGame(GameItem item) async {
    final db = await database;
    await db.insert(
      'games',
      {
        'id': item.id,
        'category': item.category,
        'gameType': item.gameType,
        'titleHindi': item.titleHindi,
        'titleSantali': item.titleSantali,
        'descriptionHindi': item.descriptionHindi,
        'descriptionSantali': item.descriptionSantali,
        'isAvailableOffline': item.isAvailableOffline ? 1 : 0,
        'isComingSoon': item.isComingSoon ? 1 : 0,
        'payloadJson': jsonEncode(item.rawData),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Activities CRUD
  Future<List<ActivityItem>> getAllActivities() async {
    final db = await database;
    final maps = await db.query('activities');
    return maps.map((m) {
      final payload = jsonDecode(m['payloadJson'] as String) as Map<String, dynamic>;
      return ActivityItem.fromJson(payload);
    }).toList();
  }

  Future<void> insertActivity(ActivityItem item) async {
    final db = await database;
    await db.insert(
      'activities',
      {
        'id': item.id,
        'category': item.category,
        'type': item.type,
        'titleHindi': item.titleHindi,
        'titleSantali': item.titleSantali,
        'instructionsHindi': item.instructionsHindi,
        'instructionsSantali': item.instructionsSantali,
        'payloadJson': jsonEncode(item.rawData),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Stories CRUD
  Future<List<StoryItem>> getAllStories() async {
    final db = await database;
    final maps = await db.query('stories');
    return maps.map((m) {
      final payload = jsonDecode(m['payloadJson'] as String) as Map<String, dynamic>;
      return StoryItem.fromJson(payload);
    }).toList();
  }

  Future<void> insertStory(StoryItem item) async {
    final db = await database;
    await db.insert(
      'stories',
      {
        'id': item.id,
        'titleHindi': item.titleHindi,
        'titleSantali': item.titleSantali,
        'coverImage': item.coverImage,
        'author': item.author,
        'payloadJson': jsonEncode(item.toJson()),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
