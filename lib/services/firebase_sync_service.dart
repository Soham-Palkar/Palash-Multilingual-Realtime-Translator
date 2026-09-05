import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../database/app_database.dart';
import '../models/flashcard_model.dart';
import '../models/note_model.dart';
import '../models/ai_content_model.dart';
import 'sync_service.dart';

/// Implementation of [SyncService] that synchronizes local Drift database with
/// Firebase Firestore. It uploads teacher‑initiated changes and pulls published
/// content for students.
class FirebaseSyncService implements SyncService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AppDatabase _db = AppDatabase.instance;

  final StreamController<SyncStatusResult> _statusController =
      StreamController.broadcast();

  @override
  Stream<SyncStatusResult> get syncStatusStream => _statusController.stream;

  @override
  SyncStatusResult get currentStatus =>
      SyncStatusResult(isSyncing: false, isSuccess: true);

  @override
  Future<SyncStatusResult> syncContent() async {
    try {
      final notesQuery = await _firestore
          .collection('notes')
          .where('isPublished', isEqualTo: 1)
          .get();
      for (var doc in notesQuery.docs) {
        final data = doc.data();
        final note = TeacherNote(
          id: doc.id,
          lessonId: data['lessonId'] as String,
          gradeClass: data['gradeClass'] as int,
          subject: data['subject'] as String,
          title: data['title'] as String,
          hindiContent: data['hindiContent'] as String,
          santaliContent: data['santaliContent'] as String,
          santaliOlChiki: data['santaliOlChiki'] as String?,
          author: data['author'] as String,
          isDraft: false,
          isApproved: (data['isApproved'] ?? 0) == 1,
          isPublished: true,
          createdAt: (data['createdAt'] as Timestamp).toDate(),
        );
        await _db.insertNote(note);
      }

      // Pull published flashcards
      final fcQuery = await _firestore
          .collection('flashcards')
          .where('isPublished', isEqualTo: 1)
          .get();
      for (var doc in fcQuery.docs) {
        final data = doc.data();
        final fc = FlashcardItem(
          id: doc.id,
          category: data['category'] as String,
          subcategory: data['subcategory'] as String,
          hindi: data['hindi'] as String,
          santali: data['santali'] as String,
          santaliOlChiki: data['santaliOlChiki'] as String?,
          image: data['imagePath'] as String?,
          iconName: data['iconName'] as String?,
          pronunciation: data['pronunciation'] as String?,
          linguistNote: data['linguistNote'] as String?,
          isDefault: (data['isDefault'] ?? 0) == 1,
          isTeacherCreated: (data['isTeacherCreated'] ?? 0) == 1,
          isPublished: true,
          createdAt: (data['createdAt'] as Timestamp).toDate(),
        );
        await _db.insertFlashcard(fc);
      }

      // Pull published AI generated content
      final aiQuery = await _firestore
          .collection('generated_ai_content')
          .where('state', isEqualTo: 'published')
          .get();
      for (var doc in aiQuery.docs) {
        final data = doc.data();
        List<FlashcardItem> flashcards = [];
        List<AIPracticeQuestion> practiceQuestions = [];
        List<AIActivityIdea> activities = [];

        if (data['payloadJson'] != null && (data['payloadJson'] as String).isNotEmpty) {
          try {
            final payload = jsonDecode(data['payloadJson'] as String) as Map<String, dynamic>;
            if (payload['flashcards'] is List) {
              flashcards = (payload['flashcards'] as List)
                  .map((f) => FlashcardItem.fromJson(Map<String, dynamic>.from(f)))
                  .toList();
            }
            if (payload['practiceQuestions'] is List) {
              practiceQuestions = (payload['practiceQuestions'] as List).map((q) {
                final map = Map<String, dynamic>.from(q);
                return AIPracticeQuestion(
                  questionHindi: map['questionHindi'] as String? ?? '',
                  questionSantali: map['questionSantali'] as String? ?? '',
                  optionsHindi: List<String>.from(map['optionsHindi'] ?? []),
                  optionsSantali: List<String>.from(map['optionsSantali'] ?? []),
                  correctIndex: map['correctIndex'] as int? ?? 0,
                  explanation: map['explanation'] as String? ?? '',
                );
              }).toList();
            }
            if (payload['activities'] is List) {
              activities = (payload['activities'] as List).map((a) {
                final map = Map<String, dynamic>.from(a);
                return AIActivityIdea(
                  titleHindi: map['titleHindi'] as String? ?? '',
                  titleSantali: map['titleSantali'] as String? ?? '',
                  descriptionHindi: map['descriptionHindi'] as String? ?? '',
                  descriptionSantali: map['descriptionSantali'] as String? ?? '',
                );
              }).toList();
            }
          } catch (_) {}
        }

        final content = AIGeneratedContent(
          id: doc.id,
          noteId: data['noteId'] as String? ?? '',
          noteTitle: data['noteTitle'] as String? ?? '',
          explanationHindi: data['explanationHindi'] as String? ?? '',
          explanationSantali: data['explanationSantali'] as String? ?? '',
          translationSantali: data['translationSantali'] as String? ?? '',
          flashcards: flashcards,
          practiceQuestions: practiceQuestions,
          activities: activities,
          state: ContentState.published,
          createdAt: data['createdAt'] != null
              ? (data['createdAt'] as Timestamp).toDate()
              : DateTime.now(),
        );
        await _db.insertAIContent(content);
      }

      _statusController.add(SyncStatusResult(isSuccess: true, message: 'Sync complete'));
      return SyncStatusResult(isSuccess: true, message: 'Sync complete');
    } catch (e) {
      _statusController.add(SyncStatusResult(isSuccess: false, message: e.toString()));
      return SyncStatusResult(isSuccess: false, message: e.toString());
    }
  }

  // Helper upload methods called from repositories
  Future<void> uploadNote(TeacherNote note) async {
    await _firestore.collection('notes').doc(note.id).set({
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
      'createdAt': Timestamp.fromDate(note.createdAt),
    }, SetOptions(merge: true));
  }

  Future<void> uploadFlashcard(FlashcardItem fc) async {
    await _firestore.collection('flashcards').doc(fc.id).set({
      'category': fc.category,
      'subcategory': fc.subcategory,
      'hindi': fc.hindi,
      'santali': fc.santali,
      'santaliOlChiki': fc.santaliOlChiki,
      'imagePath': fc.image,
      'iconName': fc.iconName,
      'pronunciation': fc.pronunciation,
      'linguistNote': fc.linguistNote,
      'isDefault': fc.isDefault ? 1 : 0,
      'isTeacherCreated': fc.isTeacherCreated ? 1 : 0,
      'isPublished': fc.isPublished ? 1 : 0,
      'createdAt': Timestamp.fromDate(fc.createdAt),
    }, SetOptions(merge: true));
  }

  Future<void> uploadAIContent(AIGeneratedContent content) async {
    final payload = {
      'flashcards': content.flashcards.map((f) => f.toJson()).toList(),
      'practiceQuestions': content.practiceQuestions
          .map((q) => {
                'questionHindi': q.questionHindi,
                'questionSantali': q.questionSantali,
                'optionsHindi': q.optionsHindi,
                'optionsSantali': q.optionsSantali,
                'correctIndex': q.correctIndex,
                'explanation': q.explanation,
              })
          .toList(),
      'activities': content.activities
          .map((a) => {
                'titleHindi': a.titleHindi,
                'titleSantali': a.titleSantali,
                'descriptionHindi': a.descriptionHindi,
                'descriptionSantali': a.descriptionSantali,
              })
          .toList(),
    };
    await _firestore.collection('generated_ai_content').doc(content.id).set({
      'noteId': content.noteId,
      'noteTitle': content.noteTitle,
      'explanationHindi': content.explanationHindi,
      'explanationSantali': content.explanationSantali,
      'translationSantali': content.translationSantali,
      'payloadJson': jsonEncode(payload),
      'state': content.state.name,
      'createdAt': Timestamp.fromDate(content.createdAt),
    }, SetOptions(merge: true));
  }
}
