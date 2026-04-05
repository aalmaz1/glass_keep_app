import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Note {
  String id;
  String title;
  String content;
  List<String> labels;
  bool isPinned;
  bool isArchived;
  DateTime? reminder;
  String? imageBase64;
  DateTime updatedAt;
  String? userId;

  Note({
    required this.id,
    required this.title,
    required this.content,
    this.labels = const [],
    this.isPinned = false,
    this.isArchived = false,
    this.reminder,
    this.imageBase64,
    required this.updatedAt,
    this.userId,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'content': content,
    'labels': labels,
    'isPinned': isPinned,
    'isArchived': isArchived,
    'reminder': reminder?.millisecondsSinceEpoch,
    'imageBase64': imageBase64,
    'updatedAt': updatedAt.millisecondsSinceEpoch,
    'userId': userId,
  };

  factory Note.fromMap(Map<String, dynamic> m) => Note(
    id: m['id'] ?? '',
    title: m['title'] ?? '',
    content: m['content'] ?? '',
    labels: List<String>.from(m['labels'] ?? []),
    isPinned: m['isPinned'] ?? false,
    isArchived: m['isArchived'] ?? false,
    reminder: m['reminder'] != null ? DateTime.fromMillisecondsSinceEpoch(m['reminder']) : null,
    imageBase64: m['imageBase64'],
    updatedAt: DateTime.fromMillisecondsSinceEpoch(m['updatedAt'] ?? DateTime.now().millisecondsSinceEpoch),
    userId: m['userId'],
  );
}

class StorageService {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  static Future<StorageService> init() async {
    FirebaseFirestore.instance.settings = const Settings(persistenceEnabled: true);
    return StorageService();
  }

  String get _uid => _auth.currentUser?.uid ?? 'anonymous';

  Stream<List<Note>> getNotesStream() {
    return _db.collection('notes')
        .where('userId', isEqualTo: _uid)
        .snapshots()
        .map((s) => s.docs.map((d) => Note.fromMap(d.data())).toList());
  }

  Future<void> save(Note note) async {
    note.userId = _uid;
    if (note.id.isEmpty) {
      final doc = _db.collection('notes').doc();
      note.id = doc.id;
    }
    await _db.collection('notes').doc(note.id).set(note.toMap());
  }

  Future<void> delete(String id) async {
    await _db.collection('notes').doc(id).delete();
  }
}
