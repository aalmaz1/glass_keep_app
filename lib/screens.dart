import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/cupertino.dart' show CupertinoIcons, CupertinoActivityIndicator, CupertinoNavigationBar, CupertinoButton;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:glass_keep/l10n/app_localizations.dart';
import 'package:glass_keep/data.dart';
import 'package:glass_keep/widgets.dart';
import 'package:glass_keep/constants.dart';
import 'package:glass_keep/providers.dart';
import 'package:glass_keep/settings_screen.dart';
import 'package:glass_keep/biometric_service.dart';

class NotesScreen extends StatefulWidget {
  final StorageService storage;
  const NotesScreen({super.key, required this.storage});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  String _search = '';
  late TextEditingController _searchController;
  late Stream<List<Note>> _notesStream;
  List<Note>? _filteredNotes;
  String _lastSearch = '';
  List<Note>? _lastSourceNotes;
  // Debounce timer for search
  Timer? _searchDebounceTimer;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    // Initialize stream once in initState
    _notesStream = widget.storage.getNotesStream();
  }

  @override
  void dispose() {
    _searchDebounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  /// Debounced search update to avoid rebuilding on every keystroke
  void _onSearchChanged(String value) {
    _searchDebounceTimer?.cancel();
    _searchDebounceTimer = Timer(const Duration(milliseconds: 150), () {
      if (context.mounted) {
        setState(() => _search = value);
      }
    });
  }

  void _logout() async {
    widget.storage.clearCache();
    await FirebaseAuth.instance.signOut();
  }

  void _openNote(BuildContext context, Note note) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black26,
      builder: (context) => NoteEditScreen(note: note, storage: widget.storage),
    );
  }

  void _openTrash(BuildContext context) {
    HapticFeedback.mediumImpact();
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => TrashScreen(storage: widget.storage),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeOutCubic;
          final tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          return SlideTransition(position: animation.drive(tween), child: child);
        },
      ),
    );
  }

  /// Optimized filtering with memoization using hash-based comparison for better performance
  List<Note> _getFilteredAndSortedNotes(List<Note> sourceNotes) {
    final lastSource = _lastSourceNotes;
    final filtered = _filteredNotes;

    // Quick cache check using hash-based comparison for O(1) lookup instead of O(n²)
    if (filtered != null &&
        _lastSearch == _search &&
        lastSource != null &&
        lastSource.length == sourceNotes.length) {
      // Use hash set for O(1) comparison instead of O(n²) every/any
      final oldIds = Map.fromEntries(lastSource.map((n) => MapEntry('${n.id}_${n.updatedAt.millisecondsSinceEpoch}', true)));
      final allMatch = sourceNotes.every((n) => oldIds.containsKey('${n.id}_${n.updatedAt.millisecondsSinceEpoch}'));
      if (allMatch) {
        return filtered;
      }
    }

    // Filter out archived notes
    var notes = sourceNotes.where((n) => !n.isArchived).toList();

    // Apply search filter if needed
    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      notes = notes.where((n) =>
        n.title.toLowerCase().contains(q) ||
        n.content.toLowerCase().contains(q) ||
        n.labels.any((l) => l.toLowerCase().contains(q))
      ).toList();
    }

    // Sort: pinned first, then by updatedAt
    notes.sort((a, b) {
      if (a.isPinned != b.isPinned) return a.isPinned ? -1 : 1;
      return b.updatedAt.compareTo(a.updatedAt);
    });

    // Update cache
    _filteredNotes = List.unmodifiable(notes);
    _lastSearch = _search;
    _lastSourceNotes = List.unmodifiable(sourceNotes);
    return notes;
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    const paddingH = 24.0;
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppColors.obsidianBlack,
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          Positioned.fill(
            child: VisionBackground(),
          ),
          SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(paddingH, 10, paddingH, 0),
                    child: Row(
                      children: [
                        Expanded(
                          child: GlassSearchBar(
                            controller: _searchController,
                            onChanged: _onSearchChanged,
                          ),
                        ),
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: () => _showMenu(context),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                            ),
                            child: const Icon(
                              CupertinoIcons.ellipsis_vertical,
                              size: 26,
                              color: Colors.white,
                              shadows: AppColors.iconShadows,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                StreamBuilder<List<Note>>(
                  stream: _notesStream,
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return SliverFillRemaining(
                        child: Center(
                          child: Text(
                            'Error: ${snapshot.error}',
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      );
                    }
                    final sourceNotes = snapshot.data;
                    if (sourceNotes == null) {
                      return const SliverFillRemaining(
                        child: Center(
                          child: CupertinoActivityIndicator(
                            radius: 15,
                          ),
                        ),
                      );
                    }

                    // Optimized filtering - only runs when data or search changes
                    final notes = _getFilteredAndSortedNotes(sourceNotes);

                    if (notes.isEmpty) {
                      return SliverFillRemaining(
                        child: Center(
                          child: Text(
                            l10n?.noNotes ?? 'No notes found',
                            style: const TextStyle(
                              color: AppColors.secondaryText,
                              fontSize: 17,
                            ),
                          ),
                        ),
                      );
                    }

                    final crossAxisCount = ((size.width - 2 * paddingH + 18.0) / (300.0 + 18.0))
                        .floor()
                        .clamp(1, 6)
                        .toInt();

                  return SliverPadding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24.0,
                      vertical: 24.0,
                    ),
                    sliver: SliverMasonryGrid.count(
                      crossAxisCount: crossAxisCount,
                      mainAxisSpacing: 18.0,
                      crossAxisSpacing: 18.0,
                      itemBuilder: (context, i) => NoteCard(
                        key: ValueKey('note_${notes[i].id}'),
                        note: notes[i],
                        onTap: () => _openNote(context, notes[i]),
                      ),
                      childCount: notes.length,
                    ),
                  );
                  },
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
          ),
          Positioned(
            bottom: size.height * 0.04,
            left: 0,
            right: 0,
            child: const Center(child: _NewNoteButton()),
          ),
        ],
      ),
    );
  }

  void _showMenu(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return;
    final outerContext = context;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: VisionGlassCard(
          borderRadius: 24,
          color: AppColors.obsidianBlack.withValues(alpha: 0.9),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(width: 36, height: 5, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2.5))),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppColors.accentBlue, AppColors.accentDeepPurple],
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.blur_on, size: 20, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Glass Keep',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _MenuItem(icon: CupertinoIcons.paintbrush, label: l10n.appearance, onTap: () { Navigator.pop(context); _openBackgroundSettings(outerContext); }),
              _MenuItem(icon: CupertinoIcons.globe, label: l10n.language, onTap: () { Navigator.pop(context); _showLanguagePicker(outerContext); }),
              _MenuItem(icon: CupertinoIcons.trash, label: l10n.trash, onTap: () { Navigator.pop(context); _openTrash(outerContext); }),
              _MenuItem(icon: Icons.upload_file, label: l10n.exportBackup, onTap: () async {
                Navigator.pop(context);
                try {
                  await widget.storage.exportNotes();
                  if (outerContext.mounted) {
                    final exportL10n = AppLocalizations.of(outerContext);
                    ScaffoldMessenger.of(outerContext).showSnackBar(
                      SnackBar(
                        content: Text(exportL10n?.exportSuccess ?? 'Exported successfully'),
                        backgroundColor: AppColors.accentBlue,
                        behavior: SnackBarBehavior.floating,
                        margin: const EdgeInsets.all(16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    );
                  }
                } catch (e) {
                  if (outerContext.mounted) {
                    final exportL10n = AppLocalizations.of(outerContext);
                    ScaffoldMessenger.of(outerContext).showSnackBar(
                      SnackBar(
                        content: Text('${exportL10n?.exportError ?? 'Export error'}: $e'),
                        backgroundColor: AppColors.accentRed,
                        behavior: SnackBarBehavior.floating,
                        margin: const EdgeInsets.all(16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    );
                  }
                }
              }),
              _MenuItem(icon: Icons.download, label: l10n.importBackup, onTap: () async {
                Navigator.pop(context);
                try {
                  await widget.storage.importNotes();
                  if (outerContext.mounted) {
                    final importL10n = AppLocalizations.of(outerContext);
                    ScaffoldMessenger.of(outerContext).showSnackBar(
                      SnackBar(
                        content: Text(importL10n?.importSuccess ?? 'Imported successfully'),
                        backgroundColor: AppColors.accentBlue,
                        behavior: SnackBarBehavior.floating,
                        margin: const EdgeInsets.all(16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    );
                  }
                } catch (e) {
                  if (outerContext.mounted) {
                    final importL10n = AppLocalizations.of(outerContext);
                    ScaffoldMessenger.of(outerContext).showSnackBar(
                      SnackBar(
                        content: Text('${importL10n?.importError ?? 'Import error'}: $e'),
                        backgroundColor: AppColors.accentRed,
                        behavior: SnackBarBehavior.floating,
                        margin: const EdgeInsets.all(16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    );
                  }
                }
              }),
              const _BiometricToggle(),
              _MenuItem(icon: Icons.logout, label: l10n.logout, onTap: () { Navigator.pop(context); _logout(); }, isDestructive: true),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _openBackgroundSettings(BuildContext context) {
    final provider = GlassAnimationProvider.of(context);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SettingsScreen(
          storage: widget.storage,
          onThemeChanged: (Color? color, List<Color>? blobs, Decoration? decoration) {
            debugPrint('[SYSTEM-REBORN] Theme change requested: color=$color, blobs=${blobs?.map((c) => c.value).toList()}');
            if (provider?.onThemeChanged != null) {
              provider!.onThemeChanged!(color, blobs);
              debugPrint('[SYSTEM-REBORN] Theme change callback executed');
            } else {
              debugPrint('[SYSTEM-REBORN] ERROR: onThemeChanged is null in provider');
            }
          },
        ),
      ),
    );
  }

  void _showLanguagePicker(BuildContext context) {
    final provider = GlassAnimationProvider.of(context);
    if (provider == null) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: VisionGlassCard(
          borderRadius: 24,
          color: AppColors.obsidianBlack.withValues(alpha: 0.9),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(width: 36, height: 5, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2.5))),
              const SizedBox(height: 20),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    Icon(CupertinoIcons.globe, color: AppColors.accentBlue, size: 22, shadows: AppColors.iconShadows),
                    SizedBox(width: 12),
                    Text('Language', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white)),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              _LanguageOption(locale: const Locale('en'), flag: '🇺🇸', name: 'English', currentLocale: provider.locale, onTap: (locale) {
                provider.onLocaleChanged(locale);
                Navigator.pop(context);
              }),
              _LanguageOption(locale: const Locale('ru'), flag: '🇷🇺', name: 'Русский', currentLocale: provider.locale, onTap: (locale) {
                provider.onLocaleChanged(locale);
                Navigator.pop(context);
              }),
              _LanguageOption(locale: const Locale('ko'), flag: '🇰🇷', name: '한국어', currentLocale: provider.locale, onTap: (locale) {
                provider.onLocaleChanged(locale);
                Navigator.pop(context);
              }),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  const _MenuItem({required this.icon, required this.label, required this.onTap, this.isDestructive = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        onTap();
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        child: Row(
          children: [
            Icon(icon, color: isDestructive ? AppColors.accentRed : AppColors.accentBlue, size: 26, shadows: AppColors.iconShadows),
            const SizedBox(width: 16),
            Text(label, style: TextStyle(fontSize: 17, color: isDestructive ? AppColors.accentRed : Colors.white)),
          ],
        ),
      ),
    );
  }
}

class _LanguageOption extends StatelessWidget {
  final Locale locale;
  final String flag;
  final String name;
  final Locale currentLocale;
  final Function(Locale) onTap;

  const _LanguageOption({
    required this.locale,
    required this.flag,
    required this.name,
    required this.currentLocale,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = locale == currentLocale;
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        onTap(locale);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accentBlue.withValues(alpha: 0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.accentBlue : Colors.white.withValues(alpha: 0.1),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Text(flag, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                name,
                style: TextStyle(
                  fontSize: 17,
                  color: isSelected ? AppColors.accentBlue : Colors.white,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
            if (isSelected)
              const Icon(
                CupertinoIcons.check_mark_circled,
                color: AppColors.accentBlue,
                size: 22,
                shadows: AppColors.iconShadows,
              ),
          ],
        ),
      ),
    );
  }
}

class _NewNoteButton extends StatelessWidget {
  const _NewNoteButton();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final animationProvider = GlassAnimationProvider.of(context);
    final blobColors = animationProvider?.blobColors ?? [AppColors.accentBlue, AppColors.accentIndigo, AppColors.accentDeepPurple];
    final primaryBlobColor = blobColors.isNotEmpty ? blobColors[0] : AppColors.accentDeepPurple;

    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        final storage = _getStorageService(context);
        if (storage == null) return;
        final n = Note(
          id: '',
          title: '',
          content: '',
          updatedAt: DateTime.now(),
        );
        _openNoteEditor(context, n, storage);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
        decoration: BoxDecoration(
          color: primaryBlobColor.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: primaryBlobColor.withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              CupertinoIcons.plus,
              color: Colors.white,
              size: 28,
              shadows: AppColors.iconShadows,
            ),
            const SizedBox(width: 8),
            Text(
              l10n?.newNote ?? 'New Note',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  StorageService? _getStorageService(BuildContext context) {
    final state = context.findAncestorStateOfType<_NotesScreenState>();
    return state?.widget.storage;
  }

  void _openNoteEditor(BuildContext context, Note note, StorageService storage) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => NoteEditScreen(note: note, storage: storage),
    );
  }
}

class NoteCard extends StatefulWidget {
  final Note note;
  final VoidCallback onTap;

  const NoteCard({super.key, required this.note, required this.onTap});

  @override
  State<NoteCard> createState() => _NoteCardState();
}

class _NoteCardState extends State<NoteCard> with AutomaticKeepAliveClientMixin {
  Uint8List? _decodedImage;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _updateImage();
  }

  @override
  void didUpdateWidget(NoteCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.note.imageBase64 != widget.note.imageBase64 ||
        oldWidget.note.id != widget.note.id) {
      _updateImage();
    }
  }

  void _updateImage() {
    _decodedImage = widget.note.cachedImage;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final image = _decodedImage;
    return RepaintBoundary(
      child: _NoteCardContent(
        key: ValueKey('note_content_${widget.note.id}_${widget.note.updatedAt.millisecondsSinceEpoch}'),
        note: widget.note,
        decodedImage: image,
        onTap: widget.onTap,
      ),
    );
  }
}

/// Вынесенный контент карточки для оптимизации перерисовки
class _NoteCardContent extends StatelessWidget {
  final Note note;
  final Uint8List? decodedImage;
  final VoidCallback onTap;

  const _NoteCardContent({
    super.key,
    required this.note,
    required this.decodedImage,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final image = decodedImage;
    final reminder = note.reminder;

    return VisionGlassCard(
      padding: EdgeInsets.zero,
      useDistortion: false, // Отключаем искажение для карточек заметок для производительности
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (image != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.memory(
                      image,
                      fit: BoxFit.cover,
                      cacheWidth: 400,
                      gaplessPlayback: true,
                    ),
                  ),
                ),
              Row(
                children: [
                  if (note.isPinned)
                    const Icon(
                      CupertinoIcons.pin,
                      size: 14,
                      color: AppColors.accentDeepPurple,
                      shadows: AppColors.iconShadows,
                    ),
                  if (note.isPinned) const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      note.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.white,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                ],
              ),
              if (note.content.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    note.content,
                    maxLines: 6,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 14,
                      height: 1.3,
                    ),
                  ),
                ),
              if (note.labels.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: note.labels.map((l) => LabelChip(label: l)).toList(),
                ),
              ],
              if (reminder != null) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(
                      CupertinoIcons.alarm,
                      size: 14,
                      color: AppColors.accentDeepPurple,
                      shadows: AppColors.iconShadows,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat('dd.MM HH:mm').format(reminder),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.accentDeepPurple,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class NoteEditScreen extends StatefulWidget {
  final Note note;
  final StorageService storage;

  const NoteEditScreen({super.key, required this.note, required this.storage});

  @override
  State<NoteEditScreen> createState() => _NoteEditScreenState();
}

class _NoteEditScreenState extends State<NoteEditScreen> {
  late TextEditingController _t, _c, _l;
  String? _img;
  DateTime? _rem;
  final _picker = ImagePicker();
  Uint8List? _decodedImage;
  bool _isLoading = false;

  /// Compress image to fit within maxBytes limit
  Future<Uint8List?> _compressImage(Uint8List bytes, int maxBytes) async {
    // For web, we can't use dart:io easily, so if image is too large, return null to skip it
    if (bytes.length <= maxBytes) return bytes;
    
    // Image too large for Firestore (1MB limit), skip saving image
    debugPrint('[SYSTEM-REBORN] Image too large (${bytes.length} bytes), skipping image to prevent Firestore error');
    if (context.mounted) {
      _showSnackBar('Image too large, saved note without image', isError: true);
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _t = TextEditingController(text: widget.note.title);
    _c = TextEditingController(text: widget.note.content);
    _l = TextEditingController(text: widget.note.labels.join(', '));
    _img = widget.note.imageBase64;
    _rem = widget.note.reminder;
    // Use cached image from note if available
    _decodedImage = widget.note.cachedImage;
  }

  @override
  void dispose() {
    _t.dispose();
    _c.dispose();
    _l.dispose();
    super.dispose();
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.accentRed : AppColors.accentDeepPurple,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _save() async {
    if (_t.text.trim().isEmpty && _c.text.trim().isEmpty && _img == null) {
      if (context.mounted) Navigator.pop(context);
      return;
    }
    final l10n = AppLocalizations.of(context);

    final updatedNote = widget.note.copyWith(
      title: _t.text.trim(),
      content: _c.text.trim(),
      labels: _l.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
      imageBase64: _img,
      reminder: _rem,
      updatedAt: DateTime.now(),
    );
    try {
      await widget.storage.save(updatedNote);
      if (context.mounted) {
        _showSnackBar(l10n?.saveSuccess ?? 'Saved');
        Navigator.pop(context);
      }
    } catch (e) {
      if (context.mounted) {
        _showSnackBar('${l10n?.saveError ?? 'Save error'}: $e', isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final l10n = AppLocalizations.of(context);

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        height: size.height * 0.85,
        decoration: BoxDecoration(
          color: AppColors.obsidianBlack.withValues(alpha: 0.9),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          border: Border.all(color: Colors.white.withValues(alpha: 0.15), width: 1),
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Stack(
              children: [
                Positioned(
                  top: 0, left: 0, right: 0, height: 1,
                  child: Container(decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.transparent, Colors.white.withValues(alpha: 0.1), Colors.transparent]))),
                ),
                Scaffold(
                  resizeToAvoidBottomInset: false,
                  backgroundColor: Colors.transparent,
                  appBar: PreferredSize(
                    preferredSize: const Size.fromHeight(70),
                    child: Column(
                      children: [
                        const SizedBox(height: 12),
                        Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.tertiaryText.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2))),
                        const SizedBox(height: 4),
                        CupertinoNavigationBar(
                          backgroundColor: Colors.transparent,
                          border: null,
                          automaticallyImplyLeading: false,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CupertinoButton(
                                padding: EdgeInsets.zero,
                                child: Icon(
                                  CupertinoIcons.pin,
                                  color: widget.note.isPinned ? AppColors.accentDeepPurple : AppColors.accentDeepPurple.withValues(alpha: 0.3),
                                  size: 22,
                                  shadows: AppColors.iconShadows,
                                ),
                                onPressed: () async {
                                  HapticFeedback.lightImpact();
                                  final updatedNote = widget.note.copyWith(isPinned: !widget.note.isPinned);
                                  try {
                                    await widget.storage.save(updatedNote);
                                    if (context.mounted) setState(() {});
                                  } catch (e) {
                                    _showSnackBar('${l10n?.pinError ?? 'Pin error'}: $e', isError: true);
                                  }
                                },
                              ),
                              CupertinoButton(
                                padding: EdgeInsets.zero,
                                child: const Icon(CupertinoIcons.trash, color: AppColors.accentRed, size: 22, shadows: AppColors.iconShadows),
                                onPressed: () async {
                                  HapticFeedback.mediumImpact();
                                  if (widget.note.id.isNotEmpty) {
                                    try {
                                      await widget.storage.delete(widget.note.id);
                                      if (context.mounted) Navigator.pop(context);
                                    } catch (e) {
                                      _showSnackBar('${l10n?.deleteError ?? 'Delete error'}: $e', isError: true);
                                    }
                                  } else {
                                    Navigator.pop(context);
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  body: Stack(
                    children: [
                      _buildBody(l10n),
                      Positioned(
                        right: 24,
                        bottom: 24,
                        child: GestureDetector(
                          onTap: () {
                            HapticFeedback.mediumImpact();
                            _save();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                            decoration: BoxDecoration(
                              color: AppColors.accentDeepPurple.withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: [BoxShadow(color: AppColors.accentDeepPurple.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  CupertinoIcons.checkmark,
                                  color: Colors.white,
                                  size: 24,
                                  shadows: AppColors.iconShadows,
                                ),
                                const SizedBox(width: 8),
                                Text(l10n?.save ?? 'Save', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(AppLocalizations? l10n) {
    final image = _decodedImage;
    final reminder = _rem;
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(
        children: [
          if (image != null)
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.memory(
                    image,
                    // Optimize image rendering
                    cacheWidth: 800,
                    gaplessPlayback: true,
                  ),
                ),
                Positioned(
                  right: 8,
                  top: 8,
                  child: CupertinoButton(
                    padding: EdgeInsets.zero,
                    child: const Icon(
                      CupertinoIcons.multiply_circle,
                      color: Colors.white70,
                      shadows: AppColors.iconShadows,
                    ),
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      if (context.mounted) {
                        setState(() {
                          _img = null;
                          _decodedImage = null;
                          widget.note.clearImageCache();
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
          TextField(controller: _t, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: -0.5), decoration: InputDecoration(hintText: l10n?.title ?? 'Title', hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)), border: InputBorder.none)),
          TextField(controller: _c, maxLines: null, style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 18, height: 1.5), decoration: InputDecoration(hintText: l10n?.note ?? 'Note', hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)), border: InputBorder.none)),
          const SizedBox(height: 24),
          VisionGlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            useDistortion: false,
            child: IntrinsicHeight(
              child: Row(
                children: [
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(CupertinoIcons.photo, color: Colors.white70, shadows: AppColors.iconShadows),
                    onPressed: _isLoading ? null : () async {
                      HapticFeedback.lightImpact();
                      if (context.mounted) setState(() => _isLoading = true);
                      try {
                        final XFile? image = await _picker.pickImage(
                          source: ImageSource.gallery,
                          maxWidth: 800,
                          maxHeight: 800,
                          imageQuality: 60,
                        );
                        if (!context.mounted) return;
                        if (image != null) {
                          final bytes = await image.readAsBytes();
                          // Compress further if too large (>500KB)
                          if (bytes.length > 500 * 1024) {
                            if (context.mounted) {
                              setState(() => _isLoading = true);
                            }
                            final compressed = await _compressImage(bytes, 500 * 1024);
                            if (!context.mounted) return;
                            setState(() {
                              _img = compressed != null ? base64Encode(compressed) : null;
                              _decodedImage = compressed;
                            });
                          } else {
                            // Process in microtask to avoid blocking UI
                            await Future.microtask(() {
                              if (context.mounted) {
                                setState(() {
                                  _img = base64Encode(bytes);
                                  _decodedImage = bytes;
                                });
                              }
                            });
                          }
                        }
                      } finally {
                        if (context.mounted) {
                          setState(() => _isLoading = false);
                        }
                      }
                    },
                  ),
                  const VerticalDivider(color: Colors.white24, indent: 8, endIndent: 8),
                  IconButton(padding: EdgeInsets.zero, constraints: const BoxConstraints(), icon: const Icon(CupertinoIcons.alarm, color: Colors.white70, shadows: AppColors.iconShadows), onPressed: () async {
                    HapticFeedback.lightImpact();
                    final now = DateTime.now();
                    final d = await showDatePicker(context: context, initialDate: now, firstDate: now, lastDate: now.add(const Duration(days: 365)));
                    if (d == null || !context.mounted) return;
                    final t = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(now));
                    if (t == null || !context.mounted) return;
                    setState(() => _rem = DateTime(d.year, d.month, d.day, t.hour, t.minute));
                  }),
                  if (reminder != null) ...[
                    const SizedBox(width: 8),
                    Expanded(child: Text(DateFormat('dd.MM HH:mm').format(reminder), style: const TextStyle(fontSize: 12, color: AppColors.accentDeepPurple, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      child: const Icon(CupertinoIcons.xmark_circle_fill, size: 18, color: Colors.white54),
                      onPressed: () => setState(() => _rem = null),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          TextField(controller: _l, style: const TextStyle(color: Colors.white70, fontSize: 15), decoration: InputDecoration(hintText: l10n?.labelsHint ?? 'Labels', hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)), border: InputBorder.none)),
          const SizedBox(height: 100),
        ],
      ),
    );
  }
}

/// TRASH SCREEN - Экран корзины
class TrashScreen extends StatefulWidget {
  final StorageService storage;
  const TrashScreen({super.key, required this.storage});

  @override
  State<TrashScreen> createState() => _TrashScreenState();
}

class _TrashScreenState extends State<TrashScreen> {
  late Stream<List<Note>> _notesStream;

  @override
  void initState() {
    super.initState();
    _notesStream = widget.storage.getNotesStream();
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.accentRed : AppColors.accentDeepPurple,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final size = MediaQuery.sizeOf(context);
    final paddingH = size.width * 0.04;

    return Scaffold(
      backgroundColor: AppColors.obsidianBlack,
      body: Stack(
        children: [
          Positioned.fill(child: VisionBackground()),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(paddingH, 10, paddingH, 0),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          Navigator.pop(context);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                          ),
                          child: const Icon(CupertinoIcons.arrow_left, color: Colors.white70, size: 22, shadows: AppColors.iconShadows),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(l10n?.trash ?? 'Trash', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                    ],
                  ),
                ),
                Expanded(
                  child: StreamBuilder<List<Note>>(
                    stream: _notesStream,
                    builder: (context, snapshot) {
                      final data = snapshot.data;
                      if (data == null) {
                        return const Center(child: CupertinoActivityIndicator(color: AppColors.accentBlue));
                      }

                      final archivedNotes = data.where((n) => n.isArchived).toList();

                      if (archivedNotes.isEmpty) {
                        return Center(child: Text(l10n?.trashEmptyHint ?? 'Trash is empty', style: const TextStyle(color: AppColors.secondaryText, fontSize: 17)));
                      }

                      return ListView.builder(
                        padding: EdgeInsets.all(paddingH),
                        itemCount: archivedNotes.length,
                        itemBuilder: (context, index) {
                          final note = archivedNotes[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _TrashNoteCard(
                              note: note,
                              onRestore: () async {
                                final updatedNote = note.copyWith(isArchived: false);
                                try {
                                  await widget.storage.save(updatedNote);
                                  _showSnackBar(l10n?.noteRestored ?? 'Note restored');
                                } catch (e) {
                                  _showSnackBar('${l10n?.restoreError ?? 'Restore error'}: $e', isError: true);
                                }
                              },
                              onDelete: () async {
                                try {
                                  await widget.storage.delete(note.id);
                                  _showSnackBar(l10n?.deletePermanent ?? 'Deleted permanently');
                                } catch (e) {
                                  _showSnackBar('${l10n?.deleteError ?? 'Delete error'}: $e', isError: true);
                                }
                              },
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TrashNoteCard extends StatelessWidget {
  final Note note;
  final VoidCallback onRestore;
  final VoidCallback onDelete;

  const _TrashNoteCard({
    required this.note,
    required this.onRestore,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: VisionGlassCard(
        useDistortion: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    note.title.isEmpty ? 'Untitled' : note.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    CupertinoIcons.arrow_counterclockwise,
                    color: AppColors.accentBlue,
                    size: 20,
                    shadows: AppColors.iconShadows,
                  ),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    onRestore();
                  },
                  tooltip: 'Restore',
                ),
                IconButton(
                  icon: const Icon(
                    CupertinoIcons.trash,
                    color: AppColors.accentRed,
                    size: 20,
                    shadows: AppColors.iconShadows,
                  ),
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    onDelete();
                  },
                  tooltip: 'Delete forever',
                ),
              ],
            ),
            if (note.content.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  note.content,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 14,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _BiometricToggle extends StatefulWidget {
  const _BiometricToggle();

  @override
  State<_BiometricToggle> createState() => _BiometricToggleState();
}

class _BiometricToggleState extends State<_BiometricToggle> {
  final BiometricService _biometricService = BiometricService();
  bool _isEnabled = false;
  bool _isAvailable = false;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    final available = await _biometricService.isBiometricsAvailable();
    final enabled = await _biometricService.isEnabled();
    if (context.mounted) {
      setState(() {
        _isAvailable = available;
        _isEnabled = enabled;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAvailable || kIsWeb) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
      child: Row(
        children: [
          const Icon(CupertinoIcons.lock_shield,
              color: AppColors.accentBlue, size: 26, shadows: AppColors.iconShadows),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              l10n?.biometricLock ?? 'Biometric Lock',
              style: const TextStyle(fontSize: 17, color: Colors.white),
            ),
          ),
          Switch.adaptive(
            value: _isEnabled,
            activeTrackColor: AppColors.accentBlue,
            onChanged: (value) async {
              HapticFeedback.mediumImpact();
              if (value) {
                final authenticated = await _biometricService.authenticate();
                if (authenticated) {
                  await _biometricService.setEnabled(true);
                  if (context.mounted) setState(() => _isEnabled = true);
                }
              } else {
                await _biometricService.setEnabled(false);
                if (context.mounted) setState(() => _isEnabled = false);
              }
            },
          ),
        ],
      ),
    );
  }
}
