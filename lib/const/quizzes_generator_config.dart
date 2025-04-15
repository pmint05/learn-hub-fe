enum QuizzesSource { file, text, image, link }

enum QuizzesType {
  mixed("Mixed"),
  multipleChoice("Multiple Choice"),
  trueFalse("True/False"),
  fillInTheBlank("Fill In The Blank");

  const QuizzesType(this.label);

  final String label;
}

enum QuizzesMode {
  quiz("Quiz"),
  exam("Exam");

  const QuizzesMode(this.label);

  final String label;
}

enum QuizzesDifficulty {
  easy("Easy"),
  medium("Medium"),
  hard("Hard");

  const QuizzesDifficulty(this.label);

  final String label;
}

enum QuizzesLanguage {
  auto("Auto Detect"),
  en("English"),
  vi("Vietnamese");

  const QuizzesLanguage(this.label);

  final String label;
}

class QuizzesGeneratorConfig {
  final QuizzesSource source;
  final QuizzesType type;
  final QuizzesMode mode;
  final QuizzesDifficulty difficulty;
  final QuizzesLanguage language;
  final int numberOfQuiz;

  QuizzesGeneratorConfig({
    required this.source,
    required this.type,
    required this.mode,
    required this.difficulty,
    required this.numberOfQuiz,
    required this.language,
  });
}
