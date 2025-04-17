import 'package:learn_hub/screens/quizzes.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../screens/home.dart';
import '../screens/materials.dart';
import '../screens/ask.dart';
import '../screens/profile.dart';

final List<Map<String, dynamic>> routes = [
  {
    "icon": {
      "regular": PhosphorIconsRegular.houseSimple,
      "bold": PhosphorIconsBold.houseSimple,
      "filled": PhosphorIconsFill.houseSimple,
      "duotone": PhosphorIconsDuotone.houseSimple,
    },
    "title": "LearnHub",
    "label": "Home",
    "screen": const HomeScreen(),
    "showOnNav": true,
    "route": "/",
  },
  {
    "icon": {
      "regular": PhosphorIconsRegular.question,
      "bold": PhosphorIconsBold.question,
      "filled": PhosphorIconsFill.question,
      "duotone": PhosphorIconsDuotone.question,
    },
    "title": "Quizzes",
    "label": "Quizzes",
    "screen": const QuizzesScreen(),
    "showOnNav": true,
    "route": "/quizzes",
  },
  {
    "icon": {
      "regular": PhosphorIconsRegular.book,
      "bold": PhosphorIconsBold.book,
      "filled": PhosphorIconsFill.book,
      "duotone": PhosphorIconsDuotone.book,
    },
    "title": "Materials",
    "label": "Materials",
    "screen": const MaterialsScreen(),
    "showOnNav": true,
    "route": "/materials",
  },
  {
    "icon": {
      "regular": PhosphorIconsRegular.chatTeardropDots,
      "bold": PhosphorIconsBold.chatTeardropDots,
      "filled": PhosphorIconsFill.chatTeardropDots,
      "duotone": PhosphorIconsDuotone.chatTeardropDots,
    },
    "title": "Chat",
    "label": "Chat",
    "screen": (context, args) => AskScreen(),
    "showOnNav": true,
    "route": "/chat"
  },
  {
    "icon": "",
    "filledIcon": "",
    "title": "LearnHub",
    "label": "",
    "screen": const ProfileScreen(),
    "showOnNav": false,
    "route": "/profile"
  },
];
