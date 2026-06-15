import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/rides/presentation/create_ride_screen.dart';
import '../../features/rides/presentation/search_ride_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/auth/presentation/welcome_routes_screen.dart';
import '../../features/auth/presentation/auth_controller.dart';
import '../../shared/widgets/main_scaffold.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authControllerProvider);

  return GoRouter(
    initialLocation: '/login',
    // AuthGuard reattivo: usa lo stato del controller invece di leggere il disco ogni volta
    redirect: (context, state) {
      final isLoggedIn = authState.status == AuthStatus.authenticated;
      final isGoingToLogin = state.matchedLocation == '/login';

      // Se non è loggato e non sta andando al login, forzalo al login
      if (!isLoggedIn && !isGoingToLogin) {
        return '/login';
      }

      // Se è loggato e prova ad andare al login, mandalo al benvenuto
      if (isLoggedIn && isGoingToLogin) {
        return '/benvenuto';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: '/benvenuto',
        builder: (_, __) => const WelcomeRoutesScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) {
          final location = state.matchedLocation;
          String title = 'UniMove';
          if (location == '/home') {
            title = 'Home';
          } else if (location == '/esplora') {
            title = 'Esplora';
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
            builder: (_, __) => const HomeScreen(),
          ),
          GoRoute(
            path: '/corse/crea',
            builder: (_, __) => const CreateRideScreen(),
          ),
          GoRoute(
            path: '/corse/cerca',
            builder: (_, __) => const SearchRideScreen(),
          ),
          GoRoute(
            path: '/profilo',
            builder: (_, __) => const ProfileScreen(),
          ),
          GoRoute(
            path: '/esplora',
            builder: (_, __) => const Center(
              child: Text('Esplora', style: TextStyle(color: Colors.black54)),
            ),
          ),
        ],
      ),
    ],
  );
});