// lib/configs/router_keys.dart
import 'package:flutter/material.dart';

// Using const constructor ensures keys are not recreated on hot reload
final rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final shellNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'shell');