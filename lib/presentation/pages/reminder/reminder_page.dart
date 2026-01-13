import 'package:couple_note/core/config/app_constants.dart';
import 'package:couple_note/core/constants/trans_keys.dart';
import 'package:couple_note/core/services/alarm/alarm_service.dart';
import 'package:couple_note/core/services/local_notification_service.dart';
import 'package:couple_note/core/utils/datetime_utils.dart';
import 'package:couple_note/core/utils/utils.dart';
import 'package:couple_note/di/dependency_injection.dart';
import 'package:couple_note/domain/entities/reminder.dart';
import 'package:couple_note/presentation/routes/router.dart';
import 'package:couple_note/presentation/themes/app_colors.dart';
import 'package:couple_note/presentation/viewmodels/reminder_viewmodel.dart';
import 'package:couple_note/presentation/widgets/base/custom_dialog_widget.dart';
import 'package:couple_note/presentation/widgets/base/snackbar.dart';
import 'package:couple_note/presentation/widgets/header_tabs_widget.dart';
import 'package:couple_note/providers/auth_provider.dart';
import 'package:couple_note/providers/connect_provider.dart';
import 'package:couple_note/providers/reminder_provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class RemindersPage extends ConsumerStatefulWidget {
  const RemindersPage({super.key});
  @override
  ConsumerState<RemindersPage> createState() => _RemindersPageState();
}

class _RemindersPageState extends ConsumerState<RemindersPage>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeIn));
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.locale;

    final reminderState = ref.watch(reminderListViewModelProvider);
    final partner = ref.watch(partnerProvider).value?.data;
    final viewModel = ref.read(reminderListViewModelProvider.notifier);
    final tabs = ref.watch(tabsProvider((partner, locale.languageCode)));
    return Scaffold(
      backgroundColor: AppColors.background.withAlpha(100),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 0),
            child: Column(
              children: [
                CoupleNoteHeaderTabs(
                  title: TransKeys.reminder.tr(),
                  userTabs: tabs,
                  currentUserTab: reminderState.currentTab,
                  onUserTabChanged: (tabKey) {
                    ref
                        .read(reminderListViewModelProvider.notifier)
                        .changeTab(tabKey);
                  },
                  onFilterTap: () {
                    viewModel.showFilterSheet(context);
                  },
                ),

                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _buildRemindersList(
                      reminderState.reminders,
                      partner?.displayName ?? '',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildRemindersList(
    List<ReminderEntity> reminders,
    String partnerName,
  ) {
    final partner = ref.watch(partnerProvider).value?.data;
    final currentTab = ref.watch(reminderListViewModelProvider).currentTab;

    if ((currentTab == 'couple' || currentTab == 'partner') &&
        partner == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              TransKeys.invitation_request_content.tr(),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                context.pushNamed('connect');
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 10,
                ),
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 2,
                shadowColor: Theme.of(
                  context,
                ).primaryColor.withValues(alpha: 0.3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    TransKeys.connect_now.tr(),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (reminders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_none, size: 64, color: Colors.grey[400]),
            SizedBox(height: 16),
            Text(
              TransKeys.Add_new_reminder_to_get_add.tr(),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () =>
          ref.read(reminderListViewModelProvider.notifier).refreshReminders(),
      child: _buildListReminders(_groupRemindersPending(reminders)),
    );
  }

  Widget _buildListReminders(
    Map<bool, List<ReminderEntity>> groupRemindersPending,
  ) {
    final reminderState = ref.watch(reminderListViewModelProvider);
    final viewModel = ref.read(reminderListViewModelProvider.notifier);
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                Visibility(
                  visible: reminderState.isSelectionMode,
                  maintainSize: true,
                  maintainAnimation: true,
                  maintainState: true,
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => viewModel.exitSelectionMode(),
                        child: Icon(
                          Icons.arrow_back_outlined,
                          color: Colors.grey[900],
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Text(
                  reminderState.isSelectionMode
                      ? '${reminderState.selectedReminders.length} ${TransKeys.items.tr()}'
                      : '${reminderState.reminders.length} ${TransKeys.items.tr()}',
                  style: const TextStyle(fontSize: 13),
                ),
                if (reminderState.currentTab != 'partner') ...[
                  SizedBox(
                    width: 26,
                    height: 24,
                    child: PopupMenuButton<String>(
                      padding: EdgeInsets.only(left: 5),
                      splashRadius: 20,
                      iconSize: 20,
                      constraints: BoxConstraints(),
                      icon: Icon(Icons.settings, size: 20),
                      onSelected: (String value) {
                        switch (value) {
                          case 'select_deselect_all':
                            viewModel.selectOrDeselectAll();
                            break;

                          case 'delete':
                            _confirmDelete();
                            break;
                        }
                      },
                      itemBuilder: (BuildContext context) => [
                        PopupMenuItem<String>(
                          value: 'select_deselect_all',
                          child: Row(
                            children: [
                              Icon(Icons.check, size: 20),
                              SizedBox(width: 8),
                              Text(
                                reminderState.selectedReminders.length ==
                                        reminderState.reminders.length
                                    ? TransKeys.deselect_all.tr()
                                    : TransKeys.select_all.tr(),
                              ),
                            ],
                          ),
                        ),

                        PopupMenuItem<String>(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline, size: 20),
                              SizedBox(width: 8),
                              Text(
                                reminderState.isSelectionMode
                                    ? TransKeys.delete_selection.tr()
                                    : TransKeys.delete_all.tr(),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          _buildListSection(
            title: TransKeys.pending_approval.tr(),
            reimders: groupRemindersPending[true] ?? const [],
          ),
          _buildListSection(reimders: groupRemindersPending[false] ?? const []),
        ],
      ),
    );
  }

  Widget _buildListSection({
    String? title,
    required List<ReminderEntity> reimders,
  }) {
    if (reimders.isEmpty) return const SizedBox.shrink();

    final verticalList = ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: reimders.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _buildReminderCard(reimders[i]),
    );

    if (title == null) return verticalList;

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Color(0xFF222222),
              height: 1.3,
            ),
          ),
          const SizedBox(height: 12),

          SizedBox(
            height: 180,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: reimders.length,
              separatorBuilder: (_, __) => const SizedBox(width: 15),
              itemBuilder: (_, i) =>
                  SizedBox(width: 320, child: _buildReminderCard(reimders[i])),
            ),
          ),
        ],
      ),
    );
  }

  Map<bool, List<ReminderEntity>> _groupRemindersPending(
    List<ReminderEntity> reminders,
  ) {
    return reminders.fold<Map<bool, List<ReminderEntity>>>(
      {true: [], false: []},
      (map, reminder) {
        final isPending =
            ((reminder.approvalStatus == ApprovalStatus.pending &&
                reminder.ownerId == ref.read(currentUserProvider)?.uid) ||
            (reminder.approvalStatus == ApprovalStatus.pending &&
                    reminder.ownerId ==
                        ref.read(coupleProvider).value?.data?.id) &&
                reminder.createdBy != ref.read(currentUserProvider)?.uid);
        map[isPending]!.add(reminder);
        return map;
      },
    );
  }

  Widget _buildReminderCard(ReminderEntity reminder) {
    final viewModel = ref.read(reminderListViewModelProvider.notifier);
    final reminderState = ref.watch(reminderListViewModelProvider);
    final currentUserId = ref.read(currentUserProvider)?.uid;

    final isDoing =
        (reminder.ownerId == ref.read(coupleProvider).value?.data?.id &&
            reminder.createdBy != currentUserId)
        ? reminder.partnerReminderStatus == ReminderStatus.doing
        : reminder.reminderStatus == ReminderStatus.doing;
    ;
    final isSelected = viewModel.isReminderSelected(reminder);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (reminderState.isSelectionMode) {
          viewModel.toggleReminderSelection(reminder);
        } else {
          final isViewOnly =
              reminder.ownerId == ref.read(coupleProvider).value?.data?.id ||
              reminder.ownerId == ref.read(partnerProvider).value?.data?.uid;
          context.pushNamed(
            'reminder-form',
            extra: ReminderFormParams(
              reminder: reminder,
              isViewOnly: isViewOnly,
            ),
          );
        }
      },
      onLongPress: () {
        if (!reminderState.isSelectionMode &&
            reminder.ownerId != ref.read(partnerProvider).value?.data?.uid) {
          viewModel.enterSelectionMode(reminder);
          HapticFeedback.mediumImpact();
        }
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.1)
              : Colors.white,
          border: isSelected
              ? Border.all(color: AppColors.primary, width: 1.5)
              : null,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(10),
              blurRadius: 12,
              spreadRadius: 0,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              IntrinsicHeight(
                child: Row(
                  spacing: 6,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.access_time_rounded,
                                size: 18,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                DateTimeUtils.formatTimeWith24Hour(
                                  reminder.reminderDate,
                                ),
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: const Color.fromARGB(
                                    221,
                                    229,
                                    96,
                                    156,
                                  ),
                                  height: 1.1,
                                ),
                              ),
                            ],
                          ),

                          Text(
                            reminder.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                          ),

                          const SizedBox(height: 8),

                          Row(
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.calendar_today_rounded,
                                      size: 14,
                                      color: Colors.grey[600],
                                    ),
                                    const SizedBox(width: 6),
                                    Flexible(
                                      child: Text(
                                        getReminderDateContent(reminder),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[700],
                                          fontWeight: FontWeight.w500,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Transform.scale(
                          scale: 0.8,
                          child: Switch.adaptive(
                            value: isDoing,
                            activeThumbColor: AppColors.primary,
                            onChanged: (v) {
                              final currentUserId = ref
                                  .read(currentUserProvider)
                                  ?.uid;
                              final partnerId = ref
                                  .read(partnerProvider)
                                  .value
                                  ?.data
                                  ?.uid;
                              final coupleId = ref
                                  .read(coupleProvider)
                                  .value
                                  ?.data
                                  ?.id;

                              final canToggleOwn =
                                  reminder.approvalStatus !=
                                      ApprovalStatus.pending &&
                                  reminder.ownerId == currentUserId;

                              final canToggleCouple =
                                  reminder.ownerId == coupleId &&
                                  reminder.createdBy == currentUserId;
                              final canToggleCoupleAccepted =
                                  reminder.ownerId == coupleId &&
                                  reminder.approvalStatus !=
                                      ApprovalStatus.pending;

                              if (canToggleOwn ||
                                  canToggleCouple ||
                                  canToggleCoupleAccepted) {
                                _toggleReminderStatus(reminder);
                              } else if (reminder.ownerId == partnerId) {
                                CustomSnackBar.showWarning(
                                  context,
                                  message: TransKeys
                                      .error_cannot_toggle_partner_reminder
                                      .tr(),
                                );
                              } else {
                                CustomSnackBar.showWarning(
                                  context,
                                  message: TransKeys.unapproved_reminder.tr(),
                                );
                              }
                            },
                          ),
                        ),
                        Row(
                          spacing: 6,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              width: 16,
                              height: 16,
                              child: reminder.syncStatus == SyncStatus.pending
                                  ? const Icon(
                                      Icons.cloud_off_outlined,
                                      size: 16,
                                      color: Color(0xFF6B7280),
                                    )
                                  : null,
                            ),

                            if (reminder.isPrivate == true)
                              Icon(
                                Icons.lock_outline,
                                size: 16,
                                color: const Color(0xFF1F2937),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (reminder.approvalStatus == ApprovalStatus.pending) ...[
                const SizedBox(height: 8),
                Center(child: _buildApprovalSection(reminder, viewModel)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildApprovalSection(
    ReminderEntity reminder,
    ReminderViewModel viewModel,
  ) {
    final currentUserId = ref.read(currentUserProvider)?.uid;

    if (reminder.createdBy == currentUserId) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF7ED),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.hourglass_bottom_rounded,
              size: 12,
              color: const Color(0xFFB45309),
            ),
            const SizedBox(width: 6),
            Text(
              TransKeys.pending_approval.tr(),
              style: TextStyle(
                fontSize: 10,
                color: const Color(0xFFB45309),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          child: _buildPrimaryButton(
            text: TransKeys.accept.tr(),
            onTap: () => _approveReminder(reminder),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildGhostButton(
            text: TransKeys.reject.tr(),
            onTap: () => _rejectReminder(reminder),
          ),
        ),
      ],
    );
  }

  Widget _buildPrimaryButton({
    required String text,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: AppColors.primary,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withAlpha(50),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildGhostButton({
    required String text,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB)),
          color: Colors.white,
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Color(0xFF4B5563),
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton(
      heroTag: 'floating_reminder',
      onPressed: () async {
        debugPrint('🎯 Button pressed - scheduling notification');

        await LocalNotifications.scheduleNotification(
          id: 9999333,
          title: 'Test Reminder',
          body: 'Notification after 15 seconds',
          scheduledDate: DateTime.now().add(const Duration(seconds: 20)),
        );
      },
      backgroundColor: AppColors.primary,
      child: Icon(Icons.add, color: Colors.white),
    );
  }

  void _confirmDelete() async {
    final reminderState = ref.read(reminderListViewModelProvider);

    final confirmed = await CustomDialog.showConfirmDialog(
      context: context,
      title: TransKeys.delete_reminder.tr(),
      subtitle: reminderState.isSelectionMode
          ? '${TransKeys.confirm_delete.tr()} ${reminderState.selectedReminders.length} ${TransKeys.reminder.tr().toLowerCase()}s?'
          : '${TransKeys.confirm_delete_all.tr()} ${TransKeys.reminder.tr().toLowerCase()}s?',
      cancelText: TransKeys.cancel.tr(),
      confirmText: TransKeys.delete.tr(),
      isDanger: true,
    );

    if (confirmed == true) {
      _deleteReminders();
    }
  }

  Future<void> _deleteReminders() async {
    final viewModel = ref.read(reminderListViewModelProvider.notifier);
    final reminderState = ref.read(reminderListViewModelProvider);
    final connection = ref.watch(connectivityServiceProvider);
    final success;
    if (reminderState.isSelectionMode) {
      success = await viewModel.deleteSelectedReminders();
    } else {
      success = await viewModel.deleteAllReminders();
    }

    if (success && mounted) {
      if (!connection.isOnline) {
        CustomSnackBar.showSuccess(
          context,
          message: TransKeys.deleted_sync.tr(),
        );
      }
    }
  }

  void _toggleReminderStatus(ReminderEntity reminder) async {
    final viewModel = ref.read(reminderListViewModelProvider.notifier);
    final isCoupleNotCreatedBy =
        (reminder.ownerId == ref.read(coupleProvider).value?.data?.id &&
        reminder.createdBy != ref.read(currentUserProvider)?.uid);

    ReminderStatus? reminderStatus = isCoupleNotCreatedBy
        ? reminder.partnerReminderStatus
        : reminder.reminderStatus;

    ReminderStatus? newStatus;
    DateTime reminderDate = reminder.reminderDate;
    int newAlarmId = reminder.alarmId ?? -1;

    final now = DateTime.now();

    if (reminderStatus == ReminderStatus.done) {
      newStatus = ReminderStatus.doing;

      if (reminder.recurringType == RecurringType.none) {
        final reminderTime = TimeOfDay.fromDateTime(reminder.reminderDate);
        final todayWithReminderTime = DateTime(
          now.year,
          now.month,
          now.day,
          reminderTime.hour,
          reminderTime.minute,
        );

        if (todayWithReminderTime.isAfter(now)) {
          reminderDate = todayWithReminderTime;
        } else {
          reminderDate = todayWithReminderTime.add(const Duration(days: 1));
        }
      } else if (reminder.recurringType == RecurringType.daily) {
        reminderDate = DateTimeUtils.nextDailyFrom(reminder.reminderDate);
      } else {
        reminderDate = DateTimeUtils.nextWeeklyFrom(reminder.reminderDate);
      }

      newAlarmId = await AlarmService.scheduleWithRollback(
        reminderDate: reminderDate,
      );
    } else if (reminderStatus == ReminderStatus.overdue) {
      if (reminder.recurringType == RecurringType.none) {
        newStatus = ReminderStatus.doing;

        final reminderTime = TimeOfDay.fromDateTime(reminder.reminderDate);
        final todayWithReminderTime = DateTime(
          now.year,
          now.month,
          now.day,
          reminderTime.hour,
          reminderTime.minute,
        );

        if (todayWithReminderTime.isAfter(now)) {
          reminderDate = todayWithReminderTime;
        } else {
          reminderDate = todayWithReminderTime.add(const Duration(days: 1));
        }

        newAlarmId = await AlarmService.scheduleWithRollback(
          reminderDate: reminderDate,
        );
      }
    }
    //doing
    else {
      if (now.isAfter(reminderDate) &&
          reminder.recurringType == RecurringType.none) {
        newStatus = ReminderStatus.overdue;
        if (reminder.alarmId != null && reminder.alarmId! > 0) {
          await AlarmService.cancel(reminder.alarmId!);
        }
        newAlarmId = -1;
      } else {
        newStatus = ReminderStatus.done;
        if (reminder.alarmId != null && reminder.alarmId! > 0) {
          await AlarmService.cancel(reminder.alarmId!);
        }
        newAlarmId = -1;
      }
    }

    final updatedReminder = reminder.copyWith(
      alarmId: newAlarmId,
      reminderDate: reminderDate,
      updatedAt: DateTime.now(),
      reminderStatus: isCoupleNotCreatedBy
          ? reminder.reminderStatus
          : newStatus,
      partnerReminderStatus: isCoupleNotCreatedBy
          ? newStatus
          : reminder.partnerReminderStatus,
    );

    final success = await viewModel.toggleReminderStatus(updatedReminder);

    if (!success) {
      CustomSnackBar.showError(
        context,
        message: TransKeys.an_error_occurred.tr(),
      );
    }
  }

  void _approveReminder(ReminderEntity reminder) async {
    final viewModel = ref.read(reminderListViewModelProvider.notifier);
    DateTime reminderDate = reminder.reminderDate;
    final isCoupleNotCreatedBy =
        (reminder.ownerId == ref.read(coupleProvider).value?.data?.id &&
        reminder.createdBy != ref.read(currentUserProvider)?.uid);

    if (reminder.days != null && reminder.days!.isNotEmpty) {
      reminderDate = DateTimeUtils.getNextReminderDate(
        reminderDate,
        reminder.days!,
      );
    }

    if (reminderDate.isBefore(DateTime.now())) {
      await viewModel.updateReminder(
        reminder.copyWith(
          approvalStatus: ApprovalStatus.accepted,
          reminderStatus: isCoupleNotCreatedBy
              ? reminder.reminderStatus
              : ReminderStatus.overdue,
          partnerReminderStatus: isCoupleNotCreatedBy
              ? ReminderStatus.overdue
              : reminder.partnerReminderStatus,
          updatedAt: DateTime.now(),
        ),
      );

      CustomSnackBar.showWarning(
        context,
        message: TransKeys.reminder_date_have_expired.tr(),
      );
      return;
    }

    try {
      final alarmId = await AlarmService.scheduleWithRollback(
        reminderDate: reminderDate,
        alarmId: reminder.alarmId ?? -1,
      );

      final success = await viewModel.updateReminder(
        reminder.copyWith(
          alarmId: alarmId,
          reminderDate: reminderDate,
          updatedAt: DateTime.now(),
          approvalStatus: ApprovalStatus.accepted,
          reminderStatus: isCoupleNotCreatedBy
              ? reminder.reminderStatus
              : ReminderStatus.doing,
          partnerReminderStatus: isCoupleNotCreatedBy
              ? ReminderStatus.doing
              : reminder.partnerReminderStatus,
        ),
      );

      if (!success) {
        CustomSnackBar.showError(
          context,
          message: TransKeys.an_error_occurred.tr(),
        );
      }
    } catch (e) {
      CustomSnackBar.showError(
        context,
        message: TransKeys.an_error_occurred.tr(),
      );
    }
  }

  void _rejectReminder(ReminderEntity reminder) async {
    final viewModel = ref.read(reminderListViewModelProvider.notifier);

    final success = await viewModel.deleteReminder(
      reminder,
      ref.read(currentUserProvider)!.uid,
    );

    viewModel.updateReminder(
      reminder.copyWith(
        updatedAt: DateTime.now(),
        approvalStatus: ApprovalStatus.rejected,
      ),
    );

    if (!success) {
      CustomSnackBar.showError(
        context,
        message: TransKeys.an_error_occurred.tr(),
      );
    }
  }
}
