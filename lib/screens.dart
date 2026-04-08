import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:glass_keep/l10n/app_localizations.dart';
import 'package:glass_keep/data.dart';
import 'package:glass_keep/widgets.dart';

class NotesScreen extends StatefulWidget {
  final StorageService storage;
  const NotesScreen({super.key, required this.storage});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  String _search = '';
  final bool _showArchived = false;
  late TextEditingController _searchController;
  late Stream<List<Note>> _notesStream;
  
  // Cache for filtered and sorted notes
  List<Note>? _filteredNotes;
  String _lastSearch = '';
  List<Note>? _lastSourceNotes;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    // Initialize stream once to avoid rebuilding
    _notesStream = widget.storage.getNotesStream();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _logout() async {
    widget.storage.clearCache();
    await FirebaseAuth.instance.signOut();
  }

  void _openNote(BuildContext context, Note note) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      builder: (context) => NoteEditScreen(note: note, storage: widget.storage),
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

    var notes = sourceNotes.where((n) => n.isArchived == _showArchived).toList();
    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      notes = notes.where((n) => 
        n.title.toLowerCase().contains(q) || 
        n.content.toLowerCase().contains(q)
      ).toList();
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
      backgroundColor: const Color(0xFF0A0A14),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
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
                            onChanged: (v) => setState(() => _search = v),
                          ),
                        ),
                        const SizedBox(width: 12),
                        VisionGlassCard(
                          padding: EdgeInsets.zero,
                          borderRadius: 14,
                          child: PopupMenuButton<String>(
                            icon: const Icon(CupertinoIcons.ellipsis_vertical, color: Colors.white70),
                            color: const Color(0xFF1E1E2E),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            onSelected: (val) {
                              if (val == 'logout') _logout();
                            },
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                value: 'logout',
                                child: Row(
                                  children: [
                                    const Icon(CupertinoIcons.arrow_right_square, color: CupertinoColors.systemRed, size: 20),
                                    const SizedBox(width: 10),
                                    Text(l10n.logout, style: const TextStyle(color: Colors.white)),
                                  ],
                                ),
                              ),
                            ],
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
                        child: Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red))),
                      );
                    }
                    if (!snapshot.hasData) {
                      return const SliverFillRemaining(
                        child: Center(child: CupertinoActivityIndicator(color: CupertinoColors.activeBlue, radius: 15)),
                      );
                    }
                    
                    final notes = _getFilteredAndSortedNotes(snapshot.data!);

                    if (notes.isEmpty) {
                      return SliverFillRemaining(
                        child: Center(child: Text(l10n.noNotes, style: const TextStyle(color: Colors.white24, fontSize: 17))),
                      );
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
            child: const Center(
              child: _NewNoteButton(),
            ),
          ),
        ],
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
    
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          final storage = _getStorageService(context);
          final n = Note(id: '', title: '', content: '', updatedAt: DateTime.now());
          _openNoteEditor(context, n, storage);
        },
        child: VisionGlassCard(
          borderRadius: 30,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(CupertinoIcons.add, color: Colors.white, size: 28),
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
      ),
    );
  }
  
  StorageService _getStorageService(BuildContext context) {
    // Access storage through NotesScreen's storage
    final state = context.findAncestorStateOfType<_NotesScreenState>();
    return state!.widget.storage;
  }
  
  void _openNoteEditor(BuildContext context, Note note, StorageService storage) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
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
    // Only re-decode if image data changed
    if (oldWidget.note.imageBase64 != widget.note.imageBase64 ||
        oldWidget.note.id != widget.note.id) {
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
    final heroTag = note.id.isEmpty ? null : 'note-${note.id}';
    
    // Wrap in RepaintBoundary to isolate painting
    Widget content = RepaintBoundary(
      child: VisionGlassCard(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_decodedImage != null) Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.memory(_decodedImage!, fit: BoxFit.cover),
              ),
            ),
            Row(
              children: [
                if (note.isPinned) const Icon(CupertinoIcons.pin_fill, size: 14, color: CupertinoColors.activeBlue),
                if (note.isPinned) const SizedBox(width: 6),
                Expanded(child: Text(note.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white, letterSpacing: -0.2))),
              ],
            ),
            if (note.content.isNotEmpty) Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(note.content, maxLines: 6, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 14, height: 1.3)),
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
    );

    if (heroTag != null) {
      content = Hero(tag: heroTag, child: content);
    }

    return GestureDetector(
      onTap: widget.onTap,
      child: content,
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
    final heroTag = widget.note.id.isEmpty ? null : 'note-${widget.note.id}';
    final size = MediaQuery.of(context).size;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        height: size.height * 0.85,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1),
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
            child: Stack(
              children: [
                Positioned(
                  top: 0, left: 0, right: 0, height: 1,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.transparent, Colors.white.withValues(alpha: 0.6), Colors.transparent],
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
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
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
                                  widget.note.isPinned ? CupertinoIcons.pin_fill : CupertinoIcons.pin,
                                  color: CupertinoColors.activeBlue,
                                  size: 22,
                                ),
                                onPressed: () => setState(() => widget.note.isPinned = !widget.note.isPinned),
                              ),
                              CupertinoButton(
                                padding: EdgeInsets.zero,
                                child: const Icon(CupertinoIcons.trash, color: CupertinoColors.systemRed, size: 22),
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
                      _buildBody(heroTag, l10n),
                      Positioned(
                        right: 24,
                        bottom: 24,
                        child: MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: GestureDetector(
                            onTap: () {
                              _save();
                              Navigator.pop(context);
                            },
                            child: VisionGlassCard(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                              borderRadius: 30,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(CupertinoIcons.check_mark, color: Colors.white, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    l10n.save,
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                ],
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
    );
  }

  Widget _buildBody(String? heroTag, AppLocalizations l10n) {
    Widget content = SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(
        children: [
          if (_decodedImage != null) Stack(
            children: [
              ClipRRect(borderRadius: BorderRadius.circular(20), child: Image.memory(_decodedImage!)),
              Positioned(right: 8, top: 8, child: CupertinoButton(padding: EdgeInsets.zero, child: const Icon(CupertinoIcons.xmark_circle_fill, color: Colors.white70), onPressed: () => setState(() {
                _img = null;
                _decodedImage = null;
              }))),
            ],
          ),
          TextField(
            controller: _t, 
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: -0.5), 
            decoration: InputDecoration(hintText: l10n.title, hintStyle: const TextStyle(color: Colors.white24), border: InputBorder.none),
          ),
          TextField(
            controller: _c, 
            maxLines: null, 
            style: const TextStyle(color: Colors.white, fontSize: 18, height: 1.5), 
            decoration: InputDecoration(hintText: l10n.note, hintStyle: const TextStyle(color: Colors.white24), border: InputBorder.none),
          ),
          const SizedBox(height: 24),
          VisionGlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: IntrinsicHeight(
              child: Row(
                children: [
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(CupertinoIcons.photo, color: Colors.white70),
                    onPressed: () async {
                      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
                      if (image != null) {
                        final bytes = await image.readAsBytes();
                        setState(() {
                          _img = base64Encode(bytes);
                          _decodedImage = bytes;
                        });
                      }
                    },
                  ),
                  const VerticalDivider(color: Colors.white12, indent: 8, endIndent: 8),
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(CupertinoIcons.alarm, color: Colors.white70),
                    onPressed: () async {
                      final now = DateTime.now();
                      final d = await showDatePicker(
                        context: context,
                        initialDate: now,
                        firstDate: now,
                        lastDate: now.add(const Duration(days: 365)),
                      );
                      if (d == null || !context.mounted) return;
                      
                      final t = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.fromDateTime(now),
                      );
                      
                      if (t != null && context.mounted) {
                        setState(() => _rem = DateTime(d.year, d.month, d.day, t.hour, t.minute));
                      }
                    },
                  ),
                  if (_rem != null) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        DateFormat('dd.MM HH:mm').format(_rem!),
                        style: const TextStyle(fontSize: 12, color: CupertinoColors.activeBlue, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _l,
            style: const TextStyle(color: Colors.white54, fontSize: 15),
            decoration: InputDecoration(
              hintText: l10n.labelsHint,
              hintStyle: TextStyle(color: CupertinoColors.white.withValues(alpha: 0.2)),
              border: InputBorder.none,
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
