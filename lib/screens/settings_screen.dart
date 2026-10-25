import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/expense_provider.dart';
import '../providers/settings_provider.dart';
import '../services/file_service.dart';
import '../widgets/pin_lock_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  void _showPinSetup(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => PinLockScreen(
          isSetupMode: true,
          onPinCreated: (pin) {
            context.read<SettingsProvider>().setAppLock(enabled: true, pin: pin);
            Navigator.pop(ctx);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('App lock PIN configured successfully!')),
            );
          },
        ),
      ),
    );
  }

  void _showRestoreDialog(BuildContext context) {
    final textCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restore from Backup'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FilledButton.icon(
              icon: const Icon(Icons.folder_open),
              label: const Text('Pick Backup File (.json)'),
              onPressed: () async {
                final jsonContent = await FileService().pickBackupFile();
                if (jsonContent != null && jsonContent.isNotEmpty) {
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (context.mounted) {
                    final messenger = ScaffoldMessenger.of(context);
                    final success = await context
                        .read<ExpenseProvider>()
                        .importBackupJson(jsonContent);
                    if (!context.mounted) return;
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(success
                            ? 'Data restored successfully from file!'
                            : 'Failed to restore: Invalid backup data format.'),
                        backgroundColor: success ? Colors.green : Colors.red,
                      ),
                    );
                  }
                }
              },
            ),
            const SizedBox(height: 16),
            const Row(
              children: [
                Expanded(child: Divider()),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text('OR PASTE JSON', style: TextStyle(fontSize: 11, color: Colors.grey)),
                ),
                Expanded(child: Divider()),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: textCtrl,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Paste backup JSON here...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final text = textCtrl.text.trim();
              if (text.isNotEmpty) {
                final success =
                    await context.read<ExpenseProvider>().importBackupJson(text);
                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(success
                          ? 'Data restored successfully!'
                          : 'Failed to restore: Invalid backup data format.'),
                      backgroundColor: success ? Colors.green : Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Restore from Text'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAllDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete All Data?'),
        content: const Text(
          'This action is irreversible! All your logged expenses, custom categories, and records will be deleted permanently.',
          style: TextStyle(color: Colors.redAccent),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              context.read<ExpenseProvider>().wipeAllData();
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('All data wiped successfully.')),
              );
            },
            child: const Text('Delete Everything'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    final settings = context.watch<SettingsProvider>();
    final expenseProvider = context.read<ExpenseProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // APPEARANCE SECTION
          _buildSectionHeader('Appearance'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.palette_outlined),
                  title: const Text('Theme'),
                  subtitle: Text(
                    settings.themeMode == ThemeMode.light
                        ? 'Light'
                        : settings.themeMode == ThemeMode.dark
                            ? 'Dark'
                            : 'System Default',
                  ),
                  trailing: DropdownButton<ThemeMode>(
                    value: settings.themeMode,
                    underline: const SizedBox(),
                    items: const [
                      DropdownMenuItem(
                          value: ThemeMode.system, child: Text('System')),
                      DropdownMenuItem(
                          value: ThemeMode.light, child: Text('Light')),
                      DropdownMenuItem(
                          value: ThemeMode.dark, child: Text('Dark')),
                    ],
                    onChanged: (val) {
                      if (val != null) settings.setThemeMode(val);
                    },
                  ),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.calendar_view_week_outlined),
                  title: const Text('First Day of the Week'),
                  subtitle: Text(
                      settings.firstDayOfWeek == 7 ? 'Sunday' : 'Monday'),
                  trailing: DropdownButton<int>(
                    value: settings.firstDayOfWeek,
                    underline: const SizedBox(),
                    items: const [
                      DropdownMenuItem(value: 7, child: Text('Sunday')),
                      DropdownMenuItem(value: 1, child: Text('Monday')),
                    ],
                    onChanged: (val) {
                      if (val != null) settings.setFirstDayOfWeek(val);
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // SECURITY SECTION
          _buildSectionHeader('Security'),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  secondary: const Icon(Icons.lock_outline),
                  title: const Text('App Lock'),
                  subtitle: Text(settings.isAppLockEnabled
                      ? 'Protected by 4-digit PIN / Biometrics'
                      : 'Disabled'),
                  value: settings.isAppLockEnabled,
                  onChanged: (val) {
                    if (val) {
                      _showPinSetup(context);
                    } else {
                      settings.setAppLock(enabled: false);
                    }
                  },
                ),
                if (settings.isAppLockEnabled) ...[
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.pin_outlined),
                    title: const Text('Change PIN'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showPinSetup(context),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.timer_outlined),
                    title: const Text('Lock Delay'),
                    subtitle: Text(
                      settings.lockDelayMinutes == 0
                          ? 'Immediately'
                          : '${settings.lockDelayMinutes} minute${settings.lockDelayMinutes == 1 ? '' : 's'}',
                    ),
                    trailing: DropdownButton<int>(
                      value: settings.lockDelayMinutes,
                      underline: const SizedBox(),
                      items: const [
                        DropdownMenuItem(value: 0, child: Text('Immediately')),
                        DropdownMenuItem(value: 1, child: Text('1 minute')),
                        DropdownMenuItem(value: 5, child: Text('5 minutes')),
                      ],
                      onChanged: (val) {
                        if (val != null) settings.setLockDelayMinutes(val);
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // REMINDERS SECTION
          _buildSectionHeader('Reminders'),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  secondary: const Icon(Icons.notifications_active_outlined),
                  title: const Text('Daily Expense Reminder'),
                  subtitle: Text(settings.isReminderEnabled
                      ? 'Scheduled daily at ${settings.reminderTime}'
                      : 'Disabled'),
                  value: settings.isReminderEnabled,
                  onChanged: (val) async {
                    final granted = await settings.setReminder(enabled: val);
                    if (val && !granted && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                              'Notification permission denied. Please enable in phone settings.'),
                        ),
                      );
                    }
                  },
                ),
                if (settings.isReminderEnabled) ...[
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.access_time_outlined),
                    title: const Text('Reminder Time'),
                    trailing: TextButton(
                      onPressed: () async {
                        final parts = settings.reminderTime.split(':');
                        final initial = TimeOfDay(
                          hour: int.tryParse(parts[0]) ?? 21,
                          minute: int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0,
                        );
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: initial,
                        );
                        if (picked != null) {
                          final formatted =
                              '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
                          await settings.setReminder(enabled: true, time: formatted);
                        }
                      },
                      child: Text(
                        settings.reminderTime,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // DATA & BACKUP SECTION
          _buildSectionHeader('Data & Backup'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.file_download_outlined),
                  title: const Text('Export CSV Report (.csv)'),
                  subtitle: const Text('Exports real spreadsheet file with all expenses'),
                  trailing: const Icon(Icons.share_outlined),
                  onTap: () async {
                    final csv = expenseProvider.generateCsv();
                    final fileName =
                        'Expense_Report_${DateTime.now().toIso8601String().substring(0, 10)}.csv';
                    final ok = await FileService().exportCsv(csv, fileName);
                    if (ok && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('CSV Report exported successfully!')),
                      );
                    }
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.cloud_upload_outlined),
                  title: const Text('Backup Data (.json file)'),
                  subtitle: const Text('Exports real JSON backup file to save or share'),
                  trailing: const Icon(Icons.file_upload_outlined),
                  onTap: () async {
                    final jsonString = expenseProvider.exportBackupJson();
                    final fileName =
                        'ExpenseTracker_Backup_${DateTime.now().toIso8601String().substring(0, 10)}.json';
                    final ok = await FileService().exportBackupJson(jsonString, fileName);
                    if (ok && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Backup file exported successfully!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.cloud_download_outlined),
                  title: const Text('Restore from Backup'),
                  subtitle: const Text('Pick a .json backup file from storage'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showRestoreDialog(context),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.delete_forever_outlined, color: Colors.redAccent),
                  title: const Text('Delete All Data',
                      style: TextStyle(color: Colors.redAccent)),
                  subtitle: const Text('Permanently erase all records'),
                  onTap: () => _showDeleteAllDialog(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // GENERAL SECTION
          _buildSectionHeader('General'),
          Card(
            child: Column(
              children: [
                const ListTile(
                  leading: Icon(Icons.currency_rupee),
                  title: Text('Default Currency'),
                  trailing: Text('₹ INR', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                const Divider(),
                const ListTile(
                  leading: Icon(Icons.info_outline),
                  title: Text('Version'),
                  trailing: Text('1.0.0 (Release)'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.0,
          color: Colors.grey,
        ),
      ),
    );
  }
}
