import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../models/category.dart';
import '../models/expense.dart';
import '../services/storage_service.dart';

class CategorySummary {
  final ExpenseCategory category;
  final double totalAmount;
  final int count;
  final double percentage;

  const CategorySummary({
    required this.category,
    required this.totalAmount,
    required this.count,
    required this.percentage,
  });
}

class ExpenseProvider with ChangeNotifier {
  final StorageService _storage;
  final _uuid = const Uuid();

  List<ExpenseCategory> _categories = [];
  List<Expense> _expenses = [];
  String? _lastUsedCategoryId;
  Expense? _recentlyDeletedExpense;

  ExpenseProvider(this._storage) {
    _loadData();
  }

  List<ExpenseCategory> get categories => List.unmodifiable(_categories);
  List<Expense> get expenses => List.unmodifiable(_expenses);
  String? get lastUsedCategoryId => _lastUsedCategoryId;
  Expense? get recentlyDeletedExpense => _recentlyDeletedExpense;

  void _loadData() {
    _categories = List<ExpenseCategory>.from(_storage.loadCategories());
    _expenses = List<Expense>.from(_storage.loadExpenses());
    _lastUsedCategoryId = _storage.getLastUsedCategoryId();
    if (_lastUsedCategoryId == null && _categories.isNotEmpty) {
      _lastUsedCategoryId = _categories.first.id;
    }
    notifyListeners();
  }

  ExpenseCategory? getCategoryById(String id) {
    try {
      return _categories.firstWhere((c) => c.id == id);
    } catch (_) {
      return _categories.firstWhere(
        (c) => c.id == 'other',
        orElse: () => _categories.isNotEmpty
            ? _categories.first
            : const ExpenseCategory(
                id: 'other',
                name: 'Other',
                iconKey: 'more_horiz',
                colorValue: 0xFF6B7280,
                isDefault: true,
              ),
      );
    }
  }

  // --- Date queries ---
  bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  List<Expense> getExpensesForDate(DateTime date) {
    return _expenses
        .where((e) => isSameDay(e.date, date))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  double getTotalForDate(DateTime date) {
    return getExpensesForDate(date).fold(0.0, (sum, e) => sum + e.amount);
  }

  bool hasExpensesOnDate(DateTime date) {
    return _expenses.any((e) => isSameDay(e.date, date));
  }

  Set<DateTime> getDatesWithExpensesForMonth(int year, int month) {
    final set = <DateTime>{};
    for (final e in _expenses) {
      if (e.date.year == year && e.date.month == month) {
        set.add(DateTime(e.date.year, e.date.month, e.date.day));
      }
    }
    return set;
  }

  // --- Range queries (max 31 days) ---
  List<Expense> getExpensesForRange(DateTime start, DateTime end) {
    final s = DateTime(start.year, start.month, start.day);
    final e = DateTime(end.year, end.month, end.day, 23, 59, 59);
    return _expenses
        .where((exp) => exp.date.isAfter(s.subtract(const Duration(seconds: 1))) &&
            exp.date.isBefore(e.add(const Duration(seconds: 1))))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  double getTotalForRange(DateTime start, DateTime end) {
    return getExpensesForRange(start, end).fold(0.0, (sum, e) => sum + e.amount);
  }

  List<CategorySummary> getCategorySummaries(DateTime start, DateTime end) {
    final rangeExpenses = getExpensesForRange(start, end);
    final grandTotal = rangeExpenses.fold(0.0, (sum, e) => sum + e.amount);

    final map = <String, List<Expense>>{};
    for (final exp in rangeExpenses) {
      map.putIfAbsent(exp.categoryId, () => []).add(exp);
    }

    final list = <CategorySummary>[];
    map.forEach((catId, exps) {
      final cat = getCategoryById(catId);
      if (cat != null) {
        final total = exps.fold(0.0, (sum, e) => sum + e.amount);
        final pct = grandTotal > 0 ? (total / grandTotal) * 100 : 0.0;
        list.add(CategorySummary(
          category: cat,
          totalAmount: total,
          count: exps.length,
          percentage: pct,
        ));
      }
    });

    list.sort((a, b) => b.totalAmount.compareTo(a.totalAmount));
    return list;
  }

  // --- Expense CRUD ---
  Future<void> addExpense({
    required double amount,
    required String categoryId,
    required DateTime date,
    String? note,
  }) async {
    final newExpense = Expense(
      id: _uuid.v4(),
      amount: amount,
      categoryId: categoryId,
      date: date,
      note: note?.trim().isEmpty ?? true ? null : note!.trim(),
      createdAt: DateTime.now(),
    );

    _expenses.add(newExpense);
    _lastUsedCategoryId = categoryId;
    await _storage.setLastUsedCategoryId(categoryId);
    await _storage.saveExpenses(_expenses);
    notifyListeners();
  }

  Future<void> updateExpense({
    required String id,
    required double amount,
    required String categoryId,
    required DateTime date,
    String? note,
  }) async {
    final index = _expenses.indexWhere((e) => e.id == id);
    if (index != -1) {
      _expenses[index] = _expenses[index].copyWith(
        amount: amount,
        categoryId: categoryId,
        date: date,
        note: note?.trim().isEmpty ?? true ? null : note!.trim(),
      );
      _lastUsedCategoryId = categoryId;
      await _storage.setLastUsedCategoryId(categoryId);
      await _storage.saveExpenses(_expenses);
      notifyListeners();
    }
  }

  Future<void> deleteExpense(String id) async {
    final index = _expenses.indexWhere((e) => e.id == id);
    if (index != -1) {
      _recentlyDeletedExpense = _expenses[index];
      _expenses.removeAt(index);
      await _storage.saveExpenses(_expenses);
      notifyListeners();
    }
  }

  Future<void> undoDeleteExpense() async {
    if (_recentlyDeletedExpense != null) {
      _expenses.add(_recentlyDeletedExpense!);
      _recentlyDeletedExpense = null;
      await _storage.saveExpenses(_expenses);
      notifyListeners();
    }
  }

  // --- Category CRUD ---
  Future<void> addCategory({
    required String name,
    required String iconKey,
    required int colorValue,
  }) async {
    final newCat = ExpenseCategory(
      id: _uuid.v4(),
      name: name.trim(),
      iconKey: iconKey,
      colorValue: colorValue,
      isDefault: false,
    );
    _categories.add(newCat);
    await _storage.saveCategories(_categories);
    notifyListeners();
  }

  Future<void> updateCategory({
    required String id,
    required String name,
    required String iconKey,
    required int colorValue,
  }) async {
    final index = _categories.indexWhere((c) => c.id == id);
    if (index != -1) {
      _categories[index] = _categories[index].copyWith(
        name: name.trim(),
        iconKey: iconKey,
        colorValue: colorValue,
      );
      await _storage.saveCategories(_categories);
      notifyListeners();
    }
  }

  int getExpenseCountForCategory(String categoryId) {
    return _expenses.where((e) => e.categoryId == categoryId).length;
  }

  Future<void> deleteCategory(
    String categoryId, {
    String? moveToCategoryId,
  }) async {
    if (categoryId == 'other') {
      throw Exception("The 'Other' category is a system fallback and cannot be deleted.");
    }

    if (_categories.length <= 1) {
      throw Exception("Cannot delete the only remaining category.");
    }

    if (moveToCategoryId != null && moveToCategoryId != categoryId) {
      // Reassign expenses
      for (var i = 0; i < _expenses.length; i++) {
        if (_expenses[i].categoryId == categoryId) {
          _expenses[i] = _expenses[i].copyWith(categoryId: moveToCategoryId);
        }
      }
      await _storage.saveExpenses(_expenses);
    } else {
      // Delete all expenses in this category permanently
      _expenses.removeWhere((e) => e.categoryId == categoryId);
      await _storage.saveExpenses(_expenses);
    }

    _categories.removeWhere((c) => c.id == categoryId);
    if (_lastUsedCategoryId == categoryId) {
      _lastUsedCategoryId = _categories.first.id;
      await _storage.setLastUsedCategoryId(_lastUsedCategoryId!);
    }
    await _storage.saveCategories(_categories);
    notifyListeners();
  }

  // --- Export CSV ---
  String generateCsv({DateTime? start, DateTime? end}) {
    final list = (start != null && end != null)
        ? getExpensesForRange(start, end)
        : List<Expense>.from(_expenses)..sort((a, b) => b.date.compareTo(a.date));

    final buffer = StringBuffer();
    buffer.writeln('Date,Category,Amount (INR),Note,Created At');

    final dateFormat = DateFormat('yyyy-MM-dd');
    for (final e in list) {
      final cat = getCategoryById(e.categoryId);
      final date = dateFormat.format(e.date);
      final catName = '"${(cat?.name ?? 'Unknown').replaceAll('"', '""')}"';
      final amount = e.amount.toStringAsFixed(2);
      final note = '"${(e.note ?? '').replaceAll('"', '""')}"';
      final created = e.createdAt.toIso8601String();
      buffer.writeln('$date,$catName,$amount,$note,$created');
    }

    return buffer.toString();
  }

  // --- Full Backup & Restore ---
  String exportBackupJson() {
    final payload = _storage.createBackupPayload();
    return const JsonEncoder.withIndent('  ').convert(payload);
  }

  Future<bool> importBackupJson(String jsonString) async {
    try {
      final data = jsonDecode(jsonString) as Map<String, dynamic>;
      final success = await _storage.restoreFromPayload(data);
      if (success) {
        _loadData();
      }
      return success;
    } catch (_) {
      return false;
    }
  }

  Future<void> wipeAllData() async {
    await _storage.wipeAllData();
    _loadData();
  }
}
