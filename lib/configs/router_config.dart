import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:learn_hub/configs/router_keys.dart';
import 'package:learn_hub/models/quiz.dart';
import 'package:learn_hub/providers/app_auth_provider.dart';
import 'package:learn_hub/screens/app.dart';
import 'package:learn_hub/screens/do_quiz_history.dart';
import 'package:learn_hub/screens/do_quizzes.dart';
import 'package:learn_hub/screens/do_quizzes_result.dart';
import 'package:learn_hub/screens/forgot_password.dart';
import 'package:learn_hub/screens/generate_quizzes.dart';
import 'package:learn_hub/screens/home.dart';
import 'package:learn_hub/screens/login.dart';
import 'package:learn_hub/screens/materials.dart';
import 'package:learn_hub/screens/quizzes.dart';
import 'package:learn_hub/screens/ask.dart';
import 'package:learn_hub/screens/profile.dart';
import 'package:learn_hub/screens/register.dart';
import 'package:learn_hub/screens/search_quizzes.dart';
import 'package:learn_hub/screens/settings.dart';
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
  forgotPassword,
  doQuizzes,
  quizResults,
  generateQuiz,
  settings,
  doQuizHistory,
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
          state.matchedLocation == '/welcome' ||
          state.matchedLocation == '/forgot-password';

      if (state.matchedLocation == '/login' ||
          state.matchedLocation == '/register' ||
          state.matchedLocation == '/forgot-password') {
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
        path: "/forgot-password",
        name: AppRoute.forgotPassword.name,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),

      GoRoute(
        path: '/do-quizzes',
        name: AppRoute.doQuizzes.name,
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) {
          final params = state.extra as Map<String, dynamic>;
          final quizzes =
              params.containsKey('quizzes')
                  ? params['quizzes'] as List<Map<String, dynamic>>
                  : null;
          final quiz =
              params.containsKey('quiz') ? params['quiz'] as Quiz : null;
          final prevRoute =
              params.containsKey('prevRoute')
                  ? params['prevRoute'] as AppRoute?
                  : null;
          final quizId = params.containsKey('quiz_id')
              ? params['quiz_id'] as String
              : null;
          final resultId = params.containsKey('result_id') && params['result_id'] != null
              ? params['result_id'] as String
              : null;
          return MaterialPage(
            child: DoQuizzesScreen(
              quizzes: quizzes,
              quiz: quiz,
              prevRoute: prevRoute,
              quizId: quizId,
              resultId: resultId,
            ),
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
        pageBuilder: (context, state) {
          if (state.extra == null) {
            return const MaterialPage(child: GenerateQuizzesScreen());
          }
          final params = state.extra as Map<String, dynamic>;
          final material =
              params.containsKey('material')
                  ? params['material'] as ContextFileInfo
                  : null;
          return MaterialPage(
            child: GenerateQuizzesScreen(materialDocument: material),
          );
        },
      ),

      GoRoute(
        path: '/search-quizzes',
        name: AppRoute.searchQuizzes.name,
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) {
          return MaterialPage(
            child: SearchQuizzesScreen(
              searchExtra: state.extra as SearchQuizzesExtra,
            ),
          );
        },
      ),

      GoRoute(
        path: "/settings",
        name: AppRoute.settings.name,
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) {
          return const MaterialPage(child: SettingsScreen());
        },
      ),
      GoRoute(path: "/do-quiz-history",
        name: AppRoute.doQuizHistory.name,
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) {
          return const MaterialPage(child: DoQuizHistoryScreen());
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
              List<ContextFileInfo> contextFiles = [];
              if (state.extra != null) {
                contextFiles = state.extra as List<ContextFileInfo>;
              } else {
                contextFiles = <ContextFileInfo>[];
              }
              return AskScreen(contextFiles: contextFiles);
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
