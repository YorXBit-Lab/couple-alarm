import 'package:couple_note/core/config/app_constants.dart';
import 'package:couple_note/core/constants/trans_keys.dart';
import 'package:couple_note/core/services/Admob/rewarded_ad_manager%20.dart';
import 'package:couple_note/core/utils/datetime_utils.dart';
import 'package:couple_note/core/utils/utils.dart';
import 'package:couple_note/di/dependency_injection.dart';
import 'package:couple_note/domain/entities/invitation.dart';
import 'package:couple_note/domain/entities/user.dart';
import 'package:couple_note/domain/repositories/invitation_repository.dart';
import 'package:couple_note/presentation/themes/app_colors.dart';
import 'package:couple_note/presentation/widgets/base/avatar_picker_widget.dart';
import 'package:couple_note/presentation/widgets/base/custom_dialog_widget.dart';
import 'package:couple_note/presentation/widgets/base/snackbar.dart';
import 'package:couple_note/providers/auth_provider.dart';
import 'package:couple_note/providers/connect_provider.dart';
import 'package:couple_note/providers/user_provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

class CoupleConnectPage extends ConsumerStatefulWidget {
  const CoupleConnectPage({Key? key}) : super(key: key);

  @override
  ConsumerState<CoupleConnectPage> createState() => _CoupleConnectPageState();
}

class _CoupleConnectPageState extends ConsumerState<CoupleConnectPage> {
  @override
  void initState() {
    super.initState();
    RewardedAdManager().loadAd();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final connectionState = ref.watch(connectionViewModelProvider);
    final currentUser = ref.read(currentUserProvider);

    final couple = ref.watch(coupleProvider).value?.data;
    final partner = ref.watch(partnerProvider).value?.data;

    final connectViewModel = ref.read(connectionViewModelProvider.notifier);

    return Scaffold(
      backgroundColor: const Color(0xFFFFF5F7),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF2D3748)),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          couple != null
              ? TransKeys.connection_info.tr()
              : TransKeys.connect_to_lover.tr(),
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: Color(0xFF2D3748),
          ),
        ),
        backgroundColor: const Color(0xFFFFF5F7),
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: couple != null
          ? _buildConnectedView(couple, partner, currentUser, connectViewModel)
          : _buildNotConnectedView(
              connectionState,
              currentUser,
              connectViewModel,
            ),
      bottomNavigationBar: couple != null
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: _buildPrimaryButton(
                  // icon: Icons.video_collection,
                  onPressed: () => {
                    // RewardedAdManager().showAd(
                    //   onUserEarnedReward: () {

                    //   },
                    // ),
                    _showResetConfirmDialog(context),
                  },
                  label: TransKeys.reset.tr(),
                  backgroundColor: Colors.red,
                  height: 53,
                  isLoading: connectionState.isLoading,
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildConnectedView(
    dynamic couple,
    dynamic partner,
    UserEntity? currentUser,
    dynamic connectViewModel,
  ) {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 24),

          // Avatar
          Stack(
            children: [
              (ref.watch(connectivityServiceProvider).isOnline &&
                      partner?.photoURL != null)
                  ? CircleAvatar(
                      radius: 50,
                      foregroundImage: NetworkImage(partner!.photoURL!),
                    )
                  : CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.grey[300],
                      child: Icon(
                        Icons.person,
                        size: 30,
                        color: Colors.grey[700],
                      ),
                    ),

              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: () => _showAvatarPicker(context, ref, partner),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF6B9D),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(
                      Icons.edit,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,

            children: [
              Text(
                ' ${getName(partner)}',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2D3748),
                ),
              ),
              IconButton(
                onPressed: () => editNickname(context),
                icon: const Icon(
                  Icons.edit,
                  size: 20,
                  color: Color.fromARGB(255, 131, 149, 173),
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),

          const SizedBox(height: 4),

          // Email
          Text(
            partner?.email ?? '',
            style: const TextStyle(fontSize: 14, color: Color(0xFF64748B)),
          ),

          const SizedBox(height: 32),

          Container(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),

              child: Column(
                children: [
                  _buildInfoCard(
                    TransKeys.status.tr(),
                    TransKeys.connected.tr(),
                    isStatus: true,
                  ),
                  const SizedBox(height: 12),

                  _buildInfoCard(
                    TransKeys.in_love_since.tr(),
                    couple.loveStartDate == null
                        ? 'Unknown'
                        : DateTimeUtils.formatDate(couple.loveStartDate!),
                    hasEditIcon: true,
                    onEditPressed: () => _showDatePicker(context),
                  ),

                  const SizedBox(height: 12),

                  _buildInfoCard(
                    TransKeys.days_in_love.tr(),
                    couple?.loveStartDate == null
                        ? 'Unknown'
                        : '${calculateDaysTogether(couple!.loveStartDate)} ${TransKeys.days.tr()}',
                    isPink: true,
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Future<void> editNickname(BuildContext context) async {
    final partner = ref.watch(partnerProvider).value?.data;
    final newNickname = await CustomDialog.showInputDialog(
      context: context,
      title: TransKeys.edit_nickname.tr(),
      initialValue: getName(partner),
      hintText: TransKeys.enter_a_nickname.tr(),
      maxLength: 14,
      cancelText: TransKeys.cancel.tr(),
      confirmText: TransKeys.save.tr(),
    );

    if (newNickname != null) {
      try {
        final result = await ref
            .read(updateNicknameUseCaseProvider)
            .call(partner?.uid ?? '', newNickname.trim());

        if (result.isFailure) {
          CustomSnackBar.showError(
            context,
            message: TransKeys.an_error_occurred.tr(),
          );
        }
      } catch (e) {}
    }
  }

  Widget _buildInfoCard(
    String label,
    String value, {
    bool isStatus = false,
    bool isPink = false,
    bool hasEditIcon = false,
    VoidCallback? onEditPressed,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFEC4899).withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
          if (isStatus)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            )
          else
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    color: isPink
                        ? const Color(0xFFEC4899)
                        : const Color(0xFF2D3748),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (hasEditIcon) ...[
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: onEditPressed,
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: const Icon(
                        Icons.edit,
                        size: 14,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ),
                ],
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildNotConnectedView(
    dynamic connectionState,
    UserEntity? currentUser,
    dynamic connectViewModel,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            TransKeys.share_qr_to_connect_with.tr(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              color: Color(0xFF64748B),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 32),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF64748B).withValues(alpha: 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                Text(
                  TransKeys.your_qr_code.tr(),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2D3748),
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFFE2E8F0),
                      width: 2,
                    ),
                  ),
                  child: QrImageView(
                    data: currentUser?.uid ?? '',
                    version: QrVersions.auto,
                    size: 180.0,
                    foregroundColor: const Color(0xFF2D3748),
                    backgroundColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'ID: ${currentUser?.uid ?? 'N/A'}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF64748B),
                      letterSpacing: 0.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          Row(
            children: [
              Expanded(
                child: _buildPrimaryButton(
                  onPressed: connectionState.isLoading
                      ? null
                      : () => context.pushNamed('scanner'),
                  icon: Icons.qr_code_scanner_outlined,
                  label: TransKeys.Connect.tr(),
                  isLoading: connectionState.isLoading,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSecondaryButton(
                  onPressed: () => _shareConnectionLink(currentUser),
                  icon: Icons.share_outlined,
                  label: TransKeys.share.tr(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildOutlinedButton(
            onPressed: () => _copyConnectionLink(context, currentUser),
            icon: Icons.content_copy_outlined,
            label: TransKeys.conpy_the_connection_code.tr(),
          ),
          const SizedBox(height: 32),

          StreamBuilder<List<InvitationWithUser>>(
            stream: connectViewModel.getPendingInvitationsUseCase(
              currentUser!.uid,
            ),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final invitations = snapshot.data;
              return _buildInvitationsList(invitations);
            },
          ),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFEC4899).withValues(alpha: 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.lightbulb_outline,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      TransKeys.connection_instructions.tr(),
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: Color(0xFF2D3748),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildInstructionItem(
                  TransKeys.share_qr_code_or_link.tr(),
                  '1',
                ),
                _buildInstructionItem(
                  TransKeys.or_scan_your_lovers_qr.tr(),
                  '2',
                ),
                _buildInstructionItem(
                  TransKeys.confirm_connection_and_start.tr(),
                  '3',
                ),
              ],
            ),
          ),

          if (connectionState.isLoading)
            Padding(
              padding: const EdgeInsets.only(top: 32),
              child: Column(
                children: [
                  const SizedBox(
                    width: 32,
                    height: 32,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    TransKeys.connecting.tr(),
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _showResetConfirmDialog(BuildContext context) async {
    final currentUserId = ref.read(currentUserProvider)!.uid;
    final loverId = ref.read(partnerProvider).value?.data!.uid ?? '';
    final coupleId = ref.read(coupleProvider).value?.data!.id ?? '';

    final confirmed =
        await CustomDialog.showConfirmDialog(
          context: context,
          title: TransKeys.reset.tr(),
          subtitle:
              '${TransKeys.this_will_delete_all_data.tr()}\n${TransKeys.are_u_sure_continue.tr()}',
          cancelText: TransKeys.cancel.tr(),
          confirmText: TransKeys.reset.tr(),
          isDanger: true,
        ) ??
        false;

    if (confirmed) {
      final isSuccess = await ref
          .read(connectionViewModelProvider.notifier)
          .disconnect(currentUserId, loverId, coupleId);

      if (isSuccess) {
        Navigator.pop(context);
        CustomSnackBar.showSuccess(
          context,
          message: TransKeys.disconnected_successfully.tr(),
        );
      }
    }
  }

  Widget _buildInvitationsList(List<InvitationWithUser>? invitations) {
    if (invitations == null || invitations.isEmpty) {
      return const SizedBox();
    }

    final pendingInvitations = invitations
        .where(
          (invWrapper) =>
              invWrapper.invitation.status == InvitationStatus.pending,
        )
        .toList();

    if (pendingInvitations.isEmpty) {
      return const SizedBox();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.mail_outline, size: 20, color: Color(0xFF9333EA)),
            const SizedBox(width: 8),
            Text(
              TransKeys.invitation_to_connect.tr(),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color(0xFF2D3748),
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${pendingInvitations.length}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF9333EA),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...pendingInvitations
            .map((invitationWrapper) => _buildInvitationCard(invitationWrapper))
            .toList(),
      ],
    );
  }

  Widget _buildInvitationCard(InvitationWithUser invitationWrapper) {
    final invitation = invitationWrapper.invitation;
    final currentUserId = ref.read(currentUserProvider)?.uid ?? '';
    final isReceiver = invitation.toUserId == currentUserId;
    final isSender = invitation.fromUserId == currentUserId;

    final displayUser = isSender
        ? invitationWrapper.toUser
        : invitationWrapper.fromUser;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFEC4899).withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              displayUser?.photoURL != null && displayUser!.photoURL!.isNotEmpty
                  ? CircleAvatar(
                      radius: 20,
                      backgroundImage: NetworkImage(displayUser.photoURL!),
                    )
                  : CircleAvatar(
                      radius: 20,
                      backgroundColor: AppColors.primary,
                      child: Text(
                        displayUser?.displayName.isNotEmpty == true
                            ? displayUser!.displayName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayUser?.displayName ?? 'Anonymous',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2D3748),
                      ),
                    ),
                    if (displayUser?.email != null &&
                        displayUser!.email.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        displayUser.email,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                    const SizedBox(height: 2),
                    if (!isSender)
                      Text(
                        TransKeys.want_to_connect.tr(),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                      ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: isSender
                          ? const Color(0xFFF59E0B).withValues(alpha: 0.2)
                          : AppColors.primary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Icon(
                      isSender
                          ? Icons.schedule_outlined
                          : Icons.person_add_outlined,
                      color: isSender
                          ? const Color(0xFFF59E0B)
                          : AppColors.primary,
                      size: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateTimeUtils.getTimeAgo(
                      invitation?.createdAt ?? DateTime.now(),
                    ),
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (isReceiver) ...[
            Row(
              spacing: 10,
              children: [
                Expanded(
                  child: _buildPrimaryButton(
                    onPressed: () => _acceptInvitation(invitation),
                    icon: null,
                    label: TransKeys.accept.tr(),
                  ),
                ),
                Expanded(
                  child: _buildPrimaryButton(
                    onPressed: () => _declineInvitation(invitation),
                    icon: null,
                    label: TransKeys.reject.tr(),
                    backgroundColor: Colors.grey,
                  ),
                ),
              ],
            ),
          ] else if (isSender) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.schedule,
                    size: 14,
                    color: Color(0xFFF59E0B),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    TransKeys.pending_approval.tr(),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFFF59E0B),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _acceptInvitation(InvitationEntity invitation) async {
    final connectViewModel = ref.read(connectionViewModelProvider.notifier);
    await connectViewModel.updateInvitationStatusUseCase(
      invitation,
      ApprovalStatus.accepted,
    );
  }

  void _showAvatarPicker(
    BuildContext context,
    WidgetRef ref,
    UserEntity? user,
  ) {
    if (user == null) {
      return;
    }

    AvatarPickerBottomSheet.show(
      context: context,
      onCameraTap: () => _uploadAvatar(context, ref, user, ImageSource.camera),
      onGalleryTap: () =>
          _uploadAvatar(context, ref, user, ImageSource.gallery),
    );
  }

  Future<void> _uploadAvatar(
    BuildContext context,
    WidgetRef ref,
    UserEntity user,
    ImageSource source,
  ) async {
    final uploadService = ref.read(avatarUploadServiceProvider);

    await uploadService.uploadAndUpdateAvatar(
      userId: user.uid,
      source: source,
      context: context,
      onUpdate: (newAvatarUrl) async {
        final updatedUser = user.copyWith(photoURL: newAvatarUrl);
        await ref.read(updateUserUseCaseProvider).call(updatedUser);
      },
    );
  }

  Future<void> _declineInvitation(InvitationEntity invitation) async {
    final connectViewModel = ref.read(connectionViewModelProvider.notifier);
    await connectViewModel.updateInvitationStatusUseCase(
      invitation,
      ApprovalStatus.rejected,
    );
  }

  Widget _buildPrimaryButton({
    required VoidCallback? onPressed,
    IconData? icon,
    Color? backgroundColor,
    required String label,
    bool isLoading = false,
    double? height,
  }) {
    return SizedBox(
      width: double.infinity,
      height: height ?? 48,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: isLoading
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : icon == null
            ? null
            : Icon(icon, size: 18),
        label: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor == null
              ? AppColors.primary
              : backgroundColor,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildSecondaryButton({
    required VoidCallback onPressed,
    required IconData icon,
    Color? backgroundColor,
    required String label,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor != null
              ? backgroundColor
              : AppColors.primary.withValues(alpha: 0.8),
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildOutlinedButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
    bool isDestructive = false,
  }) {
    final color = isDestructive
        ? const Color(0xFFEF4444)
        : const Color(0xFF64748B);

    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 14,
            color: color,
          ),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color.withValues(alpha: 0.3)),
          backgroundColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildInstructionItem(String text, String number) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                text,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF475569),
                  height: 1.4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _shareConnectionLink(UserEntity? user) {
    final link = user?.uid ?? "";
    SharePlus.instance.share(
      ShareParams(
        text: '${TransKeys.plan_together.tr()} 💕\n$link',
        subject: TransKeys.couple_note_connection_invitation.tr(),
      ),
    );
  }

  void _copyConnectionLink(BuildContext context, UserEntity? user) {
    final link = user?.uid ?? '';
    Clipboard.setData(ClipboardData(text: link));

    CustomSnackBar.showSuccess(
      context,
      message: TransKeys.copied_connection_code.tr(),
    );
  }

  void _showDatePicker(BuildContext context) async {
    final couple = ref.watch(coupleProvider).value?.data;
    final connection = ref.watch(connectivityServiceProvider);
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(primary: AppColors.primary),
            chipTheme: ChipThemeData(selectedColor: AppColors.primary),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final updateCoupleProvider = ref.read(updateCoupleUseCaseProvider);
      await updateCoupleProvider(couple!.copyWith(loveStartDate: picked));
      if (!connection.isOnline)
        CustomSnackBar.showError(
          context,
          message: TransKeys.added_love_day_sync.tr(),
        );
    }
  }
}
