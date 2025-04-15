import 'package:learn_hub/screens/quizzes.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../screens/home.dart';
import '../screens/generate_quizzes.dart';
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
    "screen": const AskScreen(),
    "showOnNav": true,
  },
  {
    "icon": "",
    "filledIcon": "",
    "title": "LearnHub",
    "label": "",
    "screen": const ProfileScreen(),
    "showOnNav": false,
  },
];
