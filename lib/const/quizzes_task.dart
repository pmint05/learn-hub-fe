import 'package:learn_hub/const/quizzes_generator_config.dart';
import 'package:moment_dart/moment_dart.dart';

class QuizzesTask {
  final String taskId;
  final DateTime createdAt;
  final QuizzesGeneratorConfig config;
  String status;
  String errorMessage = '';
  List<Map<String, dynamic>>? result;

  QuizzesTask({
    required this.taskId,
    required this.createdAt,
    required this.config,
    this.status = 'pending',
    this.result,
    this.errorMessage = '',
  });

  String get createdAtHumanized => Moment(createdAt).fromNow();

  Map<String, dynamic> toJson() => {
    'taskId': taskId,
    'createdAt': createdAt.toIso8601String(),
    'config': {
      'source': config.source.name,
      'type': config.type.name,
      'mode': config.mode.name,
      'difficulty': config.difficulty.name,
      'numberOfQuiz': config.numberOfQuiz,
      'language': config.language.name,
    },
    'status': status,
    'errorMessage': errorMessage,
  };

  factory QuizzesTask.fromJson(Map<String, dynamic> json) {
    return QuizzesTask(
      taskId: json['taskId'],
      createdAt: DateTime.parse(json['createdAt']),
      config: QuizzesGeneratorConfig(
        isPublic: json['config']['is_public'] ?? false,
        source: QuizzesSource.values.byName(json['config']['source']),
        type: QuizzesType.values.byName(json['config']['type']),
        mode: QuizzesMode.values.byName(json['config']['mode']),
        difficulty: QuizzesDifficulty.values.byName(json['config']['difficulty']),
        numberOfQuiz: json['config']['numberOfQuiz'],
        language: QuizzesLanguage.values.byName(json['config']['language']),
      ),
      status: json['status'],
      errorMessage: json['errorMessage'] ?? '',
    );
  }
}