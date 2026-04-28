import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'route_names.dart';

// Replaced with real AuthBloc listener in PR 6
bool _isAuthenticated = false;

final appRouter = GoRouter(
  initialLocation: RouteNames.splash,
  redirect: (context, state) {
    final isAuthRoute = state.matchedLocation == RouteNames.signIn ||
        state.matchedLocation == RouteNames.signUp ||
        state.matchedLocation == RouteNames.forgotPassword;

    if (!_isAuthenticated && !isAuthRoute) return RouteNames.signIn;
    if (_isAuthenticated && isAuthRoute) return RouteNames.home;
    return null;
  },
  routes: [
    GoRoute(
      path: RouteNames.splash,
      builder: (_, __) => const _SplashPage(),
    ),
    GoRoute(
      path: RouteNames.signIn,
      builder: (_, __) => const _PlaceholderPage(title: 'Sign In'),
    ),
    GoRoute(
      path: RouteNames.signUp,
      builder: (_, __) => const _PlaceholderPage(title: 'Sign Up'),
    ),
    GoRoute(
      path: RouteNames.forgotPassword,
      builder: (_, __) => const _PlaceholderPage(title: 'Forgot Password'),
    ),
    GoRoute(
      path: RouteNames.home,
      builder: (_, __) => const _PlaceholderPage(title: 'Home'),
    ),
    GoRoute(
      path: RouteNames.onboarding,
      builder: (_, __) => const _PlaceholderPage(title: 'Onboarding'),
    ),
    GoRoute(
      path: RouteNames.profile,
      builder: (_, __) => const _PlaceholderPage(title: 'Profile'),
    ),
  ],
);

class _SplashPage extends StatelessWidget {
  const _SplashPage();

  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: CircularProgressIndicator()));
}

class _PlaceholderPage extends StatelessWidget {
  final String title;
  const _PlaceholderPage({required this.title});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(title)),
        body: Center(child: Text(title)),
      );
}
