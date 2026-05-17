import 'package:couple_note/core/constants/trans_keys.dart';
import 'package:couple_note/core/config/theme/app_colors.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class CustomDateTimePicker {
  static Future<DateTime?> show({
    required BuildContext context,
    DateTime? initialDate,
    DateTime? firstDate,
    DateTime? lastDate,
    bool includeTime = false,
    String title = 'Choose date',
    Color? primaryColor,
    Color? backgroundColor,
  }) async {
    final now = DateTime.now();
    final defaultFirstDate = firstDate ?? now;
    final defaultLastDate = lastDate ?? now.add(const Duration(days: 365));
    final defaultInitialDate = initialDate ?? now.add(const Duration(days: 1));
    return await showDialog<DateTime>(
      context: context,
      builder: (BuildContext context) {
        return _CustomDateTimePickerDialog(
          initialDate: defaultInitialDate,
          firstDate: defaultFirstDate,
          lastDate: defaultLastDate,
          includeTime: includeTime,
          title: title,
          primaryColor: primaryColor,
          backgroundColor: backgroundColor,
        );
      },
    );
  }
}

class _CustomDateTimePickerDialog extends StatefulWidget {
  final DateTime? initialDate;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final bool includeTime;
  final String title;
  final Color? primaryColor;
  final Color? backgroundColor;

  const _CustomDateTimePickerDialog({
    this.initialDate,
    this.firstDate,
    this.lastDate,
    required this.includeTime,
    required this.title,
    this.primaryColor,
    this.backgroundColor,
  });

  @override
  State<_CustomDateTimePickerDialog> createState() =>
      _CustomDateTimePickerDialogState();
}

class _CustomDateTimePickerDialogState
    extends State<_CustomDateTimePickerDialog> {
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  int _currentStep = 0;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDate = widget.initialDate ?? now;
    _selectedTime = TimeOfDay.fromDateTime(_selectedDate);
  }

  Color get _primaryColor => widget.primaryColor ?? AppColors.primary;
  Color get _backgroundColor =>
      widget.backgroundColor ?? Theme.of(context).cardColor;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: _backgroundColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            if (widget.includeTime) _buildStepIndicator(),
            Flexible(child: _buildDatePicker()),
            _buildActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _primaryColor.withValues(alpha: 0.1),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          Icon(
            widget.includeTime ? Icons.schedule : Icons.calendar_today,
            color: _primaryColor,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _primaryColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _getSelectedDateTimeText(),
                  style: TextStyle(
                    fontSize: 14,
                    color: _primaryColor.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator() {
    if (!widget.includeTime) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          _buildStepItem(0, TransKeys.date.tr(), Icons.calendar_today),
          Expanded(
            child: Container(
              height: 2,
              margin: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: _currentStep > 0 ? _primaryColor : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ),
          _buildStepItem(1, TransKeys.hour.tr(), Icons.access_time),
        ],
      ),
    );
  }

  Widget _buildStepItem(int step, String label, IconData icon) {
    final isActive = _currentStep == step;
    final isCompleted = _currentStep > step;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isActive || isCompleted ? _primaryColor : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isActive || isCompleted ? _primaryColor : Colors.grey.shade300,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: isActive || isCompleted ? Colors.white : Colors.grey,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isActive || isCompleted ? Colors.white : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDatePicker() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(
            primary: _primaryColor,
            surface: _backgroundColor,
          ),
        ),
        child: CalendarDatePicker(
          initialDate: _selectedDate,
          firstDate: widget.firstDate ?? DateTime(2020),
          lastDate: widget.lastDate ?? DateTime(2030),
          onDateChanged: (date) {
            setState(() {
              _selectedDate = date;
            });
          },
        ),
      ),
    );
  }

  Widget _buildActions() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (widget.includeTime && _currentStep > 0)
            TextButton(
              onPressed: () {
                setState(() {
                  _currentStep = 0;
                });
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.arrow_back, size: 16, color: _primaryColor),
                  const SizedBox(width: 4),
                  Text(
                    TransKeys.back.tr(),
                    style: TextStyle(color: _primaryColor),
                  ),
                ],
              ),
            )
          else
            const SizedBox.shrink(),
          Row(
            children: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  TransKeys.cancel.tr(),
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: _handleConfirm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  widget.includeTime && _currentStep == 0
                      ? TransKeys.continuee.tr()
                      : TransKeys.confirm.tr(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _handleConfirm() async {
    if (widget.includeTime && _currentStep == 0) {
      final pickedTime = await _showTimePickerDirect();
      if (pickedTime != null) {
        setState(() {
          _selectedTime = pickedTime;
        });
        final result = DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
          _selectedTime.hour,
          _selectedTime.minute,
        );
        Navigator.of(context).pop(result);
      }
    } else {
      final result = widget.includeTime
          ? DateTime(
              _selectedDate.year,
              _selectedDate.month,
              _selectedDate.day,
              _selectedTime.hour,
              _selectedTime.minute,
            )
          : _selectedDate;
      Navigator.of(context).pop(result);
    }
  }

  Future<TimeOfDay?> _showTimePickerDirect() async {
    return await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(
              context,
            ).colorScheme.copyWith(primary: _primaryColor),
          ),
          child: child!,
        );
      },
    );
  }

  String _getSelectedDateTimeText() {
    if (widget.includeTime) {
      return '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year} ${_selectedTime.format(context)}';
    } else {
      return '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}';
    }
  }
}
