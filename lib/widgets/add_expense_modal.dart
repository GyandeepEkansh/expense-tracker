import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/category.dart';
import '../models/expense.dart';
import '../providers/expense_provider.dart';

class AddExpenseModal extends StatefulWidget {
  final DateTime initialDate;
  final Expense? expenseToEdit;

  const AddExpenseModal({
    super.key,
    required this.initialDate,
    this.expenseToEdit,
  });

  static Future<void> show(
    BuildContext context, {
    required DateTime initialDate,
    Expense? expenseToEdit,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AddExpenseModal(
        initialDate: initialDate,
        expenseToEdit: expenseToEdit,
      ),
    );
  }

  @override
  State<AddExpenseModal> createState() => _AddExpenseModalState();
}

class _AddExpenseModalState extends State<AddExpenseModal> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  late DateTime _selectedDate;
  String? _selectedCategoryId;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.expenseToEdit != null;
    _selectedDate = widget.expenseToEdit?.date ?? widget.initialDate;

    if (_isEditing) {
      _amountController.text = widget.expenseToEdit!.amount.toStringAsFixed(0);
      _noteController.text = widget.expenseToEdit!.note ?? '';
      _selectedCategoryId = widget.expenseToEdit!.categoryId;
    } else {
      final provider = context.read<ExpenseProvider>();
      _selectedCategoryId = provider.lastUsedCategoryId ??
          (provider.categories.isNotEmpty ? provider.categories.first.id : null);
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _showNewCategoryDialog() {
    final nameCtrl = TextEditingController();
    int selectedColor = 0xFF10B981;
    String selectedIconKey = 'shopping_bag';

    final colorOptions = [
      0xFF10B981, // Emerald
      0xFF3B82F6, // Blue
      0xFFF59E0B, // Amber
      0xFFEF4444, // Red
      0xFF8B5CF6, // Purple
      0xFFEC4899, // Pink
      0xFF14B8A6, // Teal
      0xFFF97316, // Orange
      0xFF6B7280, // Gray
    ];

    final iconKeys = CategoryIcons.availableKeys;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          title: const Text('New Category'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Category Name',
                    hintText: 'e.g., Entertainment, Gym',
                  ),
                  autofocus: true,
                ),
                const SizedBox(height: 16),
                const Text('Choose Color',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: colorOptions.map((c) {
                    final isSel = selectedColor == c;
                    return InkWell(
                      onTap: () => setDlgState(() => selectedColor = c),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Color(c),
                          shape: BoxShape.circle,
                          border: isSel
                              ? Border.all(color: Colors.white, width: 3)
                              : null,
                          boxShadow: [
                            if (isSel)
                              BoxShadow(
                                color: Color(c).withValues(alpha: 0.5),
                                blurRadius: 6,
                              ),
                          ],
                        ),
                        child: isSel
                            ? const Icon(Icons.check, size: 18, color: Colors.white)
                            : null,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                const Text('Choose Icon',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: iconKeys.map((key) {
                    final isSel = selectedIconKey == key;
                    final icon = CategoryIcons.get(key);
                    return InkWell(
                      onTap: () => setDlgState(() => selectedIconKey = key),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isSel
                              ? Theme.of(context).primaryColor.withValues(alpha: 0.2)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSel
                                ? Theme.of(context).primaryColor
                                : Colors.grey.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Icon(icon, size: 22),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final name = nameCtrl.text.trim();
                if (name.isNotEmpty) {
                  final provider = context.read<ExpenseProvider>();
                  provider.addCategory(
                    name: name,
                    iconKey: selectedIconKey,
                    colorValue: selectedColor,
                  );
                  Navigator.pop(dialogCtx);
                  // Auto-select newly created category
                  setState(() {
                    _selectedCategoryId = provider.categories.last.id;
                  });
                }
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  void _onSave() {
    final amountText = _amountController.text.trim();
    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }

    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category')),
      );
      return;
    }

    final provider = context.read<ExpenseProvider>();
    if (_isEditing) {
      provider.updateExpense(
        id: widget.expenseToEdit!.id,
        amount: amount,
        categoryId: _selectedCategoryId!,
        date: _selectedDate,
        note: _noteController.text,
      );
    } else {
      provider.addExpense(
        amount: amount,
        categoryId: _selectedCategoryId!,
        date: _selectedDate,
        note: _noteController.text,
      );
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = Theme.of(context).colorScheme.surface;
    final primaryColor = Theme.of(context).primaryColor;
    final categories = context.watch<ExpenseProvider>().categories;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
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
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Handle
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

              // Title
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _isEditing ? 'Edit Expense' : 'Add Expense',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  InkWell(
                    onTap: _pickDate,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today, size: 14, color: primaryColor),
                          const SizedBox(width: 6),
                          Text(
                            DateFormat('EEE, d MMM').format(_selectedDate),
                            style: TextStyle(
                              color: primaryColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Amount Field with ₹ symbol
              Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: primaryColor.withOpacity(0.4),
                    width: 1.5,
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      '₹',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _amountController,
                        autofocus: !_isEditing,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                        decoration: const InputDecoration(
                          hintText: '0',
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                          fillColor: Colors.transparent,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Categories Header
              const Text(
                'Category',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),

              // Category Chips + New Category Chip
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ...categories.map((cat) {
                    final isSel = _selectedCategoryId == cat.id;
                    return FilterChip(
                      selected: isSel,
                      avatar: CircleAvatar(
                        backgroundColor: cat.color.withOpacity(isSel ? 1.0 : 0.2),
                        child: Icon(
                          cat.icon,
                          size: 15,
                          color: isSel ? Colors.white : cat.color,
                        ),
                      ),
                      label: Text(cat.name),
                      labelStyle: TextStyle(
                        fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                        color: isSel ? (isDark ? Colors.black : Colors.white) : null,
                      ),
                      selectedColor: primaryColor,
                      checkmarkColor: isDark ? Colors.black : Colors.white,
                      onSelected: (val) {
                        if (val) {
                          setState(() {
                            _selectedCategoryId = cat.id;
                          });
                        }
                      },
                    );
                  }),
                  ActionChip(
                    avatar: const Icon(Icons.add, size: 16),
                    label: const Text('New'),
                    onPressed: _showNewCategoryDialog,
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Note Field
              TextField(
                controller: _noteController,
                decoration: const InputDecoration(
                  labelText: 'Note (Optional)',
                  hintText: 'e.g., Dinner with friends, petrol',
                  prefixIcon: Icon(Icons.edit_note),
                ),
              ),
              const SizedBox(height: 24),

              // Save Button
              FilledButton(
                onPressed: _onSave,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  _isEditing ? 'Update Expense' : 'Save Expense',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
