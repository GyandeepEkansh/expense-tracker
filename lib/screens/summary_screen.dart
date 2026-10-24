import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/expense_provider.dart';

enum SummaryRangePreset { today, last7Days, last30Days, custom }

class SummaryScreen extends StatefulWidget {
  const SummaryScreen({super.key});

  @override
  State<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends State<SummaryScreen> {
  SummaryRangePreset _preset = SummaryRangePreset.last30Days;
  late DateTime _startDate;
  late DateTime _endDate;
  int _touchedIndex = -1;

  @override
  void initState() {
    super.initState();
    _applyPreset(SummaryRangePreset.last30Days);
  }

  void _applyPreset(SummaryRangePreset preset) {
    final now = DateTime.now();
    setState(() {
      _preset = preset;
      switch (preset) {
        case SummaryRangePreset.today:
          _startDate = DateTime(now.year, now.month, now.day);
          _endDate = DateTime(now.year, now.month, now.day);
          break;
        case SummaryRangePreset.last7Days:
          _startDate = now.subtract(const Duration(days: 6));
          _endDate = now;
          break;
        case SummaryRangePreset.last30Days:
          _startDate = now.subtract(const Duration(days: 29));
          _endDate = now;
          break;
        case SummaryRangePreset.custom:
          // Keep current dates
          break;
      }
    });
  }

  Future<void> _pickCustomRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      helpText: 'Select Range (Max 31 Days)',
    );

    if (picked != null) {
      final days = picked.end.difference(picked.start).inDays + 1;
      if (days > 31) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Date range cannot exceed 31 days. Please select up to 1 month.'),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }
      setState(() {
        _preset = SummaryRangePreset.custom;
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;
    final provider = context.watch<ExpenseProvider>();

    final summaries = provider.getCategorySummaries(_startDate, _endDate);
    final grandTotal = provider.getTotalForRange(_startDate, _endDate);

    final currencyFormat = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    );

    final dateFormat = DateFormat('d MMM');
    final rangeText = isSameDay(_startDate, _endDate)
        ? DateFormat('d MMMM yyyy').format(_startDate)
        : '${dateFormat.format(_startDate)} - ${dateFormat.format(_endDate)} (${_endDate.difference(_startDate).inDays + 1} days)';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Spending Summary'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Preset Filter Chips
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildPresetChip('Today', SummaryRangePreset.today),
                    const SizedBox(width: 8),
                    _buildPresetChip('7 Days', SummaryRangePreset.last7Days),
                    const SizedBox(width: 8),
                    _buildPresetChip('30 Days', SummaryRangePreset.last30Days),
                    const SizedBox(width: 8),
                    ActionChip(
                      avatar: const Icon(Icons.date_range, size: 16),
                      label: Text(
                        _preset == SummaryRangePreset.custom ? 'Custom ✓' : 'Custom (Max 31d)',
                        style: TextStyle(
                          fontWeight: _preset == SummaryRangePreset.custom
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      onPressed: _pickCustomRange,
                    ),
                  ],
                ),
              ),
            ),

            // Date Range Display Card with Total
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      rangeText,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      currencyFormat.format(grandTotal),
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                    Text(
                      'Total Cumulative Spend',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.grey[400] : Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            if (summaries.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.pie_chart_outline_rounded,
                        size: 64,
                        color: isDark ? Colors.grey[700] : Colors.grey[300],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No expenses found for this period',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Try picking a different date range or log an expense.',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.grey[500] : Colors.grey[500],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            else ...[
              // Donut Chart
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const Text(
                        'Category Breakdown',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        height: 200,
                        child: PieChart(
                          PieChartData(
                            pieTouchData: PieTouchData(
                              touchCallback: (event, pieTouchResponse) {
                                setState(() {
                                  if (!event.isInterestedForInteractions ||
                                      pieTouchResponse == null ||
                                      pieTouchResponse.touchedSection == null) {
                                    _touchedIndex = -1;
                                    return;
                                  }
                                  _touchedIndex = pieTouchResponse
                                      .touchedSection!.touchedSectionIndex;
                                });
                              },
                            ),
                            borderData: FlBorderData(show: false),
                            sectionsSpace: 3,
                            centerSpaceRadius: 55,
                            sections: List.generate(summaries.length, (i) {
                              final isTouched = i == _touchedIndex;
                              final radius = isTouched ? 45.0 : 38.0;
                              final item = summaries[i];
                              return PieChartSectionData(
                                color: item.category.color,
                                value: item.totalAmount,
                                title: isTouched ? '${item.percentage.toStringAsFixed(1)}%' : '',
                                radius: radius,
                                titleStyle: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              );
                            }),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),

              // Categories List
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Text(
                  'Spending by Category (${summaries.length})',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),

              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                itemCount: summaries.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (ctx, i) {
                  final item = summaries[i];
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14.0),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: item.category.color.withOpacity(0.18),
                                child: Icon(
                                  item.category.icon,
                                  color: item.category.color,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.category.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                    Text(
                                      '${item.count} ${item.count == 1 ? 'entry' : 'entries'} • ${item.percentage.toStringAsFixed(1)}%',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                currencyFormat.format(item.totalAmount),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          // Linear progress bar for percentage
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: item.percentage / 100,
                              minHeight: 6,
                              backgroundColor: isDark
                                  ? Colors.grey[800]
                                  : Colors.grey[200],
                              valueColor: AlwaysStoppedAnimation<Color>(item.category.color),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 32),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPresetChip(String label, SummaryRangePreset preset) {
    final isSel = _preset == preset;
    return ChoiceChip(
      label: Text(label),
      selected: isSel,
      onSelected: (val) {
        if (val) _applyPreset(preset);
      },
    );
  }

  bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
