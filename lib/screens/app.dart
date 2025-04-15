import 'package:flutter/material.dart';
import 'package:learn_hub/providers/appbar_provider.dart';
import 'package:provider/provider.dart';
import '../configs/routes.dart';
import '../widgets/bottom_nav.dart';
import '../widgets/header.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  AppState createState() => AppState();
}

class AppState extends State<App> {
  int _currentIndex = 1;
  bool _isBottomNavBarVisible = true;

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
      // _isBottomNavBarVisible = index != 2;
    });
  }

  @override
  Widget build(BuildContext context) {
    final appbarProvider = Provider.of<AppBarProvider>(context);
    final action = appbarProvider.currentAction;

    return Scaffold(
      appBar: Header(
        title: routes[_currentIndex]["title"],
        actionType: action.type,
        onPostfixActionTap: action.callback,
        notificationCount: action.notificationCount ?? 0,
        logoURL: "assets/images/logo.png",
      ),
      body: routes[_currentIndex]["screen"],
      extendBody: true,
      bottomNavigationBar: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: _isBottomNavBarVisible ? 80 : 0,
        child: BottomNavBar(
          currentIndex: _currentIndex,
          onItemTapped: _onItemTapped,
        ),
      ),
    );
  }
}
