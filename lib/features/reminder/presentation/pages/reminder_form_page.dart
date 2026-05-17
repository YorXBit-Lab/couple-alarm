import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:audioplayers/audioplayers.dart';
import 'package:couple_note/core/constants/trans_keys.dart';
import 'package:couple_note/core/services/Admob/interstitial_ad_manager.dart';
import 'package:couple_note/core/services/alarm/alarm_service.dart';
import 'package:couple_note/core/services/fcm_service.dart';
import 'package:couple_note/core/utils/datetime_utils.dart';
import 'package:couple_note/common/widgets/base/date_picker.dart';
import 'package:couple_note/common/widgets/base/snackbar.dart';
import 'package:couple_note/features/auth/presentation/provider/auth_provider.dart';
import 'package:couple_note/features/connect/presentation/provider/connect_provider.dart';
import 'package:couple_note/features/reminder/presentation/provider/reminder_notifier.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:couple_note/core/config/app_constants.dart';
import 'package:couple_note/core/config/theme/app_colors.dart';
import 'package:couple_note/features/reminder/domain/entities/reminder.dart';
import 'package:record/record.dart';

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

  // Repeat mode: 'once', 'weekly', 'daily'
  String _repeatMode = 'once';

  // Sound mode: 'default', 'voice', 'silent'
  String _soundMode = 'default';

  // Voice recording
  String? _voiceRecordPath;
  bool _isRecording = false;
  bool _isPlayingVoice = false;
  int _recordingSeconds = 0;
  int _voiceDuration = 0;
  Timer? _recordingTimer;
  final _audioRecorder = AudioRecorder();
  final _voicePlayer = AudioPlayer();

  static const int _maxRecordSeconds = 15;

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
    _initVoicePlayer();
    if (_isEditMode) {
      _loadReminderData();
    } else {
      _reminderDate = DateTime.now();
      _updateReminderDateBasedOnTime();
      _repeatMode = 'weekly';
      _selectedDays = {1, 2, 3, 4, 5};
      _isSelectedDays = true;
      final reminderState = ref.read(reminderProvider);
      if (reminderState.currentTab == 'partner') {
        _assignee = AssigneeType.lover;
      } else if (reminderState.currentTab == 'couple') {
        _assignee = AssigneeType.couple;
      } else {
        _assignee = AssigneeType.me;
      }
    }
  }

  void _initVoicePlayer() {
    _voicePlayer.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _isPlayingVoice = false);
    });
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
      _reminderDate = todayWithReminderTime.isAfter(now)
          ? todayWithReminderTime
          : todayWithReminderTime.add(const Duration(days: 1));
    } else {
      _reminderDate = reminder.reminderDate;
    }

    _selectedDays = reminder.days ?? {};
    _isSelectedDays = _selectedDays.isNotEmpty;
    _isAlarmSoundEnabled = reminder.isSound;
    _isVibrate = reminder.isVibrate;

    if (_selectedDays.length == 7) {
      _repeatMode = 'daily';
    } else if (_selectedDays.isNotEmpty) {
      _repeatMode = 'weekly';
    } else {
      _repeatMode = 'once';
    }

    _assignee = _determineVisibilityFromReminder(reminder);
  }

  AssigneeType _determineVisibilityFromReminder(ReminderEntity reminder) {
    final currentUser = ref.read(currentUserProvider);
    final partner = ref.read(partnerProvider).value?.data;

    if (reminder.isPrivate) return AssigneeType.private;
    if (reminder.ownerId == currentUser?.uid) return AssigneeType.me;
    if (reminder.ownerId == partner?.uid) return AssigneeType.lover;
    return AssigneeType.couple;
  }

  @override
  void dispose() {
    _adManager.dispose();
    _titleController.dispose();
    _fadeController.dispose();
    _recordingTimer?.cancel();
    _audioRecorder.dispose();
    _voicePlayer.dispose();
    _deleteVoiceTempFile();
    super.dispose();
  }

  void _deleteVoiceTempFile() {
    if (_voiceRecordPath != null) {
      try {
        File(_voiceRecordPath!).deleteSync();
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF5F0),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildAssigneeTabs(),
                        const SizedBox(height: 20),
                        _buildTimePicker(),
                        const SizedBox(height: 20),
                        _buildMessageCard(),
                        const SizedBox(height: 14),
                        _buildSoundCard(),
                        const SizedBox(height: 14),
                        _buildRepeatCard(),
                        const SizedBox(height: 14),
                        _buildVibrateCard(),
                        if (_assignee == AssigneeType.couple) ...[
                          const SizedBox(height: 14),
                          _buildWarning(),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (!widget.isViewOnly) _buildSetAlarmButton(),
          ],
        ),
      ),
    );
  }

  // ─── Header ───────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Close button
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              icon: const Icon(Icons.close, size: 22, color: Color(0xFF555555)),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          // Title
          Text(
            widget.isViewOnly
                ? TransKeys.detailed_information.tr()
                : _isEditMode
                ? TransKeys.edit_reminder.tr()
                : 'New alarm',
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              fontStyle: FontStyle.italic,
              color: AppColors.primary,
              letterSpacing: 0.2,
            ),
          ),
          // Delete button (edit mode)
          if (_isEditMode &&
              _getOwnerId() != ref.read(partnerProvider).value?.data?.uid)
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                icon: Icon(
                  Icons.delete_outline_rounded,
                  size: 22,
                  color: Colors.red[400],
                ),
                onPressed: _handleDeleteReminder,
              ),
            ),
        ],
      ),
    );
  }

  // ─── Assignee Tabs ────────────────────────────────────────────────────────

  Widget _buildAssigneeTabs() {
    final partner = ref.watch(partnerProvider).value?.data;
    final partnerName = partner?.displayName.split(' ').last ??
        TransKeys.lover.tr();
    final hasPartner = partner != null;
    final canEdit = _canEditVisibility && !widget.isViewOnly;

    final types = [AssigneeType.me, AssigneeType.lover, AssigneeType.couple];
    final labels = [TransKeys.mine.tr(), partnerName, 'Us'];
    final icons = [
      Icons.person_rounded,
      Icons.favorite_rounded,
      Icons.people_rounded,
    ];
    final activeColors = [
      const Color(0xFF5B8DEF),
      AppColors.primary,
      const Color(0xFF9B6FD4),
    ];
    final disabled = [false, !hasPartner, !hasPartner];
    final selectedIndex = types.indexOf(_assignee).clamp(0, 2);

    return LayoutBuilder(
      builder: (context, constraints) {
        const padding = 4.0;
        final itemWidth = (constraints.maxWidth - padding * 2) / 3;
        final activeColor = activeColors[selectedIndex];

        return Container(
          height: 46,
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(26),
          ),
          padding: const EdgeInsets.all(padding),
          child: Stack(
            children: [
              // Sliding white indicator
              AnimatedPositioned(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                left: selectedIndex * itemWidth,
                top: 0,
                bottom: 0,
                width: itemWidth,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: activeColor.withValues(alpha: 0.18),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
              // Item labels
              Row(
                children: List.generate(3, (i) {
                  final isSelected = i == selectedIndex;
                  final isDisabled = disabled[i];
                  return Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: (isDisabled || !canEdit)
                          ? null
                          : () => setState(() => _assignee = types[i]),
                      child: Opacity(
                        opacity: isDisabled ? 0.4 : 1.0,
                        child: Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                icons[i],
                                size: 14,
                                color: isSelected
                                    ? activeColors[i]
                                    : Colors.grey[500],
                              ),
                              const SizedBox(width: 5),
                              Text(
                                labels[i],
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: isSelected
                                      ? activeColors[i]
                                      : Colors.grey[500],
                                ),
                              ),
                              if (isDisabled) ...[
                                const SizedBox(width: 3),
                                Icon(
                                  Icons.lock_outline_rounded,
                                  size: 10,
                                  color: Colors.grey[400],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        );
      },
    );
  }

  // ─── Time Picker (kept as existing) ───────────────────────────────────────

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

  // ─── Message Card ─────────────────────────────────────────────────────────

  Widget _buildMessageCard() {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionLabel('MESSAGE'),
          const SizedBox(height: 8),
          TextFormField(
            enabled: !widget.isViewOnly,
            controller: _titleController,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A1A),
            ),
            maxLines: null,
            decoration: InputDecoration(
              hintText: TransKeys.enter_reminder_title.tr(),
              hintStyle: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.grey[300],
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _assignee == AssigneeType.me
                ? "Only you'll see this"
                : _assignee == AssigneeType.lover
                ? "Your partner will see this"
                : "Both of you will see this",
            style: TextStyle(fontSize: 12, color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }

  // ─── Sound Card ───────────────────────────────────────────────────────────

  Widget _buildSoundCard() {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionLabel('WAKE THEM WITH'),
          const SizedBox(height: 12),
          // Default ring
          _buildSoundOption(
            icon: Icons.notifications_outlined,
            iconBg: Colors.grey[100]!,
            iconColor: Colors.grey[600]!,
            title: 'Default ring',
            subtitle: 'System alarm sound',
            isSelected: _soundMode == 'default',
            onTap: widget.isViewOnly
                ? null
                : () => setState(() {
                      _soundMode = 'default';
                      _isAlarmSoundEnabled = true;
                    }),
          ),
          const SizedBox(height: 8),
          // Your voice
          _buildSoundOption(
            icon: Icons.mic_rounded,
            iconBg: AppColors.primary.withValues(alpha: 0.1),
            iconColor: AppColors.primary,
            title: 'Your voice',
            subtitle: _voiceRecordPath != null
                ? '${_formatVoiceDuration(_voiceDuration)} recorded · tap to re-record'
                : 'Record up to ${_maxRecordSeconds}s',
            isSelected: _soundMode == 'voice',
            onTap: widget.isViewOnly
                ? null
                : () {
                    setState(() {
                      _soundMode = 'voice';
                      _isAlarmSoundEnabled = true;
                    });
                  },
          ),
          // Voice recorder UI (visible when 'voice' selected)
          if (_soundMode == 'voice') ...[
            const SizedBox(height: 10),
            _buildVoiceRecorder(),
          ],
          const SizedBox(height: 8),
          // Silent
          _buildSoundOption(
            icon: Icons.volume_off_outlined,
            iconBg: Colors.grey[100]!,
            iconColor: Colors.grey[500]!,
            title: 'Silent',
            subtitle: 'Vibrate only',
            isSelected: _soundMode == 'silent',
            onTap: widget.isViewOnly
                ? null
                : () => setState(() {
                      _soundMode = 'silent';
                      _isAlarmSoundEnabled = false;
                    }),
          ),
        ],
      ),
    );
  }

  Widget _buildSoundOption({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool isSelected,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.06)
              : Colors.grey[50],
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.3)
                : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withValues(alpha: 0.15)
                    : iconBg,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 18,
                color: isSelected ? AppColors.primary : iconColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? const Color(0xFF1A1A1A)
                          : Colors.grey[700],
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? AppColors.primary : Colors.transparent,
                border: Border.all(
                  color: isSelected ? AppColors.primary : Colors.grey[300]!,
                  width: 1.5,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  // ─── Voice Recorder ───────────────────────────────────────────────────────

  Widget _buildVoiceRecorder() {
    if (_isRecording) {
      // Recording in progress
      final remaining = _maxRecordSeconds - _recordingSeconds;
      final progress = _recordingSeconds / _maxRecordSeconds;
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primary.withValues(alpha: 0.12),
              const Color(0xFFEDE8FF).withValues(alpha: 0.6),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Row(
              children: [
                // Animated red dot
                _AnimatedRecordDot(),
                const SizedBox(width: 8),
                Text(
                  _formatVoiceDuration(_recordingSeconds),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const Spacer(),
                Text(
                  '−${remaining}s',
                  style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.white.withValues(alpha: 0.6),
                valueColor: AlwaysStoppedAnimation(AppColors.primary),
                minHeight: 4,
              ),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _stopRecording,
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.stop_rounded, size: 18, color: Colors.red[400]),
                    const SizedBox(width: 6),
                    Text(
                      'Stop recording',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.red[400],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (_voiceRecordPath != null) {
      // Has a recording — show waveform + controls
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFEDE8FF), Color(0xFFFFE8F0)],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Row(
              children: [
                // Play/pause button
                GestureDetector(
                  onTap: _togglePlayVoice,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _isPlayingVoice
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Waveform bars
                Expanded(child: _buildWaveformBars()),
                const SizedBox(width: 12),
                Text(
                  _formatVoiceDuration(_voiceDuration),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Re-record button
            GestureDetector(
              onTap: _startRecording,
              child: Container(
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.refresh_rounded, size: 15, color: AppColors.primary),
                    const SizedBox(width: 5),
                    Text(
                      'Re-record',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    // No recording yet — show start button
    return GestureDetector(
      onTap: _startRecording,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.25),
            style: BorderStyle.solid,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.mic_rounded, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            Text(
              'Tap to record (max ${_maxRecordSeconds}s)',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWaveformBars() {
    final rand = math.Random(42);
    return SizedBox(
      height: 32,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(28, (i) {
          final h = 6.0 + rand.nextDouble() * 20;
          return Container(
            width: 3,
            height: h,
            decoration: BoxDecoration(
              color: _isPlayingVoice
                  ? AppColors.primary
                  : AppColors.primary.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(2),
            ),
          );
        }),
      ),
    );
  }

  String _formatVoiceDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Future<void> _startRecording() async {
    try {
      if (_isPlayingVoice) {
        await _voicePlayer.stop();
        setState(() => _isPlayingVoice = false);
      }
      if (_voiceRecordPath != null) {
        try { File(_voiceRecordPath!).deleteSync(); } catch (_) {}
        _voiceRecordPath = null;
      }

      final hasPermission = await _audioRecorder.hasPermission();
      if (!hasPermission) {
        if (mounted) {
          CustomSnackBar.showWarning(context, message: 'Microphone permission required');
        }
        return;
      }

      final path =
          '${Directory.systemTemp.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';

      await _audioRecorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 64000),
        path: path,
      );

      setState(() {
        _isRecording = true;
        _recordingSeconds = 0;
      });

      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (!mounted) { t.cancel(); return; }
        setState(() => _recordingSeconds++);
        if (_recordingSeconds >= _maxRecordSeconds) {
          t.cancel();
          _stopRecording();
        }
      });
    } catch (e) {
      if (mounted) {
        CustomSnackBar.showError(context, message: 'Cannot start recording: $e');
      }
    }
  }

  Future<void> _stopRecording() async {
    _recordingTimer?.cancel();
    try {
      final path = await _audioRecorder.stop();
      if (path != null && mounted) {
        setState(() {
          _isRecording = false;
          _voiceRecordPath = path;
          _voiceDuration = _recordingSeconds;
          _recordingSeconds = 0;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() { _isRecording = false; _recordingSeconds = 0; });
        CustomSnackBar.showError(context, message: 'Cannot save recording: $e');
      }
    }
  }

  Future<void> _togglePlayVoice() async {
    if (_voiceRecordPath == null) return;
    try {
      if (_isPlayingVoice) {
        await _voicePlayer.stop();
        setState(() => _isPlayingVoice = false);
      } else {
        await _voicePlayer.play(DeviceFileSource(_voiceRecordPath!));
        setState(() => _isPlayingVoice = true);
      }
    } catch (e) {
      setState(() => _isPlayingVoice = false);
    }
  }

  // ─── Repeat Card ──────────────────────────────────────────────────────────

  Widget _buildRepeatCard() {
    final repeatLabel = _repeatMode == 'daily'
        ? TransKeys.every_day.tr()
        : _repeatMode == 'weekly'
        ? _getSelectedDaysText()
        : _getOnceDateText();

    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildSectionLabel('REPEAT'),
              const SizedBox(width: 8),
              Text(
                repeatLabel,
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildRepeatSegment(),
          // Day grid (show when weekly)
          if (_repeatMode == 'weekly') ...[
            const SizedBox(height: 16),
            _buildDayGrid(),
            const SizedBox(height: 12),
            _buildDayPresets(),
          ],
          // Date picker (show when once)
          if (_repeatMode == 'once') ...[
            const SizedBox(height: 14),
            GestureDetector(
              onTap: widget.isViewOnly ? null : _selectReminderDate,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 11,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 16,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      _getOnceDateText(),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF333333),
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.chevron_right,
                      size: 18,
                      color: Colors.grey[400],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _setRepeatMode(String mode) {
    if (widget.isViewOnly) return;
    setState(() {
      _repeatMode = mode;
      if (mode == 'daily') {
        _selectedDays = {1, 2, 3, 4, 5, 6, 7};
        _isSelectedDays = true;
      } else if (mode == 'once') {
        _selectedDays = {};
        _isSelectedDays = false;
        _updateReminderDateBasedOnTime();
      } else if (mode == 'weekly' && _selectedDays.isEmpty) {
        _selectedDays = {1, 2, 3, 4, 5};
        _isSelectedDays = true;
      }
    });
  }

  Widget _buildRepeatSegment() {
    const modes = ['once', 'weekly', 'daily'];
    const labels = ['Once', 'Weekly', 'Daily'];
    final selectedIndex = modes.indexOf(_repeatMode);

    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        const padding = 4.0;
        final itemWidth = (totalWidth - padding * 2) / 3;

        return Container(
          height: 44,
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(24),
          ),
          padding: const EdgeInsets.all(padding),
          child: Stack(
            children: [
              // Sliding indicator
              AnimatedPositioned(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                left: selectedIndex * itemWidth,
                top: 0,
                bottom: 0,
                width: itemWidth,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
              // Labels row
              Row(
                children: List.generate(3, (i) {
                  final isSelected = i == selectedIndex;
                  return Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => _setRepeatMode(modes[i]),
                      child: Center(
                        child: Text(
                          labels[i],
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: isSelected
                                ? const Color(0xFF1A1A1A)
                                : Colors.grey[500],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDayGrid() {
    final dayLabels = ['S', 'M', 'T', 'W', 'Th', 'F', 'Sa'];
    // dayLabels[i] maps to day index: Sun=7, Mon=1, Tue=2, Wed=3, Thu=4, Fri=5, Sat=6
    final dayIndices = [7, 1, 2, 3, 4, 5, 6];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(7, (i) {
        final dayIndex = dayIndices[i];
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
                  });
                },
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : Colors.white,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? AppColors.primary : Colors.grey[200]!,
              ),
            ),
            child: Center(
              child: Text(
                dayLabels[i],
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : Colors.grey[600],
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildDayPresets() {
    return Row(
      children: [
        Expanded(child: _buildDayPresetChip('Weekdays', {1, 2, 3, 4, 5})),
        const SizedBox(width: 8),
        Expanded(child: _buildDayPresetChip('Weekends', {6, 7})),
        const SizedBox(width: 8),
        Expanded(child: _buildDayPresetChip('Every day', {1, 2, 3, 4, 5, 6, 7})),
      ],
    );
  }

  Widget _buildDayPresetChip(String label, Set<int> days) {
    final isActive = setEquals(_selectedDays, days);
    return GestureDetector(
      onTap: widget.isViewOnly
          ? null
          : () {
              setState(() {
                _selectedDays = Set<int>.from(days);
                _isSelectedDays = true;
              });
            },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.primary.withValues(alpha: 0.1)
              : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? AppColors.primary.withValues(alpha: 0.4) : Colors.transparent,
          ),
        ),
        child: Center(
          child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isActive ? AppColors.primary : Colors.grey[600],
          ),
        ),
        ),
      ),
    );
  }

  bool setEquals<T>(Set<T>? a, Set<T>? b) {
    if (a == null || b == null) return a == b;
    if (a.length != b.length) return false;
    return a.containsAll(b);
  }

  // ─── Vibrate Card ─────────────────────────────────────────────────────────

  Widget _buildVibrateCard() {
    return _buildCard(
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.phone_android_outlined,
              size: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Vibrate',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                Text(
                  'Gentle haptic pulse',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: _isVibrate,
            onChanged: widget.isViewOnly
                ? null
                : (v) => setState(() => _isVibrate = v),
            activeThumbColor: AppColors.primary,
            activeTrackColor: AppColors.primary.withValues(alpha: 0.35),
          ),
        ],
      ),
    );
  }

  // ─── Warning ──────────────────────────────────────────────────────────────

  Widget _buildWarning() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.orange[200]!, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.orange[700], size: 18),
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

  // ─── Set Alarm Button ─────────────────────────────────────────────────────

  Widget _buildSetAlarmButton() {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        12 + MediaQuery.of(context).padding.bottom,
      ),
      child: GestureDetector(
        onTap: _isSubmitting ? null : () => _handleReminder(_isEditMode),
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            gradient: _isSubmitting
                ? null
                : const LinearGradient(
                    colors: [Color(0xFFFF7A9C), Color(0xFFFFAA85)],
                  ),
            color: _isSubmitting ? Colors.grey[300] : null,
            borderRadius: BorderRadius.circular(28),
            boxShadow: _isSubmitting
                ? null
                : [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.35),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: _isSubmitting
                ? [
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _isEditMode
                          ? TransKeys.updating.tr()
                          : TransKeys.creating.tr(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ]
                : [
                    const Icon(
                      Icons.favorite_rounded,
                      size: 18,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _isEditMode
                          ? TransKeys.update_reminder.tr()
                          : 'Set alarm',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
          ),
        ),
      ),
    );
  }

  // ─── Shared helpers ───────────────────────────────────────────────────────

  Widget _buildCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: Colors.grey[500],
        letterSpacing: 1.2,
      ),
    );
  }

  // ─── Date helpers ─────────────────────────────────────────────────────────

  String _getOnceDateText() {
    if (DateTimeUtils.isToday(_reminderDate)) return TransKeys.today.tr();
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    if (_reminderDate.year == tomorrow.year &&
        _reminderDate.month == tomorrow.month &&
        _reminderDate.day == tomorrow.day) {
      return TransKeys.tomorrow.tr();
    }
    return DateTimeUtils.formatDate(_reminderDate);
  }

  String _getSelectedDaysText() {
    if (_selectedDays.isEmpty) return '';
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
    final names = sortedDays.map((d) => dayMap[d]!).toList();
    if (names.length == 7) return TransKeys.every_day.tr();
    return '${TransKeys.every.tr()} ${names.join(', ')}';
  }

  void _updateReminderDateBasedOnTime() {
    if (_isSelectedDays) return;
    final now = DateTime.now();
    final todayWithTime = DateTime(
      now.year,
      now.month,
      now.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );
    _reminderDate = todayWithTime.isAfter(now)
        ? todayWithTime
        : todayWithTime.add(const Duration(days: 1));
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

  // ─── Business Logic ───────────────────────────────────────────────────────

  bool get _canEditVisibility {
    if (!_isEditMode) return true;
    final currentUserId = ref.read(currentUserProvider)?.uid ?? '';
    final reminder = widget.reminder;
    if (reminder == null) return true;
    return reminder.ownerId == currentUserId;
  }

  String _getOwnerId() {
    if (_isEditMode && !_canEditVisibility) {
      return widget.reminder!.ownerId;
    }
    final currentUserId = ref.read(currentUserProvider)?.uid ?? '';
    final partner = ref.read(partnerProvider).value?.data;
    final couple = ref.read(coupleStreamProvider).value?.data;

    switch (_assignee) {
      case AssigneeType.lover:
        return partner?.uid ?? currentUserId;
      case AssigneeType.couple:
        return couple?.id ?? currentUserId;
      case AssigneeType.private:
      case AssigneeType.me:
        return currentUserId;
    }
  }

  bool _isPrivate() {
    if (_isEditMode && !_canEditVisibility) return widget.reminder!.isPrivate;
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
    if (_isEditMode && _isReminderInactiveNonRecurring) return ReminderStatus.doing;
    if (_assignee == AssigneeType.lover && ownerId != currentUserId) {
      return ReminderStatus.done;
    }
    return ReminderStatus.doing;
  }

  RecurringType _getRecurringType() {
    if (_selectedDays.length == 7) return RecurringType.daily;
    if (_selectedDays.isNotEmpty) return RecurringType.weekly;
    return RecurringType.none;
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

      final notifier = ref.read(reminderProvider.notifier);
      final bool success;

      if (isEditMode) {
        success = await notifier.updateReminder(
          dto.copyWith(
            id: widget.reminder!.id,
            createdAt: widget.reminder!.createdAt,
          ),
        );
      } else {
        success = await notifier.createReminder(dto);
      }

      if (!mounted) return;

      if (success) {
        if (ownerId != currentUser?.uid && partner != null) {
          final reminderId = ref.read(reminderProvider).selectedReminder?.id;
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
                if (mounted) {
                  CustomSnackBar.showSuccess(
                    context,
                    message: isEditMode
                        ? TransKeys.update_success.tr()
                        : TransKeys.create_success.tr(),
                  );
                }
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
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _handleDeleteReminder() async {
    try {
      final notifier = ref.read(reminderProvider.notifier);
      final currentUserId = ref.read(currentUserProvider)?.uid ?? '';
      final success = await notifier.deleteReminder(
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

class _AnimatedRecordDot extends StatefulWidget {
  @override
  State<_AnimatedRecordDot> createState() => _AnimatedRecordDotState();
}

class _AnimatedRecordDotState extends State<_AnimatedRecordDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.3, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: Container(
        width: 10,
        height: 10,
        decoration: const BoxDecoration(
          color: Colors.red,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
