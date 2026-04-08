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

class _NotesScreenState extends State<NotesScreen> with SingleTickerProviderStateMixin {
  String _search = '';
  final bool _showArchived = false;
  late TextEditingController _searchController;
  late Stream<List<Note>> _notesStream;
  late AnimationController _fabAnimationController;
  List<Note>? _filteredNotes;
  String _lastSearch = '';
  List<Note>? _lastSourceNotes;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _notesStream = widget.storage.getNotesStream();
    _fabAnimationController = AnimationController(duration: const Duration(milliseconds: 600), vsync: this);
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

  List<Note> _getFilteredAndSortedNotes(List<Note> sourceNotes) {
    if (_filteredNotes != null && _lastSearch == _search && _lastSourceNotes != null && _lastSourceNotes!.length == sourceNotes.length) {
      return _filteredNotes!;
    }

    var notes = sourceNotes.where((n) => !n.isArchived).toList();
    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      notes = notes.where((n) => n.title.toLowerCase().contains(q) || n.content.toLowerCase().contains(q)).toList();
    }
    notes.sort((a, b) {
      if (a.isPinned != b.isPinned) return a.isPinned ? -1 : 1;
      return b.updatedAt.compareTo(a.updatedAt);
    });

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
                            hintText: l10n.searchHint,
                          ),
                        ),
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: () => _showMenu(context),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                            ),
                            child: const Icon(CupertinoIcons.ellipsis_vertical, color: AppColors.secondaryText, size: 22),
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
                      return SliverFillRemaining(child: Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red))));
                    }
                    if (!snapshot.hasData) {
                      return const SliverFillRemaining(child: Center(child: CupertinoActivityIndicator(color: AppColors.accentBlue, radius: 15)));
                    }

                    final notes = _getFilteredAndSortedNotes(snapshot.data!);
                    if (notes.isEmpty) {
                      return SliverFillRemaining(child: Center(child: Text(l10n.noNotes, style: const TextStyle(color: AppColors.secondaryText, fontSize: 17))));
                    }

                    final crossAxisCount = size.width > 900 ? 4 : (size.width > 600 ? 3 : 2);

                    return SliverPadding(
                      padding: EdgeInsets.symmetric(horizontal: paddingH, vertical: 8),
                      sliver: SliverMasonryGrid.count(
                        crossAxisCount: crossAxisCount,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        itemBuilder: (context, i) => NoteCard(
                          note: notes[i],
                          onTap: () => _openNote(context, notes[i]),
                          onArchive: () {
                            notes[i].isArchived = !notes[i].isArchived;
                            widget.storage.save(notes[i]);
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
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(width: 36, height: 5, decoration: BoxDecoration(color: AppColors.tertiaryText.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2.5))),
            const SizedBox(height: 20),
            _MenuItem(icon: CupertinoIcons.trash, label: 'Trash', onTap: () { Navigator.pop(context); _openTrash(context); }),
            _MenuItem(icon: CupertinoIcons.arrow_right_square, label: 'Logout', onTap: () { Navigator.pop(context); _logout(); }, isDestructive: true),
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
            Text(label, style: TextStyle(fontSize: 17, color: isDestructive ? AppColors.accentRed : AppColors.primaryText)),
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
        final n = Note(id: '', title: '', content: '', updatedAt: DateTime.now());
        _openNoteEditor(context, n, storage);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.accentBlue.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [BoxShadow(color: AppColors.accentBlue.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 6))],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(CupertinoIcons.add, color: Colors.white, size: 24),
            const SizedBox(width: 8),
            Text(l10n.newNote, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: -0.5)),
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
  late Note _lastNote;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _lastNote = widget.note;
    _decodeImageIfNeeded();
  }

  @override
  void didUpdateWidget(NoteCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.note.imageBase64 != widget.note.imageBase64 || oldWidget.note.id != widget.note.id) {
      _lastNote = widget.note;
      _decodeImageIfNeeded();
    }
  }

  void _decodeImageIfNeeded() {
    if (widget.note.imageBase64 != null && widget.note.imageBase64!.isNotEmpty) {
      try {
        _decodedImage = base64Decode(widget.note.imageBase64!);
      } catch (e) {
        _decodedImage = null;
      }
    } else {
      _decodedImage = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final note = widget.note;

    return GlassCard(
      onTap: widget.onTap,
      isInteractive: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_decodedImage != null) Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.memory(_decodedImage!, fit: BoxFit.cover)),
          ),
          Row(
            children: [
              if (note.isPinned) const Icon(CupertinoIcons.pin_fill, size: 14, color: AppColors.accentBlue),
              if (note.isPinned) const SizedBox(width: 6),
              Expanded(child: Text(note.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primaryText, letterSpacing: -0.2))),
            ],
          ),
          if (note.content.isNotEmpty) Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(note.content, maxLines: 6, overflow: TextOverflow.ellipsis, style: TextStyle(color: AppColors.secondaryText, fontSize: 14, height: 1.3)),
          ),
          if (note.labels.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(spacing: 6, runSpacing: 6, children: note.labels.map((l) => LabelChip(label: l)).toList()),
          ],
        ],
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

  @override
  void initState() {
    super.initState();
    _t = TextEditingController(text: widget.note.title);
    _c = TextEditingController(text: widget.note.content);
    _l = TextEditingController(text: widget.note.labels.join(', '));
    _img = widget.note.imageBase64;
    _rem = widget.note.reminder;
    _decodeImageIfNeeded();
  }

  @override
  void dispose() {
    _t.dispose();
    _c.dispose();
    _l.dispose();
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
    if (_t.text.trim().isEmpty && _c.text.trim().isEmpty && _img == null) return;
    widget.note.title = _t.text.trim();
    widget.note.content = _c.text.trim();
    widget.note.labels = _l.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    widget.note.imageBase64 = _img;
    widget.note.reminder = _rem;
    widget.note.updatedAt = DateTime.now();
    widget.storage.save(widget.note);
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
          color: Colors.white.withValues(alpha: 0.95),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1),
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Stack(
              children: [
                Positioned(
                  top: 0, left: 0, right: 0, height: 1,
                  child: Container(decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.transparent, Colors.white.withValues(alpha: 0.6), Colors.transparent]))),
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
                                child: Icon(widget.note.isPinned ? CupertinoIcons.pin_fill : CupertinoIcons.pin, color: AppColors.accentBlue, size: 22),
                                onPressed: () => setState(() => widget.note.isPinned = !widget.note.isPinned),
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
                              color: AppColors.accentBlue.withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: [BoxShadow(color: AppColors.accentBlue.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))],
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
          if (_decodedImage != null) Stack(
            children: [
              ClipRRect(borderRadius: BorderRadius.circular(20), child: Image.memory(_decodedImage!)),
              Positioned(right: 8, top: 8, child: CupertinoButton(padding: EdgeInsets.zero, child: const Icon(CupertinoIcons.xmark_circle_fill, color: Colors.white70), onPressed: () => setState(() { _img = null; _decodedImage = null; }))),
            ],
          ),
          TextField(controller: _t, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.primaryText, letterSpacing: -0.5), decoration: InputDecoration(hintText: l10n.title, hintStyle: TextStyle(color: AppColors.tertiaryText.withValues(alpha: 0.5)), border: InputBorder.none)),
          TextField(controller: _c, maxLines: null, style: TextStyle(color: AppColors.secondaryText, fontSize: 18, height: 1.5), decoration: InputDecoration(hintText: l10n.note, hintStyle: TextStyle(color: AppColors.tertiaryText.withValues(alpha: 0.5)), border: InputBorder.none)),
          const SizedBox(height: 24),
          GlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            hasBlur: false,
            child: IntrinsicHeight(
              child: Row(
                children: [
                  IconButton(padding: EdgeInsets.zero, constraints: const BoxConstraints(), icon: const Icon(CupertinoIcons.photo, color: AppColors.secondaryText), onPressed: () async {
                    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
                    if (image != null) {
                      final bytes = await image.readAsBytes();
                      setState(() { _img = base64Encode(bytes); _decodedImage = bytes; });
                    }
                  }),
                  const VerticalDivider(color: AppColors.tertiaryText, indent: 8, endIndent: 8),
                  IconButton(padding: EdgeInsets.zero, constraints: const BoxConstraints(), icon: const Icon(CupertinoIcons.alarm, color: AppColors.secondaryText), onPressed: () async {
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
          TextField(controller: _l, style: const TextStyle(color: AppColors.secondaryText, fontSize: 15), decoration: InputDecoration(hintText: l10n.labelsHint, hintStyle: TextStyle(color: AppColors.tertiaryText.withValues(alpha: 0.5)), border: InputBorder.none)),
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
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          const Positioned.fill(child: LightBackground()),
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
                            color: Colors.white.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                          ),
                          child: const Icon(CupertinoIcons.back, color: AppColors.secondaryText, size: 22),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(l10n.trash, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primaryText)),
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
                        return Center(child: Text(l10n.trashEmpty, style: const TextStyle(color: AppColors.secondaryText, fontSize: 17)));
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
                                note.isArchived = false;
                                widget.storage.save(note);
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

  const _TrashNoteCard({required this.note, required this.onRestore, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(note.title.isEmpty ? 'Untitled' : note.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primaryText))),
              IconButton(
                icon: const Icon(CupertinoIcons.arrow_counterclockwise, color: AppColors.accentBlue, size: 20),
                onPressed: onRestore,
                tooltip: 'Restore',
              ),
              IconButton(
                icon: const Icon(CupertinoIcons.trash, color: AppColors.accentRed, size: 20),
                onPressed: onDelete,
                tooltip: 'Delete forever',
              ),
            ],
          ),
          if (note.content.isNotEmpty) Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(note.content, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: AppColors.secondaryText, fontSize: 14)),
          ),
        ],
      ),
    );
  }
}
