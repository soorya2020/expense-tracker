import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../../core/money.dart';

/// Schedules the report and salary-day notifications on the phone.
class AppNotifications {
  AppNotifications._();
  static final instance = AppNotifications._();
  final _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;
  void Function(String payload)? onOpen;

  static const _reportId = 1;
  static const _salaryId = 2;

  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'reports',
      'Cycle reports',
      channelDescription: 'Your report at the start of each pay cycle',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    ),
  );

  Future<void> init() async {
    if (_ready) return;
    tzdata.initializeTimeZones();
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));
    }
    await _plugin.initialize(
      settings: const InitializationSettings(android: AndroidInitializationSettings('@mipmap/ic_launcher')),
      onDidReceiveNotificationResponse: (r) {
        if (r.payload != null) onOpen?.call(r.payload!);
      },
    );
    _ready = true;
  }

  /// Payload of the notification that launched the app, if any.
  Future<String?> launchPayload() async {
    final d = await _plugin.getNotificationAppLaunchDetails();
    return (d?.didNotificationLaunchApp ?? false) ? d?.notificationResponse?.payload : null;
  }

  Future<bool> askPermission() async {
    final a = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    return await a?.requestNotificationsPermission() ?? false;
  }

  /// Schedules the 9 AM notifications for the first day of the next cycle.
  Future<void> scheduleFor({
    required DateTime currentStart,
    required DateTime currentEnd,
    required DateTime nextStart,
    required bool report,
    required bool salaryReminder,
    required int usualSalary,
  }) async {
    if (!_ready) return;
    await _plugin.cancel(id: _reportId);
    await _plugin.cancel(id: _salaryId);
    final at = tz.TZDateTime(tz.local, nextStart.year, nextStart.month, nextStart.day, 9);
    if (at.isBefore(tz.TZDateTime.now(tz.local))) return;
    if (report) {
      await _plugin.zonedSchedule(
        id: _reportId,
        scheduledDate: at,
        notificationDetails: _details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        title: 'Your ${rangeLabel(currentStart, currentEnd)} report is ready',
        body: 'See how the cycle went. Tap to open it.',
        payload: 'report:${currentStart.millisecondsSinceEpoch}',
      );
    }
    if (salaryReminder) {
      await _plugin.zonedSchedule(
        id: _salaryId,
        scheduledDate: at.add(const Duration(minutes: 1)),
        notificationDetails: _details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        title: 'Salary day',
        body: usualSalary > 0 ? 'Got your salary? Tap to add ${rupees(usualSalary)}.' : 'Got your salary? Tap to add it.',
        payload: 'salary',
      );
    }
  }

  static const _backupId = 3;
  static const _billBase = 200;
  static const _billDetails = NotificationDetails(
    android: AndroidNotificationDetails(
      'bills',
      'Bill reminders',
      channelDescription: 'A reminder the day before a recurring bill',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    ),
  );

  /// Bill reminders (9 AM the day before) and the payday backup reminder.
  Future<void> scheduleExtras({required List<(DateTime, String, String)> bills, DateTime? backupAt}) async {
    if (!_ready) return;
    for (var i = 0; i < 30; i++) {
      await _plugin.cancel(id: _billBase + i);
    }
    await _plugin.cancel(id: _backupId);
    final now = tz.TZDateTime.now(tz.local);
    var i = 0;
    for (final (day, title, body) in bills.take(30)) {
      final at = tz.TZDateTime(tz.local, day.year, day.month, day.day, 9);
      if (at.isBefore(now)) continue;
      await _plugin.zonedSchedule(
        id: _billBase + i++,
        scheduledDate: at,
        notificationDetails: _billDetails,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        title: title,
        body: body,
        payload: 'home',
      );
    }
    if (backupAt != null) {
      final at = tz.TZDateTime(tz.local, backupAt.year, backupAt.month, backupAt.day, 9, 5);
      if (at.isAfter(now)) {
        await _plugin.zonedSchedule(
          id: _backupId,
          scheduledDate: at,
          notificationDetails: _details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          title: 'Payday backup',
          body: 'Save a copy of your Tally data to Drive. Tap to back up.',
          payload: 'backup',
        );
      }
    }
  }
}
