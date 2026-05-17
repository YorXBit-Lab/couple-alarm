import 'package:couple_note/core/common/api_response.dart';
import 'package:couple_note/core/config/app_constants.dart';
import 'package:couple_note/core/config/routers/router.dart';
import 'package:couple_note/core/services/Admob/interstitial_ad_manager.dart';
import 'package:couple_note/core/services/alarm/alarm_service.dart';
import 'package:couple_note/core/utils/datetime_utils.dart';
import 'package:couple_note/core/utils/utils.dart';
import 'package:couple_note/core/providers/global_providers.dart';
import 'package:couple_note/features/connect/presentation/provider/connect_notifier.dart';
import 'package:couple_note/features/invitation/domain/entities/invitation.dart';
import 'package:couple_note/features/reminder/domain/entities/reminder.dart';
import 'package:couple_note/features/invitation/domain/repository/invitation_repository.dart';
import 'package:couple_note/features/reminder/domain/repository/reminder_repository.dart';
import 'package:couple_note/core/config/theme/app_colors.dart';
import 'package:couple_note/common/widgets/Admob/banner_widget.dart';
import 'package:couple_note/common/widgets/base/snackbar.dart';
import 'package:couple_note/features/auth/presentation/provider/auth_provider.dart';
import 'package:couple_note/features/couple/presentation/provider/couple_notifier.dart';
import 'package:couple_note/features/reminder/presentation/provider/reminder_notifier.dart';
import 'package:couple_note/features/reminder/presentation/provider/reminder_provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:couple_note/core/constants/trans_keys.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePage();
}

class _HomePage extends ConsumerState<HomePage> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final InterstitialAdManager _interstitialAdManager = InterstitialAdManager();

  @override
  void initState() {
    super.initState();

    _interstitialAdManager.loadAd();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(currentUserStreamProvider).value?.data;
      if (user != null) {
        ref.read(coupleProvider.notifier).getCoupleByUserId(user.uid);
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF5F0),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Stack(
            children: [
              Column(
                children: [
                  _buildHeader(),
                  _buildNextAlarmBanner(),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.only(bottom: 100),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildPendingSection(),
                          _buildFilterTabs(),
                          _buildAlarmList(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: BannerAdWidget(),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'home_fab',
        onPressed: () => context.pushNamed('reminder-form'),
        backgroundColor: AppColors.primary,
        elevation: 4,
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }

  // ─── Header ───────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    final currentUser = ref.watch(currentUserStreamProvider).value?.data;
    final partner = ref.watch(partnerProvider).value?.data;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_getGreeting()}, ${getName(currentUser)}',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[500],
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 2),
                RichText(
                  text: const TextSpan(
                    children: [
                      TextSpan(
                        text: 'Alarms ',
                        style: TextStyle(
                          fontSize: 27,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF1A1A1A),
                          letterSpacing: -0.5,
                        ),
                      ),
                      TextSpan(
                        text: 'together',
                        style: TextStyle(
                          fontSize: 27,
                          fontWeight: FontWeight.w900,
                          fontStyle: FontStyle.italic,
                          color: Color(0xFF1A1A1A),
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => context.pushNamed('setting'),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.07),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.settings_outlined,
                size: 18,
                color: Colors.grey[600],
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 58,
            height: 38,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  right: 0,
                  child: _buildAvatarCircle(
                    photoUrl: partner?.photoURL,
                    initial: getName(partner),
                    color: const Color(0xFFD4C0F0),
                    size: 36,
                  ),
                ),
                Positioned(
                  left: 0,
                  child: Container(
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFFFDF5F0),
                    ),
                    padding: const EdgeInsets.all(2),
                    child: _buildAvatarCircle(
                      photoUrl: currentUser?.photoURL,
                      initial: getName(currentUser),
                      color: const Color(0xFFE8A0C0),
                      size: 34,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarCircle({
    String? photoUrl,
    required String initial,
    required Color color,
    double size = 36,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: ClipOval(
        child: photoUrl != null && photoUrl.isNotEmpty
            ? Image.network(photoUrl, fit: BoxFit.cover)
            : Center(
                child: Text(
                  initial.isNotEmpty ? initial[0].toUpperCase() : '?',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
      ),
    );
  }

  // ─── Next Alarm Banner ────────────────────────────────────────────────────

  Widget _buildNextAlarmBanner() {
    final reminders = ref.watch(reminderProvider).reminders;
    final currentUserId = ref.read(currentUserProvider)?.uid;
    final coupleId = ref.read(coupleStreamProvider).value?.data?.id;
    final now = DateTime.now();

    final upcoming = reminders.where((r) {
      final isDoing =
          (r.ownerId == coupleId && r.createdBy != currentUserId)
              ? r.partnerReminderStatus == ReminderStatus.doing
              : r.reminderStatus == ReminderStatus.doing;
      return isDoing && r.reminderDate.isAfter(now);
    }).toList()
      ..sort((a, b) => a.reminderDate.compareTo(b.reminderDate));

    if (upcoming.isEmpty) return const SizedBox.shrink();

    final next = upcoming.first;
    final diff = next.reminderDate.difference(now);
    final hours = diff.inHours;
    final minutes = diff.inMinutes % 60;

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 14),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(Icons.alarm_rounded, size: 14, color: AppColors.primary),
          const SizedBox(width: 7),
          Text(
            'Next in ${hours}h ${minutes}m',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
          Text(
            ' · ',
            style: TextStyle(fontSize: 12, color: Colors.grey[400]),
          ),
          Expanded(
            child: Text(
              "'${next.title}' · ${DateTimeUtils.formatTimeWithAMPM(next.reminderDate)}",
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Pending Section ──────────────────────────────────────────────────────

  Widget _buildPendingSection() {
    final connectNotifier = ref.read(connectProvider.notifier);
    final currentUser = ref.read(currentUserStreamProvider).value?.data;
    final coupleAsync = ref.watch(coupleStreamProvider);
    final couple = coupleAsync.value?.data;

    if (currentUser == null) return const SizedBox.shrink();

    final pendingReminders = ref
        .read(getFilteredRemindersWithOptionsUseCaseProvider)
        .call(
          currentUser.uid,
          const ReminderFilterOptions(approvalStatus: ['pending']),
          currentUser.uid,
        );

    if (couple == null) {
      final coupleRequest = connectNotifier.getPendingInvitationsUseCase(
        currentUser.uid,
      );
      return StreamBuilder<List<InvitationWithUser>>(
        stream: coupleRequest,
        builder: (context, invSnapshot) {
          return StreamBuilder<ApiResponse<List<ReminderEntity>>>(
            stream: pendingReminders,
            builder: (context, remSnapshot) {
              final invitations = invSnapshot.data ?? [];
              final reminders = remSnapshot.data?.data ?? [];
              final hasPending = invitations.isNotEmpty || reminders.isNotEmpty;
              if (!hasPending) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.fromLTRB(0, 0, 0, 4),
                child: Column(
                  children: [
                    ...invitations
                        .where(
                          (i) =>
                              i.invitation.status == InvitationStatus.pending &&
                              i.invitation.fromUserId != currentUser.uid,
                        )
                        .map((inv) => _buildConnectionRequestCard(inv)),
                    ...reminders.map((r) => _buildPartnerReminderCard(r)),
                  ],
                ),
              );
            },
          );
        },
      );
    } else {
      return StreamBuilder<ApiResponse<List<ReminderEntity>>>(
        stream: pendingReminders,
        builder: (context, snapshot) {
          final reminders = snapshot.data?.data ?? [];
          if (reminders.isEmpty) return const SizedBox.shrink();
          return Padding(
            padding: const EdgeInsets.fromLTRB(0, 0, 0, 4),
            child: Column(
              children: reminders.map((r) => _buildPartnerReminderCard(r)).toList(),
            ),
          );
        },
      );
    }
  }

  Widget _buildConnectionRequestCard(InvitationWithUser invWrapper) {
    final invitation = invWrapper.invitation;
    final fromUser = invWrapper.fromUser;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'CONNECTION REQUEST',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                _buildAvatarCircle(
                  photoUrl: fromUser?.photoURL,
                  initial: fromUser?.displayName ?? '?',
                  color: const Color(0xFFC8A8D8),
                  size: 42,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${fromUser?.displayName ?? 'Someone'} wants to connect',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        DateTimeUtils.getTimeAgo(invitation.createdAt),
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: _buildOutlinedActionButton(
                    label: 'Ignore',
                    onTap: () => _declineInvitation(ref, invitation),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildGradientActionButton(
                    label: 'Connect',
                    icon: Icons.favorite_rounded,
                    colors: const [Color(0xFF9B6FD4), Color(0xFFB88CE8)],
                    onTap: () => _acceptInvitation(ref, invitation),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPartnerReminderCard(ReminderEntity reminder) {
    final partner = ref.read(partnerProvider).value?.data;
    final partnerName = getName(partner);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF0ECFF),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              children: [
                Icon(Icons.favorite_rounded, size: 10, color: AppColors.primary),
                const SizedBox(width: 6),
                Text(
                  'NEW FROM ${partnerName.toUpperCase()}',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                _buildAvatarCircle(
                  photoUrl: partner?.photoURL,
                  initial: partnerName,
                  color: const Color(0xFFB09CDC),
                  size: 42,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$partnerName set an alarm for you',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        "${DateTimeUtils.formatTimeWithAMPM(reminder.reminderDate)} · '${reminder.title}'",
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: _buildOutlinedActionButton(
                    label: TransKeys.reject.tr(),
                    onTap: () => _rejectReminder(reminder),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildGradientActionButton(
                    label: TransKeys.accept.tr(),
                    icon: Icons.favorite_rounded,
                    colors: const [Color(0xFFFF8C7A), Color(0xFFFFAA85)],
                    onTap: () => _approveReminder(reminder),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOutlinedActionButton({
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE0E0E0)),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF555555),
          ),
        ),
      ),
    );
  }

  Widget _buildGradientActionButton({
    required String label,
    required IconData icon,
    required List<Color> colors,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: colors),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: Colors.white),
            const SizedBox(width: 5),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Filter Tabs ──────────────────────────────────────────────────────────

  Widget _buildFilterTabs() {
    final reminderState = ref.watch(reminderProvider);
    final partner = ref.watch(partnerProvider).value?.data;
    final locale = context.locale;
    final tabs = ref.watch(tabsProvider((partner, locale.languageCode)));

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          spacing: 8,
          children: tabs.map((tab) {
            final isSelected = reminderState.currentTab == tab.key;
            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                ref.read(reminderProvider.notifier).changeTab(tab.key);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF1A1A1A)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: isSelected
                      ? null
                      : [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                ),
                child: Text(
                  tab.label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : Colors.grey[700],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // ─── Alarm List ───────────────────────────────────────────────────────────

  Widget _buildAlarmList() {
    final reminderState = ref.watch(reminderProvider);
    final partner = ref.watch(partnerProvider).value?.data;

    if (reminderState.isLoading) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (reminderState.currentTab != 'all' &&
        (reminderState.currentTab == 'couple' ||
            reminderState.currentTab == 'partner') &&
        partner == null) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.favorite_border, size: 40, color: Colors.grey[300]),
              const SizedBox(height: 12),
              Text(
                TransKeys.invitation_request_content.tr(),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () => context.pushNamed('connect'),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, Color(0xFFFF9BB0)],
                    ),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Text(
                    TransKeys.connect_now.tr(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (reminderState.reminders.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 32, 20, 0),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.alarm_off_outlined, size: 44, color: Colors.grey[300]),
              const SizedBox(height: 12),
              Text(
                TransKeys.Add_new_reminder_to_get_add.tr(),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: reminderState.reminders.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) => _buildAlarmCard(reminderState.reminders[i]),
      ),
    );
  }

  Widget _buildAlarmCard(ReminderEntity reminder) {
    final currentUserId = ref.read(currentUserProvider)?.uid;
    final partnerId = ref.read(partnerProvider).value?.data?.uid;
    final partnerName = getName(ref.read(partnerProvider).value?.data);
    final currentUserName = getName(ref.read(currentUserStreamProvider).value?.data);
    final coupleId = ref.read(coupleStreamProvider).value?.data?.id;
    final notifier = ref.read(reminderProvider.notifier);
    final reminderState = ref.watch(reminderProvider);

    final isCoupleNotCreatedBy =
        reminder.ownerId == coupleId && reminder.createdBy != currentUserId;
    final isDoing = isCoupleNotCreatedBy
        ? reminder.partnerReminderStatus == ReminderStatus.doing
        : reminder.reminderStatus == ReminderStatus.doing;

    final isFromPartner = reminder.createdBy == partnerId;
    final isSelected = notifier.isReminderSelected(reminder);

    final isPending = reminder.approvalStatus == ApprovalStatus.pending;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (reminderState.isSelectionMode) {
          notifier.toggleReminderSelection(reminder);
        } else {
          final isViewOnly =
              reminder.ownerId == coupleId ||
              reminder.ownerId == partnerId;
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
            reminder.ownerId != partnerId) {
          notifier.enterSelectionMode(reminder);
          HapticFeedback.mediumImpact();
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.08)
              : const Color(0xFFEDE8FF),
          borderRadius: BorderRadius.circular(22),
          border: isSelected
              ? Border.all(color: AppColors.primary, width: 1.5)
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Attribution row + toggle
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 14, 0),
              child: Row(
                children: [
                  _buildAvatarCircle(
                    photoUrl: isFromPartner
                        ? ref.read(partnerProvider).value?.data?.photoURL
                        : ref.read(currentUserStreamProvider).value?.data?.photoURL,
                    initial: isFromPartner ? partnerName : currentUserName,
                    color: isFromPartner
                        ? const Color(0xFFB09CDC)
                        : const Color(0xFFE8A0C0),
                    size: 22,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isFromPartner
                        ? 'From $partnerName  ·  to $currentUserName'
                        : 'From $currentUserName',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  Transform.scale(
                    scale: 0.75,
                    child: Switch.adaptive(
                      value: isDoing,
                      activeThumbColor: AppColors.primary,
                      activeTrackColor: AppColors.primary.withValues(alpha: 0.4),
                      onChanged: isPending
                          ? null
                          : (v) => _toggleReminderStatus(reminder),
                    ),
                  ),
                ],
              ),
            ),
            // Time
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
              child: Text(
                DateTimeUtils.formatTimeWithAMPM(reminder.reminderDate),
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1A1A1A),
                  letterSpacing: -1,
                  height: 1.1,
                ),
              ),
            ),
            // Title
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              child: Text(
                reminder.title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF333333),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Schedule info + pending badge
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 14),
              child: Row(
                children: [
                  Icon(Icons.replay_rounded, size: 13, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(
                    getReminderDateContent(reminder),
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  if (reminder.isSound) ...[
                    const SizedBox(width: 12),
                    Icon(Icons.volume_up_rounded, size: 13, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Text(
                      'Sound',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                  if (isPending) ...[
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        TransKeys.pending_approval.tr(),
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.deepOrange,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // Accept/Decline row for pending from partner
            if (isPending && isFromPartner)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildOutlinedActionButton(
                        label: TransKeys.reject.tr(),
                        onTap: () => _rejectReminder(reminder),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildGradientActionButton(
                        label: TransKeys.accept.tr(),
                        icon: Icons.favorite_rounded,
                        colors: const [Color(0xFFFF8C7A), Color(0xFFFFAA85)],
                        onTap: () => _approveReminder(reminder),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ─── Business Logic ───────────────────────────────────────────────────────

  void _approveReminder(ReminderEntity reminder) async {
    final notifier = ref.read(reminderProvider.notifier);
    DateTime reminderDate = reminder.reminderDate;
    final isCoupleNotCreatedBy =
        (reminder.ownerId == ref.read(coupleStreamProvider).value?.data?.id &&
            reminder.createdBy !=
                ref.read(currentUserStreamProvider).value?.data?.uid);

    if (reminder.days != null && reminder.days!.isNotEmpty) {
      reminderDate = DateTimeUtils.getNextReminderDate(
        reminderDate,
        reminder.days!,
      );
    }

    if (reminderDate.isBefore(DateTime.now())) {
      await notifier.updateReminder(
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

      final success = await notifier.updateReminder(
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

      if (success) {
        if (mounted) {
          CustomSnackBar.showSuccess(context, message: TransKeys.accepted.tr());
        }
      } else {
        if (mounted) {
          CustomSnackBar.showError(
            context,
            message: TransKeys.an_error_occurred.tr(),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        CustomSnackBar.showError(
          context,
          message: TransKeys.an_error_occurred.tr(),
        );
      }
    }
  }

  void _rejectReminder(ReminderEntity reminder) async {
    final notifier = ref.read(reminderProvider.notifier);

    final success = await notifier.deleteReminder(
      reminder,
      ref.read(currentUserStreamProvider).value?.data?.uid ?? '',
    );

    notifier.updateReminder(
      reminder.copyWith(
        updatedAt: DateTime.now(),
        approvalStatus: ApprovalStatus.rejected,
      ),
    );

    if (mounted) {
      if (success) {
        CustomSnackBar.showSuccess(context, message: TransKeys.rejected.tr());
      } else {
        CustomSnackBar.showError(
          context,
          message: TransKeys.an_error_occurred.tr(),
        );
      }
    }
  }

  Future<void> _acceptInvitation(
    WidgetRef ref,
    InvitationEntity invitation,
  ) async {
    final connectNotifier = ref.read(connectProvider.notifier);
    await connectNotifier.updateInvitationStatusUseCase(
      invitation,
      ApprovalStatus.accepted,
    );
  }

  Future<void> _declineInvitation(
    WidgetRef ref,
    InvitationEntity invitation,
  ) async {
    final connectNotifier = ref.read(connectProvider.notifier);
    await connectNotifier.updateInvitationStatusUseCase(
      invitation,
      ApprovalStatus.rejected,
    );
  }

  void _toggleReminderStatus(ReminderEntity reminder) async {
    final notifier = ref.read(reminderProvider.notifier);
    final currentUserId = ref.read(currentUserProvider)?.uid;
    final coupleId = ref.read(coupleStreamProvider).value?.data?.id;
    final partnerId = ref.read(partnerProvider).value?.data?.uid;

    final isCoupleNotCreatedBy =
        reminder.ownerId == coupleId && reminder.createdBy != currentUserId;
    ReminderStatus? reminderStatus = isCoupleNotCreatedBy
        ? reminder.partnerReminderStatus
        : reminder.reminderStatus;

    ReminderStatus? newStatus;
    DateTime reminderDate = reminder.reminderDate;
    int newAlarmId = reminder.alarmId ?? -1;
    final now = DateTime.now();

    final canToggleOwn =
        reminder.approvalStatus != ApprovalStatus.pending &&
        reminder.ownerId == currentUserId;
    final canToggleCouple =
        reminder.ownerId == coupleId && reminder.createdBy == currentUserId;
    final canToggleCoupleAccepted =
        reminder.ownerId == coupleId &&
        reminder.approvalStatus != ApprovalStatus.pending;

    if (!canToggleOwn && !canToggleCouple && !canToggleCoupleAccepted) {
      if (reminder.ownerId == partnerId) {
        CustomSnackBar.showWarning(
          context,
          message: TransKeys.error_cannot_toggle_partner_reminder.tr(),
        );
      } else {
        CustomSnackBar.showWarning(
          context,
          message: TransKeys.unapproved_reminder.tr(),
        );
      }
      return;
    }

    if (reminderStatus == ReminderStatus.done) {
      newStatus = ReminderStatus.doing;
      if (reminder.recurringType == RecurringType.none) {
        final reminderTime = TimeOfDay.fromDateTime(reminder.reminderDate);
        final todayWithTime = DateTime(
          now.year,
          now.month,
          now.day,
          reminderTime.hour,
          reminderTime.minute,
        );
        reminderDate = todayWithTime.isAfter(now)
            ? todayWithTime
            : todayWithTime.add(const Duration(days: 1));
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
        final todayWithTime = DateTime(
          now.year,
          now.month,
          now.day,
          reminderTime.hour,
          reminderTime.minute,
        );
        reminderDate = todayWithTime.isAfter(now)
            ? todayWithTime
            : todayWithTime.add(const Duration(days: 1));
        newAlarmId = await AlarmService.scheduleWithRollback(
          reminderDate: reminderDate,
        );
      }
    } else {
      if (now.isAfter(reminderDate) &&
          reminder.recurringType == RecurringType.none) {
        newStatus = ReminderStatus.overdue;
      } else {
        newStatus = ReminderStatus.done;
      }
      if (reminder.alarmId != null && reminder.alarmId! > 0) {
        await AlarmService.cancel(reminder.alarmId!);
      }
      newAlarmId = -1;
    }

    if (newStatus == null) return;

    final success = await notifier.toggleReminderStatus(
      reminder.copyWith(
        alarmId: newAlarmId,
        reminderDate: reminderDate,
        updatedAt: DateTime.now(),
        reminderStatus: isCoupleNotCreatedBy ? reminder.reminderStatus : newStatus,
        partnerReminderStatus:
            isCoupleNotCreatedBy ? newStatus : reminder.partnerReminderStatus,
      ),
    );

    if (!success && mounted) {
      CustomSnackBar.showError(
        context,
        message: TransKeys.an_error_occurred.tr(),
      );
    }
  }
}
