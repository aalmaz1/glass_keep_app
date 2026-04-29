import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/cupertino.dart' show CupertinoIcons, CupertinoActivityIndicator, CupertinoButton;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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


enum SortType { manual, dateCreated, dateModified }

class NotesScreen extends StatefulWidget {
  final StorageService storage;
  const NotesScreen({super.key, required this.storage});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  String _search = '';
  late TextEditingController _searchController;
  late ScrollController _scrollController;
  StreamSubscription<StreamedNotes>? _notesSubscription;
  
  List<Note> _streamNotes = [];
  final List<Note> _additionalNotes = [];
  DocumentSnapshot? _lastDoc;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  
  Timer? _searchDebounceTimer;
  SortType _sortType = SortType.dateModified;
  bool _sortAscending = false;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _scrollController = ScrollController();
    
    _notesSubscription = widget.storage.getNotesStream().listen((data) {
      if (mounted) {
        setState(() {
          _streamNotes = data.notes;
          // If we haven't successfully loaded additional notes via pagination yet,
          // keep our pagination pointer synced with the end of the real-time stream.
          if (_additionalNotes.isEmpty) {
            _lastDoc = data.lastDoc;
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _notesSubscription?.cancel();
    _searchDebounceTimer?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMoreNotes() async {
    if (_isLoadingMore || !_hasMore || _search.isNotEmpty) return;

    setState(() => _isLoadingMore = true);

    final result = await widget.storage.getNotesPaginated(
      startAfter: _lastDoc,
      limit: 20,
    );

    if (mounted) {
      setState(() {
        _isLoadingMore = false;
        _lastDoc = result.lastDoc;
        _hasMore = result.hasMore;
        
        // Add only notes not already in stream or already in additional notes
        final existingIds = {
          ..._streamNotes.map((n) => n.id),
          ..._additionalNotes.map((n) => n.id),
        };
        final newNotes = result.notes.where((n) => !existingIds.contains(n.id)).toList();
        _additionalNotes.addAll(newNotes);
      });
    }
  }

  List<Note> _getAllCombinedNotes() {
    // Merge stream notes and additional notes
    final combined = [..._streamNotes];
    final streamIds = _streamNotes.map((n) => n.id).toSet();
    
    for (var note in _additionalNotes) {
      if (!streamIds.contains(note.id)) {
        combined.add(note);
      }
    }
    return combined;
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

  /// Update note order in Firestore for manual sorting
  Future<void> _updateNoteOrder(List<String> orderedIds) async {
    // Update orderIndex for each note
    for (int i = 0; i < orderedIds.length; i++) {
      final id = orderedIds[i];
      // Find the note in either stream or additional notes
      Note? note;
      int streamIdx = -1;
      int addIdx = -1;
      
      streamIdx = _streamNotes.indexWhere((n) => n.id == id);
      if (streamIdx != -1) {
        note = _streamNotes[streamIdx];
      } else {
        addIdx = _additionalNotes.indexWhere((n) => n.id == id);
        if (addIdx != -1) {
          note = _additionalNotes[addIdx];
        }
      }
      if (note != null && note.orderIndex != i) {
        final updatedNote = note.copyWith(orderIndex: i);
        await widget.storage.save(updatedNote);
        // Update local list
        if (streamIdx != -1) {
          _streamNotes[streamIdx] = updatedNote;
        } else if (addIdx != -1) {
          _additionalNotes[addIdx] = updatedNote;
        }
      }
    }
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
      builder: (context) => NoteEditScreen(
        note: note,
        storage: widget.storage,
        onDeleted: _handleNoteDeleted,
        onSaved: _handleNoteSaved,
      ),
    );
  }

  void _handleNoteDeleted(String id) {
    if (mounted) {
      setState(() {
        _streamNotes.removeWhere((n) => n.id == id);
        _additionalNotes.removeWhere((n) => n.id == id);
      });
    }
  }

  void _handleNoteSaved(Note note) {
    if (mounted) {
      setState(() {
        // Update in stream notes if exists
        final streamIdx = _streamNotes.indexWhere((n) => n.id == note.id);
        if (streamIdx != -1) {
          _streamNotes[streamIdx] = note;
        } else {
          // Update in additional notes if exists
          final addIdx = _additionalNotes.indexWhere((n) => n.id == note.id);
          if (addIdx != -1) {
            _additionalNotes[addIdx] = note;
          } else if (note.id.isNotEmpty) {
            // New note that isn't in stream yet
            _streamNotes.insert(0, note);
          }
        }
      });
    }
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

  /// Simplified filtering and sorting without over-engineered memoization
  List<Note> _getFilteredAndSortedNotes(List<Note> sourceNotes) {
    // Filter out archived notes
    var notes = sourceNotes.where((n) => !n.isArchived).toList();

    // Apply search filter if needed
    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      notes = notes.where((n) =>
        n.title.toLowerCase().contains(q) ||
        n.content.toLowerCase().contains(q) ||
        n.labels.any((l) => l.toLowerCase().contains(q)) ||
        n.checklist.any((item) => item.text.toLowerCase().contains(q))
      ).toList();
    }

    // Sort based on selected sort type
    if (_sortType == SortType.manual) {
      // Manual sort: use orderIndex field
      notes.sort((a, b) {
        if (a.isPinned != b.isPinned) return a.isPinned ? -1 : 1;
        return a.orderIndex.compareTo(b.orderIndex);
      });
    } else if (_sortType == SortType.dateCreated) {
      // Sort by createdAt
      notes.sort((a, b) {
        if (a.isPinned != b.isPinned) return a.isPinned ? -1 : 1;
        return _sortAscending ? a.createdAt.compareTo(b.createdAt) : b.createdAt.compareTo(a.createdAt);
      });
    } else {
      // Sort by updatedAt (default)
      notes.sort((a, b) {
        if (a.isPinned != b.isPinned) return a.isPinned ? -1 : 1;
        return _sortAscending ? a.updatedAt.compareTo(b.updatedAt) : b.updatedAt.compareTo(a.updatedAt);
      });
    }

    return notes;
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    const paddingH = 24.0;
    final l10n = AppLocalizations.of(context);
    final provider = GlassAnimationProvider.of(context);
    final themeColor = provider?.themeColor ?? AppColors.obsidianBlack;

    return Scaffold(
      backgroundColor: AppColors.obsidianBlack,
      extendBody: true,
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          Positioned.fill(
            child: VisionBackground(
              backgroundColor: themeColor,
              blobColors: provider?.blobColors,
            ),
          ),
          SafeArea(
            child: NotificationListener<ScrollNotification>(
              onNotification: (notification) {
                final provider = GlassAnimationProvider.of(context);
                if (provider != null) {
                  if (notification is ScrollStartNotification) {
                    provider.isLowPerformanceMode.value = true;
                  } else if (notification is ScrollEndNotification) {
                    provider.isLowPerformanceMode.value = false;
                  }
                }

                if (notification is ScrollUpdateNotification) {
                  if (notification.metrics.pixels >= notification.metrics.maxScrollExtent * 0.8) {
                    _loadMoreNotes();
                  }
                }
                return false;
              },
              child: CustomScrollView(
                controller: _scrollController,
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
                            onSortPressed: () => _showSortMenu(context),
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
                Builder(
                  builder: (context) {
                    final sourceNotes = _getAllCombinedNotes();
                    final notes = _getFilteredAndSortedNotes(sourceNotes);

                    if (notes.isEmpty && _streamNotes.isEmpty) {
                      return const SliverFillRemaining(
                        child: Center(
                          child: CupertinoActivityIndicator(
                            radius: 15,
                          ),
                        ),
                      );
                    }

                    if (notes.isEmpty) {
                      return SliverFillRemaining(
                        child: Center(
                          child: Text(
                            l10n?.noNotes ?? 'No notes found',
                            style: const TextStyle(
                              color: Colors.white70,
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

                    // For manual sort mode, use ReorderableListView; otherwise use MasonryGrid for performance
                    if (_sortType == SortType.manual) {
                      return SliverPadding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24.0,
                          vertical: 24.0,
                        ),
                        sliver: ReorderableListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: notes.length,
                          onReorder: (oldIndex, newIndex) {
                            setState(() {
                              if (newIndex > oldIndex) newIndex -= 1;
                              final note = notes.removeAt(oldIndex);
                              notes.insert(newIndex, note);
                              // Update the order in additionalNotes or streamNotes accordingly
                              _updateNoteOrder(notes.map((n) => n.id).toList());
                            });
                          },
                          itemBuilder: (context, i) => Padding(
                            key: ValueKey('note_${notes[i].id}'),
                            padding: const EdgeInsets.only(bottom: 18.0),
                            child: NoteCard(
                              note: notes[i],
                              onTap: () => _openNote(context, notes[i]),
                            ),
                          ),
                        ),
                      );
                    } else {
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
                    }
                  },
                ),
                if (_isLoadingMore)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.only(bottom: 40),
                      child: Center(child: CupertinoActivityIndicator(color: Colors.white)),
                    ),
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
          ),
        ),
      ],
    ),
    floatingActionButton: _NewNoteButton(
        onPressed: () {
          HapticFeedback.mediumImpact();
          _openNote(context, Note.empty());
        },
        label: l10n?.newNote ?? 'New Note',
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  void _showMenu(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return;
    final outerContext = context;
    final provider = GlassAnimationProvider.of(context);
    final themeColor = provider?.themeColor ?? AppColors.obsidianBlack;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: themeColor.withValues(alpha: 0.95),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1.5),
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
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
      ),
    );
  }

  void _showSortMenu(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return;
    final provider = GlassAnimationProvider.of(context);
    final themeColor = provider?.themeColor ?? AppColors.obsidianBlack;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: themeColor.withValues(alpha: 0.95),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1.5),
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Text(
                    'Сортировка',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                _SortMenuItem(
                  label: 'Ручной',
                  subtitle: 'Перетаскивайте заметки для изменения порядка',
                  isSelected: _sortType == SortType.manual,
                  onTap: () {
                    Navigator.pop(context);
                    setState(() => _sortType = SortType.manual);
                  },
                ),
                _SortMenuItem(
                  label: 'По дате создания',
                  subtitle: _sortAscending ? 'Сначала старые' : 'Сначала новые',
                  isSelected: _sortType == SortType.dateCreated,
                  onTap: () {
                    Navigator.pop(context);
                    setState(() {
                      if (_sortType == SortType.dateCreated) {
                        _sortAscending = !_sortAscending;
                      } else {
                        _sortType = SortType.dateCreated;
                        _sortAscending = false;
                      }
                    });
                  },
                ),
                _SortMenuItem(
                  label: 'По дате изменения',
                  subtitle: _sortAscending ? 'Сначала старые' : 'Сначала новые',
                  isSelected: _sortType == SortType.dateModified,
                  onTap: () {
                    Navigator.pop(context);
                    setState(() {
                      if (_sortType == SortType.dateModified) {
                        _sortAscending = !_sortAscending;
                      } else {
                        _sortType = SortType.dateModified;
                        _sortAscending = false;
                      }
                    });
                  },
                ),
                const SizedBox(height: 20),
              ],
            ),
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
          onThemeChanged: (AppTheme theme) {
            debugPrint('[SYSTEM-REBORN] Theme change requested: theme=${theme.name}');
            if (provider?.onThemeChanged != null) {
              provider!.onThemeChanged!(theme);
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

class _NewNoteButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String label;

  const _NewNoteButton({required this.onPressed, required this.label});

  @override
  Widget build(BuildContext context) {
    final provider = GlassAnimationProvider.of(context);
    final themeColor = provider?.themeColor ?? Colors.black;
    final accentColor = provider?.accentColor ?? Colors.white;

    return Align(
      alignment: Alignment.bottomCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 220),
        child: GestureDetector(
          onTap: onPressed,
          child: VisionGlassCard(
            borderRadius: 28,
            color: themeColor.withValues(alpha: 0.8),
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.plus, color: accentColor, size: 24),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: TextStyle(
                    color: accentColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                    letterSpacing: -0.4,
                  ),
                ),
              ],
            ),
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

class _SortMenuItem extends StatelessWidget {
  final String label;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _SortMenuItem({
    required this.label,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        onTap();
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accentBlue.withValues(alpha: 0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.accentBlue : Colors.white.withValues(alpha: 0.1),
            width: 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      color: isSelected ? AppColors.accentBlue : Colors.white,
                    ),
                  ),
                ),
                if (isSelected)
                  const Icon(
                    CupertinoIcons.checkmark_circle_fill,
                    color: AppColors.accentBlue,
                    size: 22,
                    shadows: AppColors.iconShadows,
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 13,
                color: Colors.white.withValues(alpha: 0.6),
              ),
            ),
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
                CupertinoIcons.checkmark_circle_fill,
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

class NoteCard extends StatefulWidget {
  final Note note;
  final VoidCallback onTap;

  const NoteCard({super.key, required this.note, required this.onTap});

  @override
  State<NoteCard> createState() => _NoteCardState();
}

class _NoteCardState extends State<NoteCard> {
  Uint8List? _decodedImage;

  @override
  void initState() {
    super.initState();
    _updateImage();
  }

  @override
  void dispose() {
    // Clear image cache when card is disposed (scrolled out of view)
    // to keep memory usage under 300MB
    widget.note.clearImageCache();
    super.dispose();
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

  Color _getAccentColor() {
    final provider = GlassAnimationProvider.of(context);
    return provider?.accentColor ?? AppColors.accentBlue;
  }

  @override
  Widget build(BuildContext context) {
    final image = _decodedImage;
    return RepaintBoundary(
      child: _NoteCardContent(
        key: ValueKey('note_content_${widget.note.id}_${widget.note.updatedAt.millisecondsSinceEpoch}'),
        note: widget.note,
        decodedImage: image,
        onTap: widget.onTap,
        accentColor: _getAccentColor(),
      ),
    );
  }
}

/// Extracted card content to optimize repainting
class _NoteCardContent extends StatelessWidget {
  final Note note;
  final Uint8List? decodedImage;
  final VoidCallback onTap;
  final Color accentColor;

  const _NoteCardContent({
    super.key,
    required this.note,
    required this.decodedImage,
    required this.onTap,
    required this.accentColor,
  });

  Widget _buildChecklistPreview(BuildContext context) {
    final itemsToShow = note.checklist.take(4).toList();
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Column(
        children: itemsToShow
            .map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 4.0),
                  child: Row(
                    children: [
                      Icon(
                        item.isChecked ? CupertinoIcons.checkmark_circle_fill : CupertinoIcons.circle,
                        size: 14,
                        color: item.isChecked ? accentColor : Colors.white54,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item.text,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: item.isChecked ? Colors.white54 : Colors.white,
                            fontSize: 14,
                            decoration: item.isChecked ? TextDecoration.lineThrough : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                ))
            .toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final image = decodedImage;
    final reminder = note.reminder;

    return VisionGlassCard(
      padding: EdgeInsets.zero,
      useDistortion: false, // Disable distortion for note cards for performance
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
                    Icon(
                      CupertinoIcons.pin,
                      size: 14,
                      color: accentColor,
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
              if (note.isChecklist && note.checklist.isNotEmpty)
                _buildChecklistPreview(context)
              else if (note.content.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    note.content,
                    maxLines: 6,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
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
                  children: note.labels.map((l) => LabelChip(label: l, accentColor: accentColor)).toList(),
                ),
              ],
              if (reminder != null) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(
                      CupertinoIcons.alarm,
                      size: 14,
                      color: accentColor,
                      shadows: AppColors.iconShadows,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat('dd.MM HH:mm').format(reminder),
                      style: TextStyle(
                        fontSize: 12,
                        color: accentColor,
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
  final Function(String)? onDeleted;
  final Function(Note)? onSaved;

  const NoteEditScreen({super.key, required this.note, required this.storage, this.onDeleted, this.onSaved});

  @override
  State<NoteEditScreen> createState() => _NoteEditScreenState();
}

class _NoteEditScreenState extends State<NoteEditScreen> {
  late TextEditingController _t, _c, _l;
  String? _img;
  DateTime? _rem;
  bool _isPinned = false;
  late String _noteId;
  final _picker = ImagePicker();
  Uint8List? _decodedImage;
  bool _isLoading = false;
  bool _isChecklist = false;
  List<ChecklistItem> _checklist = [];

  /// Compress image to fit within maxBytes limit using a robust approach
  Future<Uint8List?> _compressImage(Uint8List bytes, int maxBytes) async {
    if (bytes.length <= maxBytes) return bytes;
    
    try {
      // Decode image to get dimensions and perform resize
      final ui.ImmutableBuffer buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
      final ui.ImageDescriptor descriptor = await ui.ImageDescriptor.encoded(buffer);
      
      // Calculate target dimensions maintaining aspect ratio
      int targetWidth = descriptor.width;
      int targetHeight = descriptor.height;
      
      const int maxDim = 600;
      if (targetWidth > maxDim || targetHeight > maxDim) {
        if (targetWidth > targetHeight) {
          targetHeight = (targetHeight * maxDim / targetWidth).round();
          targetWidth = maxDim;
        } else {
          targetWidth = (targetWidth * maxDim / targetHeight).round();
          targetHeight = maxDim;
        }
      }

      final ui.Codec codec = await descriptor.instantiateCodec(
        targetWidth: targetWidth,
        targetHeight: targetHeight,
      );
      final ui.FrameInfo frameInfo = await codec.getNextFrame();
      final ui.Image image = frameInfo.image;
      
      // Encode back to image bytes. We use PNG as a simple fallback here because 
      // dart:ui does not provide a native JPEG encoder. While JPEG would provide 
      // better compression for photos, using dart:ui PNG avoids adding heavy 
      // external dependencies for image processing.
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return null;
      final result = byteData.buffer.asUint8List();
      
      debugPrint('[SYSTEM-REBORN] Resized image from ${bytes.length} to ${result.length} bytes');
      
      if (result.length > maxBytes) {
        debugPrint('[SYSTEM-REBORN] Image still large (${result.length} bytes), skipping');
        return null;
      }
      return result;
    } catch (e) {
      debugPrint('[SYSTEM-REBORN] Error compressing image: $e');
      return null;
    }
  }

  @override
  void initState() {
    super.initState();
    _t = TextEditingController(text: widget.note.title);
    _c = TextEditingController(text: widget.note.content);
    _l = TextEditingController(text: widget.note.labels.join(', '));
    _img = widget.note.imageBase64;
    _rem = widget.note.reminder;
    _isPinned = widget.note.isPinned;
    _noteId = widget.note.id;
    // Use cached image from note if available
    _decodedImage = widget.note.cachedImage;
    _isChecklist = widget.note.isChecklist;
    _checklist = List.from(widget.note.checklist);
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
        backgroundColor: isError ? AppColors.accentRed : AppColors.accentBlue,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _toggleChecklist() {
    HapticFeedback.mediumImpact();
    setState(() {
      if (_isChecklist) {
        // Converting from checklist to text
        _c.text = _checklist.map((i) => i.text).join('\n');
        _isChecklist = false;
      } else {
        // Converting from text to checklist
        final lines = _c.text.split('\n').where((l) => l.trim().isNotEmpty).toList();
        if (lines.isEmpty) {
          _checklist = [ChecklistItem(id: DateTime.now().millisecondsSinceEpoch.toString(), text: '')];
        } else {
          _checklist = lines
              .map((l) => ChecklistItem(
                    id: DateTime.now().add(Duration(milliseconds: lines.indexOf(l))).millisecondsSinceEpoch.toString(),
                    text: l,
                  ))
              .toList();
        }
        _isChecklist = true;
      }
    });
  }

  void _save() async {
    if (_t.text.trim().isEmpty && (_isChecklist ? _checklist.isEmpty : _c.text.trim().isEmpty) && _img == null) {
      if (context.mounted) Navigator.pop(context);
      return;
    }
    final l10n = AppLocalizations.of(context);

    final updatedNote = widget.note.copyWith(
      id: _noteId,
      title: _t.text.trim(),
      content: _isChecklist ? '' : _c.text.trim(),
      labels: _l.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
      imageBase64: _img,
      reminder: _rem,
      isPinned: _isPinned,
      updatedAt: DateTime.now(),
      isChecklist: _isChecklist,
      checklist: _isChecklist ? _checklist : [],
    );
    try {
      final savedNote = await widget.storage.save(updatedNote);
      if (mounted) {
        setState(() {
          _noteId = savedNote.id;
        });
      }
      if (widget.onSaved != null) widget.onSaved!(savedNote);
      if (!mounted) return;
      _showSnackBar(l10n?.saveSuccess ?? 'Saved');
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        _showSnackBar('${l10n?.saveError ?? 'Save error'}: $e', isError: true);
      }
    }
  }

  Widget _buildChecklistEditor() {
    final l10n = AppLocalizations.of(context);
    final provider = GlassAnimationProvider.of(context);
    final accentColor = provider?.accentColor ?? AppColors.accentBlue;

    return Column(
      children: [
        ReorderableListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _checklist.length,
          onReorder: (oldIndex, newIndex) {
            setState(() {
              if (newIndex > oldIndex) newIndex -= 1;
              final item = _checklist.removeAt(oldIndex);
              _checklist.insert(newIndex, item);
            });
          },
          itemBuilder: (context, index) {
            final item = _checklist[index];
            return GlassChecklistItemWidget(
              key: ValueKey('item_${item.id}'),
              text: item.text,
              isChecked: item.isChecked,
              accentColor: accentColor,
              onChecked: (val) {
                setState(() {
                  _checklist[index] = item.copyWith(isChecked: val ?? false);
                });
              },
              onChanged: (val) {
                _checklist[index] = item.copyWith(text: val);
              },
              onRemoved: () {
                setState(() {
                  _checklist.removeAt(index);
                });
              },
              onSubmitted: () {
                setState(() {
                  _checklist.insert(
                      index + 1,
                      ChecklistItem(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        text: '',
                      ));
                });
              },
            );
          },
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            setState(() {
              _checklist.add(ChecklistItem(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                text: '',
              ));
            });
          },
          child: VisionGlassCard(
            borderRadius: 12,
            useDistortion: false,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.white.withValues(alpha: 0.05),
            child: Row(
              children: [
                Icon(CupertinoIcons.plus, color: accentColor, size: 20),
                const SizedBox(width: 12),
                Text(
                  l10n?.addItem ?? 'Add Item',
                  style: TextStyle(color: accentColor, fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final l10n = AppLocalizations.of(context);
    final provider = GlassAnimationProvider.of(context);
    final themeColor = provider?.themeColor ?? AppColors.obsidianBlack;
    final accentColor = provider?.accentColor ?? AppColors.accentBlue;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        height: size.height * 0.85,
        decoration: BoxDecoration(
          color: themeColor.withValues(alpha: 0.95),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1.5),
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: _toggleChecklist,
                        child: Icon(
                          CupertinoIcons.list_bullet,
                          color: _isChecklist ? accentColor : Colors.white54,
                          size: 24,
                        ),
                      ),
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: () async {
                          HapticFeedback.lightImpact();
                          final oldPinned = _isPinned;
                          setState(() {
                            _isPinned = !_isPinned;
                          });
                          
                          final updatedNote = widget.note.copyWith(
                            id: _noteId,
                            title: _t.text.trim(),
                            content: _c.text.trim(),
                            labels: _l.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
                            imageBase64: _img,
                            reminder: _rem,
                            isPinned: _isPinned,
                            updatedAt: DateTime.now(),
                          );

                          try {
                            final savedNote = await widget.storage.save(updatedNote);
                            if (mounted) {
                              setState(() {
                                _noteId = savedNote.id;
                              });
                            }
                            if (widget.onSaved != null) widget.onSaved!(savedNote);
                          } catch (e) {
                            if (mounted) {
                              setState(() {
                                _isPinned = oldPinned;
                              });
                              _showSnackBar('${l10n?.pinError ?? 'Pin error'}: $e', isError: true);
                            }
                          }
                        },
                        child: Icon(
                          CupertinoIcons.pin,
                          color: _isPinned ? accentColor : Colors.white54,
                          size: 24,
                        ),
                      ),
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: () {
                          HapticFeedback.mediumImpact();
                          if (_noteId.isNotEmpty) {
                            if (widget.onDeleted != null) widget.onDeleted!(_noteId);
                            Navigator.pop(context);
                            // Deletion happens in background
                            widget.storage.delete(_noteId).catchError((e) {
                              debugPrint('Error deleting note in background: $e');
                            });
                          } else {
                            Navigator.pop(context);
                          }
                        },
                        child: const Icon(CupertinoIcons.trash, color: AppColors.accentRed, size: 24),
                      ),
                    ],
                  ),
                ),
                Expanded(child: _buildBody(l10n)),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                  child: Align(
                    alignment: Alignment.center,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 220),
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.mediumImpact();
                          _save();
                        },
                        child: VisionGlassCard(
                          borderRadius: 16,
                          useDistortion: false,
                          color: themeColor.withValues(alpha: 0.8),
                          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(CupertinoIcons.checkmark_alt, color: accentColor, size: 24),
                              const SizedBox(width: 10),
                              Text(
                                l10n?.save ?? 'Save',
                                style: TextStyle(
                                  color: accentColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
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
    final provider = GlassAnimationProvider.of(context);
    final accentColor = provider?.accentColor ?? AppColors.accentBlue;

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
                    child: Icon(
                      CupertinoIcons.multiply_circle,
                      color: accentColor.withValues(alpha: 0.8),
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
          TextField(
            controller: _t,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: -0.5),
            decoration: InputDecoration(
              hintText: l10n?.title ?? 'Title',
              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
              border: InputBorder.none,
            ),
          ),
          if (_isChecklist)
            _buildChecklistEditor()
          else
            TextField(
              controller: _c,
              maxLines: null,
              style: const TextStyle(color: Colors.white, fontSize: 18, height: 1.5),
              decoration: InputDecoration(
                hintText: l10n?.note ?? 'Note',
                hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                border: InputBorder.none,
              ),
            ),
          const SizedBox(height: 24),
          VisionGlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            useDistortion: false,
            accentColor: accentColor,
            border: Border.all(color: accentColor.withValues(alpha: 0.15), width: 1),
            child: IntrinsicHeight(
              child: Row(
                children: [
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: Icon(CupertinoIcons.photo, color: accentColor, shadows: AppColors.iconShadows),
                    onPressed: _isLoading ? null : () async {
                      HapticFeedback.lightImpact();
                      if (context.mounted) setState(() => _isLoading = true);
                      try {
                        final XFile? image = await _picker.pickImage(
                          source: ImageSource.gallery,
                          maxWidth: 600,
                          maxHeight: 600,
                          imageQuality: 50,
                        );
                        if (!context.mounted) return;
                        if (image != null) {
                          final bytes = await image.readAsBytes();
                          // Aggressive check: if >200KB, compress further
                          if (bytes.length > 200 * 1024) {
                            if (context.mounted) {
                              setState(() => _isLoading = true);
                            }
                            final compressed = await _compressImage(bytes, 200 * 1024);
                            if (!context.mounted) return;
                            setState(() {
                              _img = compressed != null ? base64Encode(compressed) : null;
                              _decodedImage = compressed;
                            });
                          } else {

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
                  IconButton(padding: EdgeInsets.zero, constraints: const BoxConstraints(), icon: Icon(CupertinoIcons.alarm, color: accentColor, shadows: AppColors.iconShadows), onPressed: () async {
                    HapticFeedback.lightImpact();
                    final now = DateTime.now();
                    final d = await showDatePicker(context: context, initialDate: now, firstDate: now, lastDate: now.add(const Duration(days: 365)));
                    if (d == null) return;
                    if (!mounted) return;
                    final t = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(now));
                    if (t == null) return;
                    if (!mounted) return;
                    setState(() => _rem = DateTime(d.year, d.month, d.day, t.hour, t.minute));
                  }),
                  if (reminder != null) ...[
                    const SizedBox(width: 8),
                    Expanded(child: Text(DateFormat('dd.MM HH:mm').format(reminder), style: TextStyle(fontSize: 12, color: accentColor, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      child: Icon(CupertinoIcons.xmark_circle_fill, size: 18, color: accentColor),
                      onPressed: () => setState(() => _rem = null),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          TextField(controller: _l, style: const TextStyle(color: Colors.white, fontSize: 15), decoration: InputDecoration(hintText: l10n?.labelsHint ?? 'Labels', hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)), border: InputBorder.none)),
          const SizedBox(height: 100),
        ],
      ),
    );
  }
}

/// TRASH SCREEN
class TrashScreen extends StatefulWidget {
  final StorageService storage;
  const TrashScreen({super.key, required this.storage});

  @override
  State<TrashScreen> createState() => _TrashScreenState();
}

class _TrashScreenState extends State<TrashScreen> {
  late Stream<StreamedNotes> _notesStream;

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
        backgroundColor: isError ? AppColors.accentRed : AppColors.accentBlue,
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
    final provider = GlassAnimationProvider.of(context);
    final themeColor = provider?.themeColor ?? AppColors.obsidianBlack;

    return Scaffold(
      backgroundColor: AppColors.obsidianBlack,
      extendBody: true,
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          Positioned.fill(
            child: VisionBackground(
              backgroundColor: themeColor,
              blobColors: provider?.blobColors,
            ),
          ),
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
                  child: StreamBuilder<StreamedNotes>(
                    stream: _notesStream,
                    builder: (context, snapshot) {
                      final data = snapshot.data;
                      if (data == null) {
                        return const Center(child: CupertinoActivityIndicator(color: AppColors.accentBlue));
                      }

                      final archivedNotes = data.notes.where((n) => n.isArchived).toList();

                      if (archivedNotes.isEmpty) {
                        return Center(child: Text(l10n?.trashEmptyHint ?? 'Trash is empty', style: const TextStyle(color: Colors.white70, fontSize: 17)));
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
                  style: const TextStyle(
                    color: Colors.white,
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
