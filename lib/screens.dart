import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui';
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
import 'package:glass_keep/styles.dart';
import 'package:glass_keep/constants.dart';

class NotesScreen extends StatefulWidget {
  final StorageService storage;
  const NotesScreen({super.key, required this.storage});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen>
    with SingleTickerProviderStateMixin {
  String _search = '';
  final bool _showArchived = false;
  late TextEditingController _searchController;
  late Stream<List<Note>> _notesStream;
  late AnimationController _fabAnimationController;

  // Cache for filtered and sorted notes
  List<Note>? _filteredNotes;
  String _lastSearch = '';
  List<Note>? _lastSourceNotes;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _notesStream = widget.storage.getNotesStream();
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fabAnimationController.forward();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _fabAnimationController.dispose();
    super.dispose();
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
      transitionAnimationController: AnimationController(
        duration: const Duration(milliseconds: 400),
        vsync: Navigator.of(context),
      ),
      builder: (context) => NoteEditScreen(note: note, storage: widget.storage),
    );
  }

  void _openTrash(BuildContext context) {
    HapticFeedback.mediumImpact();
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => TrashScreen(
          storage: widget.storage,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeOutCubic;
          var tween = Tween(begin: begin, end: end).chain(
            CurveTween(curve: curve),
          );
          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
      ),
    );
  }

  /// Memoized filter and sort for notes
  List<Note> _getFilteredAndSortedNotes(List<Note> sourceNotes) {
    // Return cached result if inputs haven't changed
    if (_filteredNotes != null &&
        _lastSearch == _search &&
        _lastSourceNotes != null &&
        _lastSourceNotes!.length == sourceNotes.length) {
      return _filteredNotes!;
    }

    var notes = sourceNotes.where((n) => !n.isArchived).toList();
    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      notes = notes.where((n) {
        return n.title.toLowerCase().contains(q) ||
            n.content.toLowerCase().contains(q);
      }).toList();
    }
    notes.sort((a, b) {
      if (a.isPinned != b.isPinned) return a.isPinned ? -1 : 1;
      return b.updatedAt.compareTo(a.updatedAt);
    });

    // Cache the result
    _filteredNotes = notes;
    _lastSearch = _search;
    _lastSourceNotes = List.unmodifiable(sourceNotes);

    return notes;
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final paddingH = size.width * 0.04;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.background,
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          const Positioned.fill(child: LightBackground()),
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
                            onChanged: (v) => setState(() => _search = v),
                          ),
                        ),
                        const SizedBox(width: 12),
                        GlassIconButton(
                          icon: CupertinoIcons.trash,
                          onPressed: () => _openTrash(context),
                          iconColor: AppColors.secondaryText,
                          size: 50,
                        ),
                        const SizedBox(width: 12),
                        GlassIconButton(
                          icon: CupertinoIcons.ellipsis_vertical,
                          onPressed: () => _showMenu(context, l10n),
                          iconColor: AppColors.secondaryText,
                          size: 50,
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
                            style: const TextStyle(color: AppColors.accentRed),
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

                    final notes = _getFilteredAndSortedNotes(snapshot.data!);

                    if (notes.isEmpty) {
                      return SliverFillRemaining(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                CupertinoIcons.doc_text_search,
                                size: 64,
                                color: AppColors.tertiaryText.withValues(alpha: 0.4),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                l10n.noNotes,
                                style: TextStyle(
                                  color: AppColors.tertiaryText.withValues(alpha: 0.6),
                                  fontSize: 17,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    final crossAxisCount =
                        size.width > 900 ? 4 : (size.width > 600 ? 3 : 2);

                    return SliverPadding(
                      padding: EdgeInsets.symmetric(
                        horizontal: paddingH,
                        vertical: 8,
                      ),
                      sliver: SliverMasonryGrid.count(
                        crossAxisCount: crossAxisCount,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        itemBuilder: (context, i) => NoteCard(
                          note: notes[i],
                          onTap: () => _openNote(context, notes[i]),
                          onArchive: () {
                            HapticFeedback.lightImpact();
                            notes[i].isArchived = true;
                            widget.storage.save(notes[i]);
                          },
                        ),
                        childCount: notes.length,
                      ),
                    );
                  },
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 120)),
              ],
            ),
          ),
          // Floating Action Button
          Positioned(
            bottom: size.height * 0.04,
            left: 0,
            right: 0,
            child: Center(
              child: AnimatedBuilder(
                animation: _fabAnimationController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _fabAnimationController.value,
                    child: child,
                  );
                },
                child: const _NewNoteButton(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showMenu(BuildContext context, AppLocalizations l10n) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black12,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.95),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.secondaryBackground,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: const Icon(
                    CupertinoIcons.arrow_right_square,
                    color: AppColors.accentRed,
                  ),
                  title: Text(
                    l10n.logout,
                    style: const TextStyle(
                      color: AppColors.accentRed,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _logout();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Extracted widget to reduce rebuilds
class _NewNoteButton extends StatelessWidget {
  const _NewNoteButton();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
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
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.accentBlue,
              AppColors.accentBlue.withValues(alpha: 0.9),
            ],
          ),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: AppColors.accentBlue.withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
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
                      fontWeight: FontWeight.w600,
                      fontSize: 17,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
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
      barrierColor: Colors.black26,
      builder: (context) => NoteEditScreen(note: note, storage: storage),
    );
  }
}

class NoteCard extends StatefulWidget {
  final Note note;
  final VoidCallback onTap;
  final VoidCallback onArchive;

  const NoteCard({
    super.key,
    required this.note,
    required this.onTap,
    required this.onArchive,
  });

  @override
  State<NoteCard> createState() => _NoteCardState();
}

class _NoteCardState extends State<NoteCard>
    with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {
  Uint8List? _decodedImage;
  late Note _lastNote;
  late AnimationController _pressController;
  late Animation<double> _scaleAnimation;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _lastNote = widget.note;
    _decodeImageIfNeeded();
    _pressController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(
        parent: _pressController,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.spring,
      ),
    );
  }

  @override
  void didUpdateWidget(NoteCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.note.imageBase64 != widget.note.imageBase64 ||
        oldWidget.note.id != widget.note.id) {
      _lastNote = widget.note;
      _decodeImageIfNeeded();
    }
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  void _decodeImageIfNeeded() {
    if (widget.note.imageBase64 != null &&
        widget.note.imageBase64!.isNotEmpty) {
      try {
        _decodedImage = base64Decode(widget.note.imageBase64!);
      } catch (e) {
        _decodedImage = null;
      }
    } else {
      _decodedImage = null;
    }
  }

  void _handleTapDown(TapDownDetails details) {
    _pressController.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    _pressController.reverse();
    widget.onTap();
  }

  void _handleTapCancel() {
    _pressController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final note = widget.note;
    final heroTag = note.id.isEmpty ? null : 'note-${note.id}';

    Widget content = AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        );
      },
      child: GlassCard(
        padding: const EdgeInsets.all(14),
        borderRadius: 20,
        onTap: widget.onTap,
        isInteractive: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_decodedImage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.memory(
                    _decodedImage!,
                    fit: BoxFit.cover,
                    width: double.infinity,
                  ),
                ),
              ),
            Row(
              children: [
                if (note.isPinned)
                  const Padding(
                    padding: EdgeInsets.only(right: 6),
                    child: Icon(
                      CupertinoIcons.pin_fill,
                      size: 14,
                      color: AppColors.accentBlue,
                    ),
                  ),
                Expanded(
                  child: Text(
                    note.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppColors.primaryText,
                      letterSpacing: -0.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            if (note.content.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  note.content,
                  maxLines: 6,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.secondaryText,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ),
            if (note.labels.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: note.labels.map((l) => LabelChip(label: l)).toList(),
              ),
            ],
          ],
        ),
      ),
    );

    if (heroTag != null) {
      content = Hero(tag: heroTag, child: content);
    }

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onLongPress: () {
        HapticFeedback.mediumImpact();
        widget.onArchive();
      },
      child: content,
    );
  }
}

class NoteEditScreen extends StatefulWidget {
  final Note note;
  final StorageService storage;

  const NoteEditScreen({
    super.key,
    required this.note,
    required this.storage,
  });

  @override
  State<NoteEditScreen> createState() => _NoteEditScreenState();
}

class _NoteEditScreenState extends State<NoteEditScreen>
    with SingleTickerProviderStateMixin {
  late TextEditingController _t, _c, _l;
  String? _img;
  DateTime? _rem;
  final _picker = ImagePicker();
  Uint8List? _decodedImage;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _t = TextEditingController(text: widget.note.title);
    _c = TextEditingController(text: widget.note.content);
    _l = TextEditingController(text: widget.note.labels.join(', '));
    _img = widget.note.imageBase64;
    _rem = widget.note.reminder;
    _decodeImageIfNeeded();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 50),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _t.dispose();
    _c.dispose();
    _l.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _decodeImageIfNeeded() {
    if (_img != null && _img!.isNotEmpty) {
      try {
        _decodedImage = base64Decode(_img!);
      } catch (e) {
        _decodedImage = null;
      }
    } else {
      _decodedImage = null;
    }
  }

  void _save() {
    if (_t.text.trim().isEmpty &&
        _c.text.trim().isEmpty &&
        _img == null) {
      return;
    }
    widget.note.title = _t.text.trim();
    widget.note.content = _c.text.trim();
    widget.note.labels =
        _l.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    widget.note.imageBase64 = _img;
    widget.note.reminder = _rem;
    widget.note.updatedAt = DateTime.now();
    widget.storage.save(widget.note);
  }

  void _moveToTrash() {
    if (widget.note.id.isNotEmpty) {
      widget.note.isArchived = true;
      widget.storage.save(widget.note);
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final heroTag = widget.note.id.isEmpty ? null : 'note-${widget.note.id}';
    final size = MediaQuery.of(context).size;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final l10n = AppLocalizations.of(context)!;

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: child,
        );
      },
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: Container(
          height: size.height * 0.85,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.7),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 40,
                offset: const Offset(0, -10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Stack(
                children: [
                  // Top gradient line
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: 1,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            Colors.white.withValues(alpha: 0.5),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                  Scaffold(
                    resizeToAvoidBottomInset: false,
                    backgroundColor: Colors.transparent,
                    appBar: PreferredSize(
                      preferredSize: const Size.fromHeight(70),
                      child: Column(
                        children: [
                          const SizedBox(height: 12),
                          Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: AppColors.secondaryBackground,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(height: 4),
                          CupertinoNavigationBar(
                            backgroundColor: Colors.transparent,
                            border: null,
                            automaticallyImplyLeading: false,
                            leading: CupertinoButton(
                              padding: EdgeInsets.zero,
                              child: const Icon(
                                CupertinoIcons.xmark_circle_fill,
                                color: AppColors.tertiaryText,
                                size: 28,
                              ),
                              onPressed: () => Navigator.pop(context),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CupertinoButton(
                                  padding: EdgeInsets.zero,
                                  child: Icon(
                                    widget.note.isPinned
                                        ? CupertinoIcons.pin_fill
                                        : CupertinoIcons.pin,
                                    color: AppColors.accentBlue,
                                    size: 24,
                                  ),
                                  onPressed: () {
                                    HapticFeedback.lightImpact();
                                    setState(() =>
                                        widget.note.isPinned = !widget.note.isPinned);
                                  },
                                ),
                                CupertinoButton(
                                  padding: EdgeInsets.zero,
                                  child: const Icon(
                                    CupertinoIcons.trash,
                                    color: AppColors.accentRed,
                                    size: 24,
                                  ),
                                  onPressed: () {
                                    HapticFeedback.mediumImpact();
                                    _moveToTrash();
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
                        _buildBody(heroTag, l10n),
                        Positioned(
                          right: 24,
                          bottom: 24,
                          child: GestureDetector(
                            onTap: () {
                              HapticFeedback.mediumImpact();
                              _save();
                              Navigator.pop(context);
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppColors.accentBlue.withValues(alpha: 0.7),
                                borderRadius: BorderRadius.circular(30),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.accentBlue.withValues(alpha: 0.2),
                                    blurRadius: 16,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(30),
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 14,
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          CupertinoIcons.check_mark,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          l10n.save,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
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
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(String? heroTag, AppLocalizations l10n) {
    Widget content = SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(
        children: [
          if (_decodedImage != null)
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.memory(_decodedImage!),
                ),
                Positioned(
                  right: 8,
                  top: 8,
                  child: CupertinoButton(
                    padding: EdgeInsets.zero,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.4),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        CupertinoIcons.xmark,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                    onPressed: () => setState(() {
                      _img = null;
                      _decodedImage = null;
                    }),
                  ),
                ),
              ],
            ),
          TextField(
            controller: _t,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryText,
              letterSpacing: -0.5,
            ),
            decoration: InputDecoration(
              hintText: l10n.title,
              hintStyle: TextStyle(
                color: AppColors.tertiaryText.withValues(alpha: 0.5),
              ),
              border: InputBorder.none,
            ),
          ),
          TextField(
            controller: _c,
            maxLines: null,
            style: const TextStyle(
              color: AppColors.primaryText,
              fontSize: 18,
              height: 1.5,
            ),
            decoration: InputDecoration(
              hintText: l10n.note,
              hintStyle: TextStyle(
                color: AppColors.tertiaryText.withValues(alpha: 0.5),
              ),
              border: InputBorder.none,
            ),
          ),
          const SizedBox(height: 24),
          GlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: IntrinsicHeight(
              child: Row(
                children: [
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(
                      CupertinoIcons.photo,
                      color: AppColors.secondaryText,
                    ),
                    onPressed: () async {
                      HapticFeedback.lightImpact();
                      final XFile? image = await _picker.pickImage(
                        source: ImageSource.gallery,
                      );
                      if (image != null) {
                        final bytes = await image.readAsBytes();
                        setState(() {
                          _img = base64Encode(bytes);
                          _decodedImage = bytes;
                        });
                      }
                    },
                  ),
                  const VerticalDivider(
                    color: AppColors.secondaryBackground,
                    indent: 8,
                    endIndent: 8,
                  ),
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(
                      CupertinoIcons.alarm,
                      color: AppColors.secondaryText,
                    ),
                    onPressed: () async {
                      HapticFeedback.lightImpact();
                      final now = DateTime.now();
                      final d = await showDatePicker(
                        context: context,
                        initialDate: now,
                        firstDate: now,
                        lastDate: now.add(const Duration(days: 365)),
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: const ColorScheme.light(
                                primary: AppColors.accentBlue,
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (d == null || !context.mounted) return;

                      final t = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.fromDateTime(now),
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: const ColorScheme.light(
                                primary: AppColors.accentBlue,
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );

                      if (t != null && context.mounted) {
                        setState(() => _rem = DateTime(
                              d.year,
                              d.month,
                              d.day,
                              t.hour,
                              t.minute,
                            ));
                      }
                    },
                  ),
                  if (_rem != null) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        DateFormat('dd.MM HH:mm').format(_rem!),
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.accentBlue,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: const Icon(
                        CupertinoIcons.xmark_circle_fill,
                        color: AppColors.tertiaryText,
                        size: 20,
                      ),
                      onPressed: () => setState(() => _rem = null),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _l,
            style: const TextStyle(
              color: AppColors.secondaryText,
              fontSize: 15,
            ),
            decoration: InputDecoration(
              hintText: l10n.labelsHint,
              hintStyle: TextStyle(
                color: AppColors.tertiaryText.withValues(alpha: 0.4),
              ),
              border: InputBorder.none,
              prefixIcon: const Icon(
                CupertinoIcons.tag,
                color: AppColors.tertiaryText,
                size: 20,
              ),
            ),
          ),
          const SizedBox(height: 100),
        ],
      ),
    );

    if (heroTag != null) {
      return Hero(
        tag: heroTag,
        child: Material(color: Colors.transparent, child: content),
      );
    }
    return content;
  }
}

/// Trash screen for archived/deleted notes
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

  void _restoreNote(Note note) {
    HapticFeedback.mediumImpact();
    note.isArchived = false;
    widget.storage.save(note);
  }

  void _deleteForever(String id) {
    HapticFeedback.mediumImpact();
    widget.storage.delete(id);
  }

  void _emptyTrash(List<Note> notes) {
    HapticFeedback.heavyImpact();
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(AppLocalizations.of(context)!.emptyTrash),
        content: const Text('This action cannot be undone.'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.pop(context);
              for (final note in notes) {
                if (note.isArchived) {
                  widget.storage.delete(note.id);
                }
              }
            },
            child: const Text('Delete All'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final paddingH = size.width * 0.04;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.background,
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          const Positioned.fill(child: LightBackground()),
          SafeArea(
            child: CustomScrollView(
              slivers: [
                // Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(paddingH, 10, paddingH, 16),
                    child: Row(
                      children: [
                        GlassIconButton(
                          icon: CupertinoIcons.back,
                          onPressed: () => Navigator.pop(context),
                          iconColor: AppColors.primaryText,
                          size: 44,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            l10n.trash,
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryText,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Notes List
                StreamBuilder<List<Note>>(
                  stream: _notesStream,
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return SliverFillRemaining(
                        child: Center(
                          child: Text(
                            'Error: ${snapshot.error}',
                            style: const TextStyle(color: AppColors.accentRed),
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

                    final notes = snapshot.data!
                        .where((n) => n.isArchived)
                        .toList()
                      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

                    if (notes.isEmpty) {
                      return SliverFillRemaining(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                CupertinoIcons.trash,
                                size: 64,
                                color: AppColors.tertiaryText.withValues(alpha: 0.4),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                l10n.noNotesInTrash,
                                style: TextStyle(
                                  color: AppColors.tertiaryText.withValues(alpha: 0.6),
                                  fontSize: 17,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                l10n.trashEmptyHint,
                                style: TextStyle(
                                  color: AppColors.tertiaryText.withValues(alpha: 0.4),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return SliverPadding(
                      padding: EdgeInsets.symmetric(
                        horizontal: paddingH,
                        vertical: 8,
                      ),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => _TrashNoteCard(
                            note: notes[index],
                            onRestore: () => _restoreNote(notes[index]),
                            onDelete: () => _deleteForever(notes[index].id),
                          ),
                          childCount: notes.length,
                        ),
                      ),
                    );
                  },
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
          ),
          // Empty Trash Button
          Positioned(
            bottom: size.height * 0.04,
            left: 0,
            right: 0,
            child: StreamBuilder<List<Note>>(
              stream: _notesStream,
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox.shrink();
                final notes = snapshot.data!.where((n) => n.isArchived).toList();
                if (notes.isEmpty) return const SizedBox.shrink();

                return Center(
                  child: GestureDetector(
                    onTap: () => _emptyTrash(notes),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.accentRed.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: AppColors.accentRed.withValues(alpha: 0.2),
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(30),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 28,
                              vertical: 16,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  CupertinoIcons.trash,
                                  color: AppColors.accentRed,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  l10n.emptyTrash,
                                  style: const TextStyle(
                                    color: AppColors.accentRed,
                                    fontWeight: FontWeight.w600,
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
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Card for trash screen with restore/delete options
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
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  note.title.isEmpty ? '(No title)' : note.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: AppColors.primaryText,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                DateFormat('dd.MM').format(note.updatedAt),
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.tertiaryText.withValues(alpha: 0.6),
                ),
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
                  color: AppColors.secondaryText,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: onRestore,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.accentBlue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          CupertinoIcons.arrow_counterclockwise,
                          color: AppColors.accentBlue,
                          size: 16,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Restore',
                          style: TextStyle(
                            color: AppColors.accentBlue,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: onDelete,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.accentRed.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          CupertinoIcons.trash,
                          color: AppColors.accentRed,
                          size: 16,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Delete',
                          style: TextStyle(
                            color: AppColors.accentRed,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
