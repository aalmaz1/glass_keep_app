// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get newNote => 'Новая заметка';

  @override
  String get save => 'Сохранить';

  @override
  String get logout => 'Выйти';

  @override
  String get title => 'Заголовок';

  @override
  String get note => 'Заметка';

  @override
  String get labelsHint => 'Метки (работа, идея...)';

  @override
  String get noNotes => 'Заметки не найдены';

  @override
  String get searchHint => 'Поиск заметок...';

  @override
  String get delete => 'Удалить';

  @override
  String get archive => 'В архив';
}
