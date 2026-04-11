import 'dart:async';
import 'dart:convert';
import 'dart:ui' hide ImageFilter;
import 'dart:ui' as ui show ImageFilter;
import 'package:flutter/cupertino.dart';
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
import 'package:glass_keep/main.dart';
import 'package:glass_keep/settings_screen.dart';

class NotesScreen extends StatefulWidget {
  final StorageService storage;
  const NotesScreen({super.key, required this.storage});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> with SingleTickerProviderStateMixin {
  String _search = '';
  late TextEditingController _searchController;
  late Stream<List<Note>> _notesStream;
  late AnimationController _fabAnimationController;
  List<Note>? _filteredNotes;
  String _lastSearch = '';
  List<Note>? _lastSourceNotes;
  // Debounce timer for search
  Timer? _searchDebounceTimer;
  // Background state
  Color? _backgroundColor;
  Decoration? _backgroundDecoration;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    // Initialize stream once in initState
    _notesStream = widget.storage.getNotesStream();
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fabAnimationController.forward();
  }

  @override
  void dispose() {
    _searchDebounceTimer?.cancel();
    _searchController.dispose();
    _fabAnimationController.dispose();
    super.dispose();
  }

  /// Debounced search update to avoid rebuilding on every keystroke
  void _onSearchChanged(String value) {
    _searchDebounceTimer?.cancel();
    _searchDebounceTimer = Timer(const Duration(milliseconds: 150), () {
      if (mounted) {
        setState(() => _search = value);
      }
    });
  }

  void _logout() async {
    widget.storage.clearCache();
    await FirebaseAuth.instance.signOut();
  }

  void _openNote(BuildContext context, Note note) {
    HapticFeedback.mediumImpact();
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
          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          return SlideTransition(position: animation.drive(tween), child: child);
        },
      ),
    );
  }

  /// Optimized filtering with memoization - prevents unnecessary recalculations
  List<Note> _getFilteredAndSortedNotes(List<Note> sourceNotes) {
    // Quick cache check using multiple criteria for accuracy
    if (_filteredNotes != null &&
        _lastSearch == _search &&
        _lastSourceNotes != null &&
        _lastSourceNotes!.length == sourceNotes.length &&
        _lastSourceNotes!.every((note) => sourceNotes.any((n) => n.id == note.id && n.updatedAt == note.updatedAt))) {
      return _filteredNotes!;
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

  /// Clear filter cache when notes change significantly (kept for API compatibility)
  void _clearFilterCache() {
    _filteredNotes = null;
    _lastSourceNotes = null;
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final paddingH = ResponsiveDimensions.gridPadding;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: _backgroundColor ?? AppColors.obsidianDark,
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          if (_backgroundDecoration != null)
            Positioned.fill(child: Container(decoration: _backgroundDecoration))
          else
            const Positioned.fill(child: VisionBackground()),
          SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(paddingH, 10, paddingH, 0),
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
                              color: Color(0xFFFFFFFF).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Color(0xFFFFFFFF).withValues(alpha: 0.15)),
                            ),
                            child: const Icon(
                              CupertinoIcons.ellipsis_vertical,
                              color: AppColors.secondaryText,
                              size: 22,
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
                    if (!snapshot.hasData) {
                      return const SliverFillRemaining(
                        child: Center(
                          child: CupertinoActivityIndicator(
                            color: AppColors.accentBlue,
                            radius: 15,
                          ),
                        ),
                      );
                    }

                    // Optimized filtering - only runs when data or search changes
                    final notes = _getFilteredAndSortedNotes(snapshot.data!);

                    if (notes.isEmpty) {
                      return SliverFillRemaining(
                        child: Center(
                          child: Text(
                            l10n.noNotes,
                            style: const TextStyle(
                              color: AppColors.secondaryText,
                              fontSize: 17,
                            ),
                          ),
                        ),
                      );
                    }

                    final crossAxisCount = ((size.width - 2 * paddingH + ResponsiveDimensions.gridGap) / (ResponsiveDimensions.cardMinWidth + ResponsiveDimensions.gridGap)).floor().clamp(1, 6);

                    return SliverPadding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: ResponsiveDimensions.gridPadding,
                        vertical: ResponsiveDimensions.gridPadding,
                      ),
                      sliver: SliverMasonryGrid.count(
                        crossAxisCount: crossAxisCount,
                        mainAxisSpacing: ResponsiveDimensions.gridGap,
                        crossAxisSpacing: ResponsiveDimensions.gridGap,
                        itemBuilder: (context, i) => NoteCard(
                          key: ValueKey('note_${notes[i].id}'),
                          note: notes[i],
                          onTap: () => _openNote(context, notes[i]),
                          onArchive: () {
                            final updatedNote = notes[i].copyWith(isArchived: !notes[i].isArchived);
                            widget.storage.save(updatedNote);
                          },
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
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.obsidianDark.withOpacity(0.95),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(width: 36, height: 5, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2.5))),
            const SizedBox(height: 20),
            _MenuItem(icon: CupertinoIcons.paintbrush, label: 'Фон', onTap: () { Navigator.pop(context); _openBackgroundSettings(context); }),
            _MenuItem(icon: CupertinoIcons.globe, label: l10n.language, onTap: () { Navigator.pop(context); _showLanguagePicker(context); }),
            _MenuItem(icon: CupertinoIcons.trash, label: l10n.trash, onTap: () { Navigator.pop(context); _openTrash(context); }),
            _MenuItem(icon: CupertinoIcons.arrow_right_square, label: l10n.logout, onTap: () { Navigator.pop(context); _logout(); }, isDestructive: true),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _openBackgroundSettings(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SettingsScreen(
          onThemeChanged: (Color? color, Decoration? decoration) {
            setState(() {
              _backgroundColor = color;
              _backgroundDecoration = decoration;
            });
          },
        ),
      ),
    );
  }

  void _showLanguagePicker(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final provider = GlassAnimationProvider.of(context);
    if (provider == null) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.obsidianDark.withOpacity(0.95),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(width: 36, height: 5, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2.5))),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  const Icon(CupertinoIcons.globe, color: AppColors.accentBlue, size: 22),
                  const SizedBox(width: 12),
                  Text(l10n.language, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white)),
                ],
              ),
            ),
            const SizedBox(height: 8),
            _LanguageOption(locale: const Locale('en'), flag: '🇺🇸', name: 'English', currentLocale: provider.locale, onTap: (locale) {
              Navigator.pop(context);
              // Use the provider's onLocaleChanged callback instead of accessing state directly
              provider.onLocaleChanged(locale);
            }),
            _LanguageOption(locale: const Locale('ru'), flag: '🇷🇺', name: 'Русский', currentLocale: provider.locale, onTap: (locale) {
              Navigator.pop(context);
              provider.onLocaleChanged(locale);
            }),
            _LanguageOption(locale: const Locale('ko'), flag: '🇰🇷', name: '한국어', currentLocale: provider.locale, onTap: (locale) {
              Navigator.pop(context);
              provider.onLocaleChanged(locale);
            }),
            const SizedBox(height: 20),
          ],
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
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        child: Row(
          children: [
            Icon(icon, color: isDestructive ? AppColors.accentRed : AppColors.accentBlue, size: 22),
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
        Navigator.pop(context);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accentBlue.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.accentBlue : Colors.white.withOpacity(0.1),
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
    final l10n = AppLocalizations.of(context)!;

    return GestureDetector(
      onTap: () {
        final storage = _getStorageService(context);
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
          color: AppColors.accentBlue.withOpacity(0.9),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: AppColors.accentBlue.withOpacity(0.3),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              CupertinoIcons.add,
              color: Colors.white,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              l10n.newNote,
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

  StorageService _getStorageService(BuildContext context) {
    final state = context.findAncestorStateOfType<_NotesScreenState>();
    return state!.widget.storage;
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
  final VoidCallback onArchive;

  const NoteCard({super.key, required this.note, required this.onTap, required this.onArchive});

  @override
  State<NoteCard> createState() => _NoteCardState();
}

class _NoteCardState extends State<NoteCard> with AutomaticKeepAliveClientMixin {
  Uint8List? _decodedImage;
  String? _lastImageBase64;
  bool _isHovered = false;

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
    _lastImageBase64 = widget.note.imageBase64;
    _decodedImage = widget.note.cachedImage;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return RepaintBoundary(
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: AnimatedScale(
          scale: _isHovered ? 1.01 : 1.0,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOutCubic,
            transform: Matrix4.translationValues(0, _isHovered ? -6 : 0, 0),
            child: _NoteCardContent(
              note: widget.note,
              decodedImage: _decodedImage,
              onTap: widget.onTap,
            ),
          ),
        ),
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
    required this.note,
    required this.decodedImage,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return VisionGlassCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (decodedImage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.memory(
                      decodedImage!,
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
                      CupertinoIcons.pin_fill,
                      size: 14,
                      color: AppColors.accentBlue,
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
                      color: Colors.white.withOpacity(0.7),
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

  void _save() {
    if (_t.text.trim().isEmpty && _c.text.trim().isEmpty && _img == null) return;
    
    final updatedNote = widget.note.copyWith(
      title: _t.text.trim(),
      content: _c.text.trim(),
      labels: _l.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
      imageBase64: _img,
      reminder: _rem,
      updatedAt: DateTime.now(),
    );
    widget.storage.save(updatedNote);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        height: size.height * 0.85,
        decoration: BoxDecoration(
          color: AppColors.obsidianDark.withOpacity(0.9),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          border: Border.all(color: Colors.white.withOpacity(0.15), width: 1),
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Stack(
              children: [
                Positioned(
                  top: 0, left: 0, right: 0, height: 1,
                  child: Container(decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.transparent, Colors.white.withOpacity(0.1), Colors.transparent]))),
                ),
                Scaffold(
                  resizeToAvoidBottomInset: false,
                  backgroundColor: Colors.transparent,
                  appBar: PreferredSize(
                    preferredSize: const Size.fromHeight(70),
                    child: Column(
                      children: [
                        const SizedBox(height: 12),
                        Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.tertiaryText.withOpacity(0.3), borderRadius: BorderRadius.circular(2))),
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
                                child: Icon(widget.note.isPinned ? CupertinoIcons.pin_fill : CupertinoIcons.pin, color: AppColors.accentBlue, size: 22),
                                onPressed: () {
                                  final updatedNote = widget.note.copyWith(isPinned: !widget.note.isPinned);
                                  widget.storage.save(updatedNote);
                                  setState(() {});
                                },
                              ),
                              CupertinoButton(
                                padding: EdgeInsets.zero,
                                child: const Icon(CupertinoIcons.trash, color: AppColors.accentRed, size: 22),
                                onPressed: () {
                                  if (widget.note.id.isNotEmpty) widget.storage.delete(widget.note.id);
                                  Navigator.pop(context);
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
                          onTap: () { _save(); Navigator.pop(context); },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                            decoration: BoxDecoration(
                              color: AppColors.accentBlue.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: [BoxShadow(color: AppColors.accentBlue.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(CupertinoIcons.check_mark, color: Colors.white, size: 20),
                                const SizedBox(width: 8),
                                Text(l10n.save, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
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

  Widget _buildBody(AppLocalizations l10n) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(
        children: [
          if (_decodedImage != null)
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.memory(
                    _decodedImage!,
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
                      CupertinoIcons.xmark_circle_fill,
                      color: Colors.white70,
                    ),
                    onPressed: () => setState(() {
                      _img = null;
                      _decodedImage = null;
                      widget.note.clearImageCache();
                    }),
                  ),
                ),
              ],
            ),
          TextField(controller: _t, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: -0.5), decoration: InputDecoration(hintText: l10n.title, hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)), border: InputBorder.none)),
          TextField(controller: _c, maxLines: null, style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 18, height: 1.5), decoration: InputDecoration(hintText: l10n.note, hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)), border: InputBorder.none)),
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
                    icon: const Icon(CupertinoIcons.photo, color: Colors.white70),
                    onPressed: _isLoading ? null : () async {
                      setState(() => _isLoading = true);
                      try {
                        final XFile? image = await _picker.pickImage(
                          source: ImageSource.gallery,
                          maxWidth: 1200,
                          maxHeight: 1200,
                          imageQuality: 85,
                        );
                        if (image != null) {
                          final bytes = await image.readAsBytes();
                          // Process in microtask to avoid blocking UI
                          await Future.microtask(() {
                            setState(() {
                              _img = base64Encode(bytes);
                              _decodedImage = bytes;
                            });
                          });
                        }
                      } finally {
                        if (mounted) {
                          setState(() => _isLoading = false);
                        }
                      }
                    },
                  ),
                  const VerticalDivider(color: Colors.white24, indent: 8, endIndent: 8),
                  IconButton(padding: EdgeInsets.zero, constraints: const BoxConstraints(), icon: const Icon(CupertinoIcons.alarm, color: Colors.white70), onPressed: () async {
                    final now = DateTime.now();
                    final d = await showDatePicker(context: context, initialDate: now, firstDate: now, lastDate: now.add(const Duration(days: 365)));
                    if (d == null || !context.mounted) return;
                    final t = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(now));
                    if (t != null && context.mounted) setState(() => _rem = DateTime(d.year, d.month, d.day, t.hour, t.minute));
                  }),
                  if (_rem != null) ...[
                    const SizedBox(width: 8),
                    Expanded(child: Text(DateFormat('dd.MM HH:mm').format(_rem!), style: const TextStyle(fontSize: 12, color: AppColors.accentBlue, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          TextField(controller: _l, style: const TextStyle(color: Colors.white70, fontSize: 15), decoration: InputDecoration(hintText: l10n.labelsHint, hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)), border: InputBorder.none)),
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final size = MediaQuery.of(context).size;
    final paddingH = size.width * 0.04;

    return Scaffold(
      backgroundColor: AppColors.obsidianDark,
      body: Stack(
        children: [
          const Positioned.fill(child: VisionBackground()),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(paddingH, 10, paddingH, 0),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white.withOpacity(0.15)),
                          ),
                          child: const Icon(CupertinoIcons.back, color: Colors.white70, size: 22),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(l10n.trash, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                    ],
                  ),
                ),
                Expanded(
                  child: StreamBuilder<List<Note>>(
                    stream: _notesStream,
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CupertinoActivityIndicator(color: AppColors.accentBlue));
                      }

                      final archivedNotes = snapshot.data!.where((n) => n.isArchived).toList();

                      if (archivedNotes.isEmpty) {
                        return Center(child: Text(l10n.trashEmptyHint, style: const TextStyle(color: AppColors.secondaryText, fontSize: 17)));
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
                              onRestore: () {
                                final updatedNote = note.copyWith(isArchived: false);
                                widget.storage.save(updatedNote);
                              },
                              onDelete: () {
                                widget.storage.delete(note.id);
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
                  ),
                  onPressed: onRestore,
                  tooltip: 'Restore',
                ),
                IconButton(
                  icon: const Icon(
                    CupertinoIcons.trash,
                    color: AppColors.accentRed,
                    size: 20,
                  ),
                  onPressed: onDelete,
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
                    color: Colors.white.withOpacity(0.7),
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
