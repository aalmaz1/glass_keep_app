import 'dart:convert';
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

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _logout() async {
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
              // Physics удален для автоматического выбора платформой (адаптивность)
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
                  stream: widget.storage.getNotesStream(),
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
                    
                    var notes = snapshot.data!.where((n) => n.isArchived == _showArchived).toList();
                    if (_search.isNotEmpty) {
                      final q = _search.toLowerCase();
                      notes = notes.where((n) => n.title.toLowerCase().contains(q) || n.content.toLowerCase().contains(q)).toList();
                    }
                    notes.sort((a, b) {
                      if (a.isPinned != b.isPinned) return a.isPinned ? -1 : 1;
                      return b.updatedAt.compareTo(a.updatedAt);
                    });

                    if (notes.isEmpty) {
                      return SliverFillRemaining(
                        child: Center(child: Text(l10n.noNotes, style: const TextStyle(color: Colors.white24, fontSize: 17))),
                      );
                    }

                    int crossAxisCount = size.width > 900 ? 4 : (size.width > 600 ? 3 : 2);

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
            child: Center(
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () {
                    final n = Note(id: '', title: '', content: '', updatedAt: DateTime.now());
                    _openNote(context, n);
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
              ),
            ),
          ),
        ],
      ),
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
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final note = widget.note;
    final heroTag = note.id.isEmpty ? null : 'note-${note.id}';
    
    Widget content = VisionGlassCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (note.imageBase64 != null) Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.memory(base64Decode(note.imageBase64!), fit: BoxFit.cover),
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
              children: note.labels.map((l) => LabelChip(label: l)).toList().cast<Widget>(),
            ),
          ],
        ],
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

class VisionBackground extends StatelessWidget {
  const VisionBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: -100,
          right: -50,
          child: _BlurCircle(color: CupertinoColors.activeBlue.withValues(alpha: 0.2), size: 400),
        ),
        Positioned(
          bottom: -150,
          left: -100,
          child: _BlurCircle(color: CupertinoColors.systemPurple.withValues(alpha: 0.15), size: 500),
        ),
      ],
    );
  }
}

class _BlurCircle extends StatelessWidget {
  final Color color;
  final double size;
  const _BlurCircle({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80), child: Container()),
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

  @override
  void initState() {
    super.initState();
    _t = TextEditingController(text: widget.note.title);
    _c = TextEditingController(text: widget.note.content);
    _l = TextEditingController(text: widget.note.labels.join(', '));
    _img = widget.note.imageBase64;
    _rem = widget.note.reminder;
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
          if (_img != null) Stack(
            children: [
              ClipRRect(borderRadius: BorderRadius.circular(20), child: Image.memory(base64Decode(_img!))),
              Positioned(right: 8, top: 8, child: CupertinoButton(padding: EdgeInsets.zero, child: const Icon(CupertinoIcons.xmark_circle_fill, color: Colors.white70), onPressed: () => setState(() => _img = null))),
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
                        setState(() => _img = base64Encode(bytes));
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
