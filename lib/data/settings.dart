import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Small app settings kept in shared preferences.
class Settings extends ChangeNotifier {
  Settings(this._p);
  final SharedPreferences _p;

  static Future<Settings> load() async => Settings(await SharedPreferences.getInstance());

  bool get setupDone => _p.getBool('setupDone') ?? false;
  int get startingBalance => _p.getInt('startingBalance') ?? 0; // paise
  DateTime get startingDate =>
      DateTime.fromMillisecondsSinceEpoch(_p.getInt('startingDate') ?? 0);
  int get cycleDay => _p.getInt('cycleDay') ?? 1;
  bool get followSalary => _p.getBool('followSalary') ?? true;
  bool get reportNotify => _p.getBool('reportNotify') ?? true;
  bool get salaryReminder => _p.getBool('salaryReminder') ?? false;
  int get usualSalary => _p.getInt('usualSalary') ?? 0; // paise, learned from entries
  bool get biometric => _p.getBool('biometric') ?? false;
  String get lockType => _p.getString('lockType') ?? 'pin';
  bool get smsEnabled => _p.getBool('smsEnabled') ?? false;
  DateTime get smsLastScan =>
      DateTime.fromMillisecondsSinceEpoch(_p.getInt('smsLastScan') ?? 0);
  List<String> get smsSkipAccounts => _p.getStringList('smsSkipAccounts') ?? const [];
  bool get hideAmountsInNotifications => _p.getBool('hideAmounts') ?? false;
  String get recurringJson => _p.getString('recurring') ?? '[]';
  DateTime? get lastBackup {
    final v = _p.getInt('lastBackup');
    return v == null ? null : DateTime.fromMillisecondsSinceEpoch(v);
  }
  bool get backupReminder => _p.getBool('backupReminder') ?? false;
  String get catRulesJson => _p.getString('catRules') ?? '{}';
  String get customCatsJson => _p.getString('customCats') ?? '[]';
  String get budgetsJson => _p.getString('budgets') ?? '{}';
  List<String> get budgetFlags => _p.getStringList('budgetFlags') ?? const []; // alerts already shown
  bool get widgetHide => _p.getBool('widgetHide') ?? false;
  ThemeMode get themeMode => switch (_p.getString('theme')) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };

  Future<void> _set(Future<bool> f) async {
    await f;
    notifyListeners();
  }

  Future<void> completeSetup({required int startingBalance, required int cycleDay}) async {
    await _p.setInt('startingBalance', startingBalance);
    await _p.setInt('startingDate', DateTime.now().millisecondsSinceEpoch);
    await _p.setInt('cycleDay', cycleDay);
    await _set(_p.setBool('setupDone', true));
  }

  Future<void> setStartingBalance(int v) => _set(_p.setInt('startingBalance', v));
  Future<void> setCycleDay(int v) => _set(_p.setInt('cycleDay', v));
  Future<void> setFollowSalary(bool v) => _set(_p.setBool('followSalary', v));
  Future<void> setReportNotify(bool v) => _set(_p.setBool('reportNotify', v));
  Future<void> setSalaryReminder(bool v) => _set(_p.setBool('salaryReminder', v));
  Future<void> setUsualSalary(int v) => _set(_p.setInt('usualSalary', v));
  Future<void> setBiometric(bool v) => _set(_p.setBool('biometric', v));
  Future<void> setLockType(String v) => _set(_p.setString('lockType', v));
  Future<void> setSmsEnabled(bool v) => _set(_p.setBool('smsEnabled', v));
  Future<void> setSmsLastScan(DateTime v) => _set(_p.setInt('smsLastScan', v.millisecondsSinceEpoch));
  Future<void> addSmsSkipAccount(String a) =>
      _set(_p.setStringList('smsSkipAccounts', {...smsSkipAccounts, a}.toList()));
  Future<void> setHideAmounts(bool v) => _set(_p.setBool('hideAmounts', v));
  Future<void> setRecurringJson(String v) => _set(_p.setString('recurring', v));
  Future<void> setLastBackup(DateTime v) => _set(_p.setInt('lastBackup', v.millisecondsSinceEpoch));
  Future<void> setBackupReminder(bool v) => _set(_p.setBool('backupReminder', v));

  /// Every stored setting, for a backup.
  Map<String, Object?> exportPrefs() => {for (final k in _p.getKeys()) k: _p.get(k)};

  /// Puts back settings from a backup. Setup stays done on this phone.
  Future<void> importPrefs(Map<String, dynamic> m) async {
    for (final e in m.entries) {
      final v = e.value;
      if (e.key == 'setupDone' || e.key == 'biometric' || e.key == 'lockType') continue;
      if (v is bool) {
        await _p.setBool(e.key, v);
      } else if (v is int) {
        await _p.setInt(e.key, v);
      } else if (v is double) {
        await _p.setDouble(e.key, v);
      } else if (v is String) {
        await _p.setString(e.key, v);
      } else if (v is List) {
        await _p.setStringList(e.key, v.map((x) => '$x').toList());
      }
    }
    notifyListeners();
  }

  Future<void> setCatRulesJson(String v) => _set(_p.setString('catRules', v));
  Future<void> setCustomCatsJson(String v) => _set(_p.setString('customCats', v));
  Future<void> setBudgetsJson(String v) => _set(_p.setString('budgets', v));
  Future<void> addBudgetFlag(String v) => _set(_p.setStringList('budgetFlags', {...budgetFlags, v}.toList()));
  Future<void> setWidgetHide(bool v) => _set(_p.setBool('widgetHide', v));

  Future<void> setThemeMode(ThemeMode m) => _set(_p.setString('theme', m.name));
}
