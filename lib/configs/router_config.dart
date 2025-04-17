import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:learn_hub/configs/router_keys.dart';
import 'package:learn_hub/providers/app_auth_provider.dart';
import 'package:learn_hub/screens/app.dart';
import 'package:learn_hub/screens/home.dart';
import 'package:learn_hub/screens/materials.dart';
import 'package:learn_hub/screens/quizzes.dart';
import 'package:learn_hub/screens/ask.dart';
import 'package:learn_hub/screens/profile.dart';

GoRouter createRouter(AppAuthProvider authProvider) {
  return GoRouter(
    initialLocation: '/',
    navigatorKey: rootNavigatorKey,
    debugLogDiagnostics: true,
    refreshListenable: authProvider,

    redirect: (context, state) {
      final isLoggedIn = authProvider.isAuthed;
      final isLoading = authProvider.isLoading;
      final showWelcome = authProvider.shouldShowWelcomeScreen();
      final isAuthRoute =
          state.matchedLocation == '/login' ||
          state.matchedLocation == '/register' ||
          state.matchedLocation == '/welcome';

      if (isLoading) return null;

      // Show welcome screen if needed
      if (showWelcome) return '/welcome';

      if (!isLoggedIn && !isAuthRoute) return '/login';

      if (isLoggedIn && isAuthRoute) return '/';

      // No redirect needed
      return null;
    },

    routes: [
      ShellRoute(
        navigatorKey: shellNavigatorKey,
        builder: (context, state, child) {
          return App(currentLocation: state.matchedLocation, child: child);
        },
        routes: [
          // Home
          GoRoute(
            path: '/',
            name: 'home',
            builder: (context, state) => const HomeScreen(),
          ),

          // Quizzes
          GoRoute(
            path: '/quizzes',
            name: 'quizzes',
            builder: (context, state) => const QuizzesScreen(),
          ),

          // Materials
          GoRoute(
            path: '/materials',
            name: 'materials',
            builder: (context, state) => const MaterialsScreen(),
          ),

          // Chat/Ask
          GoRoute(
            path: '/chat',
            name: 'chat',
            builder: (context, state) {
              final materialIds = state.uri.queryParameters['materialIds']
                  ?.split(',');
              return AskScreen(materialIds: materialIds);
            },
          ),

          // Profile
          GoRoute(
            path: '/profile',
            name: 'profile',
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),
    ],
  );
}
