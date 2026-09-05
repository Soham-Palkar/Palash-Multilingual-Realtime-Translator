import 'package:flutter/material.dart';
import '../features/welcome/welcome_screen.dart';
import '../features/authentication/teacher_login_screen.dart';
import '../features/teacher/dashboard/teacher_dashboard_screen.dart';
import '../features/teacher/curriculum/curriculum_screen.dart';
import '../features/teacher/curriculum/lesson_detail_screen.dart';
import '../features/teacher/notes/add_edit_note_screen.dart';
import '../features/teacher/ai_generation/ai_generator_screen.dart';
import '../features/teacher/ai_generation/draft_review_screen.dart';
import '../features/teacher/flashcards/teacher_flashcards_screen.dart';
import '../features/teacher/flashcards/manual_flashcard_creator.dart';
import '../features/teacher/translation/live_translation_screen.dart';
import '../features/teacher/review/content_review_screen.dart';
import '../features/teacher/settings/teacher_settings_screen.dart';

import '../features/student/home/student_home_screen.dart';
import '../features/student/notes/student_notes_screen.dart';
import '../features/student/notes/student_lesson_view_screen.dart';
import '../features/student/flashcards/student_flashcards_screen.dart';
import '../features/student/worksheets/student_worksheets_screen.dart';
import '../features/student/worksheets/worksheet_player_screen.dart';
import '../features/student/games/student_games_screen.dart';
import '../features/student/games/game_player_screen.dart';
import '../features/student/activities/student_activities_screen.dart';
import '../features/student/activities/activity_player_screen.dart';
import '../features/student/stories/student_stories_screen.dart';
import '../features/student/stories/story_reader_screen.dart';

import '../models/curriculum_model.dart';
import '../models/note_model.dart';
import '../models/ai_content_model.dart';
import '../models/worksheet_model.dart';
import '../models/game_model.dart';
import '../models/activity_model.dart';
import '../models/story_model.dart';

class AppRoutes {
  static const String welcome = '/';
  static const String teacherLogin = '/teacher-login';
  static const String teacherDashboard = '/teacher-dashboard';
  static const String teacherCurriculum = '/teacher-curriculum';
  static const String teacherLessonDetail = '/teacher-lesson-detail';
  static const String teacherAddNote = '/teacher-add-note';
  static const String teacherAIGenerator = '/teacher-ai-generator';
  static const String teacherDraftReview = '/teacher-draft-review';
  static const String teacherFlashcards = '/teacher-flashcards';
  static const String teacherManualFlashcard = '/teacher-manual-flashcard';
  static const String teacherTranslation = '/teacher-translation';
  static const String teacherReview = '/teacher-review';
  static const String teacherSettings = '/teacher-settings';

  static const String studentHome = '/student-home';
  static const String studentNotes = '/student-notes';
  static const String studentLessonView = '/student-lesson-view';
  static const String studentFlashcards = '/student-flashcards';
  static const String studentWorksheets = '/student-worksheets';
  static const String studentWorksheetPlayer = '/student-worksheet-player';
  static const String studentGames = '/student-games';
  static const String studentGamePlayer = '/student-game-player';
  static const String studentActivities = '/student-activities';
  static const String studentActivityPlayer = '/student-activity-player';
  static const String studentStories = '/student-stories';
  static const String studentStoryReader = '/student-story-reader';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case welcome:
        return MaterialPageRoute(builder: (_) => const WelcomeScreen());
      case teacherLogin:
        return MaterialPageRoute(builder: (_) => const TeacherLoginScreen());
      case teacherDashboard:
        return MaterialPageRoute(builder: (_) => const TeacherDashboardScreen());
      case teacherCurriculum:
        return MaterialPageRoute(builder: (_) => const CurriculumScreen());
      case teacherLessonDetail:
        final lesson = settings.arguments as CurriculumLesson;
        return MaterialPageRoute(builder: (_) => LessonDetailScreen(lesson: lesson));
      case teacherAddNote:
        final args = settings.arguments;
        return MaterialPageRoute(builder: (_) => AddEditNoteScreen(initialData: args));
      case teacherAIGenerator:
        final note = settings.arguments as TeacherNote?;
        return MaterialPageRoute(builder: (_) => AIGeneratorScreen(preselectedNote: note));
      case teacherDraftReview:
        final map = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => DraftReviewScreen(
            aiContent: map['aiContent'] as AIGeneratedContent,
            note: map['note'] as TeacherNote?,
          ),
        );
      case teacherFlashcards:
        return MaterialPageRoute(builder: (_) => const TeacherFlashcardsScreen());
      case teacherManualFlashcard:
        return MaterialPageRoute(builder: (_) => const ManualFlashcardCreator());
      case teacherTranslation:
        return MaterialPageRoute(builder: (_) => const LiveTranslationScreen());
      case teacherReview:
        return MaterialPageRoute(builder: (_) => const ContentReviewScreen());
      case teacherSettings:
        return MaterialPageRoute(builder: (_) => const TeacherSettingsScreen());

      // Student routes
      case studentHome:
        return MaterialPageRoute(builder: (_) => const StudentHomeScreen());
      case studentNotes:
        return MaterialPageRoute(builder: (_) => const StudentNotesScreen());
      case studentLessonView:
        final lesson = settings.arguments as CurriculumLesson;
        return MaterialPageRoute(builder: (_) => StudentLessonViewScreen(lesson: lesson));
      case studentFlashcards:
        return MaterialPageRoute(builder: (_) => const StudentFlashcardsScreen());
      case studentWorksheets:
        return MaterialPageRoute(builder: (_) => const StudentWorksheetsScreen());
      case studentWorksheetPlayer:
        final ws = settings.arguments as WorksheetItem;
        return MaterialPageRoute(builder: (_) => WorksheetPlayerScreen(worksheet: ws));
      case studentGames:
        return MaterialPageRoute(builder: (_) => const StudentGamesScreen());
      case studentGamePlayer:
        final game = settings.arguments as GameItem;
        return MaterialPageRoute(builder: (_) => GamePlayerScreen(game: game));
      case studentActivities:
        return MaterialPageRoute(builder: (_) => const StudentActivitiesScreen());
      case studentActivityPlayer:
        final act = settings.arguments as ActivityItem;
        return MaterialPageRoute(builder: (_) => ActivityPlayerScreen(activity: act));
      case studentStories:
        return MaterialPageRoute(builder: (_) => const StudentStoriesScreen());
      case studentStoryReader:
        final story = settings.arguments as StoryItem;
        return MaterialPageRoute(builder: (_) => StoryReaderScreen(story: story));

      default:
        return MaterialPageRoute(builder: (_) => const WelcomeScreen());
    }
  }
}
