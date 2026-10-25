import 'package:flutter/material.dart';
import '../services/notification_service.dart';
import '../services/storage_service.dart';

class SettingsProvider with ChangeNotifier {
  final StorageService _storage;
  final NotificationService _notifications = NotificationService();

  late ThemeMode _themeMode;
  late int _firstDayOfWeek;
  late bool _isAppLockEnabled;
  late int _lockDelayMinutes;
  late bool _isReminderEnabled;
  late String _reminderTime;

  bool _isSessionUnlocked = false;
  DateTime? _lastPausedTime;

  int _failedAttempts = 0;
  DateTime? _lockoutUntil;

  SettingsProvider(this._storage) {
    _loadSettings();
  }

  ThemeMode get themeMode => _themeMode;
  int get firstDayOfWeek => _firstDayOfWeek;
  bool get isAppLockEnabled => _isAppLockEnabled;
  bool get hasPinSet => _storage.hasAppLockPin();
  int get lockDelayMinutes => _lockDelayMinutes;
  bool get isReminderEnabled => _isReminderEnabled;
  String get reminderTime => _reminderTime;
  String get currencySymbol => '₹';

  bool get isLockedOut =>
      _lockoutUntil != null && DateTime.now().isBefore(_lockoutUntil!);

  int get remainingLockoutSeconds {
    if (!isLockedOut) return 0;
    return _lockoutUntil!.difference(DateTime.now()).inSeconds + 1;
  }

  bool get shouldShowLockScreen {
    if (!_isAppLockEnabled || !hasPinSet) return false;
    return !_isSessionUnlocked;
  }

  void _loadSettings() {
    final modeStr = _storage.getThemeMode();
    switch (modeStr) {
      case 'light':
        _themeMode = ThemeMode.light;
        break;
      case 'dark':
        _themeMode = ThemeMode.dark;
        break;
      default:
        _themeMode = ThemeMode.system;
    }

    _firstDayOfWeek = _storage.getFirstDayOfWeek();
    _isAppLockEnabled = _storage.isAppLockEnabled();
    _lockDelayMinutes = _storage.getLockDelayMinutes();
    _isReminderEnabled = _storage.isReminderEnabled();
    _reminderTime = _storage.getReminderTime();

    if (!_isAppLockEnabled || !hasPinSet) {
      _isSessionUnlocked = true;
    } else {
      _isSessionUnlocked = false;
    }

    // Schedule notification on startup if enabled
    if (_isReminderEnabled) {
      _scheduleCurrentReminder();
    }

    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    final str = mode == ThemeMode.light
        ? 'light'
        : mode == ThemeMode.dark
            ? 'dark'
            : 'system';
    await _storage.setThemeMode(str);
    notifyListeners();
  }

  Future<void> setFirstDayOfWeek(int day) async {
    _firstDayOfWeek = day;
    await _storage.setFirstDayOfWeek(day);
    notifyListeners();
  }

  Future<void> setAppLock({required bool enabled, String? pin}) async {
    _isAppLockEnabled = enabled;
    await _storage.setAppLockEnabled(enabled);
    if (pin != null) {
      await _storage.setAppLockPin(pin);
    }
    if (!enabled) {
      _isSessionUnlocked = true;
    }
    notifyListeners();
  }

  Future<void> setLockDelayMinutes(int minutes) async {
    _lockDelayMinutes = minutes;
    await _storage.setLockDelayMinutes(minutes);
    notifyListeners();
  }

  Future<bool> setReminder({required bool enabled, String? time}) async {
    _isReminderEnabled = enabled;
    await _storage.setReminderEnabled(enabled);
    if (time != null) {
      _reminderTime = time;
      await _storage.setReminderTime(time);
    }

    if (enabled) {
      final granted = await _notifications.requestPermission();
      if (granted) {
        await _scheduleCurrentReminder();
      }
      notifyListeners();
      return granted;
    } else {
      await _notifications.cancelDailyReminder();
      notifyListeners();
      return true;
    }
  }

  Future<void> _scheduleCurrentReminder() async {
    final parts = _reminderTime.split(':');
    final hour = int.tryParse(parts[0]) ?? 21;
    final minute = int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0;
    await _notifications.scheduleDailyReminder(hour: hour, minute: minute);
  }

  bool verifyPin(String enteredPin) {
    if (isLockedOut) return false;

    final isValid = _storage.verifyPin(enteredPin);
    if (isValid) {
      _failedAttempts = 0;
      _lockoutUntil = null;
      _isSessionUnlocked = true;
      notifyListeners();
      return true;
    } else {
      _failedAttempts++;
      if (_failedAttempts >= 5) {
        _lockoutUntil = DateTime.now().add(const Duration(seconds: 30));
        _failedAttempts = 0;
      }
      notifyListeners();
      return false;
    }
  }

  void unlockSession() {
    _isSessionUnlocked = true;
    _failedAttempts = 0;
    _lockoutUntil = null;
    notifyListeners();
  }

  void lockSession() {
    if (_isAppLockEnabled && hasPinSet) {
      _isSessionUnlocked = false;
      notifyListeners();
    }
  }

  void handleAppLifecycleState(AppLifecycleState state) {
    if (!_isAppLockEnabled || !hasPinSet) return;

    if (state == AppLifecycleState.paused || state == AppLifecycleState.hidden) {
      _lastPausedTime = DateTime.now();
    } else if (state == AppLifecycleState.resumed) {
      if (_lastPausedTime != null) {
        final elapsed = DateTime.now().difference(_lastPausedTime!).inMinutes;
        if (elapsed >= _lockDelayMinutes) {
          _isSessionUnlocked = false;
          notifyListeners();
        }
      }
    }
  }
}
