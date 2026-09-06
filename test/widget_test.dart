import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:palash_app/app/app.dart';
import 'package:palash_app/database/app_database.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  testWidgets('Palash welcome screen loads with Teacher and Student roles', (WidgetTester tester) async {
    final db = AppDatabase.instance;
    await tester.pumpWidget(PalashApp(database: db));
    await tester.pumpAndSettle();

    expect(find.text('PALASH'), findsOneWidget);
    expect(find.text('अपनी भाषा में सीखें'), findsOneWidget);
    expect(find.text('विद्यार्थी / Student'), findsOneWidget);
    expect(find.text('शिक्षक / Teacher'), findsOneWidget);
  });
}
