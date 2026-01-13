import 'package:couple_note/core/services/lib/core/local_storage_service.dart';
import 'package:couple_note/di/dependency_injection.dart';
import 'package:couple_note/domain/entities/reminder.dart';
import 'package:couple_note/presentation/pages/alarm/alarm_screen.dart';
import 'package:couple_note/presentation/pages/auth/login/login_page.dart';
import 'package:couple_note/presentation/pages/auth/register/register_page.dart';
import 'package:couple_note/presentation/pages/connect/connect_page.dart';
import 'package:couple_note/presentation/pages/connect/scanner_page.dart';
import 'package:couple_note/presentation/pages/home/home_page.dart';
import 'package:couple_note/presentation/pages/home/timer_page.dart';
import 'package:couple_note/presentation/pages/onboarding/onboarding_page.dart';
import 'package:couple_note/presentation/pages/reminder/reminder_form_page.dart';
import 'package:couple_note/presentation/pages/reminder/reminder_page.dart';
import 'package:couple_note/presentation/pages/setting/setting_page.dart';
import 'package:couple_note/presentation/pages/welcome/welcome_page.dart';
import 'package:couple_note/presentation/routes/bottom_navigation.dart';
import 'package:couple_note/presentation/viewmodels/auth_viewmodel.dart';
import 'package:couple_note/providers/auth_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();

class AppRouter {
  static GoRouter createRouter(String initialLocation, WidgetRef ref) {
    return GoRouter(
      navigatorKey: rootNavigatorKey,
      initialLocation: initialLocation,
      debugLogDiagnostics: true,

      redirect: (context, state) {
        final firebaseUser = FirebaseAuth.instance.currentUser;

        final isAuthenticated = firebaseUser != null;
        final currentPath = state.matchedLocation;

        final publicRoutes = [
          '/reminder',
          '/onboarding',
          '/login',
          '/register',
        ];
        final isPublicRoute =
            publicRoutes.contains(currentPath) ||
            currentPath.startsWith('/alarm/');

        final prefs = ref.read(sharedPreferencesProvider);
        final isFirstLaunch = prefs.getBool(StorageKeys.firstLaunch) ?? true;

        if (isFirstLaunch) {
          prefs.setBool(StorageKeys.firstLaunch, false);
          return '/onboarding';
        }

        if (isAuthenticated &&
            (currentPath == '/login' || currentPath == '/register')) {
          final pending = prefs.getString(StorageKeys.pendingDeepLink);
          if (pending != null) {
            prefs.remove(StorageKeys.pendingDeepLink);
            return pending;
          }
          return '/home';
        }

        if (!isAuthenticated && !isPublicRoute) {
          prefs.setString(StorageKeys.pendingDeepLink, currentPath);
          return '/login';
        }

        return null;
      },
      refreshListenable: GoRouterRefreshStream(ref),

      routes: [
        GoRoute(
          path: '/',
          name: 'welcome',
          builder: (context, state) => WelcomePage(),
        ),
        GoRoute(
          path: '/onboarding',
          name: 'onboarding',
          pageBuilder: (context, state) {
            return CustomTransitionPage(
              key: state.pageKey,
              child: OnboardingPage(),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                    return FadeTransition(opacity: animation, child: child);
                  },
            );
          },
        ),
        GoRoute(
          path: '/login',
          name: 'login',
          builder: (context, state) => LoginPage(),
        ),
        GoRoute(
          path: '/register',
          name: 'register',
          builder: (context, state) => RegisterPage(),
        ),
        GoRoute(
          path: '/reminder-form',
          name: 'reminder-form',
          builder: (context, state) {
            final params = state.extra as ReminderFormParams?;
            return ReminderFormPage(
              reminder: params?.reminder,
              isViewOnly: params?.isViewOnly ?? false,
            );
          },
        ),
        GoRoute(
          path: '/alarm/:id',
          name: 'alarm',
          builder: (context, state) {
            final idStr = state.pathParameters['id'];
            final alarmId = int.tryParse(idStr ?? '');
            if (alarmId == null) {
              return HomePage();
            }
            return AlarmScreen(alarmId: alarmId);
          },
        ),

        ShellRoute(
          builder: (context, state, child) {
            return child;
          },
          routes: [
            GoRoute(
              path: '/connect',
              name: 'connect',
              builder: (context, state) => const CoupleConnectPage(),
            ),
            GoRoute(
              path: '/scanner',
              name: 'scanner',
              builder: (context, state) => QRScannerPage(),
            ),

            StatefulShellRoute.indexedStack(
              builder: (context, state, navigationShell) {
                return BottomNavigationScaffold(
                  navigationShell: navigationShell,
                );
              },
              branches: [
                StatefulShellBranch(
                  routes: [
                    GoRoute(
                      path: '/home',
                      name: 'home',
                      builder: (context, state) => HomePage(),
                      routes: [
                        GoRoute(
                          path: 'timer',
                          name: 'timer',
                          builder: (context, state) {
                            return TimerPage();
                          },
                        ),
                      ],
                    ),
                  ],
                ),
                StatefulShellBranch(
                  routes: [
                    GoRoute(
                      path: '/reminder',
                      name: 'reminder',
                      builder: (context, state) => RemindersPage(),
                    ),
                  ],
                ),

                StatefulShellBranch(
                  routes: [
                    GoRoute(
                      path: '/setting',
                      name: 'setting',
                      builder: (context, state) => SettingsPage(),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

class GoRouterRefreshStream extends ChangeNotifier {
  final WidgetRef _ref;

  GoRouterRefreshStream(this._ref) {
    _ref.listenManual<AuthViewState>(authViewModelProvider, (previous, next) {
      if (previous?.isAuthenticated != next.isAuthenticated) {
        notifyListeners();
      }
    }, fireImmediately: false);
  }
}

class ReminderFormParams {
  final ReminderEntity? reminder;
  final bool isViewOnly;

  const ReminderFormParams({this.reminder, this.isViewOnly = false});
}
