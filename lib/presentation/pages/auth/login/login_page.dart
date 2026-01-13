import 'package:couple_note/core/constants/trans_keys.dart';
import 'package:couple_note/presentation/themes/app_colors.dart';
import 'package:couple_note/presentation/viewmodels/auth_viewmodel.dart';
import 'package:couple_note/presentation/widgets/base/snackbar.dart';
import 'package:couple_note/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  @override
  Widget build(BuildContext context) {
    final authViewModel = ref.watch(authViewModelProvider);
    final authNotifier = ref.read(authViewModelProvider.notifier);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),

              // App Icon
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Image.asset(
                  'assets/images/app_icon/Icon_android.png',
                  height: 120,
                  width: 120,
                  fit: BoxFit.contain,
                ),
              ),

              const SizedBox(height: 40),

              Text(
                TransKeys.welcome_to.tr() + ' ' + TransKeys.app_name.tr(),
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                  letterSpacing: 0.5,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 12),

              Text(
                TransKeys.login_sub.tr(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                  height: 1.5,
                ),
              ),

              const Spacer(),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: authViewModel.isLoading
                      ? null
                      : () => _handleGoogleLogin(authNotifier),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 243, 242, 242),
                    foregroundColor: Colors.black87,
                    elevation: 0,
                  ),
                  child: authViewModel.isLoading
                      ? SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.primary,
                            ),
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset('assets/images/gg/google_logo.png'),
                            const SizedBox(width: 12),
                            Text(
                              TransKeys.continue_with_gg.tr(),
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 60),

              Padding(
                padding: const EdgeInsets.only(bottom: 24.0),
                child: Text(
                  TransKeys.cotinue_agree_terms.tr(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleGoogleLogin(AuthViewModel authNotifier) async {
    await authNotifier.signInWithGoogle();

    if (mounted) {
      final authViewModel = ref.read(authViewModelProvider.notifier);

      if (authViewModel.state.errorMessage != null)
        CustomSnackBar.showError(
          context,
          message: authViewModel.state.errorMessage!,
        );
      context.pushNamed('home');
    }
  }
}
