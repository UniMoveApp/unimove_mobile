import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/rides/presentation/create_ride_screen.dart';
import '../../features/rides/presentation/search_ride_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../services/auth_service.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authService = ref.watch(authServiceProvider);

  return GoRouter(
    initialLocation: '/login',
    // AuthGuard: redirect globale
    redirect: (context, state) async {
      final isLoggedIn = await authService.isAuthenticated();
      final isGoingToLogin = state.matchedLocation == '/login';

      if (!isLoggedIn && !isGoingToLogin) return '/login';
      if (isLoggedIn && isGoingToLogin) return '/home';
      return null; // nessun redirect
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (_, __) => const LoginScreen(),
      ),
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
    ],
  );
});