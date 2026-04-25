import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:glass_keep/notifications_service.dart';
import 'package:glass_keep/encryption_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';

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
    final base64 = imageBase64;
    if (base64 == null || base64.isEmpty) return null;
    try {
      return base64Decode(base64);
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

  factory Note.fromMap(Map<String, dynamic> m) {
    try {
      return Note(
        id: m['id']?.toString() ?? '',
        title: m['title']?.toString() ?? '',
        content: m['content']?.toString() ?? '',
        labels: m['labels'] is List ? List<String>.from(m['labels']) : [],
        isPinned: m['isPinned'] == true,
        isArchived: m['isArchived'] == true,
        reminder: m['reminder'] is int ? DateTime.fromMillisecondsSinceEpoch(m['reminder']) : null,
        imageBase64: m['imageBase64']?.toString(),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(m['updatedAt'] is int ? m['updatedAt'] : DateTime.now().millisecondsSinceEpoch),
      );
    } catch (e) {
      debugPrint('Error parsing note: $e');
      // Still rethrow so StorageService can skip it, but the parsing itself is safer
      rethrow;
    }
  }

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
    debugPrint('[SYSTEM-REBORN] Initializing StorageService...');
    if (!_initialized) {
      try {
        // Initialize Encryption
        await EncryptionService().init();

        // Optimized for safety and performance
        FirebaseFirestore.instance.settings = const Settings(
          persistenceEnabled: true,
          cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
        );
        debugPrint('[SYSTEM-REBORN] Firestore persistence enabled');
      } catch (e) {
        debugPrint('[SYSTEM-REBORN] Firestore settings already set or error: $e');
      }
      _initialized = true;
    }
    return StorageService._();
  }

  String get _uid => _auth.currentUser?.uid ?? 'anonymous';

  Stream<List<Note>> getNotesStream() {
    final cached = _notesStream;
    if (cached != null) {
      return cached;
    }

    final currentUid = _auth.currentUser?.uid;
    final stream = (currentUid != null
            ? _buildUserNotesStream(currentUid)
            : _auth
                .authStateChanges()
                .where((user) => user != null)
                .take(1)
                .asyncExpand((user) => _buildUserNotesStream(user!.uid)))
        .asBroadcastStream();

    _notesStream = stream;
    return stream;
  }

  Stream<List<Note>> _buildUserNotesStream(String uid) {
    return _db
        .collection('notes')
        .where('userId', isEqualTo: uid)
        .snapshots()
        .asyncMap(
          (snapshot) => Future.microtask(() => _mapNotesSnapshot(snapshot)),
        )
        .timeout(
          const Duration(seconds: 12),
          onTimeout: (sink) {
            debugPrint(
              '[SYSTEM-REBORN] Notes stream timeout for uid=$uid. Using cache fallback.',
            );
            sink.add(_notesCache ?? const <Note>[]);
          },
        );
  }

  List<Note> _mapNotesSnapshot(QuerySnapshot<Map<String, dynamic>> snapshot) {
    final oldNotes = _notesCache ?? const <Note>[];
    final notes = snapshot.docs.map((d) {
      final data = d.data();
      final noteId = data['id']?.toString() ?? '';
      final updatedAt = data['updatedAt'] is int ? data['updatedAt'] as int : 0;

      final existingNote = _findCachedNote(oldNotes, noteId, updatedAt);
      if (existingNote != null) {
        return existingNote;
      }

      try {
        final note = Note.fromMap(data);
        return note.copyWith(
          title: EncryptionService().decryptText(note.title),
          content: EncryptionService().decryptText(note.content),
        );
      } catch (e) {
        debugPrint('[SYSTEM-REBORN] Skipping corrupted note $noteId: $e');
        return null;
      }
    }).whereType<Note>().toList();

    _notesCache = List.unmodifiable(notes);
    return notes;
  }

  Note? _findCachedNote(List<Note> notes, String noteId, int updatedAt) {
    for (final note in notes) {
      if (note.id == noteId &&
          note.updatedAt.millisecondsSinceEpoch == updatedAt) {
        return note;
      }
    }
    return null;
  }

  /// Clear the cache - useful for logout scenarios
  void clearCache() {
    _notesStream = null;
    _notesCache = null;
  }

  Future<void> save(Note note) async {
    try {
      // Encrypt sensitive fields before saving
      final encryptedNote = note.copyWith(
        title: EncryptionService().encryptText(note.title),
        content: EncryptionService().encryptText(note.content),
      );

      final map = encryptedNote.toMap();
      map['userId'] = _uid;

      if (note.id.isEmpty) {
        final doc = _db.collection('notes').doc();
        map['id'] = doc.id;
        // We use the original note for scheduling reminders as it has unencrypted text
        await _db.collection('notes').doc(map['id']).set(map);
        if (note.reminder != null && !note.isArchived) {
          await NotificationService().scheduleReminder(note.copyWith(id: map['id']));
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

  Future<String> exportNotesToJson() async {
    final snapshot = await _db.collection('notes')
        .where('userId', isEqualTo: _uid)
        .get();
    
    final notes = snapshot.docs.map((d) {
      final data = d.data();
      try {
        final note = Note.fromMap(data);
        return note.copyWith(
          title: EncryptionService().decryptText(note.title),
          content: EncryptionService().decryptText(note.content),
        );
      } catch (e) {
        return null;
      }
    }).whereType<Note>().map((n) => n.toMap()).toList();

    final jsonString = jsonEncode(notes);
    return EncryptionService().encryptText(jsonString);
  }

  Future<void> importNotesFromJson(String json) async {
    final decryptedJson = EncryptionService().decryptText(json);
    final List<dynamic> jsonList = jsonDecode(decryptedJson);

    final batch = _db.batch();
    for (var item in jsonList) {
      try {
        final data = Map<String, dynamic>.from(item);
        final newDoc = _db.collection('notes').doc();
        
        final note = Note.fromMap(data).copyWith(
          id: newDoc.id,
          updatedAt: DateTime.now(),
        );
        
        final encryptedNote = note.copyWith(
          title: EncryptionService().encryptText(note.title),
          content: EncryptionService().encryptText(note.content),
        );
        
        final map = encryptedNote.toMap();
        map['userId'] = _uid;
        batch.set(newDoc, map);
      } catch (e) {
        debugPrint('Error importing item: $e');
      }
    }
    await batch.commit();
  }

  Future<void> exportNotes() async {
    try {
      final encryptedJson = await exportNotesToJson();
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/glass_keep_backup.json');
      await file.writeAsString(encryptedJson);

      await Share.shareXFiles([XFile(file.path)], text: 'Glass Keep Backup');
    } catch (e) {
      debugPrint('Export error: $e');
      rethrow;
    }
  }

  Future<void> importNotes() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      final path = result?.files.single.path;
      if (path != null) {
        final file = File(path);
        final jsonString = await file.readAsString();
        await importNotesFromJson(jsonString);
      }
    } catch (e) {
      debugPrint('Import error: $e');
      rethrow;
    }
  }
}
