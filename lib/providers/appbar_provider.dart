import 'package:flutter/material.dart';
import 'package:learn_hub/const/header_action.dart';

class AppBarProvider extends ChangeNotifier {
  HeaderAction _currentAction = const HeaderAction(
    type: AppBarActionType.none,
    callback: null,
  );

  HeaderAction get currentAction => _currentAction;

  void setHeaderAction(HeaderAction action) {
    _currentAction = action;
    notifyListeners();
  }

  void clear() {
    _currentAction = const HeaderAction(
      type: AppBarActionType.none,
      callback: null,
    );
    notifyListeners();
  }
}
