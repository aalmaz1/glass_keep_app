// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get newNote => '새 메모';

  @override
  String get save => '저장';

  @override
  String get logout => '로그아웃';

  @override
  String get title => '제목';

  @override
  String get note => '메모';

  @override
  String get labelsHint => '라벨 (작업, 아이디어...)';

  @override
  String get noNotes => '메모를 찾을 수 없습니다';

  @override
  String get searchHint => '메모 검색...';

  @override
  String get delete => '삭제';

  @override
  String get archive => '보관';

  @override
  String get trash => '휴지통';

  @override
  String get restore => '복원';

  @override
  String get deleteForever => '영구 삭제';

  @override
  String get noNotesInTrash => '휴지통이 비었습니다';

  @override
  String get trashEmptyHint => '삭제된 메모가 여기에 표시됩니다';

  @override
  String get emptyTrash => '휴지통 비우기';

  @override
  String get login => '로그인';

  @override
  String get signUp => '가입하기';

  @override
  String get email => '이메일';

  @override
  String get password => '비밀번호';

  @override
  String get alreadyHaveAccount => '이미 계정이 있으신가요? 로그인';

  @override
  String get dontHaveAccount => '계정이 없으신가요? 가입하기';

  @override
  String get secureCloudSync => '안전한 클라우드 동기화';

  @override
  String get language => '언어';

  @override
  String get settings => '설정';
}
