import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/category.dart';
import '../providers/expense_provider.dart';

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  void _showCategoryDialog(BuildContext context, {ExpenseCategory? categoryToEdit}) {
    final isEditing = categoryToEdit != null;
    final nameCtrl = TextEditingController(text: categoryToEdit?.name ?? '');
    int selectedColor = categoryToEdit?.colorValue ?? 0xFF10B981;
    String selectedIconKey = categoryToEdit?.iconKey ?? 'shopping_bag';

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
          title: Text(isEditing ? 'Edit Category' : 'New Category'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Category Name',
                    hintText: 'e.g., Entertainment, Fuel',
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
                  if (isEditing) {
                    provider.updateCategory(
                      id: categoryToEdit.id,
                      name: name,
                      iconKey: selectedIconKey,
                      colorValue: selectedColor,
                    );
                  } else {
                    provider.addCategory(
                      name: name,
                      iconKey: selectedIconKey,
                      colorValue: selectedColor,
                    );
                  }
                  Navigator.pop(dialogCtx);
                }
              },
              child: Text(isEditing ? 'Save Changes' : 'Create'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteCategoryDialog(BuildContext context, ExpenseCategory category) {
    final provider = context.read<ExpenseProvider>();
    final count = provider.getExpenseCountForCategory(category.id);
    final otherCategories =
        provider.categories.where((c) => c.id != category.id).toList();

    if (otherCategories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot delete the only remaining category.')),
      );
      return;
    }

    String selectedMoveTo = otherCategories.first.id;
    int deleteChoice = 0; // 0 = Move to another, 1 = Delete permanently

    if (count == 0) {
      // Simple delete
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('Delete "${category.name}"?'),
          content: const Text('This category has no logged expenses and will be removed.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
              onPressed: () {
                provider.deleteCategory(category.id);
                Navigator.pop(ctx);
              },
              child: const Text('Delete'),
            ),
          ],
        ),
      );
      return;
    }

    // Has expenses: present the two options agreed upon
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          title: Text('Delete "${category.name}"?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'This category has $count ${count == 1 ? 'logged expense' : 'logged expenses'}. What would you like to do with them?',
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              RadioListTile<int>(
                value: 0,
                groupValue: deleteChoice,
                title: const Text('Move expenses to another category',
                    style: TextStyle(fontSize: 14)),
                onChanged: (val) => setDlgState(() => deleteChoice = val!),
              ),
              if (deleteChoice == 0)
                Padding(
                  padding: const EdgeInsets.only(left: 36, bottom: 8),
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: selectedMoveTo,
                    items: otherCategories.map((c) {
                      return DropdownMenuItem(
                        value: c.id,
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 10,
                              backgroundColor: c.color.withOpacity(0.3),
                              child: Icon(c.icon, size: 12, color: c.color),
                            ),
                            const SizedBox(width: 8),
                            Text(c.name),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setDlgState(() => selectedMoveTo = val);
                      }
                    },
                  ),
                ),
              RadioListTile<int>(
                value: 1,
                groupValue: deleteChoice,
                title: const Text('Delete all expenses permanently',
                    style: TextStyle(fontSize: 14, color: Colors.redAccent)),
                onChanged: (val) => setDlgState(() => deleteChoice = val!),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: deleteChoice == 1 ? Colors.redAccent : null,
              ),
              onPressed: () {
                provider.deleteCategory(
                  category.id,
                  moveToCategoryId: deleteChoice == 0 ? selectedMoveTo : null,
                );
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Category "${category.name}" removed.')),
                );
              },
              child: Text(deleteChoice == 0 ? 'Move & Delete' : 'Delete All'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.watch<ExpenseProvider>();
    final categories = provider.categories;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Categories'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add Category',
            onPressed: () => _showCategoryDialog(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: categories.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.category_outlined,
                      size: 64, color: isDark ? Colors.grey[700] : Colors.grey[300]),
                  const SizedBox(height: 16),
                  const Text('No categories available',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    onPressed: () => _showCategoryDialog(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Category'),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: categories.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (ctx, index) {
                final cat = categories[index];
                final count = provider.getExpenseCountForCategory(cat.id);

                return Card(
                  child: ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    leading: CircleAvatar(
                      radius: 20,
                      backgroundColor: cat.color.withOpacity(0.18),
                      child: Icon(cat.icon, color: cat.color, size: 20),
                    ),
                    title: Text(
                      cat.name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    subtitle: Text(
                      '$count ${count == 1 ? 'logged expense' : 'logged expenses'}',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 20),
                          tooltip: 'Edit',
                          onPressed: () =>
                              _showCategoryDialog(context, categoryToEdit: cat),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline,
                              size: 20, color: Colors.redAccent),
                          tooltip: 'Delete',
                          onPressed: () => _showDeleteCategoryDialog(context, cat),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCategoryDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('New Category'),
      ),
    );
  }
}
