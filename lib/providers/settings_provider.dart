import 'package:flutter/material.dart';
import '../services/storage_service.dart';

class SettingsProvider with ChangeNotifier {
  final StorageService _storage;

  late ThemeMode _themeMode;
  late int _firstDayOfWeek;
  late bool _isAppLockEnabled;
  late String? _appLockPin;
  late int _lockDelayMinutes;
  late bool _isReminderEnabled;
  late String _reminderTime;

  bool _isSessionUnlocked = false;
  DateTime? _lastPausedTime;

  SettingsProvider(this._storage) {
    _loadSettings();
  }

  ThemeMode get themeMode => _themeMode;
  int get firstDayOfWeek => _firstDayOfWeek;
  bool get isAppLockEnabled => _isAppLockEnabled;
  bool get hasPinSet => _appLockPin != null && _appLockPin!.isNotEmpty;
  int get lockDelayMinutes => _lockDelayMinutes;
  bool get isReminderEnabled => _isReminderEnabled;
  String get reminderTime => _reminderTime;
  String get currencySymbol => '₹';

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
    _appLockPin = _storage.getAppLockPin();
    _lockDelayMinutes = _storage.getLockDelayMinutes();
    _isReminderEnabled = _storage.isReminderEnabled();
    _reminderTime = _storage.getReminderTime();

    // If lock is not enabled, session is unlocked by default
    if (!_isAppLockEnabled || !hasPinSet) {
      _isSessionUnlocked = true;
    } else {
      _isSessionUnlocked = false;
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
      _appLockPin = pin;
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

  Future<void> setReminder({required bool enabled, String? time}) async {
    _isReminderEnabled = enabled;
    await _storage.setReminderEnabled(enabled);
    if (time != null) {
      _reminderTime = time;
      await _storage.setReminderTime(time);
    }
    notifyListeners();
  }

  bool verifyPin(String enteredPin) {
    if (_appLockPin == null) return true;
    if (_appLockPin == enteredPin) {
      _isSessionUnlocked = true;
      notifyListeners();
      return true;
    }
    return false;
  }

  void unlockSession() {
    _isSessionUnlocked = true;
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
