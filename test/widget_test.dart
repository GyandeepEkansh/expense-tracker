import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:expense_tracker/services/storage_service.dart';
import 'package:expense_tracker/providers/expense_provider.dart';
import 'package:expense_tracker/providers/settings_provider.dart';

void main() {
  test('Expense and Category calculations test', () async {
    SharedPreferences.setMockInitialValues({});
    final storage = await StorageService.init();
    final expenseProvider = ExpenseProvider(storage);
    final settingsProvider = SettingsProvider(storage);

    expect(expenseProvider.categories.length, greaterThanOrEqualTo(6));
    expect(settingsProvider.currencySymbol, '₹');

    // Add an expense
    await expenseProvider.addExpense(
      amount: 450,
      categoryId: 'food',
      date: DateTime.now(),
      note: 'Lunch with team',
    );

    expect(expenseProvider.expenses.length, 1);
    expect(expenseProvider.getTotalForDate(DateTime.now()), 450.0);
  });
}
