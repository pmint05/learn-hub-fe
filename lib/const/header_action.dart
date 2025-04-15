import 'package:flutter/material.dart';

enum AppBarActionType { notifications, chatHistory, closeChat, settings, none }

class HeaderAction {
  final AppBarActionType type;
  final VoidCallback? callback;
  final int? notificationCount;

  const HeaderAction({
    required this.type,
    required this.callback,
    this.notificationCount = 0
  });
}
