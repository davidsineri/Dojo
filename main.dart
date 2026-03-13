import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:typed_data';
import 'package:pdf/widgets.dart' as pw;
import 'dart:convert';
import 'dart:html' as html;
import 'dart:js_util' as js_util;
import 'dart:ui' as ui; // for registering HtmlElementView on web

void main() {
  runApp(const ShinsedaikanApp());
}

class ShinsedaikanApp extends StatelessWidget {
  const ShinsedaikanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Shinsedaikan Dojo',
      navigatorKey: navigatorKey,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF990000), // Crimson Red (#990000)
        scaffoldBackgroundColor: const Color(0xFF121212), // Charcoal background
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF990000),
          secondary: Color(0xFF990000),
          surface: Color(0xFF1F1F1F),
        ),
        textTheme: const TextTheme(
          displayLarge: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            letterSpacing: 4.0,
            color: Colors.white,
          ),
          titleMedium: TextStyle(
            color: Color(0xFFBD0F0F),
            fontWeight: FontWeight.bold,
            letterSpacing: 2.0,
          ),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.5, curve: Curves.easeIn)),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.5, curve: Curves.easeOutBack)),
    );

    _controller.forward();

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const StudentListScreen()),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Pattern (Symbolic)
          Positioned.fill(
            child: Opacity(
              opacity: 0.05,
              child: CustomPaint(painter: WavePatternPainter()),
            ),
          ),
          Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Official Logo Image
                    Image.asset(
                      'assets/logo.jpg',
                      width: 180,
                      height: 180,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.door_sliding_outlined,
                        size: 120,
                        color: Color(0xFF990000),
                      ),
                    ),
                    const SizedBox(height: 48),
                    Text(
                      'SHINSEDAIKAN',
                      style: Theme.of(context).textTheme.displayLarge,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(height: 1, width: 30, color: const Color(0xFFBD0F0F).withOpacity(0.4)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'DOJO MANAGEMENT',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        Container(height: 1, width: 30, color: const Color(0xFFBD0F0F).withOpacity(0.4)),
                      ],
                    ),
                    const SizedBox(height: 80),
                    const SizedBox(
                      width: 200,
                      child: LinearProgressIndicator(
                        value: 0.75,
                        backgroundColor: Color(0xFF402020),
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFBD0F0F)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'AUTHENTICATING... 75%',
                      style: TextStyle(
                        fontSize: 10,
                        letterSpacing: 2,
                        color: Colors.white54,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                'THE PATH OF EXCELLENCE',
                style: TextStyle(
                  fontSize: 10,
                  letterSpacing: 4,
                  color: Colors.white24,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class WavePatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (double i = 0; i < size.height; i += 40) {
      for (double j = 0; j < size.width; j += 40) {
        canvas.drawCircle(Offset(j, i), 15, paint);
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

// Student Model & MAUT Logic
class Student {
  final String id;
  final String name;
  final String belt;
  final String photoUrl;
  final double technique; // 0-100
  final double etiquette; // 0-100
  final double attendance; // 0-100
  final double kiai; // 0-100 (for radar display)

  Student({
    required this.id,
    required this.name,
    required this.belt,
    required this.photoUrl,
    required this.technique,
    required this.etiquette,
    required this.attendance,
    required this.kiai,
  });

  double calculateMAUT() {
    // Weights: Technique (50%), Etiquette (30%), Attendance (20%)
    return (technique * 0.5) + (etiquette * 0.3) + (attendance * 0.2);
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'belt': belt,
        'photoUrl': photoUrl,
        'technique': technique,
        'etiquette': etiquette,
        'attendance': attendance,
        'kiai': kiai,
      };

  factory Student.fromMap(Map<String, dynamic> m) => Student(
        id: m['id'] as String,
        name: m['name'] as String,
        belt: m['belt'] as String? ?? '',
        photoUrl: m['photoUrl'] as String? ?? '',
        technique: (m['technique'] as num?)?.toDouble() ?? 0.0,
        etiquette: (m['etiquette'] as num?)?.toDouble() ?? 0.0,
        attendance: (m['attendance'] as num?)?.toDouble() ?? 0.0,
        kiai: (m['kiai'] as num?)?.toDouble() ?? 0.0,
      );
}

class StudentRepository {
  static const _key = 'students_v1';
  static const _evalKey = 'evaluations_v1';
  static const _attKey = 'attendance_v1';

  Future<List<Student>> loadStudents() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return <Student>[];
    final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
    return decoded.map((e) => Student.fromMap(Map<String, dynamic>.from(e))).toList();
  }

  Future<void> saveStudents(List<Student> students) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(students.map((s) => s.toMap()).toList());
    await prefs.setString(_key, encoded);
  }

  Future<List<Evaluation>> loadEvaluations(String studentId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_evalKey);
    if (raw == null || raw.isEmpty) return <Evaluation>[];
    final Map<String, dynamic> decoded = jsonDecode(raw) as Map<String, dynamic>;
    final list = decoded[studentId] as List<dynamic>?;
    if (list == null) return <Evaluation>[];
    return list.map((e) => Evaluation.fromMap(Map<String, dynamic>.from(e))).toList();
  }

  Future<void> saveEvaluation(String studentId, Evaluation eval) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_evalKey);
    Map<String, dynamic> decoded = {};
    if (raw != null && raw.isNotEmpty) {
      decoded = jsonDecode(raw) as Map<String, dynamic>;
    }
    final list = (decoded[studentId] as List<dynamic>?)?.toList() ?? <dynamic>[];
    list.add(eval.toMap());
    decoded[studentId] = list;
    await prefs.setString(_evalKey, jsonEncode(decoded));
  }

  Future<List<AttendanceEvent>> loadAttendanceEvents(String studentId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_attKey);
    if (raw == null || raw.isEmpty) return <AttendanceEvent>[];
    final Map<String, dynamic> decoded = jsonDecode(raw) as Map<String, dynamic>;
    final list = decoded[studentId] as List<dynamic>?;
    if (list == null) return <AttendanceEvent>[];
    return list.map((e) => AttendanceEvent.fromMap(Map<String, dynamic>.from(e))).toList();
  }

  Future<void> saveAttendanceEvent(String studentId, AttendanceEvent ev) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_attKey);
    Map<String, dynamic> decoded = {};
    if (raw != null && raw.isNotEmpty) decoded = jsonDecode(raw) as Map<String, dynamic>;
    final list = (decoded[studentId] as List<dynamic>?)?.toList() ?? <dynamic>[];
    list.add(ev.toMap());
    decoded[studentId] = list;
    await prefs.setString(_attKey, jsonEncode(decoded));
  }
}

class Evaluation {
  final String techniqueName;
  final double technique;
  final double etiquette;
  final double attendance;
  final double kiai;
  final double maut;
  final String timestamp;

  Evaluation({
    required this.techniqueName,
    required this.technique,
    required this.etiquette,
    required this.attendance,
    required this.kiai,
    required this.maut,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() => {
        'techniqueName': techniqueName,
        'technique': technique,
        'etiquette': etiquette,
        'attendance': attendance,
        'kiai': kiai,
        'maut': maut,
        'timestamp': timestamp,
      };

  factory Evaluation.fromMap(Map<String, dynamic> m) => Evaluation(
        techniqueName: m['techniqueName'] as String? ?? '',
        technique: (m['technique'] as num?)?.toDouble() ?? 0.0,
        etiquette: (m['etiquette'] as num?)?.toDouble() ?? 0.0,
        attendance: (m['attendance'] as num?)?.toDouble() ?? 0.0,
        kiai: (m['kiai'] as num?)?.toDouble() ?? 0.0,
        maut: (m['maut'] as num?)?.toDouble() ?? 0.0,
        timestamp: m['timestamp'] as String? ?? '',
      );
}

class AttendanceEvent {
  final String method; // e.g., 'QR' or 'Manual'
  final String timestamp;

  AttendanceEvent({required this.method, required this.timestamp});

  Map<String, dynamic> toMap() => {'method': method, 'timestamp': timestamp};

  factory AttendanceEvent.fromMap(Map<String, dynamic> m) => AttendanceEvent(
        method: m['method'] as String? ?? '',
        timestamp: m['timestamp'] as String? ?? '',
      );
}

class StudentListScreen extends StatefulWidget {
  const StudentListScreen({super.key});

  @override
  State<StudentListScreen> createState() => _StudentListScreenState();
}

class _StudentListScreenState extends State<StudentListScreen> {
  final StudentRepository _repo = StudentRepository();
  List<Student> _students = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final s = await _repo.loadStudents();
    if (s.isEmpty) {
      // seed with an example student for first-run clarity
      final example = Student(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: 'Mika Tanaka',
        belt: 'White',
        photoUrl: '',
        technique: 72,
        etiquette: 80,
        attendance: 90,
        kiai: 65,
      );
      _students = [example];
      await _repo.saveStudents(_students);
    } else {
      _students = s;
    }
    setState(() => _loading = false);
  }

  Future<void> _markFromInput() async {
    final raw = _controller.text.trim();
    if (raw.isEmpty) return;
    // If there is an exact id match, use it; otherwise if there's at least one suggestion, use first; else use raw
    final exact = _students.firstWhere((s) => s.id == raw, orElse: () => Student(id: '', name: '', belt: '', photoUrl: '', technique: 0, etiquette: 0, attendance: 0, kiai: 0));
    if (exact.id.isNotEmpty) {
      await _markAttendanceForId(exact.id);
      return;
    }
    if (_matches.isNotEmpty) {
      await _markAttendanceForId(_matches.first.id);
      return;
    }
    // fallback: try raw as id
    await _markAttendanceForId(raw);
  }

  Future<void> _openRegister() async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => RegisterStudentScreen()));
    await _load();
  }

  Future<void> _openEvaluate(Student student) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => EvaluationScreen(student: student)));
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('STUDENT ROSTER'),
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_awesome),
            tooltip: 'Seed demo data',
            onPressed: () async {
              final repo = StudentRepository();
              final now = DateTime.now();
              final List<Student> demo = List.generate(6, (i) {
                final id = (now.millisecondsSinceEpoch + i).toString();
                return Student(
                  id: id,
                  name: ['Aiko', 'Budi', 'Citra', 'Dedi', 'Eka', 'Fajar'][i],
                  belt: ['White', 'Yellow', 'Orange', 'Green', 'Blue', 'Brown'][i % 6],
                  photoUrl: '',
                  technique: (60 + i * 6).toDouble(),
                  etiquette: (55 + i * 7).toDouble(),
                  attendance: (70 + i * 4).toDouble(),
                  kiai: (50 + i * 5).toDouble(),
                );
              });
              await repo.saveStudents(demo);
              // seed some evaluations and attendance
              for (final s in demo) {
                await repo.saveEvaluation(s.id, Evaluation(techniqueName: 'Ikkyo', technique: s.technique, etiquette: s.etiquette, attendance: s.attendance, kiai: s.kiai, maut: s.calculateMAUT(), timestamp: DateTime.now().toIso8601String()));
                await repo.saveAttendanceEvent(s.id, AttendanceEvent(method: 'Seed', timestamp: DateTime.now().toIso8601String()));
              }
              ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(const SnackBar(content: Text('Demo data seeded')));
              Navigator.of(navigatorKey.currentContext!).pushReplacement(MaterialPageRoute(builder: (_) => const StudentListScreen()));
            },
          ),
          IconButton(
            icon: const Icon(Icons.qr_code_scanner_outlined),
            tooltip: 'Scan Attendance',
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ScanAttendanceScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'Info',
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const InfoScreen())),
          ),
        ],
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openRegister,
        icon: const Icon(Icons.person_add),
        label: const Text('Register Student'),
        backgroundColor: const Color(0xFFBD0F0F),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _students.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('No students registered yet', style: TextStyle(color: Colors.white54)),
                      const SizedBox(height: 12),
                      ElevatedButton(onPressed: _openRegister, child: const Text('Register Student')),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _students.length,
                  itemBuilder: (context, index) {
                    final student = _students[index];
                    final score = student.calculateMAUT();

                    return Card(
                      color: Theme.of(context).colorScheme.surface,
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      child: ListTile(
                      backgroundColor: const Color(0xFF990000),
                        leading: _StudentAvatar(student: student, radius: 28),
                        title: Text(
                          student.name,
                          style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.0),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Row(
                            children: [
                              _ScoreChip(label: 'T', value: student.technique.toInt()),
                              const SizedBox(width: 8),
                              _ScoreChip(label: 'E', value: student.etiquette.toInt()),
                              const SizedBox(width: 8),
                              _ScoreChip(label: 'A', value: student.attendance.toInt()),
                            ],
                          ),
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(student.belt, style: const TextStyle(fontSize: 12, color: Colors.white70)),
                            const SizedBox(height: 6),
                            Text(
                              score.toStringAsFixed(1),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFBD0F0F),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                  IconButton(
                                    onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => StudentHistoryScreen(student: student))),
                                    icon: const Icon(Icons.history, size: 18, color: Colors.white70),
                                    tooltip: 'History',
                                  ),
                                  IconButton(
                                    onPressed: () => _openEvaluate(student),
                                    icon: const Icon(Icons.edit, size: 18, color: Colors.white70),
                                    tooltip: 'Evaluate / Edit',
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

class RegisterStudentScreen extends StatefulWidget {
  @override
  State<RegisterStudentScreen> createState() => _RegisterStudentScreenState();
}

class _RegisterStudentScreenState extends State<RegisterStudentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _beltController = TextEditingController();
  final _photoController = TextEditingController();
  double _technique = 50;
  double _etiquette = 50;
  double _attendance = 50;
  double _kiai = 50;
  final StudentRepository _repo = StudentRepository();

  @override
  void dispose() {
    _nameController.dispose();
    _beltController.dispose();
    _photoController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final student = Student(
      id: id,
      name: _nameController.text.trim(),
      belt: _beltController.text.trim(),
      photoUrl: _photoController.text.trim().isNotEmpty
          ? _photoController.text.trim()
          : 'https://i.pravatar.cc/150?u=$id',
      technique: _technique,
      etiquette: _etiquette,
      attendance: _attendance,
      kiai: _kiai,
    );

    final list = await _repo.loadStudents();
    list.add(student);
    await _repo.saveStudents(list);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register Student')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter a name' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _beltController,
                decoration: const InputDecoration(labelText: 'Current Belt'),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _photoController,
                decoration: const InputDecoration(labelText: 'Photo URL (optional)'),
              ),
              const SizedBox(height: 12),
              _LabeledSlider(label: 'Technique (Waza)', value: _technique, onChanged: (v) => setState(() => _technique = v)),
              _LabeledSlider(label: 'Etiquette (Reigi)', value: _etiquette, onChanged: (v) => setState(() => _etiquette = v)),
              _LabeledSlider(label: 'Attendance', value: _attendance, onChanged: (v) => setState(() => _attendance = v)),
              _LabeledSlider(label: 'Kiai (for radar)', value: _kiai, onChanged: (v) => setState(() => _kiai = v)),
              const SizedBox(height: 12),
              ElevatedButton.icon(onPressed: _save, icon: const Icon(Icons.save), label: const Text('Save')),
            ],
          ),
        ),
      ),
    );
  }
}

class EvaluationScreen extends StatefulWidget {
  final Student student;

  const EvaluationScreen({required this.student});

  @override
  State<EvaluationScreen> createState() => _EvaluationScreenState();
}

class _EvaluationScreenState extends State<EvaluationScreen> {
  late double _technique;
  late double _etiquette;
  late double _attendance;
  late double _kiai;
  String _selectedTechnique = 'Ikkyo';
  final StudentRepository _repo = StudentRepository();
  List<Evaluation> _history = [];

  final List<String> _techniques = [
    'Tai no Henko',
    'Hiriki no Yosei',
    'Ikkyo',
    'Shihonage',
    'Ukemi',
  ];

  @override
  void initState() {
    super.initState();
    _technique = widget.student.technique;
    _etiquette = widget.student.etiquette;
    _attendance = widget.student.attendance;
    _kiai = widget.student.kiai;
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final h = await _repo.loadEvaluations(widget.student.id);
    setState(() => _history = h.reversed.toList());
  }

  Future<void> _save() async {
    final list = await _repo.loadStudents();
    final idx = list.indexWhere((s) => s.id == widget.student.id);
    if (idx != -1) {
      list[idx] = Student(
        id: widget.student.id,
        name: widget.student.name,
        belt: widget.student.belt,
        photoUrl: widget.student.photoUrl,
        technique: _technique,
        etiquette: _etiquette,
        attendance: _attendance,
        kiai: _kiai,
      );
      await _repo.saveStudents(list);
    }
    // save evaluation history
    final maut = (_technique * 0.5) + (_etiquette * 0.3) + (_attendance * 0.2);
    final eval = Evaluation(
      techniqueName: _selectedTechnique,
      technique: _technique,
      etiquette: _etiquette,
      attendance: _attendance,
      kiai: _kiai,
      maut: maut,
      timestamp: DateTime.now().toIso8601String(),
    );
    await _repo.saveEvaluation(widget.student.id, eval);
    await _loadHistory();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Evaluation saved')));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Evaluate: ${widget.student.name}')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Radar chart showing Waza, Reigi, Kiai, Attendance
            RadarChart(
              data: {
                'Waza': _technique,
                'Reigi': _etiquette,
                'Kiai': _kiai,
                'Attendance': _attendance,
              },
              size: 200,
            ),
            const SizedBox(height: 12),
            Card(
              color: Theme.of(context).colorScheme.surface,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('MAUT Breakdown', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Text('Technique (50%): ${_technique.toStringAsFixed(0)} × 0.5 = ${( _technique * 0.5).toStringAsFixed(1)}'),
                    Text('Etiquette (30%): ${_etiquette.toStringAsFixed(0)} × 0.3 = ${( _etiquette * 0.3).toStringAsFixed(1)}'),
                    Text('Attendance (20%): ${_attendance.toStringAsFixed(0)} × 0.2 = ${( _attendance * 0.2).toStringAsFixed(1)}'),
                    const SizedBox(height: 8),
                    Text('MAUT Score: ${((_technique * 0.5) + (_etiquette * 0.3) + (_attendance * 0.2)).toStringAsFixed(1)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Align(alignment: Alignment.centerLeft, child: Text('Riwayat Evaluasi', style: TextStyle(fontWeight: FontWeight.bold))),
            const SizedBox(height: 8),
            SizedBox(
              height: 160,
              child: _history.isEmpty
                  ? const Center(child: Text('Belum ada riwayat evaluasi', style: TextStyle(color: Colors.white54)))
                  : ListView.separated(
                      itemCount: _history.length,
                      separatorBuilder: (_, __) => const Divider(height: 6),
                      itemBuilder: (context, index) {
                        final e = _history[index];
                        final ts = DateTime.tryParse(e.timestamp);
                        final label = ts != null ? '${ts.year}-${ts.month.toString().padLeft(2,'0')}-${ts.day.toString().padLeft(2,'0')} ${ts.hour.toString().padLeft(2,'0')}:${ts.minute.toString().padLeft(2,'0')}' : e.timestamp;
                        return ListTile(
                          dense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
                          title: Text('${e.techniqueName} — MAUT ${e.maut.toStringAsFixed(1)}'),
                          subtitle: Text('T:${e.technique.toInt()} E:${e.etiquette.toInt()} A:${e.attendance.toInt()} — $label'),
                        );
                      },
                    ),
            ),
            DropdownButtonFormField<String>(
              value: _selectedTechnique,
              items: _techniques.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
              onChanged: (v) => setState(() => _selectedTechnique = v ?? _selectedTechnique),
              decoration: const InputDecoration(labelText: 'Technique'),
            ),
            const SizedBox(height: 12),
            _LabeledSlider(label: 'Technique (Waza)', value: _technique, onChanged: (v) => setState(() => _technique = v)),
            _LabeledSlider(label: 'Etiquette (Reigi)', value: _etiquette, onChanged: (v) => setState(() => _etiquette = v)),
            _LabeledSlider(label: 'Attendance', value: _attendance, onChanged: (v) => setState(() => _attendance = v)),
            _LabeledSlider(label: 'Kiai (for radar)', value: _kiai, onChanged: (v) => setState(() => _kiai = v)),
            const SizedBox(height: 12),
            ElevatedButton.icon(onPressed: _save, icon: const Icon(Icons.save), label: const Text('Save Evaluation')),
            const SizedBox(height: 8),
            Text('MAUT Score: ${((_technique * 0.5) + (_etiquette * 0.3) + (_attendance * 0.2)).toStringAsFixed(1)}', style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}

class RadarChart extends StatelessWidget {
  final Map<String, double> data; // label -> 0-100
  final double size;

  const RadarChart({required this.data, this.size = 180});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _RadarPainter(data: data, color: const Color(0xFF990000)),
      ),
    );
  }
}

class _RadarPainter extends CustomPainter {
  final Map<String, double> data;
  final Color color;

  _RadarPainter({required this.data, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) * 0.38;
    final count = data.length;

    final paintAxis = Paint()..color = Colors.white24..strokeWidth = 1.0;
    final paintGrid = Paint()..color = Colors.white12..style = PaintingStyle.stroke;
    final paintFill = Paint()..color = color.withOpacity(0.22);
    final paintStroke = Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = 2.0;

    // Draw grid (5 levels)
    for (int level = 1; level <= 5; level++) {
      final r = radius * (level / 5);
      final path = Path();
      for (int i = 0; i < count; i++) {
        final angle = (math.pi * 2 / count) * i - math.pi / 2;
        final p = Offset(center.dx + r * math.cos(angle), center.dy + r * math.sin(angle));
        if (i == 0) path.moveTo(p.dx, p.dy); else path.lineTo(p.dx, p.dy);
      }
      path.close();
      canvas.drawPath(path, paintGrid);
    }

    // Draw axes and labels
    final labels = data.keys.toList();
    for (int i = 0; i < count; i++) {
      final angle = (math.pi * 2 / count) * i - math.pi / 2;
      final p = Offset(center.dx + radius * math.cos(angle), center.dy + radius * math.sin(angle));
      canvas.drawLine(center, p, paintAxis);

      // label
      final textPainter = TextPainter(
        text: TextSpan(text: labels[i], style: const TextStyle(color: Colors.white70, fontSize: 12)),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      final offset = Offset(p.dx - textPainter.width / 2 + (math.cos(angle) * 8), p.dy - textPainter.height / 2 + (math.sin(angle) * 8));
      textPainter.paint(canvas, offset);
    }

    // Draw data polygon
    final path = Path();
    for (int i = 0; i < count; i++) {
      final label = labels[i];
      final v = (data[label]!.clamp(0, 100)) / 100.0;
      final angle = (math.pi * 2 / count) * i - math.pi / 2;
      final r = radius * v;
      final p = Offset(center.dx + r * math.cos(angle), center.dy + r * math.sin(angle));
      if (i == 0) path.moveTo(p.dx, p.dy); else path.lineTo(p.dx, p.dy);
    }
    path.close();

    canvas.drawPath(path, paintFill);
    canvas.drawPath(path, paintStroke);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _LabeledSlider extends StatelessWidget {
  final String label;
  final double value;
  final ValueChanged<double> onChanged;

  const _LabeledSlider({required this.label, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label: ${value.toInt()}', style: const TextStyle(color: Colors.white70)),
        Slider(value: value, min: 0, max: 100, divisions: 100, onChanged: onChanged, activeColor: const Color(0xFFBD0F0F)),
      ],
    );
  }
}

class _StudentAvatar extends StatelessWidget {
  final Student student;
  final double radius;

  const _StudentAvatar({required this.student, required this.radius});

  @override
  Widget build(BuildContext context) {
    if (student.photoUrl.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: Colors.white12,
        backgroundImage: NetworkImage(student.photoUrl),
      );
    }

    final idx = student.id.hashCode.abs() % 6 + 1;
    final asset = 'assets/avatars/avatar$idx.svg';

    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.white12,
      child: ClipOval(
        child: SvgPicture.asset(
          asset,
          width: radius * 2,
          height: radius * 2,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}

class InfoScreen extends StatelessWidget {
  const InfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tentang / Info')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('1. Untuk Kamu (Sensei/Instruktur)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('Sebagai pengelola dojo dan mahasiswa informatika, aplikasi ini adalah asisten pribadi sekaligus alat riset.'),
            SizedBox(height: 8),
            Text('• Objektivitas Mutlak: Dengan metode MAUT, kamu tidak lagi menilai "berdasarkan perasaan". Kamu punya dasar data yang kuat jika ada orang tua yang bertanya kenapa anaknya belum naik tingkat.'),
            SizedBox(height: 6),
            Text('• Efisiensi Administrasi: Semua data siswa, riwayat ujian, dan absensi tersimpan di satu tempat.'),
            SizedBox(height: 6),
            Text('• Tracking Materi: Catat materi tiap pertemuan sehingga kurikulum tetap teratur walau ada jeda.'),
            SizedBox(height: 6),
            Text('• Bahan Publikasi Ilmiah: Data aplikasi bisa diekspor untuk penelitian.'),
            SizedBox(height: 16),
            Text('2. Untuk Siswa (Anak-anak)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('Anak-anak butuh visualisasi agar mereka tetap semangat berlatih.'),
            SizedBox(height: 8),
            Text('• Visualisasi Progress (Gamifikasi): Bar progres dan radar chart membuat mereka merasa "leveling up".'),
            SizedBox(height: 6),
            Text('• Umpan Balik yang Jelas: Tahu bagian mana yang perlu ditingkatkan.'),
            SizedBox(height: 6),
            Text('• Rasa Bangga: Profil digital dengan foto dan seragam Aikido.'),
            SizedBox(height: 16),
            Text('3. Untuk Orang Tua', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('Orang tua adalah "investor" dalam pendidikan anak mereka. Mereka butuh transparansi.'),
            SizedBox(height: 8),
            Text('• Laporan Kemajuan yang Profesional: Grafik perkembangan karakter anak.'),
            SizedBox(height: 6),
            Text('• Transparansi Ujian: Menjelaskan kriteria MAUT kepada orang tua.'),
            SizedBox(height: 6),
            Text('• Kemudahan Komunikasi: Notifikasi jadwal dan info ujian.'),
            SizedBox(height: 16),
            Text('Perbandingan: Cara Lama vs Cara Baru', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('• Penilaian Ujian: Manual subjektif → MAUT otomatis dan objektif.'),
            Text('• Data Siswa: Tersebar → Terpusat.'),
            Text('• Progres Anak: Terbatas → Grafik kapan saja.'),
            Text('• Absensi: Manual → Scan QR.'),
            SizedBox(height: 24),
            Text('Catatan: Aplikasi ini dirancang untuk membantu proses pengajaran dan administrasi dojo. Silakan lanjutkan ke fitur berikutnya untuk QR attendance atau radar chart.', style: TextStyle(color: Colors.white70)),
          ],
        ),
      ),
    );
  }
}

class ScanAttendanceScreen extends StatefulWidget {
  const ScanAttendanceScreen({super.key});

  @override
  State<ScanAttendanceScreen> createState() => _ScanAttendanceScreenState();
}

class _ScanAttendanceScreenState extends State<ScanAttendanceScreen> {
  final StudentRepository _repo = StudentRepository();
  List<Student> _students = [];
  final _controller = TextEditingController();
  bool _loading = true;
  List<Student> _matches = [];

  // Camera related (web)
  html.VideoElement? _videoElement;
  html.MediaStream? _mediaStream;
  bool _cameraOn = false;
  bool _torchOn = false;
  bool _barcodeDetectorAvailable = false;
  String? _cameraViewId;
  final FocusNode _pasteFocus = FocusNode();
  final List<String> _pasteHistory = [];
  bool _requireConfirmOnExactPaste = true;
  bool _promptLock = false;

  @override
  void initState() {
    super.initState();
    _load();
    // detect if BarcodeDetector is available in this browser
    try {
      final bd = js_util.getProperty(html.window, 'BarcodeDetector');
      if (bd != null) _barcodeDetectorAvailable = true;
    } catch (_) {
      _barcodeDetectorAvailable = false;
    }
    _loadPasteHistory();
    _controller.addListener(_onPasteChanged);
    _loadPasteConfirmSetting();
  }

  void _onPasteChanged() {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      setState(() => _matches = []);
      return;
    }
    final q = text.toLowerCase();
    final results = _students.where((s) {
      return s.id.toLowerCase().contains(q) || s.name.toLowerCase().contains(q);
    }).toList();
    setState(() => _matches = results.take(6).toList());

    // If input exactly matches a student ID, prompt to confirm and mark (once)
    if (!_promptLock) {
      final exact = _students.firstWhere((s) => s.id == text, orElse: () => Student(id: '', name: '', belt: '', photoUrl: '', technique: 0, etiquette: 0, attendance: 0, kiai: 0));
      if (exact.id.isNotEmpty) {
        _promptLock = true;
        Future.delayed(const Duration(milliseconds: 250), () async {
          if (_requireConfirmOnExactPaste) {
            bool dontAsk = false;
            final confirmed = await showDialog<bool>(context: context, builder: (ctx) {
              return StatefulBuilder(builder: (ctx2, setStateDialog) {
                return AlertDialog(
                  title: const Text('Confirm attendance'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Mark ${exact.name} present?'),
                      const SizedBox(height: 12),
                      Row(children: [
                        Checkbox(value: dontAsk, onChanged: (v) => setStateDialog(() => dontAsk = v ?? false)),
                        const SizedBox(width: 8),
                        const Expanded(child: Text("Don't ask again for exact ID paste")),
                      ])
                    ],
                  ),
                  actions: [
                    TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
                    TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Mark')),
                  ],
                );
              });
            });
            if (confirmed == true) {
              await _markAttendanceForId(exact.id);
              if (dontAsk) {
                _requireConfirmOnExactPaste = false;
                await _savePasteConfirmSetting(false);
              }
            }
          } else {
            await _markAttendanceForId(exact.id);
          }
          await Future.delayed(const Duration(milliseconds: 600));
          _promptLock = false;
        });
      }
    }
  }

  Future<void> _loadPasteHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('paste_history_v1');
      if (raw == null || raw.isEmpty) return;
      final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
      _pasteHistory.clear();
      _pasteHistory.addAll(decoded.cast<String>());
      setState(() {});
    } catch (_) {}
  }

  Future<void> _savePasteHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('paste_history_v1', jsonEncode(_pasteHistory));
    } catch (_) {}
  }

  Future<void> _loadPasteConfirmSetting() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _requireConfirmOnExactPaste = prefs.getBool('confirm_exact_paste_v1') ?? true;
    } catch (_) {}
  }

  Future<void> _savePasteConfirmSetting(bool v) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('confirm_exact_paste_v1', v);
    } catch (_) {}
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    _students = await _repo.loadStudents();
    setState(() => _loading = false);
  }

  Future<void> _markAttendanceForId(String id) async {
    final list = await _repo.loadStudents();
    final idx = list.indexWhere((s) => s.id == id);
    if (idx == -1) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('QR tidak dikenal')));
      return;
    }

    final s = list[idx];
    final newAttendance = (s.attendance + 5).clamp(0, 100);
    list[idx] = Student(
      id: s.id,
      name: s.name,
      belt: s.belt,
      photoUrl: s.photoUrl,
      technique: s.technique,
      etiquette: s.etiquette,
      attendance: newAttendance,
      kiai: s.kiai,
    );
    await _repo.saveStudents(list);
    // save attendance event
    final ev = AttendanceEvent(method: 'QR', timestamp: DateTime.now().toIso8601String());
    await _repo.saveAttendanceEvent(s.id, ev);
    await _savePasteHistory();
    await _load();
    // Save paste/history for convenient re-use
    if (id.isNotEmpty && !_pasteHistory.contains(id)) {
      _pasteHistory.insert(0, id);
      if (_pasteHistory.length > 8) _pasteHistory.removeLast();
    }
    // clear input and refocus
    _controller.clear();
    _pasteFocus.requestFocus();

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${s.name} hadir — Attendance: ${newAttendance.toInt()}')));
  }

  Future<void> _startCamera() async {
    if (!kIsWeb) return;
    try {
      final constraints = {
        'video': {
          'facingMode': {'ideal': 'environment'}
        }
      };
      _mediaStream = await html.window.navigator.mediaDevices!.getUserMedia(constraints);
      _videoElement = html.VideoElement()
        ..autoplay = true
        ..muted = true
        ..playsInline = true
        ..style.width = '100%'
        ..style.height = '100%';
      _videoElement!.srcObject = _mediaStream;

      // register view factory for Flutter to show the video element
      _cameraViewId = 'camera-video-${DateTime.now().millisecondsSinceEpoch}';
      // ignore: undefined_prefixed_name
      ui.platformViewRegistry.registerViewFactory(_cameraViewId!, (int viewId) => _videoElement!);

      setState(() => _cameraOn = true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal mengakses kamera: $e')));
    }
  }

  Future<void> _stopCamera() async {
    try {
      _mediaStream?.getTracks().forEach((t) => t.stop());
      _mediaStream = null;
      _videoElement = null;
      _detectTimer?.cancel();
      setState(() {
        _cameraOn = false;
        _torchOn = false;
      });
    } catch (_) {}
  }

  Future<void> _toggleTorch() async {
    if (_mediaStream == null) return;
    try {
      final tracks = _mediaStream!.getVideoTracks();
      if (tracks.isEmpty) return;
      final track = tracks[0];
      // try applyConstraints for torch (may not be supported)
      try {
        final jsTrack = js_util.getProperty(track, '_jsTrack') ?? track;
        _torchOn = !_torchOn;
        await js_util.promiseToFuture(js_util.callMethod(jsTrack, 'applyConstraints', [js_util.jsify({'advanced': [{'torch': _torchOn}]})]));
        setState(() {});
      } catch (_) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Torch not supported on this device')));
      }
    } catch (_) {}
  }

  Future<void> _tryDetect() async {
    if (!kIsWeb || _videoElement == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Camera not running')));
      return;
    }

    if (_barcodeDetectorAvailable) {
      try {
        final detector = js_util.callConstructor(js_util.getProperty(html.window, 'BarcodeDetector'), [js_util.jsify({'formats': ['qr_code']})]);
        final promise = js_util.callMethod(detector, 'detect', [_videoElement]);
        final results = await js_util.promiseToFuture(promise);
        if (results is List && results.isNotEmpty) {
          final raw = js_util.getProperty(results[0], 'rawValue');
          if (raw != null && raw is String && raw.trim().isNotEmpty) {
            await _markAttendanceForId(raw.trim());
            return;
          }
        }
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No QR found (BarcodeDetector)')));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Detection failed: $e')));
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Browser does not support automatic QR detection')));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _pasteFocus.dispose();
    _stopCamera();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan Attendance')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Point camera ke QR atau tempel isi QR (ID murid) di bawah, lalu tekan Mark Attendance.'),
            const SizedBox(height: 8),
            Row(children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.camera_alt),
                label: Text(_cameraOn ? 'Stop Camera' : 'Start Camera'),
                onPressed: _cameraOn ? _stopCamera : _startCamera,
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                icon: const Icon(Icons.flash_on),
                label: Text(_torchOn ? 'Torch On' : 'Torch'),
                onPressed: _cameraOn ? _toggleTorch : null,
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                icon: const Icon(Icons.search),
                label: const Text('Try Detect'),
                onPressed: _cameraOn ? _tryDetect : null,
              ),
            ]),
            const SizedBox(height: 8),
            // Camera preview (web) if active, with overlay
            if (_cameraOn && _cameraViewId != null)
              SizedBox(
                height: 260,
                child: Stack(
                  children: [
                    Positioned.fill(child: HtmlElementView(viewType: _cameraViewId!)),
                    // Centered overlay box to help align QR
                    Center(
                      child: Container(
                        width: 180,
                        height: 180,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white70, width: 2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Stack(
                          children: [
                            // Corner accents
                            Positioned(
                              left: 6,
                              top: 6,
                              child: Container(width: 18, height: 4, color: Colors.white70),
                            ),
                            Positioned(
                              right: 6,
                              top: 6,
                              child: Container(width: 18, height: 4, color: Colors.white70),
                            ),
                            Positioned(
                              left: 6,
                              bottom: 6,
                              child: Container(width: 18, height: 4, color: Colors.white70),
                            ),
                            Positioned(
                              right: 6,
                              bottom: 6,
                              child: Container(width: 18, height: 4, color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Success overlay when a student is marked
                    if (_showSuccessOverlay)
                      Positioned.fill(
                        child: Container(
                          color: Colors.black45,
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.black87,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFBD0F0F), width: 2),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.check_circle, color: Color(0xFF00E676), size: 36),
                                  const SizedBox(width: 12),
                                  Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Marked Present', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                      if (_lastMarkedName != null) Text(_lastMarkedName!, style: TextStyle(color: Colors.white70)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: TextField(focusNode: _pasteFocus, controller: _controller, decoration: const InputDecoration(hintText: 'Paste QR payload / ID'))),
              const SizedBox(width: 8),
              ElevatedButton(onPressed: _markFromInput, child: const Text('Mark')),
            ]),
            const SizedBox(height: 8),
            if (_pasteHistory.isNotEmpty)
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: _pasteHistory.map((h) => ActionChip(label: Text(h, style: const TextStyle(fontSize: 12)), onPressed: () => _markAttendanceForId(h))).toList(),
              ),
            const SizedBox(height: 8),
            // Suggestions as you type
            if (_matches.isNotEmpty)
              Container(
                constraints: const BoxConstraints(maxHeight: 160),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _matches.length,
                  separatorBuilder: (_, __) => const Divider(height: 6),
                  itemBuilder: (context, i) {
                    final ms = _matches[i];
                    return ListTile(
                      leading: _StudentAvatar(student: ms, radius: 18),
                      title: Text(ms.name),
                      subtitle: Text('A: ${ms.attendance.toInt()} • ${ms.belt}', style: const TextStyle(fontSize: 12, color: Colors.white70)),
                      trailing: ElevatedButton(onPressed: () => _markAttendanceForId(ms.id), child: const Text('Mark')),
                      onTap: () => _markAttendanceForId(ms.id),
                    );
                  },
                ),
              ),
            const SizedBox(height: 16),
            const Text('Atau klik QR murid untuk menandai hadir:'),
            const SizedBox(height: 12),
            _loading
                ? const Center(child: CircularProgressIndicator())
                : Expanded(
                    child: GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 1.2, crossAxisSpacing: 12, mainAxisSpacing: 12),
                      itemCount: _students.length,
                      itemBuilder: (context, index) {
                        final s = _students[index];
                        return Card(
                          color: Theme.of(context).colorScheme.surface,
                          child: InkWell(
                            onTap: () => _markAttendanceForId(s.id),
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  QrImage(data: s.id, version: QrVersions.auto, size: 100),
                                  const SizedBox(height: 8),
                                  Text(s.name, textAlign: TextAlign.center),
                                  const SizedBox(height: 6),
                                  Text('A: ${s.attendance.toInt()}', style: const TextStyle(fontSize: 12, color: Colors.white60)),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}

class _ScoreChip extends StatelessWidget {
  final String label;
  final int value;

  const _ScoreChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white24),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(fontSize: 10, color: Colors.white70),
      ),
    );
  }
}

class StudentHistoryScreen extends StatefulWidget {
  final Student student;
  const StudentHistoryScreen({required this.student, super.key});

  @override
  State<StudentHistoryScreen> createState() => _StudentHistoryScreenState();
}

class _StudentHistoryScreenState extends State<StudentHistoryScreen> {
  final StudentRepository _repo = StudentRepository();
  List<Evaluation> _evals = [];
  List<AttendanceEvent> _atts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    _evals = await _repo.loadEvaluations(widget.student.id);
    _atts = await _repo.loadAttendanceEvents(widget.student.id);
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final entries = <Map<String, dynamic>>[];
    for (final e in _evals) {
      entries.add({'type': 'eval', 'ts': e.timestamp, 'data': e});
    }
    for (final a in _atts) {
      entries.add({'type': 'att', 'ts': a.timestamp, 'data': a});
    }
    entries.sort((a, b) => b['ts'].compareTo(a['ts']));

    return Scaffold(
      appBar: AppBar(
        title: Text('History: ${widget.student.name}'),
        actions: [
          IconButton(icon: const Icon(Icons.file_download), tooltip: 'Export CSV', onPressed: () => _exportCsv()),
          IconButton(icon: const Icon(Icons.picture_as_pdf), tooltip: 'Export PDF', onPressed: () => _exportPdf()),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : entries.isEmpty
              ? const Center(child: Text('No history yet', style: TextStyle(color: Colors.white54)))
              : ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: entries.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (context, index) {
                    final item = entries[index];
                    final ts = DateTime.tryParse(item['ts']);
                    final timeLabel = ts != null
                        ? '${ts.year}-${ts.month.toString().padLeft(2, '0')}-${ts.day.toString().padLeft(2, '0')} ${ts.hour.toString().padLeft(2, '0')}:${ts.minute.toString().padLeft(2, '0')}'
                        : item['ts'];
                    if (item['type'] == 'eval') {
                      final Evaluation e = item['data'] as Evaluation;
                      return ListTile(
                        leading: const Icon(Icons.assessment, color: Color(0xFF990000)),
                        title: Text('${e.techniqueName} — MAUT ${e.maut.toStringAsFixed(1)}'),
                        subtitle: Text('T:${e.technique.toInt()} E:${e.etiquette.toInt()} A:${e.attendance.toInt()} — $timeLabel'),
                      );
                    } else {
                      final AttendanceEvent a = item['data'] as AttendanceEvent;
                      return ListTile(
                        leading: const Icon(Icons.check_circle, color: Colors.greenAccent),
                        title: Text('Attendance — ${a.method}'),
                        subtitle: Text(timeLabel),
                      );
                    }
                  },
                ),
    );
  }

  Future<void> _exportCsv() async {
    // build csv: type,timestamp,details
    final lines = <String>[];
    lines.add('type,timestamp,detail');
    for (final e in _evals) {
      lines.add('evaluation,${e.timestamp},"${e.techniqueName} T:${e.technique.toInt()} E:${e.etiquette.toInt()} A:${e.attendance.toInt()} MAUT:${e.maut.toStringAsFixed(1)}"');
    }
    for (final a in _atts) {
      lines.add('attendance,${a.timestamp},"${a.method}"');
    }
    final csv = lines.join('\n');
    if (kIsWeb) {
      final bytes = utf8.encode(csv);
      final blob = html.Blob([bytes], 'text/csv');
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute('download', '${widget.student.name}_history.csv')
        ..click();
      html.Url.revokeObjectUrl(url);
    } else {
      await showDialog(context: context, builder: (_) => AlertDialog(title: const Text('CSV'), content: SingleChildScrollView(child: SelectableText(csv)), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))]));
    }
  }

  Future<void> _exportPdf() async {
    final doc = pw.Document();
    doc.addPage(pw.MultiPage(build: (pw.Context ctx) {
      final children = <pw.Widget>[];
      children.add(pw.Header(level: 0, child: pw.Text('${widget.student.name} — History')));
      children.add(pw.SizedBox(height: 8));
      final tableData = <List<String>>[];
      tableData.add(['Type', 'Timestamp', 'Details']);
      for (final e in _evals) {
        tableData.add(['Evaluation', e.timestamp, '${e.techniqueName} T:${e.technique.toInt()} E:${e.etiquette.toInt()} A:${e.attendance.toInt()} MAUT:${e.maut.toStringAsFixed(1)}']);
      }
      for (final a in _atts) {
        tableData.add(['Attendance', a.timestamp, a.method]);
      }
      children.add(pw.Table.fromTextArray(data: tableData));
      return children;
    }));

    final pdfBytes = await doc.save();
    if (kIsWeb) {
      final base64 = base64Encode(pdfBytes);
      final url = 'data:application/pdf;base64,$base64';
      html.AnchorElement(href: url)
        ..setAttribute('download', '${widget.student.name}_history.pdf')
        ..click();
    } else {
      // show PDF bytes as base64 in dialog for manual save
      final b64 = base64Encode(pdfBytes);
      await showDialog(context: context, builder: (_) => AlertDialog(title: const Text('PDF (base64)'), content: SingleChildScrollView(child: SelectableText(b64)), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))]));
    }
  }
}
