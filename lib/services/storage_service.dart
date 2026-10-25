import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/category.dart';
import '../models/expense.dart';

class StorageService {
  static const String _keyExpenses = 'expense_tracker_expenses_v1';
  static const String _keyCategories = 'expense_tracker_categories_v1';
  static const String _keyThemeMode = 'expense_tracker_theme_mode';
  static const String _keyFirstDayOfWeek = 'expense_tracker_first_day_of_week';
  static const String _keyAppLockPinHash = 'expense_tracker_app_lock_pin_hash';
  static const String _keyAppLockEnabled = 'expense_tracker_app_lock_enabled';
  static const String _keyLockDelay = 'expense_tracker_lock_delay';
  static const String _keyReminderEnabled = 'expense_tracker_reminder_enabled';
  static const String _keyReminderTime = 'expense_tracker_reminder_time';
  static const String _keyLastUsedCategory = 'expense_tracker_last_used_category';

  static const String _pinSalt = 'expense_tracker_salt_2026_';

  final SharedPreferences _prefs;

  StorageService(this._prefs);

  static Future<StorageService> init() async {
    final prefs = await SharedPreferences.getInstance();
    return StorageService(prefs);
  }

  // --- Categories ---
  List<ExpenseCategory> loadCategories() {
    final raw = _prefs.getString(_keyCategories);
    if (raw == null || raw.isEmpty) {
      return List<ExpenseCategory>.from(ExpenseCategory.defaultCategories);
    }
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      final categories = list
          .map((item) => ExpenseCategory.fromJson(item as Map<String, dynamic>))
          .toList();
      if (categories.isEmpty) {
        return List<ExpenseCategory>.from(ExpenseCategory.defaultCategories);
      }
      return categories;
    } catch (_) {
      return List<ExpenseCategory>.from(ExpenseCategory.defaultCategories);
    }
  }

  Future<void> saveCategories(List<ExpenseCategory> categories) async {
    final raw = jsonEncode(categories.map((c) => c.toJson()).toList());
    await _prefs.setString(_keyCategories, raw);
  }

  // --- Expenses ---
  List<Expense> loadExpenses() {
    final raw = _prefs.getString(_keyExpenses);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((item) => Expense.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveExpenses(List<Expense> expenses) async {
    final raw = jsonEncode(expenses.map((e) => e.toJson()).toList());
    await _prefs.setString(_keyExpenses, raw);
  }

  // --- Preferences ---
  String getThemeMode() => _prefs.getString(_keyThemeMode) ?? 'system';
  Future<void> setThemeMode(String mode) => _prefs.setString(_keyThemeMode, mode);

  // Default to 7 (Sunday) to match mockups!
  int getFirstDayOfWeek() => _prefs.getInt(_keyFirstDayOfWeek) ?? 7;
  Future<void> setFirstDayOfWeek(int day) => _prefs.setInt(_keyFirstDayOfWeek, day);

  bool isAppLockEnabled() => _prefs.getBool(_keyAppLockEnabled) ?? false;
  Future<void> setAppLockEnabled(bool enabled) => _prefs.setBool(_keyAppLockEnabled, enabled);

  static String hashPin(String pin) {
    final bytes = utf8.encode('$_pinSalt$pin');
    return sha256.convert(bytes).toString();
  }

  bool hasAppLockPin() => _prefs.containsKey(_keyAppLockPinHash);

  String? getAppLockPinHash() => _prefs.getString(_keyAppLockPinHash);

  Future<void> setAppLockPin(String? pin) async {
    if (pin == null || pin.isEmpty) {
      await _prefs.remove(_keyAppLockPinHash);
    } else {
      final hash = hashPin(pin);
      await _prefs.setString(_keyAppLockPinHash, hash);
    }
  }

  bool verifyPin(String enteredPin) {
    final storedHash = getAppLockPinHash();
    if (storedHash == null) return true;
    final enteredHash = hashPin(enteredPin);
    return storedHash == enteredHash;
  }

  int getLockDelayMinutes() => _prefs.getInt(_keyLockDelay) ?? 0; // 0 = Immediately, 1 = 1m, 5 = 5m
  Future<void> setLockDelayMinutes(int minutes) => _prefs.setInt(_keyLockDelay, minutes);

  bool isReminderEnabled() => _prefs.getBool(_keyReminderEnabled) ?? false;
  Future<void> setReminderEnabled(bool enabled) => _prefs.setBool(_keyReminderEnabled, enabled);

  String getReminderTime() => _prefs.getString(_keyReminderTime) ?? '21:00'; // 9:00 PM
  Future<void> setReminderTime(String time) => _prefs.setString(_keyReminderTime, time);

  String? getLastUsedCategoryId() => _prefs.getString(_keyLastUsedCategory);
  Future<void> setLastUsedCategoryId(String categoryId) =>
      _prefs.setString(_keyLastUsedCategory, categoryId);

  // --- Full Backup & Atomic Restore ---
  Map<String, dynamic> createBackupPayload() {
    return {
      'version': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'categories': loadCategories().map((c) => c.toJson()).toList(),
      'expenses': loadExpenses().map((e) => e.toJson()).toList(),
    };
  }

  /// Atomic restore: parses and validates all data in memory first.
  /// If any error occurs, existing data is untouched.
  Future<bool> restoreFromPayload(Map<String, dynamic> data) async {
    try {
      List<ExpenseCategory>? validatedCategories;
      List<Expense>? validatedExpenses;

      if (data['categories'] != null) {
        final rawCats = data['categories'] as List<dynamic>;
        validatedCategories = rawCats
            .map((c) => ExpenseCategory.fromJson(c as Map<String, dynamic>))
            .toList();
      }

      if (data['expenses'] != null) {
        final rawExps = data['expenses'] as List<dynamic>;
        validatedExpenses = rawExps
            .map((e) => Expense.fromJson(e as Map<String, dynamic>))
            .toList();
      }

      // If categories were present but parsed empty/invalid, fail safely
      if (validatedCategories != null && validatedCategories.isEmpty) {
        return false;
      }

      // Both validated without throwing! Now write atomically
      if (validatedCategories != null) {
        await saveCategories(validatedCategories);
      }
      if (validatedExpenses != null) {
        await saveExpenses(validatedExpenses);
      }
      return true;
    } catch (_) {
      // Failed during parsing: zero data overwritten!
      return false;
    }
  }

  Future<void> wipeAllData() async {
    await _prefs.remove(_keyExpenses);
    await _prefs.remove(_keyCategories);
    await _prefs.remove(_keyLastUsedCategory);
  }
}
