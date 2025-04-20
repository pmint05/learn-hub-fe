import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:learn_hub/configs/router_keys.dart';
import 'package:learn_hub/providers/app_auth_provider.dart';
import 'package:learn_hub/screens/app.dart';
import 'package:learn_hub/screens/do_quizzes.dart';
import 'package:learn_hub/screens/do_quizzes_result.dart';
import 'package:learn_hub/screens/generate_quizzes.dart';
import 'package:learn_hub/screens/home.dart';
import 'package:learn_hub/screens/login.dart';
import 'package:learn_hub/screens/materials.dart';
import 'package:learn_hub/screens/quizzes.dart';
import 'package:learn_hub/screens/ask.dart';
import 'package:learn_hub/screens/profile.dart';
import 'package:learn_hub/screens/register.dart';
import 'package:learn_hub/screens/search_quizzes.dart';
import 'package:learn_hub/screens/welcome.dart';

enum AppRoute {
  home,
  quizzes,
  searchQuizzes,
  materials,
  chat,
  profile,
  welcome,
  login,
  register,
  doQuizzes,
  quizResults,
  generateQuiz,
  settings,
}

GoRouter createRouter(AppAuthProvider authProvider) {
  return GoRouter(
    initialLocation: '/',
    navigatorKey: rootNavigatorKey,
    debugLogDiagnostics: true,
    refreshListenable: authProvider,

    redirect: (context, state) {
      if (authProvider.isLoading) return null;

      final isLoggedIn = authProvider.isAuthed;
      final showWelcome = authProvider.shouldShowWelcomeScreen();
      final isAuthRoute =
          state.matchedLocation == '/login' ||
          state.matchedLocation == '/register' ||
          state.matchedLocation == '/welcome';

      if (state.matchedLocation == '/login' ||
          state.matchedLocation == '/register') {
        return null;
      }

      if (showWelcome && state.matchedLocation != '/welcome') return '/welcome';

      if (!isLoggedIn && !isAuthRoute) return '/login';
      if (isLoggedIn && isAuthRoute) return '/';

      return null;
    },

    routes: <RouteBase>[
      GoRoute(
        path: "/welcome",
        name: AppRoute.welcome.name,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: "/login",
        name: AppRoute.login.name,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: "/register",
        name: AppRoute.register.name,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const RegisterScreen(),
      ),

      GoRoute(
        path: '/do-quizzes',
        name: AppRoute.doQuizzes.name,
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) {
          final params = state.extra as Map<String, dynamic>;
          final quizzes = params['quizzes'] as List<Map<String, dynamic>>;
          final prevRoute = params.containsKey('prevRoute') ? params['prevRoute'] as AppRoute? : null;
          return MaterialPage(
            child: DoQuizzesScreen(quizzes: quizzes, prevRoute: prevRoute),
          );
        },
      ),
      GoRoute(
        path: '/quiz-results',
        name: AppRoute.quizResults.name,
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) {
          final params = state.extra as Map<String, dynamic>;
          final quizzes = params['quizzes'] as List<Map<String, dynamic>>;
          final userAnswers = params['userAnswers'] as List<int?>;
          final answerResults = params['answerResults'] as List<bool>;

          return MaterialPage(
            child: ResultScreen(
              quizzes: quizzes,
              userAnswers: userAnswers,
              answerResults: answerResults,
            ),
          );
        },
      ),

      GoRoute(
        path: "/generate-quiz",
        name: AppRoute.generateQuiz.name,
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder:
            (context, state) =>
                const MaterialPage(child: GenerateQuizzesScreen()),
      ),

      GoRoute(
        path: '/search-quizzes',
        name: AppRoute.searchQuizzes.name,
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) {
          final params = state.extra as Map<String, dynamic>;
          return MaterialPage(
            child: SearchQuizzesScreen(
              title: params['title'],
              filterParams: params['filterParams'],
              icon: params['icon'],
              iconColor: params['iconColor'],
            ),
          );
        },
      ),

      ShellRoute(
        navigatorKey: shellNavigatorKey,
        builder: (context, state, child) {
          return App(currentLocation: state.matchedLocation, child: child);
        },
        routes: [
          GoRoute(
            path: '/',
            name: AppRoute.home.name,
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/quizzes',
            name: AppRoute.quizzes.name,
            builder: (context, state) => const QuizzesScreen(),
          ),
          GoRoute(
            path: '/materials',
            name: AppRoute.materials.name,
            builder: (context, state) => const MaterialsScreen(),
          ),
          GoRoute(
            path: '/chat',
            name: AppRoute.chat.name,
            builder: (context, state) {
              final materialIds = state.uri.queryParameters['materialIds']
                  ?.split(',');
              return AskScreen(materialIds: materialIds);
            },
          ),
          GoRoute(
            path: '/profile',
            name: AppRoute.profile.name,
            builder: (context, state) {
              print(state.name);
              print(state.topRoute);
              return const ProfileScreen();
            },
          ),
        ],
      ),
    ],
  );
}
