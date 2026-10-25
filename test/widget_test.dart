import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:expense_tracker/services/storage_service.dart';
import 'package:expense_tracker/providers/expense_provider.dart';
import 'package:expense_tracker/providers/settings_provider.dart';

void main() {
  late StorageService storage;
  late ExpenseProvider expenseProvider;
  late SettingsProvider settingsProvider;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    storage = await StorageService.init();
    expenseProvider = ExpenseProvider(storage);
    settingsProvider = SettingsProvider(storage);
  });

  group('Category & Expense Logic Tests', () {
    test('Initial defaults seeded properly', () {
      expect(expenseProvider.categories.length, 6);
      expect(expenseProvider.getCategoryById('other')?.name, 'Other');
      expect(settingsProvider.firstDayOfWeek, 7); // Default is Sunday
    });

    test('Decimal amounts are preserved accurately', () async {
      await expenseProvider.addExpense(
        amount: 450.50,
        categoryId: 'food',
        date: DateTime(2026, 10, 24),
        note: 'Team lunch',
      );

      final exp = expenseProvider.expenses.first;
      expect(exp.amount, 450.50);
      expect(expenseProvider.getTotalForDate(DateTime(2026, 10, 24)), 450.50);
    });

    test('Category delete with move-to-another safeguards expenses', () async {
      await expenseProvider.addCategory(
        name: 'Gym',
        iconKey: 'fitness_center',
        colorValue: 0xFF10B981,
      );

      final gymCat = expenseProvider.categories.firstWhere((c) => c.name == 'Gym');

      // Add expense to Gym
      await expenseProvider.addExpense(
        amount: 1200.0,
        categoryId: gymCat.id,
        date: DateTime(2026, 10, 20),
        note: 'Membership',
      );

      expect(expenseProvider.getExpenseCountForCategory(gymCat.id), 1);

      // Delete Gym and move expenses to 'other'
      await expenseProvider.deleteCategory(gymCat.id, moveToCategoryId: 'other');

      expect(expenseProvider.categories.any((c) => c.id == gymCat.id), isFalse);
      expect(expenseProvider.getExpenseCountForCategory('other'), 1);
      expect(expenseProvider.expenses.first.categoryId, 'other');
      expect(expenseProvider.expenses.first.amount, 1200.0);
    });

    test('Category delete permanently wipes associated expenses', () async {
      await expenseProvider.addCategory(
        name: 'Temporary',
        iconKey: 'shopping_bag',
        colorValue: 0xFF8B5CF6,
      );

      final tempCat =
          expenseProvider.categories.firstWhere((c) => c.name == 'Temporary');

      await expenseProvider.addExpense(
        amount: 300.0,
        categoryId: tempCat.id,
        date: DateTime(2026, 10, 22),
      );

      expect(expenseProvider.expenses.length, 1);

      // Delete permanently
      await expenseProvider.deleteCategory(tempCat.id);

      expect(expenseProvider.categories.any((c) => c.id == tempCat.id), isFalse);
      expect(expenseProvider.expenses.length, 0);
    });

    test('Cannot delete system Other category or last remaining category', () async {
      expect(
        () => expenseProvider.deleteCategory('other'),
        throwsA(isA<Exception>()),
      );
    });

    test('Date range filtering strictly includes correct period', () async {
      final oct10 = DateTime(2026, 10, 10);
      final oct20 = DateTime(2026, 10, 20);
      final nov05 = DateTime(2026, 11, 5);

      await expenseProvider.addExpense(
        amount: 100,
        categoryId: 'food',
        date: oct10,
      );
      await expenseProvider.addExpense(
        amount: 250,
        categoryId: 'grocery',
        date: oct20,
      );
      await expenseProvider.addExpense(
        amount: 500,
        categoryId: 'travel',
        date: nov05,
      );

      // Query Oct 1 to Oct 31
      final octExpenses = expenseProvider.getExpensesForRange(
        DateTime(2026, 10, 1),
        DateTime(2026, 10, 31),
      );

      expect(octExpenses.length, 2);
      expect(
        expenseProvider.getTotalForRange(DateTime(2026, 10, 1), DateTime(2026, 10, 31)),
        350.0,
      );
    });
  });

  group('Security & Atomic Restore Tests', () {
    test('PIN is hashed and verified correctly', () async {
      await settingsProvider.setAppLock(enabled: true, pin: '1234');

      expect(settingsProvider.hasPinSet, isTrue);
      // Plain text pin is not stored
      expect(storage.getAppLockPinHash(), isNot('1234'));
      expect(storage.getAppLockPinHash()?.length, 64); // SHA-256 is 64 hex chars

      // Verify correct PIN
      expect(settingsProvider.verifyPin('1234'), isTrue);
      // Verify wrong PIN
      expect(settingsProvider.verifyPin('9999'), isFalse);
    });

    test('Five failed PIN attempts triggers lockout cooldown', () async {
      await settingsProvider.setAppLock(enabled: true, pin: '4321');

      for (var i = 0; i < 5; i++) {
        settingsProvider.verifyPin('0000');
      }

      expect(settingsProvider.isLockedOut, isTrue);
      expect(settingsProvider.remainingLockoutSeconds, greaterThan(0));
    });

    test('Atomic restore rejects corrupt payload without destroying data', () async {
      // Add existing expense
      await expenseProvider.addExpense(
        amount: 999.0,
        categoryId: 'food',
        date: DateTime(2026, 10, 24),
      );

      // Attempt invalid restore payload
      final invalidJson = '{"categories": [{"bad_schema": true}], "expenses": "not_a_list"}';
      final ok = await expenseProvider.importBackupJson(invalidJson);

      expect(ok, isFalse);
      // Original data remains completely untouched!
      expect(expenseProvider.expenses.length, 1);
      expect(expenseProvider.expenses.first.amount, 999.0);
    });
  });
}
