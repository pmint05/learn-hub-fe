import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:learn_hub/configs/routes.dart';
import 'package:learn_hub/providers/appbar_provider.dart';
import 'package:learn_hub/widgets/bottom_nav.dart';
import 'package:learn_hub/widgets/header.dart';
import 'package:provider/provider.dart';

class App extends StatelessWidget {
  final String currentLocation;
  final Widget child;

  const App({super.key, required this.currentLocation, required this.child});

  @override
  Widget build(BuildContext context) {
    final appbarProvider = Provider.of<AppBarProvider>(context);
    final action = appbarProvider.currentAction;

    final currentIndex = _getNavIndexFromPath(currentLocation);
    final title = routes[currentIndex]["title"];

    return Scaffold(
      appBar: Header(
        title: title,
        actionType: action.type,
        onPostfixActionTap: action.callback,
        notificationCount: action.notificationCount ?? 0,
        logoURL: "assets/images/logo.png",
      ),
      body: child,
      extendBody: true,
      bottomNavigationBar: BottomNavBar(
        currentIndex: currentIndex,
        onItemTapped: (index) {
          final paths = ['/', '/quizzes', '/materials', '/chat', '/profile'];
          context.go(paths[index]);
        },
      ),
    );
  }

  int _getNavIndexFromPath(String path) {
    if (path.startsWith('/profile')) return 4;
    if (path.startsWith('/chat')) return 3;
    if (path.startsWith('/materials')) return 2;
    if (path.startsWith('/quizzes')) return 1;
    return 0;
  }
}
