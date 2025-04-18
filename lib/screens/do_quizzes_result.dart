import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:learn_hub/configs/router_config.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class ResultScreen extends StatefulWidget {
  final List<Map<String, dynamic>> quizzes;
  final List<int?> userAnswers;
  final List<bool> answerResults;

  const ResultScreen({
    super.key,
    required this.quizzes,
    required this.userAnswers,
    required this.answerResults,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  late int correctCount;
  late double percentage;
  late String performanceLevel;

  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    correctCount = widget.answerResults.where((result) => result).length;
    percentage = (correctCount / widget.quizzes.length) * 100;

    // Determine performance level
    if (percentage >= 90) {
      performanceLevel = "Excellent";
    } else if (percentage >= 75) {
      performanceLevel = "Very Good";
    } else if (percentage >= 60) {
      performanceLevel = "Good";
    } else if (percentage >= 40) {
      performanceLevel = "Average";
    } else {
      performanceLevel = "Needs Improvement";
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  late final cs = Theme.of(context).colorScheme;
  late final isDark = cs.brightness == Brightness.dark;

  @override
  Widget build(BuildContext context) {
    // print(widget.quizzes.toString());
    // print(widget.userAnswers);
    // print(widget.answerResults);
    final correctAnswers =
        widget.answerResults.where((result) => result).toList();
    final incorrectAnswers =
        widget.answerResults.where((result) => !result).toList();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Container(
          padding: EdgeInsets.symmetric(vertical: 5, horizontal: 16),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: cs.surfaceDim),
            boxShadow:
                !isDark
                    ? [
                      BoxShadow(
                        color: cs.onSurface.withValues(alpha: 0.08),
                        blurRadius: 10,
                        spreadRadius: 0,
                        offset: Offset.fromDirection(pi / 2, 0),
                      ),
                    ]
                    : null,
          ),
          child: Text(
            "Result",
            style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.bold),
          ),
        ),
        // leading:
        //     Navigator.canPop(context)
        //         ? Container(
        //           margin: EdgeInsets.all(8),
        //           decoration: BoxDecoration(
        //             color: cs.surface,
        //             border: Border.all(color: cs.surfaceDim),
        //             borderRadius: BorderRadius.circular(30),
        //           ),
        //           child: IconButton(
        //             icon: Icon(
        //               PhosphorIconsRegular.arrowLeft,
        //               color: cs.onSurface,
        //               size: 20,
        //             ),
        //             onPressed: () {
        //               Navigator.pop(context);
        //             },
        //           ),
        //         )
        //         : null,
        automaticallyImplyLeading: false,
        centerTitle: true,
        // titleSpacing: 0,
      ),

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color:
                      percentage >= 50 && percentage <= 60
                          ? cs.secondaryContainer.withValues(alpha: 0.12)
                          : percentage > 60
                          ? cs.tertiaryContainer.withValues(alpha: 0.12)
                          : cs.errorContainer.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("🎯", style: TextStyle(fontSize: 48)),
                    Text(
                      "Final Score",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'BricolageGrotesque',
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          percentage.toStringAsFixed(2).replaceAll('.00', ''),
                          style: TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'BricolageGrotesque',
                            color:
                                percentage >= 50 && percentage <= 60
                                    ? cs.secondary
                                    : percentage > 60
                                    ? cs.tertiary
                                    : cs.error,
                          ),
                        ),
                        Text(
                          "%",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color:
                                percentage >= 50 && percentage <= 60
                                    ? cs.secondary
                                    : percentage > 60
                                    ? cs.tertiary
                                    : cs.error,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        vertical: 3,
                        horizontal: 12,
                      ),
                      decoration: BoxDecoration(
                        color:
                            percentage >= 50 && percentage <= 60
                                ? cs.secondary.withValues(alpha: 0.13)
                                : percentage > 60
                                ? cs.tertiary.withValues(alpha: 0.15)
                                : cs.error.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        "${correctAnswers.length}/${widget.quizzes.length} correct answers",
                        style: TextStyle(
                          color:
                              percentage >= 50 && percentage <= 60
                                  ? cs.secondary
                                  : percentage > 60
                                  ? cs.tertiary
                                  : cs.error,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24),

              // Review Answers section
              Text(
                "Review Answers",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'BricolageGrotesque',
                ),
              ),

              SizedBox(height: 4),
              // Tabs
              Expanded(
                child: Column(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: cs.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: cs.surfaceDim),
                      ),
                      child: TabBar(
                        controller: _tabController,
                        tabs: [
                          Tab(text: "All (${widget.quizzes.length})"),
                          Tab(text: "Correct (${correctAnswers.length})"),
                          Tab(text: "Incorrect (${incorrectAnswers.length})"),
                        ],
                        labelColor: cs.primary,
                        unselectedLabelColor: cs.onSurface,
                        indicatorSize: TabBarIndicatorSize.label,
                        indicatorColor: cs.primary,
                        dividerColor: Colors.transparent,
                        indicator: UnderlineTabIndicator(
                          borderSide: BorderSide(width: 2.0, color: cs.primary),
                        ),
                        onTap: (index) {
                          setState(() {
                            _selectedTabIndex = index;
                          });
                        },
                      ),
                    ),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildAnswersReview(
                            widget.quizzes,
                            widget.userAnswers,
                            null,
                          ),
                          _buildAnswersReview(
                            widget.quizzes,
                            widget.userAnswers,
                            true,
                          ),
                          _buildAnswersReview(
                            widget.quizzes,
                            widget.userAnswers,
                            false,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        context.pushNamed(
                          AppRoute.doQuizzes.name,
                          extra: widget.quizzes,
                        );
                      },
                      icon: Icon(
                        PhosphorIconsRegular.arrowCounterClockwise,
                        color: cs.primary,
                      ),
                      label: Text("Retake"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(color: cs.primary),
                        ),
                        textStyle: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: cs.primary,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        context.goNamed(AppRoute.quizzes.name);
                      },
                      icon: Icon(
                        PhosphorIconsRegular.checks,
                        color: cs.onPrimary,
                      ),
                      label: Text("Finish"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: cs.primary,
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        textStyle: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: cs.onPrimary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnswersReview(
      List<Map<String, dynamic>> quizzes,
      List<int?> userAnswers,
      bool? isCorrect,
      ) {
    // Create a stateful list to track expansion states
    final List<Map<String, dynamic>> filteredItems = [];

    for (int i = 0; i < quizzes.length; i++) {
      final quiz = quizzes[i];
      final userAnswer = userAnswers[i];
      final correctAnswerIndex = quiz['answer'];
      final currentIsCorrect = userAnswer == correctAnswerIndex;

      // Skip items that don't match the filter
      if (isCorrect != null && currentIsCorrect != isCorrect) {
        continue;
      }

      filteredItems.add({
        'quiz': quiz,
        'userAnswer': userAnswer,
        'correctAnswerIndex': correctAnswerIndex,
        'currentIsCorrect': currentIsCorrect,
        'index': i,
        'isExpanded': false, // Track expansion state
      });
    }

    return StatefulBuilder(
      builder: (context, setState) {
        return filteredItems.isEmpty
            ? Center(
          child: Text(
            "No ${isCorrect == true ? 'correct' : 'incorrect'} answers",
            style: TextStyle(
              fontSize: 16,
              color: cs.onSurfaceVariant,
            ),
          ),
        )
            : ListView.builder(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(top: 10, bottom: 16),
          itemCount: filteredItems.length,
          itemBuilder: (context, index) {
            final item = filteredItems[index];
            final quiz = item['quiz'] as Map<String, dynamic>;
            final userAnswer = item['userAnswer'] as int?;
            final correctAnswerIndex = item['correctAnswerIndex'] as int;
            final currentIsCorrect = item['currentIsCorrect'] as bool;

            return ExpansionTile(
              childrenPadding: EdgeInsets.all(12),
              leading: Icon(
                currentIsCorrect
                    ? PhosphorIconsRegular.checkCircle
                    : PhosphorIconsRegular.xCircle,
                color: currentIsCorrect
                    ? Theme.of(context).colorScheme.tertiary
                    : Theme.of(context).colorScheme.error,
              ),
              title: Text(
                quiz["question"],
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontFamily: 'BricolageGrotesque',
                  fontSize: 12,
                ),
              ),
              children: [
                if (userAnswer != null)
                  _buildAnswerColumn(
                    "Your Answer:",
                    quiz['options'][userAnswer],
                    userAnswer == correctAnswerIndex,
                    false,
                  ),
                const SizedBox(height: 8),
                _buildAnswerColumn(
                  "Correct Answer:",
                  quiz['options'][correctAnswerIndex],
                  true,
                  true,
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildAnswerColumn(
    String label,
    String answer,
    bool isCorrect,
    bool isKey,
  ) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: EdgeInsets.only(left: 20),
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color:
            isKey
                ? cs.primary.withValues(alpha: 0.15)
                : isCorrect
                ? cs.tertiary.withValues(alpha: 0.15)
                : cs.error.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: cs.onSurface,
              fontFamily: 'BricolageGrotesque',
              fontSize: 12,
            ),
          ),
          SizedBox(width: 8),
          Text(
            answer,
            style: TextStyle(
              color:
                  isKey
                      ? cs.primary
                      : isCorrect
                      ? cs.tertiary
                      : cs.error,
              fontFamily: 'BricolageGrotesque',
            ),
          ),
        ],
      ),
    );
  }
}
