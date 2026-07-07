import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/rides/presentation/create_ride_screen.dart';
import '../../features/rides/presentation/search_ride_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/profile/presentation/edit_personal_info_screen.dart';
import '../../features/profile/presentation/edit_preferences_screen.dart';
import '../../features/profile/presentation/edit_iban_screen.dart';
import '../../features/profile/presentation/edit_routes_screen.dart';
import '../../features/profile/presentation/settings_screen.dart';
import '../../features/chat/presentation/chat_screen.dart';
import '../../features/auth/presentation/welcome_routes_screen.dart';
import '../../features/auth/presentation/auth_controller.dart';
import '../../shared/widgets/main_scaffold.dart';
import '../../shared/theme/app_theme.dart';

/// Un Listenable reattivo per notificare GoRouter quando lo stato di autenticazione cambia
class RouterTransitionListener extends ChangeNotifier {
  RouterTransitionListener(Ref ref) {
    ref.listen(authControllerProvider, (_, __) {
      notifyListeners();
    });
  }
}

final routerTransitionListenerProvider = Provider((ref) => RouterTransitionListener(ref));

final appRouterProvider = Provider<GoRouter>((ref) {
  // Watch instead of read to ensure the router rebuilds/re-evaluates when listenable changes
  final listenable = ref.watch(routerTransitionListenerProvider);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: listenable,
    redirect: (context, state) {
      final authState = ref.read(authControllerProvider);
      final status = authState.status;
      final location = state.matchedLocation;

      // Se sta caricando lo stato iniziale della sessione, mantieni l'utente sulla splash screen
      if (status == AuthStatus.loading) {
        return '/splash';
      }

      final isLoggedIn = status == AuthStatus.authenticated;

      // Se non è loggato e non sta andando al login, forzalo al login
      if (!isLoggedIn) {
        if (location != '/login') {
          return '/login';
        }
        return null;
      }

      // Se l'utente è loggato e si trova su una rotta iniziale (login o splash)
      // Legge isOnboardingCompleted direttamente dall'AuthState (già caricato in _init/login)
      if (location == '/login' || location == '/splash') {
        return authState.isOnboardingCompleted ? '/home' : '/benvenuto';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const Scaffold(
          backgroundColor: AppColors.deepBlack,
          body: Center(
            child: CircularProgressIndicator(color: AppColors.universityGreen),
          ),
        ),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/benvenuto',
        builder: (context, state) => const WelcomeRoutesScreen(),
      ),
      GoRoute(
        path: '/profilo/edit-info',
        builder: (context, state) => const EditPersonalInfoScreen(),
      ),
      GoRoute(
        path: '/profilo/edit-preferences',
        builder: (context, state) => const EditPreferencesScreen(),
      ),
      GoRoute(
        path: '/profilo/edit-iban',
        builder: (context, state) => const EditIbanScreen(),
      ),
      GoRoute(
        path: '/profilo/edit-routes',
        builder: (context, state) => const EditRoutesScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) {
          final location = state.matchedLocation;
          String title = 'UniMove';
          if (location == '/home') {
            title = 'Home';
          } else if (location == '/impostazioni') {
            title = 'Impostazioni';
          } else if (location == '/chat') {
            title = 'Chat';
          } else if (location == '/corse/crea') {
            title = 'Crea Corsa';
          } else if (location == '/corse/cerca') {
            title = 'Cerca Corsa';
          } else if (location == '/profilo') {
            title = 'Profilo';
          }
          return MainScaffold(
            title: title,
            currentRoute: location,
            body: child,
          );
        },
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/corse/crea',
            builder: (context, state) => const CreateRideScreen(),
          ),
          GoRoute(
            path: '/corse/cerca',
            builder: (context, state) => const SearchRideScreen(),
          ),
          GoRoute(
            path: '/profilo',
            builder: (context, state) => const ProfileScreen(),
          ),
          GoRoute(
            path: '/impostazioni',
            builder: (context, state) => const SettingsScreen(),
          ),
          GoRoute(
            path: '/chat',
            builder: (context, state) => const ChatScreen(),
          ),
        ],
      ),
    ],
  );
});