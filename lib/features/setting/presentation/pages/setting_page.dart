import 'package:couple_note/core/constants/trans_keys.dart';
import 'package:couple_note/core/services/alarm/alarm_service.dart';
import 'package:couple_note/core/services/local_storage_service.dart';
import 'package:couple_note/core/utils/utils.dart';
import 'package:couple_note/core/providers/global_providers.dart';
import 'package:couple_note/features/auth/presentation/provider/auth_notifier.dart';
import 'package:couple_note/features/reminder/domain/entities/reminder.dart';
import 'package:couple_note/features/user/domain/entities/user.dart';
import 'package:couple_note/core/config/theme/app_colors.dart';
import 'package:couple_note/common/widgets/base/avatar_picker_widget.dart';
import 'package:couple_note/common/widgets/base/custom_dialog_widget.dart';
import 'package:couple_note/common/widgets/base/snackbar.dart';
import 'package:couple_note/features/auth/presentation/provider/auth_provider.dart';
import 'package:couple_note/features/connect/presentation/provider/connect_provider.dart';
import 'package:couple_note/features/reminder/presentation/provider/reminder_provider.dart';
import 'package:couple_note/features/user/presentation/provider/user_provider.dart';
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

// ─── Colors ──────────────────────────────────────────────────────────────────

const _kPink = Color(0xFFFF6B9D);
const _kLavender = Color(0xFFB39DDB);
const _kTeal = Color(0xFF4DB6AC);
const _kPurple = Color(0xFF9575CD);
const _kOrange = Color(0xFFFF8A65);
const _kRed = Color(0xFFE57373);
const _kGreen = Color(0xFF81C784);

// ─── Page ────────────────────────────────────────────────────────────────────

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
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final isAvailable = await _inAppReview.isAvailable();
        if (mounted) setState(() => _isAvailability = isAvailable);
      } catch (_) {
        if (mounted) setState(() => _isAvailability = false);
      }
    });
  }

  Future<String> _versionString() async {
    final info = await PackageInfo.fromPlatform();
    return '${info.version} (${info.buildNumber})';
  }

  Future<void> _requestReview() async {
    if (_isAvailability) {
      await _inAppReview.requestReview();
    } else {
      await _inAppReview.openStoreListing();
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserStreamProvider).value?.data;
    final partner = ref.watch(partnerProvider).value?.data;
    final couple = ref.watch(coupleStreamProvider).value?.data;
    final locale = context.locale;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F7FA),
      appBar: _buildAppBar(context, currentUser),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProfileCard(currentUser, partner, couple),
              const SizedBox(height: 24),

              _buildSectionHeader('PREFERENCES'),
              _buildCard([
                _buildSwitchRow(
                  color: _kPink,
                  icon: Icons.favorite_rounded,
                  title: 'Auto-accept alarms from ${partner != null ? getName(partner) : 'partner'}',
                  subtitle: 'Skip the confirmation for alarms from your partner',
                  value: currentUser?.isAutoApproveReminder ?? false,
                  onChanged: _updateIsAutoApproveReminder,
                ),
                _buildDivider(),
                _buildSwitchRow(
                  color: _kLavender,
                  icon: Icons.notifications_rounded,
                  title: 'Push notifications',
                  value: ref.watch(appSettingsProvider).isNotificationEnabled,
                  onChanged: (v) =>
                      ref.read(appSettingsProvider.notifier).toggleNotification(v),
                ),
                _buildDivider(),
                _buildNavRow(
                  color: _kTeal,
                  icon: Icons.language_rounded,
                  title: TransKeys.language.tr(),
                  trailing: locale.languageCode == 'vi' ? 'Tiếng Việt' : 'English',
                  onTap: () => _showLanguageDialog(context),
                ),
              ]),

              const SizedBox(height: 24),

              if (partner != null) ...[
                _buildSectionHeader('SHARING WITH ${getName(partner).toUpperCase()}'),
                _buildCard([
                  _buildNavRow(
                    color: _kPurple,
                    icon: Icons.qr_code_rounded,
                    title: TransKeys.connection_info.tr(),
                    subtitle: TransKeys.see_code_and_share.tr(),
                    onTap: () => context.pushNamed('connect'),
                  ),
                ]),
                const SizedBox(height: 24),
              ] else ...[
                _buildSectionHeader('COUPLE'),
                _buildCard([
                  _buildNavRow(
                    color: _kPurple,
                    icon: Icons.qr_code_rounded,
                    title: TransKeys.connection_info.tr(),
                    subtitle: TransKeys.see_code_and_share.tr(),
                    onTap: () => context.pushNamed('connect'),
                  ),
                ]),
                const SizedBox(height: 24),
              ],

              _buildSectionHeader('PRIVACY & DATA'),
              _buildCard([
                _buildNavRow(
                  color: _kGreen,
                  icon: Icons.privacy_tip_rounded,
                  title: TransKeys.privacy_policy.tr(),
                  subtitle: TransKeys.terms_policy.tr(),
                  onTap: () => launchUrl(
                    Uri.parse('https://couple-alarm-569c8.web.app/csae-policy.html'),
                  ),
                ),
                _buildDivider(),
                _buildNavRow(
                  color: _kOrange,
                  icon: Icons.star_rounded,
                  title: TransKeys.rating_app.tr(),
                  subtitle: TransKeys.help_us_be_better.tr(),
                  onTap: () async => await _requestReview(),
                ),
                _buildDivider(),
                _buildNavRow(
                  color: _kTeal,
                  icon: Icons.email_rounded,
                  title: TransKeys.contact_us.tr(),
                  subtitle: TransKeys.contact_us_subtitle.tr(),
                  onTap: _sendEmail,
                ),
                _buildDivider(),
                FutureBuilder<String>(
                  future: _versionString(),
                  builder: (context, snapshot) => _buildNavRow(
                    color: _kLavender,
                    icon: Icons.info_rounded,
                    title: TransKeys.about_app.tr(),
                    trailing: snapshot.data ?? '',
                    onTap: () => _showAboutDialog(context),
                  ),
                ),
              ]),

              const SizedBox(height: 24),

              _buildSectionHeader('ACCOUNT'),
              _buildCard([
                _buildNavRow(
                  color: _kRed,
                  icon: Icons.person_off_rounded,
                  title: TransKeys.delete_account.tr(),
                  subtitle: TransKeys.delete_account_subtitle.tr(),
                  onTap: () => launchUrl(
                    Uri.parse(
                      'https://docs.google.com/forms/d/e/1FAIpQLScpQrLo3Z388P2ueD5-4mnGeejZk-RYt1l7AQAHwUP9kohceA/viewform',
                    ),
                  ),
                ),
              ]),

              const SizedBox(height: 24),
              _buildLogoutButton(context),
            ],
          ),
        ),
      ),
    );
  }

  // ─── AppBar ───────────────────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    UserEntity? currentUser,
  ) {
    return AppBar(
      backgroundColor: const Color(0xFFF8F7FA),
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      leading: GestureDetector(
        onTap: () => context.pop(),
        child: const Icon(Icons.chevron_left_rounded, size: 28, color: Colors.black87),
      ),
      title: const Text(
        'Settings',
        style: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
      actions: [
        GestureDetector(
          onTap: () => _showAvatarPicker(context, ref, currentUser),
          child: Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Text(
              'Edit',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: AppColors.primary,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ─── Profile Card ─────────────────────────────────────────────────────────

  Widget _buildProfileCard(
    UserEntity? currentUser,
    UserEntity? partner,
    dynamic couple,
  ) {
    final daysTogetherText = _daysTogetherText(couple?.createdAt);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFCE4EC), Color(0xFFEDE7F6)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _showAvatarPicker(context, ref, currentUser),
            child: _buildAvatar(currentUser),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  getName(currentUser),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2D2D2D),
                  ),
                ),
                if (currentUser?.nickname?.isNotEmpty == true) ...[
                  const SizedBox(height: 2),
                  Text(
                    '"${currentUser!.nickname}"',
                    style: const TextStyle(
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                      color: Color(0xFF888888),
                    ),
                  ),
                ],
                if (partner != null) ...[
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => context.pushNamed('connect'),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.favorite_rounded, size: 13, color: _kPink),
                        const SizedBox(width: 4),
                        Text(
                          'with ${getName(partner)}${daysTogetherText != null ? ' · $daysTogetherText' : ''}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF666666),
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.chevron_right_rounded,
                          size: 14,
                          color: Color(0xFF999999),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(UserEntity? user) {
    return Stack(
      children: [
        Container(
          width: 68,
          height: 68,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFFF48FB1),
            boxShadow: [
              BoxShadow(
                color: _kPink.withValues(alpha: 0.25),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: (ref.watch(connectivityServiceProvider).isOnline &&
                  user?.photoURL != null)
              ? ClipOval(
                  child: Image.network(
                    user!.photoURL!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _avatarInitial(user),
                  ),
                )
              : _avatarInitial(user),
        ),
        Positioned(
          bottom: 2,
          right: 2,
          child: Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: _kPink,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: const Icon(Icons.edit_rounded, size: 10, color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _avatarInitial(UserEntity? user) {
    final name = getName(user);
    return Center(
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: const TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }

  String? _daysTogetherText(DateTime? since) {
    if (since == null) return null;
    final days = DateTime.now().difference(since).inDays;
    return '${days}d';
  }

  // ─── Section Header ───────────────────────────────────────────────────────

  Widget _buildSectionHeader(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Colors.grey[500],
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  // ─── Card wrapper ─────────────────────────────────────────────────────────

  Widget _buildCard(List<Widget> children) {
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
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      indent: 60,
      endIndent: 0,
      color: Colors.grey[100],
    );
  }

  // ─── Row types ────────────────────────────────────────────────────────────

  Widget _buildIconSquare(Color color, IconData icon) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Icon(icon, size: 18, color: Colors.white),
    );
  }

  Widget _buildNavRow({
    required Color color,
    required IconData icon,
    required String title,
    String? subtitle,
    String? trailing,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: [
            _buildIconSquare(color, icon),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) ...[
              Text(
                trailing,
                style: TextStyle(fontSize: 13, color: Colors.grey[500]),
              ),
              const SizedBox(width: 4),
            ],
            Icon(Icons.chevron_right_rounded, size: 18, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchRow({
    required Color color,
    required IconData icon,
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        children: [
          _buildIconSquare(color, icon),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                ],
              ],
            ),
          ),
          CupertinoSwitch(
            value: value,
            onChanged: onChanged,
            activeTrackColor: const Color(0xFF2B2B2B),
          ),
        ],
      ),
    );
  }

  // ─── Logout Button ────────────────────────────────────────────────────────

  Widget _buildLogoutButton(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final user = ref.read(currentUserStreamProvider).value?.data;
        final couple = ref.read(coupleStreamProvider).value?.data;
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
        await ref.read(authProvider.notifier).signOut();

        if (!context.mounted) return;
        context.go('/login');
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.red[100]!),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Text(
            TransKeys.logout.tr(),
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.red[400],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Actions ──────────────────────────────────────────────────────────────

  Future<void> _updateIsAutoApproveReminder(bool value) async {
    final currentUser = ref.read(currentUserStreamProvider).value?.data;
    if (currentUser == null) return;
    try {
      final result = await ref
          .read(updateIsAutoApproveReminderUseCaseProvider)
          .call(currentUser.uid, value);
      if (result.isSuccess) {
        await ref.read(authProvider.notifier).refreshUser();
        ref
            .read(localStorageServiceProvider)
            .saveUser(currentUser, StorageKeys.user);
      }
    } catch (_) {
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('select_language'.tr()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Text('🇻🇳'),
              title: const Text('Tiếng Việt'),
              onTap: () async {
                context.setLocale(const Locale('vi'));
                final user = currentUser?.copyWith(languageCode: 'vi');
                if (user != null) {
                  await ref.read(updateUserUseCaseProvider).call(user);
                }
                if (context.mounted) Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Text('🇺🇸'),
              title: const Text('English'),
              onTap: () async {
                context.setLocale(const Locale('en'));
                final user = currentUser?.copyWith(languageCode: 'en');
                if (user != null) {
                  await ref.read(updateUserUseCaseProvider).call(user);
                }
                if (context.mounted) Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendEmail() async {
    final subject = Uri.encodeComponent(TransKeys.contact_us_subject.tr());
    final mailUri = Uri.parse('mailto:YorXBit@gmail.com?subject=$subject');
    if (await canLaunchUrl(mailUri)) {
      await launchUrl(mailUri);
    } else if (mounted) {
      CustomSnackBar.showError(context, message: TransKeys.an_error_occurred.tr());
    }
  }

  void _showAvatarPicker(
    BuildContext context,
    WidgetRef ref,
    UserEntity? currentUser,
  ) {
    if (currentUser == null) return;
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
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            '${TransKeys.version.tr()} ${info.version} (${info.buildNumber})',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: Colors.grey.shade600),
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

// ─── Partner Info Bottom Sheet ────────────────────────────────────────────────

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
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isSaving = false);
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
                            style: const TextStyle(
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
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.black54,
                ),
              ),
              const Spacer(),
              if (!_isEditingNickname)
                GestureDetector(
                  onTap: () => setState(() => _isEditingNickname = true),
                  child: Icon(Icons.edit, size: 16, color: Colors.blue.shade300),
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
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
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
