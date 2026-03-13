import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('StudentRepository save/load students', () async {
    final repo = StudentRepository();
    final s = Student(
      id: 's1',
      name: 'Test Student',
      belt: 'White',
      photoUrl: '',
      technique: 10,
      etiquette: 20,
      attendance: 30,
      kiai: 5,
    );

    await repo.saveStudents([s]);
    final loaded = await repo.loadStudents();
    expect(loaded.length, 1);
    expect(loaded[0].id, 's1');
    expect(loaded[0].name, 'Test Student');
  });

  test('save/load evaluations and attendance events', () async {
    final repo = StudentRepository();
    final eval = Evaluation(
      techniqueName: 'Ikkyo',
      technique: 10,
      etiquette: 20,
      attendance: 30,
      kiai: 5,
      maut: 10 * 0.5 + 20 * 0.3 + 30 * 0.2,
      timestamp: DateTime.now().toIso8601String(),
    );

    await repo.saveEvaluation('s1', eval);
    final evals = await repo.loadEvaluations('s1');
    expect(evals.length, 1);
    expect(evals[0].techniqueName, 'Ikkyo');

    final att = AttendanceEvent(method: 'QR', timestamp: DateTime.now().toIso8601String());
    await repo.saveAttendanceEvent('s1', att);
    final atts = await repo.loadAttendanceEvents('s1');
    expect(atts.length, 1);
    expect(atts[0].method, 'QR');
  });
}
