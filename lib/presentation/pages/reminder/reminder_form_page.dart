import 'dart:io';

import 'package:couple_note/core/constants/trans_keys.dart';
import 'package:couple_note/core/services/Admob/interstitial_ad_manager.dart';
import 'package:couple_note/core/services/alarm/alarm_service.dart';
import 'package:couple_note/core/services/fcm_service.dart';
import 'package:couple_note/core/utils/datetime_utils.dart';
import 'package:couple_note/presentation/widgets/base/date_picker.dart';
import 'package:couple_note/presentation/widgets/base/snackbar.dart';
import 'package:couple_note/providers/auth_provider.dart';
import 'package:couple_note/providers/connect_provider.dart';
import 'package:couple_note/providers/reminder_provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:couple_note/core/config/app_constants.dart';
import 'package:couple_note/presentation/themes/app_colors.dart';
import 'package:couple_note/domain/entities/reminder.dart';

class ReminderFormPage extends ConsumerStatefulWidget {
  final ReminderEntity? reminder;
  final bool isViewOnly;
  const ReminderFormPage({super.key, this.reminder, this.isViewOnly = false});

  @override
  ConsumerState<ReminderFormPage> createState() => _ReminderFormPageState();
}

class _ReminderFormPageState extends ConsumerState<ReminderFormPage>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  late DateTime _reminderDate;
  TimeOfDay _selectedTime = TimeOfDay.now();
  Set<int> _selectedDays = {};
  AssigneeType _assignee = AssigneeType.me;

  bool _isSubmitting = false;
  bool _isSelectedDays = false;
  bool _isAlarmSoundEnabled = true;
  bool _isVibrate = true;

  bool get _isEditMode => widget.reminder != null;
  bool get _isReminderInactiveNonRecurring {
    if (!_isEditMode) return false;
    final reminder = widget.reminder!;
    return reminder.recurringType == RecurringType.none &&
        (reminder.reminderStatus == ReminderStatus.done ||
            reminder.reminderStatus == ReminderStatus.overdue);
  }

  final InterstitialAdManager _adManager = InterstitialAdManager();

  @override
  void initState() {
    super.initState();
    _adManager.loadAd();
    _initializeAnimation();
    if (_isEditMode) {
      _loadReminderData();
    } else {
      _reminderDate = DateTime.now();
      _updateReminderDateBasedOnTime();
      final reminderState = ref.read(reminderListViewModelProvider);

      if (reminderState.currentTab == 'mine') {
        _assignee = AssigneeType.me;
      } else if (reminderState.currentTab == 'partner') {
        _assignee = AssigneeType.lover;
      } else {
        _assignee = AssigneeType.couple;
      }
    }
  }

  void _initializeAnimation() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _fadeController.forward();
  }

  void _loadReminderData() {
    final reminder = widget.reminder!;
    _titleController.text = reminder.title;
    _selectedTime = TimeOfDay.fromDateTime(reminder.reminderDate);

    if (_isReminderInactiveNonRecurring) {
      final now = DateTime.now();
      final reminderTime = TimeOfDay.fromDateTime(reminder.reminderDate);
      final todayWithReminderTime = DateTime(
        now.year,
        now.month,
        now.day,
        reminderTime.hour,
        reminderTime.minute,
      );

      if (todayWithReminderTime.isAfter(now)) {
        _reminderDate = todayWithReminderTime;
      } else {
        _reminderDate = todayWithReminderTime.add(const Duration(days: 1));
      }
    } else {
      _reminderDate = reminder.reminderDate;
    }

    _selectedDays = reminder.days ?? {};
    _isSelectedDays = _selectedDays.isNotEmpty;
    _isAlarmSoundEnabled = reminder.isSound;
    _isVibrate = reminder.isVibrate;

    _assignee = _determineVisibilityFromReminder(reminder);
  }

  AssigneeType _determineVisibilityFromReminder(ReminderEntity reminder) {
    final currentUser = ref.read(currentUserProvider);
    final partner = ref.read(partnerProvider).value?.data;

    if (reminder.isPrivate) {
      return AssigneeType.private;
    }

    if (reminder.ownerId == currentUser?.uid) {
      return AssigneeType.me;
    }

    if (reminder.ownerId == partner?.uid) {
      return AssigneeType.lover;
    }

    return AssigneeType.couple;
  }

  @override
  void dispose() {
    _adManager.dispose();
    _titleController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Form(key: _formKey, child: _buildForm()),
              ),
            ),
          ),
          if (!widget.isViewOnly) _buildBottomActionBar(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.arrow_back, size: 20, color: Colors.black87),
        ),
      ),
      title: Text(
        widget.isViewOnly
            ? TransKeys.detailed_information.tr()
            : _isEditMode
            ? TransKeys.edit_reminder.tr()
            : TransKeys.set_new_reminder.tr(),
        style: const TextStyle(
          color: Colors.black87,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      actions: [
        if (_isEditMode &&
            _getOwnerId() != ref.read(partnerProvider).value?.data?.uid) ...[
          IconButton(
            onPressed: _handleDeleteReminder,
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.delete_outline,
                size: 20,
                color: Colors.red[400],
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ],
    );
  }

  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTimePicker(),
        const SizedBox(height: 24),
        _buildDateSelector(),
        const SizedBox(height: 16),
        _buildDaySelector(),
        const SizedBox(height: 24),
        _buildTitleField(),
        const SizedBox(height: 24),

        _buildAlarmSoundToggle(),
        const SizedBox(height: 12),
        _buildSnoozeToggle(),
        const SizedBox(height: 12),
        _buildVisibilitySetting(),
        const SizedBox(height: 12),
        if (_assignee == AssigneeType.couple) ...[
          _buildWarning(),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _buildTimePicker() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildScrollableTimeUnit(
          value: _selectedTime.hour,
          onChanged: (newHour) {
            setState(() {
              _selectedTime = TimeOfDay(
                hour: newHour,
                minute: _selectedTime.minute,
              );
              _updateReminderDateBasedOnTime();
            });
          },
          maxValue: 23,
        ),
        _buildTimeSeparator(),
        _buildScrollableTimeUnit(
          value: _selectedTime.minute,
          onChanged: (newMinute) {
            setState(() {
              _selectedTime = TimeOfDay(
                hour: _selectedTime.hour,
                minute: newMinute,
              );
              _updateReminderDateBasedOnTime();
            });
          },
          maxValue: 59,
        ),
      ],
    );
  }

  Widget _buildScrollableTimeUnit({
    required int value,
    required Function(int) onChanged,
    required int maxValue,
  }) {
    final total = maxValue + 1;
    final scrollController = FixedExtentScrollController(
      initialItem: value + total * 1000,
    );

    return Container(
      height: 140,
      width: 80,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Stack(
        children: [
          _buildTimeUnitHighlight(),
          ListWheelScrollView.useDelegate(
            controller: scrollController,
            itemExtent: 60,
            physics: const FixedExtentScrollPhysics(),
            onSelectedItemChanged: (index) {
              final mod = index % total;
              onChanged(mod);
            },
            childDelegate: ListWheelChildBuilderDelegate(
              builder: (context, index) {
                final mod = index % total;
                return Center(
                  child: Text(
                    mod.toString().padLeft(2, '0'),
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w600,
                      color: mod == value
                          ? AppColors.primary
                          : AppColors.primary.withValues(alpha: 0.3),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeUnitHighlight() {
    return Center(
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: AppColors.primary.withValues(alpha: 0.3)),
            bottom: BorderSide(color: AppColors.primary.withValues(alpha: 0.3)),
          ),
        ),
      ),
    );
  }

  Widget _buildTimeSeparator() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      child: Text(
        ':',
        style: TextStyle(
          fontSize: 40,
          fontWeight: FontWeight.w600,
          color: AppColors.primary.withValues(alpha: 0.6),
          height: 1,
        ),
      ),
    );
  }

  Widget _buildDateSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            _getSelectedDaysText(),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey[800],
            ),
          ),
        ),
        if (!widget.isViewOnly)
          IconButton(
            onPressed: _selectReminderDate,
            icon: Icon(
              Icons.calendar_month_outlined,
              size: 24,
              color: AppColors.primary,
            ),
          ),
      ],
    );
  }

  void _updateReminderDateBasedOnTime() {
    if (_isSelectedDays) return;

    final now = DateTime.now();
    final todayWithSelectedTime = DateTime(
      now.year,
      now.month,
      now.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    if (todayWithSelectedTime.isAfter(now)) {
      _reminderDate = todayWithSelectedTime;
    } else {
      _reminderDate = todayWithSelectedTime.add(const Duration(days: 1));
    }
  }

  String _getSelectedDaysText() {
    if (!_isSelectedDays) {
      return DateTimeUtils.isToday(_reminderDate)
          ? TransKeys.today.tr()
          : TransKeys.tomorrow.tr() +
                ' ' +
                DateTimeUtils.formatDate(_reminderDate);
    }

    final dayMap = {
      1: TransKeys.mon.tr(),
      2: TransKeys.tue.tr(),
      3: TransKeys.wed.tr(),
      4: TransKeys.thu.tr(),
      5: TransKeys.fri.tr(),
      6: TransKeys.sat.tr(),
      7: TransKeys.sun.tr(),
    };

    final sortedDays = _selectedDays.toList()..sort();
    final dayNames = sortedDays.map((day) => dayMap[day]!).toList();

    if (dayNames.length == 7) return TransKeys.every_day.tr();
    return '${TransKeys.every.tr()} ${dayNames.join(', ')}';
  }

  Widget _buildDaySelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildDayButton(TransKeys.m.tr(), 1),
        _buildDayButton(TransKeys.t.tr(), 2),
        _buildDayButton(TransKeys.w.tr(), 3),
        _buildDayButton(TransKeys.t_5.tr(), 4),
        _buildDayButton(TransKeys.f.tr(), 5),
        _buildDayButton(TransKeys.s_7.tr(), 6, isWeekend: true),
        _buildDayButton(TransKeys.s.tr(), 7, isWeekend: true),
      ],
    );
  }

  Widget _buildDayButton(String label, int dayIndex, {bool isWeekend = false}) {
    final isSelected = _selectedDays.contains(dayIndex);

    return GestureDetector(
      onTap: widget.isViewOnly
          ? null
          : () {
              setState(() {
                if (isSelected) {
                  _selectedDays.remove(dayIndex);
                } else {
                  _selectedDays.add(dayIndex);
                }
                _isSelectedDays = _selectedDays.isNotEmpty;
                if (!_isSelectedDays) {
                  _updateReminderDateBasedOnTime();
                }
              });
            },
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey[300]!,
            width: 2,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : Colors.grey[600],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _selectReminderDate() async {
    final picked = await CustomDateTimePicker.show(
      initialDate: _reminderDate.isBefore(DateTime.now())
          ? DateTime.now()
          : _reminderDate,
      context: context,

      title: TransKeys.choose_reminder_date.tr(),
    );
    if (picked != null) {
      setState(() {
        _reminderDate = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _selectedTime.hour,
          _selectedTime.minute,
        );
        _isSelectedDays = false;
        _selectedDays.clear();
      });
    }
  }

  Widget _buildTitleField() {
    return TextFormField(
      enabled: !widget.isViewOnly,
      controller: _titleController,
      style: const TextStyle(fontSize: 16),
      decoration: InputDecoration(
        hintText: TransKeys.enter_reminder_title.tr(),
        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 16),
        border: UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
    );
  }

  Widget _buildAlarmSoundToggle() {
    return _buildSettingItemWithToggle(
      icon: Icons.music_note_outlined,
      label: TransKeys.alarm_sound.tr(),
      isEnabled: _isAlarmSoundEnabled,
      onToggle: (value) => setState(() => _isAlarmSoundEnabled = value),
      isViewOnly: widget.isViewOnly,
    );
  }

  Widget _buildWarning() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange[200]!, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: Colors.orange[700],
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              TransKeys.reminder_couple_warning.tr(),
              style: TextStyle(
                color: Colors.orange[900],
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSnoozeToggle() {
    return _buildSettingItemWithToggle(
      icon: Icons.snooze_outlined,
      label: TransKeys.vibrate.tr(),
      isEnabled: _isVibrate,
      onToggle: (value) => setState(() => _isVibrate = value),
      isViewOnly: widget.isViewOnly,
    );
  }

  Widget _buildSettingItemWithToggle({
    required IconData icon,
    required String label,
    required bool isEnabled,
    required ValueChanged<bool> onToggle,
    bool isViewOnly = false,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: isEnabled && !isViewOnly ? onTap : null,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        decoration: BoxDecoration(
          color: isEnabled ? Colors.white : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isEnabled ? Colors.grey[300]! : Colors.grey[200]!,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 22,
              color: isEnabled ? AppColors.primary : Colors.grey[400],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: isEnabled ? Colors.grey[800] : Colors.grey[500],
                ),
              ),
            ),
            Switch(
              value: isEnabled,
              onChanged: isViewOnly ? null : onToggle,
              activeThumbColor: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }

  bool get _canEditVisibility {
    if (!_isEditMode) return true;

    final currentUserId = ref.read(currentUserProvider)?.uid ?? '';
    final reminder = widget.reminder;

    if (reminder == null) return true;

    return reminder.ownerId == currentUserId;
  }

  Widget _buildVisibilitySetting() {
    final canEdit = _canEditVisibility && !widget.isViewOnly || !_isEditMode;

    return InkWell(
      onTap: canEdit ? _showAssigneePicker : null,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: canEdit ? Colors.white : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: canEdit ? Colors.grey[300]! : Colors.grey[200]!,
          ),
        ),
        child: Row(
          children: [
            Icon(
              _assignee.icon,
              size: 20,
              color: canEdit ? _assignee.color : Colors.grey[400],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        TransKeys.recipient.tr(),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: canEdit ? Colors.grey[800] : Colors.grey[500],
                        ),
                      ),
                      if (!canEdit) ...[
                        const SizedBox(width: 8),
                        Icon(
                          Icons.lock_outline,
                          size: 14,
                          color: Colors.grey[400],
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _assignee.description,
                    style: TextStyle(
                      fontSize: 13,
                      color: canEdit ? Colors.grey[700] : Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
            if (canEdit)
              Icon(Icons.chevron_right, size: 20, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  void _showAssigneePicker() async {
    // final result = await showModalBottomSheet(
    //   context: context,
    //   backgroundColor: Colors.transparent,
    //   builder: (context) => AssigneePickerSheet(initial: _assignee),
    // );

    // if (result != null) {
    //   setState(() => _assignee = result);
    // }
  }

  Widget _buildBottomActionBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        24,
        16,
        24,
        16 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(12),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: _buildActionButton(),
    );
  }

  Widget _buildActionButton() {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: _isSubmitting ? null : () => _handleReminder(_isEditMode),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            disabledBackgroundColor: Colors.grey[300],
          ),
          child: _isSubmitting
              ? _buildLoadingButton()
              : Text(
                  _isEditMode
                      ? TransKeys.update_reminder.tr()
                      : TransKeys.set_reminder.tr(),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildLoadingButton() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(
          height: 20,
          width: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
        const SizedBox(width: 16),
        Text(
          _isEditMode ? TransKeys.updating.tr() : TransKeys.creating.tr(),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  DateTime _calculateReminderDate() {
    final now = DateTime.now();

    if (_isSelectedDays) {
      return DateTimeUtils.getNextReminderDate(
        DateTime(
          now.year,
          now.month,
          now.day,
          _selectedTime.hour,
          _selectedTime.minute,
        ),
        _selectedDays,
      );
    }

    return DateTime(
      _reminderDate.year,
      _reminderDate.month,
      _reminderDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );
  }

  RecurringType _getRecurringType() {
    if (_selectedDays.length == 7) return RecurringType.daily;
    if (_selectedDays.isNotEmpty) return RecurringType.weekly;
    return RecurringType.none;
  }

  String _getOwnerId() {
    if (_isEditMode && !_canEditVisibility) {
      return widget.reminder!.ownerId;
    }

    final currentUserId = ref.read(currentUserProvider)?.uid ?? '';
    final partner = ref.read(partnerProvider).value?.data;
    final couple = ref.read(coupleProvider).value?.data;

    switch (_assignee) {
      case AssigneeType.lover:
        return partner?.uid ?? currentUserId;
      case AssigneeType.couple:
        return couple?.id ?? currentUserId;
      case AssigneeType.private:
      case AssigneeType.me:
      default:
        return currentUserId;
    }
  }

  bool _isPrivate() {
    if (_isEditMode && !_canEditVisibility) {
      return widget.reminder!.isPrivate;
    }

    return _assignee == AssigneeType.private;
  }

  ApprovalStatus _getApprovalStatus() {
    final currentUserId = ref.read(currentUserProvider)?.uid ?? '';
    final ownerId = _getOwnerId();

    if (ownerId != currentUserId &&
        (_assignee == AssigneeType.lover || _assignee == AssigneeType.couple)) {
      return ApprovalStatus.pending;
    }

    return ApprovalStatus.none;
  }

  ReminderStatus _getReminderStatus() {
    final currentUserId = ref.read(currentUserProvider)?.uid ?? '';
    final ownerId = _getOwnerId();

    if (_isEditMode && _isReminderInactiveNonRecurring) {
      return ReminderStatus.doing;
    }

    if (_assignee == AssigneeType.lover && ownerId != currentUserId) {
      return ReminderStatus.done;
    }

    return ReminderStatus.doing;
  }

  Future<void> _handleReminder(bool isEditMode) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final reminderDate = _calculateReminderDate();
      final connection = ref.watch(connectivityServiceProvider);

      if (reminderDate.isBefore(DateTime.now())) {
        CustomSnackBar.showWarning(
          context,
          message: TransKeys.datetime_must_be_future.tr(),
        );
        return;
      }

      final currentUser = ref.read(currentUserProvider);
      final partner = ref.watch(partnerProvider).value?.data;
      final ownerId = _getOwnerId();

      int? alarmId;

      if (ownerId != partner?.uid) {
        alarmId = await AlarmService.scheduleWithRollback(
          reminderDate: reminderDate,
          alarmId: (isEditMode ? widget.reminder!.alarmId : -1) ?? -1,
        );
      }

      if (ownerId != partner?.uid) {
        if (isEditMode && _isReminderInactiveNonRecurring) {
          alarmId = await AlarmService.scheduleWithRollback(
            reminderDate: reminderDate,
            alarmId: -1,
          );
        } else {
          alarmId = await AlarmService.scheduleWithRollback(
            reminderDate: reminderDate,
            alarmId: (isEditMode ? widget.reminder!.alarmId : -1),
          );
        }
      }

      final dto = ReminderEntity(
        id: isEditMode ? widget.reminder!.id : '',
        alarmId: alarmId,
        ownerId: ownerId,
        title: _titleController.text.trim().isEmpty
            ? TransKeys.new_reminder.tr()
            : _titleController.text.trim(),
        reminderDate: reminderDate,
        days: _selectedDays.isEmpty ? null : _selectedDays,
        isSound: _isAlarmSoundEnabled,
        isVibrate: _isVibrate,
        createdBy: currentUser?.uid ?? '',
        createdAt: isEditMode ? widget.reminder!.createdAt : DateTime.now(),
        updatedAt: DateTime.now(),
        recurringType: _getRecurringType(),
        approvalStatus: _getApprovalStatus(),
        reminderStatus: _getReminderStatus(),
        partnerReminderStatus: _assignee == AssigneeType.couple
            ? ReminderStatus.done
            : null,
        isPrivate: _isPrivate(),
        syncStatus: SyncStatus.synced,
      );

      final viewModel = ref.read(reminderListViewModelProvider.notifier);
      final success;

      if (isEditMode) {
        success = await viewModel.updateReminder(
          dto.copyWith(
            id: widget.reminder!.id,
            createdAt: widget.reminder!.createdAt,
          ),
        );
      } else {
        success = await viewModel.createReminder(dto);
      }

      if (!mounted) return;

      if (success) {
        if (ownerId != currentUser?.uid && partner != null) {
          final reminderId = ref
              .read(reminderListViewModelProvider)
              .selectedReminder
              ?.id;

          if (reminderId != null) {
            await FCMService.sendNotificationToToken(
              fcmToken: partner.fcmToken ?? '',
              title:
                  '${TransKeys.new_reminder.tr()} ${TransKeys.at.tr()} ${_selectedTime.format(context)}',
              body:
                  '${currentUser?.displayName} ${TransKeys.want_to_create_reminder_4_u.tr()}\n${TransKeys.content.tr()}: ${dto.title}',
              navigationPath: '/reminder',
              data: {
                'action': 'request_approval',
                'itemId': reminderId,
                'type': NotificationType.reminder,
              },
            );
          }
        }

        if (connection.isOnline) {
          if (ownerId != currentUser?.uid) {
            _adManager.showAd(
              onAdDismissed: () {
                CustomSnackBar.showSuccess(
                  context,
                  message: isEditMode
                      ? TransKeys.update_success.tr()
                      : TransKeys.create_success.tr(),
                );
              },
            );
          } else {
            CustomSnackBar.showSuccess(
              context,
              message: isEditMode
                  ? TransKeys.update_success.tr()
                  : TransKeys.create_success.tr(),
            );
          }
        }

        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        CustomSnackBar.showError(context, message: e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _handleDeleteReminder() async {
    try {
      final viewModel = ref.read(reminderListViewModelProvider.notifier);
      final currentUserId = ref.read(currentUserProvider)?.uid ?? '';
      final success = await viewModel.deleteReminder(
        widget.reminder!,
        currentUserId,
      );

      if (widget.reminder!.alarmId != null) {
        await AlarmService.cancel(widget.reminder!.alarmId!);
      }

      if (!mounted) return;

      if (success) {
        CustomSnackBar.showSuccess(
          context,
          message:
              '${TransKeys.deleted.tr()} ${TransKeys.reminder.tr().toLowerCase()}',
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        CustomSnackBar.showError(context, message: e.toString());
      }
    }
  }
}
