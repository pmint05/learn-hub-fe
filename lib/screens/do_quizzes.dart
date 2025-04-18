import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:learn_hub/configs/router_config.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class DoQuizzesScreen extends StatefulWidget {
  final List<Map<String, dynamic>> quizzes;

  const DoQuizzesScreen({super.key, required this.quizzes});

  @override
  State<DoQuizzesScreen> createState() => _DoQuizzesScreenState();
}

class _DoQuizzesScreenState extends State<DoQuizzesScreen> {
  late final cs = Theme.of(context).colorScheme;

  List<int?> userAnswers = [];
  List<bool> answerResults = [];

  bool isLoading = false;
  String? errorMessage;
  int currentQuestionIndex = 0;
  int? selectedAnswerIndex;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    if (widget.quizzes.isEmpty) {
      setState(() {
        errorMessage = "No quizzes available";
      });
    } else {
      userAnswers = List.filled(widget.quizzes.length, null);
      answerResults = List.filled(widget.quizzes.length, false);
    }
  }

  void _selectAnswer(int index) {
    setState(() {
      selectedAnswerIndex = index;
    });
  }

  void _nextQuestion() {
    if (currentQuestionIndex < widget.quizzes.length - 1) {
      setState(() {
        currentQuestionIndex++;
        selectedAnswerIndex = null;
      });
    }
  }

  void _showExplanation() {
    final currentQuiz = widget.quizzes[currentQuestionIndex];
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      pageBuilder: (context, animation, secondaryAnimation) {
        final scaleAnimation = Tween<double>(
          begin: 0.9,
          end: 1.0,
        ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut));

        final opacityAnimation = Tween<double>(
          begin: 0.1,
          end: 1.0,
        ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut));

        return ScaleTransition(
          scale: scaleAnimation,
          child: FadeTransition(
            opacity: opacityAnimation,
            child: AlertDialog(
              title: const Text("Explanation"),
              content: Text(
                currentQuiz["explanation"],
                style: const TextStyle(
                  fontSize: 16,
                  fontFamily: 'BricolageGrotesque',
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text("Got it!"),
                ),
              ],
              actionsAlignment: MainAxisAlignment.center,
            ),
          ),
        );
      },
    );
  }

  void _checkAnswer() {
    final currentQuiz = widget.quizzes[currentQuestionIndex];
    final correctAnswerIndex = currentQuiz['answer'];
    final isCorrect = selectedAnswerIndex == correctAnswerIndex;
    // print(currentQuiz);
    // print(isCorrect);
    // print(correctAnswerIndex);
    // print(selectedAnswerIndex);

    userAnswers[currentQuestionIndex] = selectedAnswerIndex;
    answerResults[currentQuestionIndex] = isCorrect;

    showModalBottomSheet(
      context: context,
      builder:
          (context) => Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isCorrect ? cs.tertiaryContainer : cs.errorContainer,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text(
                  isCorrect ? 'Correct!' : 'Incorrect!',
                  style: TextStyle(
                    color: isCorrect ? cs.onTertiary : cs.onError,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'BricolageGrotesque',
                  ),
                ),
                Wrap(
                  spacing: 5,
                  crossAxisAlignment: WrapCrossAlignment.end,
                  children: [
                    Text(
                      "The correct answer is:",
                      style: TextStyle(
                        color: isCorrect ? cs.onTertiary : cs.onError,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'BricolageGrotesque',
                      ),
                    ),
                    Text(
                      "${String.fromCharCode(65 + (correctAnswerIndex as int))}. ${currentQuiz['options'][correctAnswerIndex]}",
                      style: TextStyle(
                        color: isCorrect ? cs.tertiary : cs.onError,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'BricolageGrotesque',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _showExplanation,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    backgroundColor:
                        isCorrect
                            ? cs.tertiary.withValues(alpha: 0.6)
                            : cs.error.withValues(alpha: 0.7),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text("Explanation", style: TextStyle(fontSize: 16)),
                      const SizedBox(width: 10),
                      PhosphorIcon(
                        PhosphorIconsBold.sparkle,
                        color: Colors.white,
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    if (currentQuestionIndex == widget.quizzes.length - 1) {
                      context.goNamed(
                        AppRoute.quizResults.name,
                        extra: {
                          "quizzes": widget.quizzes,
                          "userAnswers": userAnswers,
                          "answerResults": answerResults,
                        },
                      );
                    } else {
                      _nextQuestion();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    backgroundColor: isCorrect ? cs.tertiary : cs.error,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        currentQuestionIndex == widget.quizzes.length - 1
                            ? "Finish!"
                            : "Next",
                        style: TextStyle(fontSize: 16),
                      ),
                      const SizedBox(width: 10),
                      if (currentQuestionIndex != widget.quizzes.length - 1)
                        PhosphorIcon(
                          PhosphorIconsBold.arrowRight,
                          color: Colors.white,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    // (widget.quizzes.toString());
    // print(isLoading);
    if (isLoading) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (widget.quizzes.isEmpty) {
      return Scaffold(
        body: Center(child: Text("No quizzes available!")),
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      );
    }
    if (errorMessage != null) {
      return Scaffold(
        body: Center(child: Text(errorMessage!)),
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      );
    }

    final currentQuiz = widget.quizzes[currentQuestionIndex];
    final progress = (currentQuestionIndex) / widget.quizzes.length;
    return Scaffold(
      key: _scaffoldKey,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(56.0),
        child: Container(
          padding: EdgeInsets.fromLTRB(0, 20, 16, 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            mainAxisSize: MainAxisSize.max,
            children: [
              IconButton(
                constraints: BoxConstraints(),
                padding: EdgeInsets.all(4),
                onPressed: () {
                  context.goNamed(
                    AppRoute.quizzes.name,
                  );
                },
                icon: Icon(
                  PhosphorIconsBold.x,
                  color: cs.onSurface.withValues(alpha: 0.5),
                  size: 16,
                ),
              ),
              Expanded(
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0.0, end: progress),
                  duration: const Duration(milliseconds: 500),
                  builder: (context, animatedValue, child) {
                    return LinearProgressIndicator(
                      borderRadius: BorderRadius.circular(8),
                      value: animatedValue,
                      backgroundColor: cs.surfaceDim,
                      color: cs.primary,
                      minHeight: 12,
                      semanticsLabel: 'Quiz Progress',
                      semanticsValue:
                          '${currentQuestionIndex + 1}/${widget.quizzes.length}',
                    );
                  },
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${currentQuestionIndex + 1}/${widget.quizzes.length}',
                style: const TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'BricolageGrotesque',
                ),
              ),
            ],
          ),
        ),
      ),

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Question ${currentQuestionIndex + 1}:',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                  fontFamily: 'BricolageGrotesque',
                ),
              ),
              const SizedBox(height: 10),
              Text(
                currentQuiz['question'],
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'BricolageGrotesque',
                ),
              ),

              const Spacer(),
              ...List.generate(
                currentQuiz['options'].length,
                (index) => Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: ChoiceCard(
                    option: currentQuiz['options'][index],
                    index: index,
                    isSelected: selectedAnswerIndex == index,
                    onTap: () => _selectAnswer(index),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: selectedAnswerIndex != null ? _checkAnswer : null,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        currentQuestionIndex == widget.quizzes.length - 1
                            ? 'Done!'
                            : 'Check Answer',
                        style: TextStyle(fontSize: 16),
                      ),
                      const SizedBox(width: 10),
                      if (currentQuestionIndex != widget.quizzes.length - 1)
                        PhosphorIcon(
                          PhosphorIconsBold.arrowRight,
                          color:
                              selectedAnswerIndex != null
                                  ? Colors.white
                                  : Colors.grey.shade400,
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ChoiceCard extends StatelessWidget {
  final String option;
  final int index;
  final bool isSelected;
  final VoidCallback onTap;

  const ChoiceCard({
    super.key,
    required this.option,
    required this.index,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.all(Radius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? cs.primary : cs.surfaceDim,
            width: 2,
          ),
          color:
              isSelected
                  ? cs.primary.withValues(alpha: isDark ? 0.2 : 0.05)
                  : cs.surface,
        ),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? cs.primary : cs.surfaceDim,
              ),
              child: Center(
                child: Text(
                  String.fromCharCode(65 + index),
                  style: TextStyle(
                    color:
                        isSelected
                            ? isDark
                                ? cs.onSurface
                                : Colors.white
                            : Colors.grey,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'BricolageGrotesque',
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                option,
                style: TextStyle(
                  fontSize: 16,
                  fontFamily: 'BricolageGrotesque',
                  color: cs.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
