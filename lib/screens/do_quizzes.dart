import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:learn_hub/configs/router_config.dart';
import 'package:learn_hub/const/result_manager_config.dart';
import 'package:learn_hub/models/quiz.dart';
import 'package:learn_hub/screens/do_quizzes_result.dart';
import 'package:learn_hub/services/quiz_manager.dart';
import 'package:learn_hub/services/result_manager.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class DoQuizzesScreen extends StatefulWidget {
  final List<Map<String, dynamic>>? quizzes;
  final Quiz? quiz;
  final AppRoute? prevRoute;
  final String? quizId;
  final String? resultId;

  const DoQuizzesScreen({
    super.key,
    this.quizzes = const [],
    this.quiz,
    this.prevRoute,
    this.quizId,
    this.resultId,
  });

  @override
  State<DoQuizzesScreen> createState() => _DoQuizzesScreenState();
}

class _DoQuizzesScreenState extends State<DoQuizzesScreen> {
  late final cs = Theme.of(context).colorScheme;
  String selectedAnswerText = '';
  bool _isSubmitting = false;

  List<int?> userAnswers = [];
  List<bool> answerResults = [];

  bool isLoading = false;
  String? errorMessage;
  int currentQuestionIndex = 0;
  int? selectedAnswerIndex;

  String? _currentResultId;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  List<Map<String, dynamic>> quizzes = [];

  @override
  void initState() {
    super.initState();
    _initializeQuizData();
  }

  Future<void> _initializeQuizData() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    if (widget.quizzes != null &&
        widget.quizzes!.isNotEmpty &&
        widget.quiz == null) {
      quizzes = widget.quizzes!;
    } else if (widget.quiz != null ||
        widget.quizId != null && widget.resultId == null) {
      try {
        final String quizId = widget.quizId ?? widget.quiz!.quizId.toString();
        final quizData = await QuizManager.instance.getQuizById(quizId: quizId);

        final createResultData = await ResultManager.instance.createNewResult(
          CreateResultConfig(quizId: quizId),
        );

        if (createResultData['status'] == 'success') {
          setState(() {
            _currentResultId = createResultData['data'];
          });
        } else if (createResultData['status'] == 'error') {
          setState(() {
            errorMessage =
                createResultData['message'] ?? "Failed to create result.";
          });
        } else {
          setState(() {
            errorMessage =
                createResultData['message'] ?? "Failed to create result.";
          });
        }

        if (quizData['status'] == 'success') {
          final questionsData = quizData['data']['questions'];

          if (questionsData != null && questionsData is List) {
            setState(() {
              quizzes = List<Map<String, dynamic>>.from(questionsData);
            });
          } else {
            setState(() {
              errorMessage = "No questions found in this quiz.";
            });
          }
        } else {
          setState(() {
            errorMessage =
                quizData['message'] ??
                "Something went wrong while loading quiz, please try again.";
          });
        }
      } catch (e) {
        setState(() {
          errorMessage = "Exception in loading quiz: $e";
          print(e);
        });
      }
    } else if (widget.resultId != null && widget.quizId != null) {
      try {
        final quizResponse = await QuizManager.instance.getQuizById(
          quizId: widget.quizId!,
        );
        final resultResponse = await ResultManager.instance.getResultById(
          resultId: widget.resultId!,
        );

        if (quizResponse['status'] == 'success' &&
            resultResponse['status'] == 'success') {
          final quizData = quizResponse['data'];
          final resultData = resultResponse['data'];
          final answerData = resultData['status'];

          setState(() {
            quizzes = List<Map<String, dynamic>>.from(quizData['questions']);
            userAnswers = List.filled(quizzes.length, null);
            answerResults = List.filled(quizzes.length, false);

            // Process answers if they exist
            if (answerData != null && answerData is List) {
              for (int i = 0; i < answerData.length; i++) {
                final answer = answerData[i];
                final questionIndex = quizzes.indexWhere(
                  (q) =>
                      q['question_id'].toString() ==
                      answer['question_id'].toString(),
                );

                if (questionIndex != -1) {
                  userAnswers[questionIndex] =
                      answer['answer'] != -1 ? answer['answer'] : null;
                  answerResults[questionIndex] =
                      answer['is_correct'] == true ||
                      answer['is_correct'] == "true";
                }
              }
            } else {
              print('No answer data found');
            }

            final unfinishedCount =
                (resultData['num_unfinished'] as num).toInt();
            currentQuestionIndex =
                unfinishedCount > 0
                    ? quizzes.length - unfinishedCount
                    : quizzes.length - 1;

            if (unfinishedCount == 0) {
              _currentResultId = widget.resultId;

              Future.delayed(Duration(milliseconds: 300), () {
                _showResultScreen();
              });
            }
          });
        } else {
          setState(() {
            errorMessage =
                resultResponse['message'] ??
                quizResponse['message'] ??
                "Failed to load quiz or result data";
          });
        }
      } catch (e) {
        setState(() {
          errorMessage = "Error loading quiz and result: $e";
          print(e);
        });
      }
    } else {
      setState(() {
        errorMessage = "No quiz data available";
      });
    }

    if (quizzes.isNotEmpty && widget.resultId == null) {
      userAnswers = List.filled(quizzes.length, null);
      answerResults = List.filled(quizzes.length, false);
    }

    setState(() {
      isLoading = false;
    });
  }

  void _showResultScreen() {
    if (!mounted) return;

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      pageBuilder: (context, animation, secondaryAnimation) {
        return SharedAxisTransition(
          fillColor: cs.surface,
          transitionType: SharedAxisTransitionType.horizontal,
          animation: animation,
          secondaryAnimation: secondaryAnimation,
          child: ResultScreen(
            quizzes: quizzes,
            userAnswers: userAnswers,
            answerResults: answerResults,
          ),
        );
      },
    ).then((result) {
      if (result != null && result is Map && result['action'] == 'retake') {
        setState(() {
          currentQuestionIndex = 0;
          selectedAnswerIndex = null;
          userAnswers = List.filled(quizzes.length, null);
          answerResults = List.filled(quizzes.length, false);
        });
      }
    });
  }

  void _selectAnswer(int index) {
    setState(() {
      selectedAnswerIndex = index;
    });
  }

  void _nextQuestion() {
    if (currentQuestionIndex < quizzes.length - 1) {
      setState(() {
        currentQuestionIndex++;
        selectedAnswerIndex = null;
      });
    }
  }

  void _showExplanation() {
    final currentQuiz = quizzes[currentQuestionIndex];
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
    if (_isSubmitting) return;
    setState(() {
      _isSubmitting = true;
    });
    final currentQuiz = quizzes[currentQuestionIndex];
    final questionType = currentQuiz['question_type'] ?? 'multiple_choice';
    final questionId = currentQuiz['question_id']?.toString() ?? '';
    bool isCorrect = false;
    String selectedAnswerText = '';
    String correctAnswerText = '';
    if (questionType == 'fill_blank') {
      // Fill in the blank type logic
      final userInput = selectedAnswerText;
      final correctAnswer = currentQuiz['answer'];
      isCorrect = userInput.toLowerCase() == correctAnswer.toLowerCase();
      correctAnswerText = correctAnswer.toString();
    } else {
      // Multiple choice type logic
      final correctAnswerIndex =
          currentQuiz['answer'] is String
              ? int.parse(currentQuiz['answer'])
              : currentQuiz['answer'];
      isCorrect = selectedAnswerIndex == correctAnswerIndex;
      correctAnswerText =
          "${String.fromCharCode(65 + (correctAnswerIndex as int))}. ${currentQuiz['options'][correctAnswerIndex]}";
    }

    userAnswers[currentQuestionIndex] = selectedAnswerIndex;
    answerResults[currentQuestionIndex] = isCorrect;

    if (_currentResultId != null) {
      _sendAnswerInBackground(
        _currentResultId!,
        questionId,
        selectedAnswerIndex ?? -1,
        isCorrect.toString(),
      );
    }

    showModalBottomSheet(
      enableDrag: false,
      context: context,
      isDismissible: false,
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
                      correctAnswerText,
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
                    if (currentQuestionIndex == quizzes.length - 1) {
                      _showResultScreen();
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
                        currentQuestionIndex == quizzes.length - 1
                            ? "Finish!"
                            : "Next",
                        style: TextStyle(fontSize: 16),
                      ),
                      const SizedBox(width: 10),
                      if (currentQuestionIndex != quizzes.length - 1)
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
    ).then((_) {
      setState(() {
        _isSubmitting = false;
      });
    });
  }

  void _sendAnswerInBackground(
    String resultId,
    String questionId,
    int answer,
    String isCorrect,
  ) {
    ResultManager.instance
        .sendAnswer(
          resultId: resultId,
          questionId: questionId,
          answer: answer,
          isCorrect: isCorrect,
        )
        .catchError((e) {
          debugPrint('Failed to send answer to backend: $e');
        });
  }

  Widget _buildQuestionContent(Map<String, dynamic> currentQuiz) {
    final questionType = currentQuiz['question_type'] ?? 'multiple_choice';

    if (questionType == 'fill_blank') {
      // Fill in the blank UI
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            currentQuiz['question'],
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              fontFamily: 'BricolageGrotesque',
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            onChanged: (value) {
              setState(() {
                selectedAnswerText = value;
                // Enable submission if not empty
                selectedAnswerIndex = value.isNotEmpty ? 0 : null;
              });
            },
            decoration: InputDecoration(
              hintText: 'Type your answer here',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: cs.primary, width: 2),
              ),
            ),
          ),
        ],
      );
    } else {
      // Multiple choice UI - your existing code for options
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            currentQuiz['question'],
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              fontFamily: 'BricolageGrotesque',
            ),
          ),
          const SizedBox(height: 16),
          ...List.generate(
            currentQuiz['options'].length,
            (index) => Padding(
              padding: const EdgeInsets.only(top: 12.0),
              child: ChoiceCard(
                option: currentQuiz['options'][index],
                index: index,
                isSelected: selectedAnswerIndex == index,
                onTap: () => _selectAnswer(index),
              ),
            ),
          ),
        ],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // (widget.quizzes.toString());
    // print(isLoading);
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(PhosphorIconsBold.arrowLeft),
            onPressed:
                () =>
                    context.canPop()
                        ? context.pop()
                        : context.goNamed(AppRoute.quizzes.name),
          ),
          title: const Text('Loading Quiz'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: cs.primary),
              const SizedBox(height: 16),
              Text(
                'Loading quiz data...',
                style: TextStyle(
                  fontSize: 16,
                  color: cs.onSurfaceVariant,
                  fontFamily: 'BricolageGrotesque',
                ),
              ),
            ],
          ),
        ),
      );
    }
    if (quizzes.isEmpty || errorMessage != null) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(PhosphorIconsBold.arrowLeft),
            onPressed:
                () =>
                    context.canPop()
                        ? context.pop()
                        : context.goNamed(AppRoute.quizzes.name),
          ),
          title: const Text('Quiz Error'),
        ),
        body: Container(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(PhosphorIconsRegular.warning, size: 48, color: cs.error),
                const SizedBox(height: 16),
                Text(
                  errorMessage ?? "No quizzes available!",
                  style: TextStyle(
                    fontSize: 16,
                    color: cs.onSurface,
                    fontFamily: 'BricolageGrotesque',
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => context.goNamed(AppRoute.quizzes.name),
                  child: const Text("Back to Quizzes"),
                ),
              ],
            ),
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

    final currentQuiz = quizzes[currentQuestionIndex];
    final progress = (currentQuestionIndex) / quizzes.length;
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
                  print(context.canPop());
                  if (widget.prevRoute != null) {
                    context.goNamed(widget.prevRoute!.name);
                  } else {
                    if (context.canPop()) {
                      context.pop();
                    }
                  }
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
                      borderRadius: BorderRadius.circular(12),
                      value: animatedValue,
                      backgroundColor: cs.surfaceDim,
                      color: cs.primary,
                      minHeight: 12,
                      semanticsLabel: 'Quiz Progress',
                      semanticsValue:
                          '${currentQuestionIndex + 1}/${quizzes.length}',
                    );
                  },
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${currentQuestionIndex + 1}/${quizzes.length}',
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
              // const Spacer(),
              // ConstrainedBox(
              //   constraints: BoxConstraints(
              //     maxHeight: MediaQuery.of(context).size.height * 0.5,
              //   ),
              //   child: SingleChildScrollView(
              //     child: Column(
              //       children: List.generate(
              //         currentQuiz['options'].length,
              //             (index) => Padding(
              //           padding: const EdgeInsets.only(top: 12.0),
              //           child: ChoiceCard(
              //             option: currentQuiz['options'][index],
              //             index: index,
              //             isSelected: selectedAnswerIndex == index,
              //             onTap: () => _selectAnswer(index),
              //           ),
              //         ),
              //       ),
              //     ),
              //   ),
              // ),
              const SizedBox(height: 10),
              Expanded(
                child: SingleChildScrollView(
                  child: _buildQuestionContent(currentQuiz),
                ),
              ),
              const SizedBox(height: 16),

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
                      _isSubmitting
                          ? SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                          : Text(
                            currentQuestionIndex == quizzes.length - 1
                                ? 'Done!'
                                : 'Check Answer',
                            style: TextStyle(fontSize: 16),
                          ),
                      if (!_isSubmitting) const SizedBox(width: 10),
                      if (!_isSubmitting &&
                          currentQuestionIndex != quizzes.length - 1)
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
