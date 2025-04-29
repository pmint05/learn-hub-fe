
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

  Quiz.fromJson(Map<String, dynamic> json)
      : quizId = json['_id'] ?? '',
        createdBy = json['user_id'] ?? '',
        numberOfQuestions = json['num_question'] ?? 0,
        isPublic = json['is_public'] ?? false,
        questions = List<Map<String, dynamic>>.from(json['questions'] ?? []) {
    title = json['title'] ?? '';
    description = json['description'] ?? '';
    categories = List<String>.from(json['categories'] ?? []);
    createdDate = DateTime.tryParse(json['created_date'] ?? '');
    lastModifiedDate = DateTime.tryParse(json['last_modified_date'] ?? '');
    difficulty = DifficultyLevel.values.firstWhere(
      (e) => e.name == (json['difficulty'] ?? ''),
      orElse: () => DifficultyLevel.unknown,
    );
  }
}