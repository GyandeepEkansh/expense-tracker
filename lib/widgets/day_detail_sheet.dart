import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/expense_provider.dart';
import 'add_expense_modal.dart';

class DayDetailSheet extends StatelessWidget {
  final DateTime selectedDate;

  const DayDetailSheet({
    super.key,
    required this.selectedDate,
  });

  static void show(BuildContext context, DateTime date) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DayDetailSheet(selectedDate: date),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = Theme.of(context).colorScheme.surface;
    final primaryColor = Theme.of(context).primaryColor;

    final provider = context.watch<ExpenseProvider>();
    final expenses = provider.getExpensesForDate(selectedDate);
    final total = provider.getTotalForDate(selectedDate);

    final currencyFormat = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    );

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header: Date & Total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormat('EEEE').format(selectedDate),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                  Text(
                    DateFormat('d MMMM yyyy').format(selectedDate),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Total Spent',
                      style: TextStyle(
                        fontSize: 11,
                        color: primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      currencyFormat.format(total),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),

          // Expense list or Empty State
          Expanded(
            child: expenses.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.receipt_long_outlined,
                          size: 56,
                          color: isDark ? Colors.grey[700] : Colors.grey[300],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No expenses logged for this day',
                          style: TextStyle(
                            fontSize: 15,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: expenses.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (ctx, index) {
                      final exp = expenses[index];
                      final cat = provider.getCategoryById(exp.categoryId);

                      return Dismissible(
                        key: Key(exp.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          decoration: BoxDecoration(
                            color: Colors.redAccent,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.delete_outline,
                            color: Colors.white,
                            size: 26,
                          ),
                        ),
                        onDismissed: (_) {
                          provider.deleteExpense(exp.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Deleted ₹${exp.amount.toStringAsFixed(0)}'),
                              action: SnackBarAction(
                                label: 'Undo',
                                onPressed: () {
                                  provider.undoDeleteExpense();
                                },
                              ),
                            ),
                          );
                        },
                        child: Material(
                          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(14),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () {
                              AddExpenseModal.show(
                                context,
                                initialDate: selectedDate,
                                expenseToEdit: exp,
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 12),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 20,
                                    backgroundColor: (cat?.color ?? primaryColor)
                                        .withOpacity(0.18),
                                    child: Icon(
                                      cat?.icon ?? Icons.category,
                                      color: cat?.color ?? primaryColor,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          cat?.name ?? 'Other',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                          ),
                                        ),
                                        if (exp.note != null && exp.note!.isNotEmpty)
                                          Padding(
                                            padding: const EdgeInsets.only(top: 2),
                                            child: Text(
                                              exp.note!,
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: isDark
                                                    ? Colors.grey[400]
                                                    : Colors.grey[600],
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    currencyFormat.format(exp.amount),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),

          const SizedBox(height: 12),

          // Add expense button
          FilledButton.icon(
            onPressed: () {
              AddExpenseModal.show(context, initialDate: selectedDate);
            },
            icon: const Icon(Icons.add),
            label: const Text(
              'Add Expense to this day',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
