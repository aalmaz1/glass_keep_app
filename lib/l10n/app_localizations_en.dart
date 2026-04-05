// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get newNote => 'New Note';

  @override
  String get save => 'Save';

  @override
  String get logout => 'Logout';

  @override
  String get title => 'Title';

  @override
  String get note => 'Note';

  @override
  String get labelsHint => 'Labels (work, idea...)';

  @override
  String get noNotes => 'No notes found';

  @override
  String get searchHint => 'Search notes...';

  @override
  String get delete => 'Delete';

  @override
  String get archive => 'Archive';
}
