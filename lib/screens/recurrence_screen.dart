import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/event.dart';

class RecurrenceScreen extends ConsumerStatefulWidget {
  final RecurrenceRule initialRule;
  final DateTime startDate;

  const RecurrenceScreen({
    super.key,
    required this.initialRule,
    required this.startDate,
  });

  @override
  ConsumerState<RecurrenceScreen> createState() => _RecurrenceScreenState();
}

class _RecurrenceScreenState extends ConsumerState<RecurrenceScreen> {
  late RecurrenceRule _rule;
  
  // Local controllers for numeric inputs
  final TextEditingController _intervalController = TextEditingController();
  final TextEditingController _countController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _rule = widget.initialRule;
    _intervalController.text = _rule.interval.toString();
    _countController.text = (_rule.count ?? 1).toString();
    
    // Default initializations if missing
    if (_rule.type == RecurrenceType.weekly && (_rule.daysOfWeek == null || _rule.daysOfWeek!.isEmpty)) {
      _rule = _rule.copyWith(daysOfWeek: [widget.startDate.weekday]);
    } else if (_rule.type == RecurrenceType.monthly && (_rule.daysOfMonth == null || _rule.daysOfMonth!.isEmpty)) {
      _rule = _rule.copyWith(daysOfMonth: [widget.startDate.day]);
    } else if (_rule.type == RecurrenceType.yearly && (_rule.monthsOfYear == null || _rule.monthsOfYear!.isEmpty)) {
      _rule = _rule.copyWith(monthsOfYear: [widget.startDate.month], daysOfMonth: [widget.startDate.day]);
    }
  }
  
  @override
  void dispose() {
    _intervalController.dispose();
    _countController.dispose();
    super.dispose();
  }

  void _updateType(RecurrenceType type) {
    setState(() {
      List<int>? daysOfWeek;
      List<int>? daysOfMonth;
      List<int>? monthsOfYear;
      
      if (type == RecurrenceType.weekly) {
        daysOfWeek = [widget.startDate.weekday];
      } else if (type == RecurrenceType.monthly) {
        daysOfMonth = [widget.startDate.day];
      } else if (type == RecurrenceType.yearly) {
        monthsOfYear = [widget.startDate.month];
        daysOfMonth = [widget.startDate.day];
      }
      
      _rule = _rule.copyWith(
        type: type,
        interval: 1,
        daysOfWeek: daysOfWeek,
        daysOfMonth: daysOfMonth,
        monthsOfYear: monthsOfYear,
      );
      _intervalController.text = '1';
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // Text Color: White in Dark, Black in Light (except Sundays)
    final mainTextColor = theme.textTheme.bodyLarge?.color ?? (isDark ? Colors.white : Colors.black);
    final sundayColor = Colors.blue;
    final accentBlue = Colors.blue;
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor, 
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: mainTextColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Repeat', style: TextStyle(color: mainTextColor, fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        children: [
          // Don't Repeat
          _buildRecurrenceOption(
            title: 'Don\'t repeat',
            value: RecurrenceType.none,
            groupValue: _rule.type,
            onChanged: (val) => _updateType(val!),
            textColor: mainTextColor,
            accentColor: accentBlue,
          ),
          
          const SizedBox(height: 16),
          
          // Daily
          _buildIntervalOption(
            type: RecurrenceType.daily,
            label: 'day',
            textColor: mainTextColor,
            accentColor: accentBlue,
          ),
          
          const SizedBox(height: 16),

          // Weekly
          _buildIntervalOption(
            type: RecurrenceType.weekly,
            label: 'week',
            textColor: mainTextColor,
            accentColor: accentBlue,
            child: _rule.type == RecurrenceType.weekly ? _buildWeekdaysSelector(sundayColor, accentBlue) : null,
          ),
          
          const SizedBox(height: 16),
          
          // Monthly
          _buildIntervalOption(
            type: RecurrenceType.monthly,
            label: 'month',
            textColor: mainTextColor,
            accentColor: accentBlue,
            child: _rule.type == RecurrenceType.monthly ? _buildMonthlySelector(accentBlue) : null,
          ),
          
          const SizedBox(height: 16),
          
          // Yearly
          _buildIntervalOption(
            type: RecurrenceType.yearly,
            label: 'year',
            textColor: mainTextColor,
            accentColor: accentBlue,
            child: _rule.type == RecurrenceType.yearly ? _buildYearlySelector(accentBlue) : null,
          ),
          
          const SizedBox(height: 32),
          
          // Duration Section
          if (_rule.isRecurring) ...[
            Text('Duration', style: TextStyle(color: isDark ? Colors.grey : Colors.grey[700], fontSize: 14)),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: isDark ? null : [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))],
              ),
              child: Column(
                children: [
                  _buildDurationOption(RecurrenceEndType.never, 'Forever', textColor: mainTextColor, accentColor: accentBlue),
                  Divider(height: 1, color: theme.dividerColor.withValues(alpha: 0.1)),
                  _buildDurationOption(RecurrenceEndType.afterCount, 'Specific number of times', showCountInput: true, textColor: mainTextColor, accentColor: accentBlue),
                  Divider(height: 1, color: theme.dividerColor.withValues(alpha: 0.1)),
                  _buildDurationOption(RecurrenceEndType.onDate, _rule.endType == RecurrenceEndType.onDate && _rule.endDate != null 
                    ? 'Until ${DateFormat('EEE, d MMM, yyyy').format(_rule.endDate!)}' 
                    : 'Until',
                    showDateConfig: true,
                    textColor: mainTextColor,
                    accentColor: accentBlue,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: accentBlue,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          onPressed: () => Navigator.pop(context, _rule),
          child: const Text('Back', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
  
  Widget _buildRecurrenceOption({
    required String title,
    required RecurrenceType value,
    required RecurrenceType groupValue,
    required ValueChanged<RecurrenceType?> onChanged,
    required Color textColor,
    required Color accentColor,
  }) {
    final isSelected = value == groupValue;
    return GestureDetector(
      onTap: () => onChanged(value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        color: Colors.transparent,
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? accentColor : Colors.grey,
            ),
            const SizedBox(width: 16),
            Text(title, style: TextStyle(color: textColor, fontSize: 16)),
          ],
        ),
      ),
    );
  }

  Widget _buildIntervalOption({
    required RecurrenceType type,
    required String label,
    required Color textColor,
    required Color accentColor,
    Widget? child,
  }) {
    final isSelected = _rule.type == type;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => _updateType(type),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            color: Colors.transparent,
            child: Row(
              children: [
                Icon(
                  isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                  color: isSelected ? accentColor : Colors.grey,
                ),
                const SizedBox(width: 16),
                Text('Every ', style: TextStyle(color: textColor, fontSize: 16)),
                if (isSelected) 
                  Container(
                    width: 50,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: accentColor, width: 2)),
                    ),
                    child: TextField(
                      controller: _intervalController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(type == RecurrenceType.daily ? 3 : 2),
                      ],
                      textAlign: TextAlign.center,
                      cursorColor: accentColor,
                      style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.bold),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                         isDense: true,
                         contentPadding: EdgeInsets.zero,
                      ),
                      onChanged: (val) {
                        if (val.isEmpty) return;
                        final interval = int.tryParse(val);
                        int max = 99;
                        if (type == RecurrenceType.daily) max = 999;
                        
                        if (interval != null && interval > 0) {
                          if (interval > max) {
                            _intervalController.text = max.toString();
                            _intervalController.selection = TextSelection.fromPosition(TextPosition(offset: _intervalController.text.length));
                            setState(() => _rule = _rule.copyWith(interval: max));
                          } else {
                            setState(() => _rule = _rule.copyWith(interval: interval));
                          }
                        }
                      },
                    ),
                  )
                else
                   const Text('1   ', style: TextStyle(color: Colors.grey, fontSize: 16)), // Placeholder space
                
                Text(label, style: TextStyle(color: textColor, fontSize: 16)),
              ],
            ),
          ),
        ),
        if (isSelected && child != null) ...[
          Padding(
            padding: const EdgeInsets.only(left: 40, top: 4), // Indent below radio
            child: child,
          ),
        ],
      ],
    ); 
  }

  Widget _buildWeekdaysSelector(Color sundayColor, Color selectedColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Text('Repeat on', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(7, (index) {
            final day = index + 1;
            final isSelected = _rule.daysOfWeek?.contains(day) ?? false;
            final isSunday = day == 7;
            
            Color textColor;
            if (isSelected) {
              textColor = Colors.white;
            } else if (isSunday) {
              textColor = Colors.redAccent;
            } else {
              final isDark = Theme.of(context).brightness == Brightness.dark;
              textColor = isDark ? Colors.white70 : Colors.black87; 
            }
            
            return GestureDetector(
              onTap: () {
                final currentDays = Set<int>.from(_rule.daysOfWeek ?? []);
                if (isSelected) {
                  currentDays.remove(day);
                } else {
                  currentDays.add(day);
                }
                setState(() => _rule = _rule.copyWith(daysOfWeek: currentDays.toList()));
              },
              child: Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected ? selectedColor : (Theme.of(context).brightness == Brightness.dark ? Colors.white10 : Colors.grey[100]), 
                  shape: BoxShape.circle,
                ),
                child: Text(
                  ['M', 'T', 'W', 'T', 'F', 'S', 'S'][index],
                  style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildMonthlySelector(Color selectedColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: Text('Repeat on days', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: List.generate(31, (index) {
            final day = index + 1;
            final isSelected = _rule.daysOfMonth?.contains(day) ?? false;
            return GestureDetector(
              onTap: () {
                final current = Set<int>.from(_rule.daysOfMonth ?? []);
                if (isSelected) {
                  current.remove(day);
                } else {
                  current.add(day);
                }
                setState(() => _rule = _rule.copyWith(daysOfMonth: current.toList()));
              },
              child: Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected ? selectedColor : (Theme.of(context).brightness == Brightness.dark ? Colors.white10 : Colors.grey[100]),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('$day', style: TextStyle(color: isSelected ? Colors.white : null, fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildYearlySelector(Color selectedColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: Text('Repeat in months', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: List.generate(12, (index) {
            final month = index + 1;
            final isSelected = _rule.monthsOfYear?.contains(month) ?? false;
            return GestureDetector(
              onTap: () {
                final current = Set<int>.from(_rule.monthsOfYear ?? []);
                if (isSelected) {
                  current.remove(month);
                } else {
                  current.add(month);
                }
                setState(() => _rule = _rule.copyWith(monthsOfYear: current.toList()));
              },
              child: Container(
                width: 50,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected ? selectedColor : (Theme.of(context).brightness == Brightness.dark ? Colors.white10 : Colors.grey[100]),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][index], 
                  style: TextStyle(color: isSelected ? Colors.white : null, fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
              ),
            );
          }),
        ),
        const SizedBox(height: 16),
        _buildMonthlySelector(selectedColor),
      ],
    );
  }

  Widget _buildDurationOption(RecurrenceEndType type, String title, {bool showCountInput = false, bool showDateConfig = false, required Color textColor, required Color accentColor}) {
     final isSelected = _rule.endType == type;

     return InkWell(
        onTap: () async {
          if (showDateConfig) {
             final picked = await showDatePicker(
                  context: context, 
                  initialDate: _rule.endDate ?? DateTime.now(), 
                  firstDate: DateTime(2020), 
                  lastDate: DateTime(2040),
                  builder: (context, child) => Theme(data: Theme.of(context), child: child!)
             );
             if (picked != null) {
               setState(() {
                 _rule = _rule.copyWith(endType: type, endDate: picked);
               });
             } else {
               setState(() => _rule = _rule.copyWith(endType: type));
             }
          } else {
             setState(() => _rule = _rule.copyWith(endType: type));
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Icon(
                isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                color: isSelected ? accentColor : Colors.grey,
              ),
              const SizedBox(width: 16),
              Expanded(child: Text(title, style: TextStyle(color: textColor, fontSize: 16))),
               
              if (isSelected && showCountInput)
                  Container(
                    width: 60,
                    margin: const EdgeInsets.only(left: 8),
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: accentColor, width: 2)),
                    ),
                    child: TextField(
                      controller: _countController,
                       keyboardType: TextInputType.number,
                       inputFormatters: [
                         FilteringTextInputFormatter.digitsOnly,
                         LengthLimitingTextInputFormatter(3),
                       ],
                       textAlign: TextAlign.center,
                       cursorColor: accentColor,
                       style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.bold),
                       decoration: const InputDecoration(
                         border: InputBorder.none,
                         isDense: true,
                         contentPadding: EdgeInsets.zero,
                       ),
                       onChanged: (val) {
                          if (val.isEmpty) return;
                          final count = int.tryParse(val);
                          if (count != null && count > 0) {
                             if (count > 999) {
                               _countController.text = '999';
                               _countController.selection = TextSelection.fromPosition(const TextPosition(offset: 3));
                               setState(() => _rule = _rule.copyWith(count: 999));
                             } else {
                               setState(() => _rule = _rule.copyWith(count: count));
                             }
                          }
                       },
                    ),
                  ),

              if (showDateConfig && _rule.endDate != null)
                 const SizedBox(),
            ],
          ),
        ),
     );
  }
}
