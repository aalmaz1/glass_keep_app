import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:glass_keep/notifications_service.dart';

class Note {
  final String id;
  final String title;
  final String content;
  final List<String> labels;
  final bool isPinned;
  final bool isArchived;
  final DateTime? reminder;
  final String? imageBase64;
  final DateTime updatedAt;

  /// Cached decoded image bytes to avoid repeated base64 decoding
  Uint8List? _cachedImage;

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
  });

  /// Get cached image bytes, decoding only on first access
  Uint8List? get cachedImage {
    if (_cachedImage != null) return _cachedImage;
    _cachedImage = decodeImage();
    return _cachedImage;
  }

  /// Clear the cached image (useful when imageBase64 changes)
  void clearImageCache() {
    _cachedImage = null;
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
  }) {
    return Note(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      labels: labels ?? this.labels,
      isPinned: isPinned ?? this.isPinned,
      isArchived: isArchived ?? this.isArchived,
      reminder: reminder ?? this.reminder,
      imageBase64: imageBase64 ?? this.imageBase64,
      updatedAt: updatedAt ?? this.updatedAt,
    );
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

  StorageService._();

  static Future<StorageService> init() async {
    if (!_initialized) {
      try {
        // Optimized for safety and performance
        FirebaseFirestore.instance.settings = const Settings(
          persistenceEnabled: true,
          cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
        );
      } catch (e) {
        debugPrint('Firestore settings already set or error: $e');
      }
      _initialized = true;
    }
    return StorageService._();
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
              final existingNote = oldNotes.where(
                (n) => n.id == noteId && n.updatedAt.millisecondsSinceEpoch == updatedAt,
              ).firstOrNull;

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
    _notesStream = stream.asBroadcastStream();
    return _notesStream!;
  }

  /// Clear the cache - useful for logout scenarios
  void clearCache() {
    _notesStream = null;
    _notesCache = null;
  }

  Future<void> save(Note note) async {
    try {
      final map = note.toMap();
      map['userId'] = _uid;

      if (note.id.isEmpty) {
        final doc = _db.collection('notes').doc();
        map['id'] = doc.id;
        final newNote = Note.fromMap(map);
        await _db.collection('notes').doc(newNote.id).set(map);
        if (newNote.reminder != null && !newNote.isArchived) {
          await NotificationService().scheduleReminder(newNote);
        }
      } else {
        await _db.collection('notes').doc(note.id).set(map);
        if (note.reminder != null && !note.isArchived) {
          await NotificationService().scheduleReminder(note);
        } else {
          await NotificationService().cancelReminder(note.id);
        }
      }
    } catch (e) {
      debugPrint('save note error: $e');
      rethrow;
    }
  }

  Future<void> delete(String id) async {
    try {
      await NotificationService().cancelReminder(id);
      await _db.collection('notes').doc(id).delete();
    } catch (e) {
      debugPrint('delete note error: $e');
      rethrow;
    }
  }
}
