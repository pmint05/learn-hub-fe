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

  const App({
    super.key,
    required this.currentLocation,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final appbarProvider = Provider.of<AppBarProvider>(context);
    final action = appbarProvider.currentAction;

    int currentIndex = 0;
    String title = routes[0]["title"];

    if (currentLocation.startsWith('/quizzes')) {
      currentIndex = 1;
      title = routes[1]["title"];
    } else if (currentLocation.startsWith('/materials')) {
      currentIndex = 2;
      title = routes[2]["title"];
    } else if (currentLocation.startsWith('/chat')) {
      currentIndex = 3;
      title = routes[3]["title"];
    } else if (currentLocation.startsWith('/profile')) {
      currentIndex = 4;
      title = routes[4]["title"];
    }

    return Scaffold(
      key: ValueKey(currentLocation),
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
}