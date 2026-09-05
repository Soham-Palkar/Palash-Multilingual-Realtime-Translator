import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/connectivity/connectivity_service.dart';
import '../core/constants/app_strings.dart';
import '../database/app_database.dart';
import '../repositories/content_repository.dart';
import '../repositories/teacher_repository.dart';
import '../services/ai_content_service.dart';
import '../services/auth_service.dart';
import '../services/mock_ai_content_service.dart';
import '../services/firebase_auth_service.dart';
import '../services/mock_sync_service.dart';
import '../services/mock_translation_service.dart';
import '../services/sync_service.dart';
import '../services/sync_service_factory.dart';
import '../services/translation_service.dart';
import 'routes.dart';
import 'theme.dart';

class PalashApp extends StatelessWidget {
  final AppDatabase database;

  const PalashApp({super.key, required this.database});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Connectivity State Service
        ChangeNotifierProvider(create: (_) => ConnectivityService()),

        // Concrete Service Implementations (Easily swappable with Firebase / FastAPI later)
        Provider<AuthService>(create: (_) => FirebaseAuthService()),
        Provider<AIContentService>(create: (_) => MockAIContentService()),
        Provider<TranslationService>(create: (_) => MockTranslationService()),
        Provider<SyncService>(create: (_) => MockSyncService()),

        // Repositories backed by SQLite/Drift Data-Access Layer
        ChangeNotifierProvider(create: (_) => ContentRepository(database)),
        ChangeNotifierProvider(create: (_) => TeacherRepository(database)),
      ],
      child: MaterialApp(
        title: AppStrings.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        initialRoute: AppRoutes.welcome,
        onGenerateRoute: AppRoutes.onGenerateRoute,
      ),
    );
  }
}
