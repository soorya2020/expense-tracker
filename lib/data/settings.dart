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
  Future<void> setThemeMode(ThemeMode m) => _set(_p.setString('theme', m.name));
}
