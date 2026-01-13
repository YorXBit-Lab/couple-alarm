import 'package:couple_note/core/constants/trans_keys.dart';
import 'package:couple_note/core/services/alarm/alarm_service.dart';
import 'package:couple_note/core/services/lib/core/local_storage_service.dart';
import 'package:couple_note/core/utils/datetime_utils.dart';
import 'package:couple_note/core/utils/utils.dart';
import 'package:couple_note/di/dependency_injection.dart';
import 'package:couple_note/domain/entities/reminder.dart';
import 'package:couple_note/domain/entities/user.dart';
import 'package:couple_note/presentation/themes/app_colors.dart';
import 'package:couple_note/presentation/widgets/base/avatar_picker_widget.dart';
import 'package:couple_note/presentation/widgets/base/custom_dialog_widget.dart';
import 'package:couple_note/presentation/widgets/base/snackbar.dart';
import 'package:couple_note/providers/auth_provider.dart';
import 'package:couple_note/providers/connect_provider.dart';
import 'package:couple_note/providers/user_provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:in_app_review/in_app_review.dart';

class AppSettings {
  final bool isNotificationEnabled;
  final bool isAutoSetReminder;
  final bool isDarkMode;

  const AppSettings({
    required this.isNotificationEnabled,
    required this.isAutoSetReminder,
    required this.isDarkMode,
  });

  AppSettings copyWith({
    bool? isAutoSetReminder,
    bool? isNotificationEnabled,
    bool? isDarkMode,
    bool? isPrivateMode,
    bool? isLocationEnabled,
    bool? isAutoSync,
  }) {
    return AppSettings(
      isNotificationEnabled:
          isNotificationEnabled ?? this.isNotificationEnabled,
      isAutoSetReminder: isAutoSetReminder ?? this.isAutoSetReminder,
      isDarkMode: isDarkMode ?? this.isDarkMode,
    );
  }
}

class AppSettingsNotifier extends StateNotifier<AppSettings> {
  final LocalStorageService _storage;

  AppSettingsNotifier(this._storage)
    : super(
        AppSettings(
          isAutoSetReminder: _storage.getAutoSetReminderEnabled(),
          isNotificationEnabled: _storage.getNotificationEnabled(),
          isDarkMode: _storage.getThemeMode() == 'dark',
        ),
      );

  Future<void> toggleNotification(bool value) async {
    await _storage.setNotificationEnabled(value);
    state = state.copyWith(isNotificationEnabled: value);
  }

  Future<void> toggleAutoSetReminder(bool value) async {
    await _storage.setAutoSetReminderEnabled(value);
    state = state.copyWith(isNotificationEnabled: value);
  }

  Future<void> toggleDarkMode(bool value) async {
    await _storage.setThemeMode(value ? 'dark' : 'light');
    state = state.copyWith(isDarkMode: value);
  }
}

final appSettingsProvider =
    StateNotifierProvider<AppSettingsNotifier, AppSettings>((ref) {
      final storage = ref.watch(localStorageServiceProvider);
      return AppSettingsNotifier(storage);
    });

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  final InAppReview _inAppReview = InAppReview.instance;
  bool _isAvailability = false;
  @override
  void initState() {
    super.initState();
    (<T>(T? o) => o!)(WidgetsBinding.instance).addPostFrameCallback((_) async {
      try {
        final isAvailable = await _inAppReview.isAvailable();
        setState(() {
          _isAvailability = isAvailable;
        });
      } catch (_) {
        setState(() => _isAvailability = false);
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<String> versionString() async {
    final info = await PackageInfo.fromPlatform();
    return '${info.version} (${info.buildNumber})';
  }

  Future<void> requestReview() async {
    if (_isAvailability) {
      await _inAppReview.requestReview();
    } else {
      await _inAppReview.openStoreListing();
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserStreamProvider).value?.data;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          TransKeys.setting.tr(),
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 20),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProfileSection(),
              const SizedBox(height: 24),
              _buildSectionTitle(TransKeys.couple_infor.tr()),
              _buildSettingsCard([
                _buildSettingsTile(
                  icon: Icons.favorite,
                  title: TransKeys.connection_info.tr(),
                  subtitle: TransKeys.see_code_and_share.tr(),
                  onTap: () => {context.pushNamed('connect')},
                ),
                // _buildSettingsTile(
                //   icon: Icons.person,
                //   title: TransKeys.lover_infor.tr(),
                //   subtitle: TransKeys.view_lover_profile.tr(),
                //   onTap: () => {
                //     if (partner != null)
                //       {_showPartnerInfoBottomSheet(context)}
                //     else
                //       {
                //         CustomSnackBar.showWarning(
                //           context,
                //           message: TransKeys.you_are_not_connected_to_anyone
                //               .tr(),
                //         ),
                //       },
                //   },
                // ),
              ]),
              const SizedBox(height: 24),

              _buildSectionTitle(TransKeys.setting.tr()),
              _buildSettingsCard([
                _buildSwitchTile(
                  icon: Icons.notifications,
                  title: TransKeys.automatic_reminder.tr(),
                  subtitle: TransKeys.auto_accept.tr(),
                  value:
                      currentUser?.isAutoApproveReminder ??
                      false, // Thêm ? để tránh lỗi null
                  onChanged: (value) => _updateIsAutoApproveReminder(value),
                ),
                // _buildSwitchTile(
                //   icon: Icons.dark_mode,
                //   title: 'Chế độ tối',
                //   subtitle: 'Giao diện tối cho mắt',
                //   value: settings.isDarkMode,
                //   onChanged: (value) => ref
                //       .read(appSettingsProvider.notifier)
                //       .toggleDarkMode(value),
                // ),
                _buildSettingsTile(
                  icon: Icons.language,
                  title: TransKeys.language.tr(),
                  subtitle: context.locale.languageCode,
                  onTap: () => _showLanguageDialog(context),
                ),
              ]),

              const SizedBox(height: 24),

              _buildSectionTitle(TransKeys.support_infor.tr()),
              _buildSettingsCard([
                // _buildSettingsTile(
                //   icon: Icons.help,
                //   title: 'Hướng dẫn sử dụng',
                //   subtitle: 'Cách sử dụng ứng dụng',
                //   onTap: () => {},
                // ),
                _buildSettingsTile(
                  icon: Icons.privacy_tip,
                  title: TransKeys.privacy_policy.tr(),
                  subtitle: TransKeys.terms_policy.tr(),
                  onTap: () => {
                    launchUrl(
                      Uri.parse(
                        'https://couple-note-a3e5d.web.app/csae-policy.html',
                      ),
                    ),
                  },
                ),
                _buildSettingsTile(
                  icon: Icons.star,
                  title: TransKeys.rating_app.tr(),
                  subtitle: TransKeys.help_us_be_better.tr(),
                  onTap: () async => await requestReview(),
                ),

                _buildSettingsTile(
                  icon: Icons.email_outlined,
                  title: TransKeys.contact_us.tr(),
                  subtitle: TransKeys.contact_us_subtitle.tr(),
                  onTap: () async {
                    final String email = 'YorXBit@gmail.com';
                    final String subject = Uri.encodeComponent(
                      TransKeys.contact_us_subject.tr(),
                    );
                    final Uri mailUri = Uri.parse(
                      'mailto:$email?subject=$subject',
                    );

                    if (await canLaunchUrl(mailUri)) {
                      await launchUrl(mailUri);
                    } else {
                      CustomSnackBar.showError(
                        context,
                        message: TransKeys.an_error_occurred.tr(),
                      );
                    }
                  },
                ),
                FutureBuilder<String>(
                  future: versionString(),
                  builder: (context, snapshot) {
                    return _buildSettingsTile(
                      icon: Icons.info,
                      title: TransKeys.about_app.tr(),
                      subtitle:
                          '${TransKeys.version.tr()} ${snapshot.data ?? ''}',
                      onTap: () => _showAboutDialog(context),
                    );
                  },
                ),
              ]),

              const SizedBox(height: 24),

              _buildSectionTitle(TransKeys.account.tr()),
              _buildSettingsCard([
                _buildSettingsTile(
                  icon: Icons.person_off_outlined,
                  title: TransKeys.delete_account.tr(),
                  subtitle: TransKeys.delete_account_subtitle.tr(),
                  onTap: () => {
                    launchUrl(
                      Uri.parse(
                        'https://docs.google.com/forms/d/e/1FAIpQLScpQrLo3Z388P2ueD5-4mnGeejZk-RYt1l7AQAHwUP9kohceA/viewform',
                      ),
                    ),
                  },
                ),
              ]),

              const SizedBox(height: 24),

              _buildLogoutButton(context),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _updateIsAutoApproveReminder(bool value) async {
    final currentUser = ref.read(currentUserStreamProvider).value?.data;

    if (currentUser == null) return;

    try {
      final result = await ref
          .read(updateIsAutoApproveReminderUseCaseProvider)
          .call(currentUser.uid, value);

      if (result.isSuccess) {
        await ref.read(authViewModelProvider.notifier).refreshUser();
        ref
            .read(localStorageServiceProvider)
            .saveUser(currentUser, StorageKeys.user);
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

  void _showLanguageDialog(BuildContext context) {
    final currentUser = ref.watch(currentUserStreamProvider).value?.data;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('select_language'.tr()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Text('🇻🇳'),
              title: Text('Tiếng Việt'),
              onTap: () async {
                context.setLocale(Locale('vi'));
                var user = currentUser?.copyWith(languageCode: 'vi');
                await ref.read(updateUserUseCaseProvider).call(user!);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Text('🇺🇸'),
              title: Text('English'),
              onTap: () async {
                context.setLocale(Locale('en'));
                var user = currentUser?.copyWith(languageCode: 'en');
                await ref.read(updateUserUseCaseProvider).call(user!);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSection() {
    final currentUser = ref.watch(currentUserStreamProvider).value?.data;
    final partner = ref.watch(partnerProvider).value?.data;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Stack(
                children: [
                  (ref.watch(connectivityServiceProvider).isOnline &&
                          currentUser?.photoURL != null)
                      ? Padding(
                          padding: const EdgeInsets.all(6.0),
                          child: CircleAvatar(
                            radius: 25,

                            foregroundImage: NetworkImage(
                              currentUser!.photoURL!,
                            ),
                          ),
                        )
                      : CircleAvatar(
                          radius: 25,
                          backgroundColor: Colors.grey[300],
                          child: Icon(
                            Icons.person,
                            size: 25,
                            color: Colors.grey[700],
                          ),
                        ),

                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: () => _showAvatarPicker(context, ref, currentUser),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF6B9D),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(
                          Icons.edit,
                          size: 12,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,

                      children: [
                        Text(
                          '${getName(currentUser, maxLength: 12)}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2D3748),
                          ),
                        ),
                        // IconButton(
                        //   onPressed: () => editNickname(context),
                        //   icon: const Icon(
                        //     Icons.edit,
                        //     size: 20,
                        //     color: Color.fromARGB(255, 131, 149, 173),
                        //   ),
                        //   padding: EdgeInsets.zero,
                        //   constraints: const BoxConstraints(),
                        // ),
                      ],
                    ),
                    Text(
                      currentUser?.email ?? TransKeys.not_updated_yet.tr(),
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 4),

                    Row(
                      children: [
                        if (partner != null) ...[
                          Expanded(
                            child: Text(
                              '${TransKeys.connected_with.tr()} ${getName(partner)} ',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAvatarPicker(
    BuildContext context,
    WidgetRef ref,
    UserEntity? currentUser,
  ) {
    if (currentUser == null) {
      return;
    }

    AvatarPickerBottomSheet.show(
      context: context,
      onCameraTap: () =>
          _uploadAvatar(context, ref, currentUser, ImageSource.camera),
      onGalleryTap: () =>
          _uploadAvatar(context, ref, currentUser, ImageSource.gallery),
    );
  }

  Future<void> _uploadAvatar(
    BuildContext context,
    WidgetRef ref,
    UserEntity currentUser,
    ImageSource source,
  ) async {
    final uploadService = ref.read(avatarUploadServiceProvider);

    await uploadService.uploadAndUpdateAvatar(
      userId: currentUser.uid,
      source: source,
      context: context,
      onUpdate: (newAvatarUrl) async {
        final updatedUser = currentUser.copyWith(photoURL: newAvatarUrl);
        await ref.read(updateUserUseCaseProvider).call(updatedUser);
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 20, color: Colors.grey[700]),
      ),
      title: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
      ),
      trailing: Icon(Icons.chevron_right, color: Colors.grey[400]),
      onTap: onTap,
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 20, color: Colors.grey[700]),
      ),
      title: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
      ),
      trailing: CupertinoSwitch(
        value: value,
        onChanged: onChanged,
        activeTrackColor: Colors.pink[400],
      ),
    );
  }

  void _showPartnerInfoBottomSheet(BuildContext context) {
    final partner = ref.watch(partnerProvider).value?.data;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PartnerInfoBottomSheet(
        uid: partner?.uid ?? '',
        nickname: partner?.nickname,
        avatar: partner?.avatar,
        email: partner?.email ?? '',
        displayName: partner?.displayName ?? '',
        photoURL: partner?.photoURL,
        createdAt: partner?.createdAt ?? DateTime.now(),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ElevatedButton(
        onPressed: () async {
          final user = ref.read(currentUserStreamProvider).value?.data;
          final couple = ref.read(coupleProvider).value?.data;

          if (user == null) return;

          final results = await Future.wait([
            ref.read(reminderRepositoryProvider).getRemindersByUser(user.uid),
            if (couple != null)
              ref
                  .read(reminderRepositoryProvider)
                  .getRemindersByUser(couple.id ?? ''),
          ]);

          final allReminders = results
              .expand((res) => res.data?.toList() ?? <ReminderEntity>[])
              .toList();

          if (allReminders.isNotEmpty) {
            await AlarmService.cancelAll(allReminders);
          }
          await ref.read(authViewModelProvider.notifier).signOut();

          if (!context.mounted) return;
          context.go('/login');
        },

        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red[50],
          foregroundColor: Colors.red[600],
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.red[200]!),
          ),
        ),
        child: Text(
          TransKeys.logout.tr(),
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Future<void> editNickname(BuildContext context) async {
    final partner = ref.read(partnerProvider).value?.data;
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

  void _showAboutDialog(BuildContext context) async {
    final info = await PackageInfo.fromPlatform();

    CustomDialog.showInfoDialog(
      context: context,
      title: TransKeys.about_app.tr(),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Couple Alarm',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            '${TransKeys.version.tr()} ${info.version} (${info.buildNumber})',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 16),
          Text(
            TransKeys.about_app_description.tr(),
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey.shade700,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '© 2025 YorXBit',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
          ),
        ],
      ),
      buttonText: TransKeys.close.tr(),
      primaryColor: AppColors.primary,
    );
  }
}

class PartnerInfoBottomSheet extends ConsumerStatefulWidget {
  final String uid;
  final String? nickname;
  final String? avatar;
  final String email;
  final String displayName;
  final String? photoURL;
  final DateTime createdAt;

  const PartnerInfoBottomSheet({
    Key? key,
    required this.uid,
    this.nickname,
    this.avatar,
    required this.email,
    required this.displayName,
    this.photoURL,
    required this.createdAt,
  }) : super(key: key);

  @override
  ConsumerState<PartnerInfoBottomSheet> createState() =>
      _PartnerInfoBottomSheetState();
}

class _PartnerInfoBottomSheetState
    extends ConsumerState<PartnerInfoBottomSheet> {
  final TextEditingController _nicknameController = TextEditingController();
  bool _isEditingNickname = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nicknameController.text = widget.nickname ?? '';
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  Future<void> _saveNickname() async {
    final partner = ref.watch(partnerProvider).value?.data;
    if (_nicknameController.text.trim().isEmpty) {
      CustomSnackBar.showSuccess(
        context,
        message: TransKeys.nickname_cannot_be_blank.tr(),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final result = await ref
          .read(updateNicknameUseCaseProvider)
          .call(partner?.uid ?? '', _nicknameController.text.trim());
      if (result.isSuccess) {
        CustomSnackBar.showSuccess(
          context,
          message: TransKeys.nickname_saved.tr(),
        );
        setState(() => _isEditingNickname = false);
      }
    } catch (e) {
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.7,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            TransKeys.lover_infor.tr(),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      Center(
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 35,
                              backgroundImage: widget.photoURL != null
                                  ? NetworkImage(widget.photoURL!)
                                  : null,
                              child: widget.photoURL == null
                                  ? Text(
                                      widget.displayName[0].toUpperCase(),
                                      style: const TextStyle(fontSize: 32),
                                    )
                                  : null,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              widget.displayName,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      _buildNicknameSection(),
                      const SizedBox(height: 24),

                      _buildInfoItem(
                        icon: Icons.email_outlined,
                        label: 'Email',
                        value: widget.email,
                      ),
                      const SizedBox(height: 16),

                      _buildInfoItem(
                        icon: Icons.calendar_today_outlined,
                        label: TransKeys.joined.tr(),
                        value: DateTimeUtils.formatDate(widget.createdAt),
                      ),
                      const SizedBox(height: 16),

                      _buildInfoItem(
                        icon: Icons.fingerprint,
                        label: TransKeys.user_id.tr(),
                        value: widget.uid,
                        showCopyButton: true,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildNicknameSection() {
    final partner = ref.watch(partnerProvider).value?.data;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                TransKeys.nickname.tr(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.black54,
                ),
              ),
              const Spacer(),
              if (!_isEditingNickname)
                GestureDetector(
                  onTap: () => setState(() => _isEditingNickname = true),
                  child: Icon(
                    Icons.edit,
                    size: 16,
                    color: Colors.blue.shade300,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),

          if (_isEditingNickname)
            Column(
              children: [
                TextField(
                  controller: _nicknameController,
                  decoration: InputDecoration(
                    hintText: TransKeys.enter_nickname_lover.tr(),
                    hintStyle: TextStyle(color: Colors.grey[400], fontSize: 12),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                  ),
                  autofocus: true,
                  enabled: !_isSaving,
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isSaving
                          ? null
                          : () {
                              _nicknameController.text = widget.nickname ?? '';
                              setState(() => _isEditingNickname = false);
                            },
                      child: Text(TransKeys.cancel.tr()),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _isSaving ? null : _saveNickname,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : Text(TransKeys.save.tr()),
                    ),
                  ],
                ),
              ],
            )
          else
            Text(
              partner?.nickname ?? TransKeys.no_nickname_yet.tr(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: partner?.nickname?.isNotEmpty == true
                    ? Colors.black87
                    : Colors.black38,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
    bool showCopyButton = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey.shade700, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(fontSize: 14, color: Colors.black87),
                ),
              ],
            ),
          ),
          if (showCopyButton)
            IconButton(
              icon: const Icon(Icons.copy, size: 18),
              onPressed: () {
                CustomSnackBar.showSuccess(
                  context,
                  message: TransKeys.id_copied.tr(),
                );
              },
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }
}
