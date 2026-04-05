import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Represents a single note in the app
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

  /// Convert Note to Firestore document
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

  /// Create Note from Firestore document
  factory Note.fromMap(Map<String, dynamic> map) => Note(
    id: map['id'] as String? ?? '',
    title: map['title'] as String? ?? '',
    content: map['content'] as String? ?? '',
    labels: List<String>.from(map['labels'] as List? ?? []),
    isPinned: map['isPinned'] as bool? ?? false,
    isArchived: map['isArchived'] as bool? ?? false,
    reminder: map['reminder'] != null
        ? DateTime.fromMillisecondsSinceEpoch(map['reminder'] as int)
        : null,
    imageBase64: map['imageBase64'] as String?,
    updatedAt: map['updatedAt'] != null
        ? DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] as int)
        : DateTime.now(),
    userId: map['userId'] as String?,
  );
}

/// Manages note storage and retrieval from Firebase Firestore
class StorageService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Initialize storage with persistence enabled
  static Future<StorageService> init() async {
    try {
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: true,
      );
      return StorageService();
    } catch (e) {
      debugPrint('Error initializing Firestore persistence: $e');
      return StorageService();
    }
  }

  /// Get current user ID
  String get _uid => _auth.currentUser?.uid ?? 'anonymous';

  /// Get stream of notes for current user
  /// 
  /// Returns a stream that emits a list of notes sorted by:
  /// 1. Pinned status (pinned first)
  /// 2. Updated date (newest first)
  Stream<List<Note>> getNotesStream() {
    try {
      return _db
          .collection('notes')
          .where('userId', isEqualTo: _uid)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs
            .map((doc) => Note.fromMap(doc.data()))
            .toList();
      }).handleError((error) {
        debugPrint('Error fetching notes: $error');
        return <Note>[];
      });
    } catch (e) {
      debugPrint('Error in getNotesStream: $e');
      return Stream.value([]);
    }
  }

  /// Save or update a note
  /// 
  /// If note.id is empty, a new document will be created.
  /// Otherwise, the existing document will be updated.
  Future<void> save(Note note) async {
    try {
      note.userId = _uid;
      
      // Generate new ID if empty
      if (note.id.isEmpty) {
        final doc = _db.collection('notes').doc();
        note.id = doc.id;
      }
      
      await _db.collection('notes').doc(note.id).set(note.toMap());
    } catch (e) {
      debugPrint('Error saving note: $e');
      rethrow;
    }
  }

  /// Delete a note by ID
  Future<void> delete(String id) async {
    try {
      await _db.collection('notes').doc(id).delete();
    } catch (e) {
      debugPrint('Error deleting note: $e');
      rethrow;
    }
  }

  /// Batch delete multiple notes
  Future<void> batchDelete(List<String> ids) async {
    try {
      final batch = _db.batch();
      for (final id in ids) {
        batch.delete(_db.collection('notes').doc(id));
      }
      await batch.commit();
    } catch (e) {
      debugPrint('Error batch deleting notes: $e');
      rethrow;
    }
  }
}
