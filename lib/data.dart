import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

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

  /// Cached decoded image bytes to avoid repeated base64 decoding
  Uint8List? _cachedImage;
  bool _imageDecoded = false;

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

  /// Get cached image bytes, decoding only on first access
  Uint8List? get cachedImage {
    if (_imageDecoded) return _cachedImage;
    _cachedImage = decodeImage();
    _imageDecoded = true;
    return _cachedImage;
  }

  /// Clear the cached image (useful when imageBase64 changes)
  void clearImageCache() {
    _cachedImage = null;
    _imageDecoded = false;
  }

  /// Decode base64 image synchronously - call this only when needed
  Uint8List? decodeImage() {
    if (imageBase64 == null || imageBase64!.isEmpty) return null;
    try {
      return base64Decode(imageBase64!);
    } catch (e) {
      return null;
    }
  }

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

  Note copyWith({
    String? id,
    String? title,
    String? content,
    List<String>? labels,
    bool? isPinned,
    bool? isArchived,
    DateTime? reminder,
    String? imageBase64,
    DateTime? updatedAt,
    String? userId,
  }) {
    final note = Note(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      labels: labels ?? this.labels,
      isPinned: isPinned ?? this.isPinned,
      isArchived: isArchived ?? this.isArchived,
      reminder: reminder ?? this.reminder,
      imageBase64: imageBase64 ?? this.imageBase64,
      updatedAt: updatedAt ?? this.updatedAt,
      userId: userId ?? this.userId,
    );
    // Clear cache if image changed
    if (imageBase64 != null && imageBase64 != this.imageBase64) {
      note.clearImageCache();
    }
    return note;
  }
}

class StorageService {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  
  // Cached stream for notes to avoid multiple subscriptions
  Stream<List<Note>>? _notesStream;
  // Cache for the latest notes data
  List<Note>? _notesCache;
  // Track if persistence is enabled
  static bool _initialized = false;

  static Future<StorageService> init() async {
    if (!_initialized) {
      FirebaseFirestore.instance.settings = const Settings(persistenceEnabled: true);
      _initialized = true;
    }
    return StorageService();
  }

  String get _uid => _auth.currentUser?.uid ?? 'anonymous';

  Stream<List<Note>> getNotesStream() {
    // Return cached broadcast stream if available
    if (_notesStream != null) {
      return _notesStream!;
    }

    // Create a new stream with optimized mapping
    final stream = _db.collection('notes')
        .where('userId', isEqualTo: _uid)
        .snapshots()
        .asyncMap((snapshot) async {
          // Process notes in microtask to avoid blocking UI
          return Future.microtask(() {
            final oldNotes = _notesCache ?? [];
            final notes = snapshot.docs.map((d) {
              final data = d.data();
              final noteId = data['id'] ?? '';
              final updatedAt = data['updatedAt'] ?? 0;
              
              // Try to find existing note in cache
              final existingNote = oldNotes.cast<Note?>().firstWhere(
                (n) => n?.id == noteId && n?.updatedAt.millisecondsSinceEpoch == updatedAt,
                orElse: () => null,
              );
              
              if (existingNote != null) {
                return existingNote;
              }
              
              return Note.fromMap(data);
            }).toList();
            _notesCache = List.unmodifiable(notes);
            return notes;
          });
        });

    // Convert to broadcast stream to allow multiple listeners without recreating
    _notesStream = stream.asBroadcastStream(
      onListen: (subscription) {
        // Handle first listener
      },
      onCancel: (subscription) {
        // Keep the stream alive for potential reconnections
        // Cache is cleared only on explicit clearCache() call
      },
    );
    return _notesStream!;
  }
  
  /// Get cached notes if available
  List<Note>? get cachedNotes => _notesCache;
  
  /// Clear the cache - useful for logout scenarios
  void clearCache() {
    _notesStream = null;
    _notesCache = null;
  }

  Future<void> save(Note note) async {
    try {
      note.userId = _uid;
      if (note.id.isEmpty) {
        final doc = _db.collection('notes').doc();
        note.id = doc.id;
      }
      await _db.collection('notes').doc(note.id).set(note.toMap());
    } catch (e) {
      debugPrint('save note error: $e');
      rethrow;
    }
  }

  Future<void> delete(String id) async {
    try {
      await _db.collection('notes').doc(id).delete();
    } catch (e) {
      debugPrint('delete note error: $e');
      rethrow;
    }
  }
}
