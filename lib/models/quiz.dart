
import 'package:learn_hub/const/constants.dart';

class Quiz {
  String quizId;
  String createdBy;
  int numberOfQuestions;
  bool isPublic;
  List<Map<String, dynamic>> questions;

  String? title;
  String? description;
  List<String>? categories;
  DateTime? createdDate;
  DateTime? lastModifiedDate;
  DifficultyLevel? difficulty;

  Quiz({
    required this.quizId,
    required this.createdBy,
    required this.isPublic,
    required this.numberOfQuestions,
    required this.questions,
    this.title,
    this.description,
    this.categories,
    this.createdDate,
    this.lastModifiedDate,
    this.difficulty,
  });
}