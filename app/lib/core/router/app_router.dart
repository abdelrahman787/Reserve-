import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/catalog/presentation/pages/product_details_page.dart';
import '../../features/shell/home_shell.dart';
import 'refresh_stream.dart';

class AppRouter {
  AppRouter(this._client);
  final SupabaseClient _client;

  late final GoRouter router = GoRouter(
    initialLocation: '/login',
    refreshListenable: GoRouterRefreshStream(_client.auth.onAuthStateChange),
    redirect: (context, state) {
      final loggedIn = _client.auth.currentSession != null;
      final goingToAuth =
          state.matchedLocation == '/login' || state.matchedLocation == '/register';

      if (!loggedIn && !goingToAuth) return '/login';
      if (loggedIn && goingToAuth) return '/home';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginPage()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterPage()),
      GoRoute(path: '/home', builder: (_, __) => const HomeShell()),
      GoRoute(
        path: '/product/:id',
        builder: (_, state) =>
            ProductDetailsPage(productId: state.pathParameters['id']!),
      ),
    ],
  );
}
