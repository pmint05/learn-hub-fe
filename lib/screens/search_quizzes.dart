import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:go_router/go_router.dart';
import 'package:learn_hub/configs/router_config.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class SearchQuizzesScreen extends StatefulWidget {
  final String title;
  final Map<String, dynamic> filterParams;
  final IconData? icon;
  final Color? iconColor;

  const SearchQuizzesScreen({
    super.key,
    required this.title,
    required this.filterParams,
    this.icon,
    this.iconColor,
  });

  @override
  State<SearchQuizzesScreen> createState() => _SearchQuizzesScreenState();
}

class _SearchQuizzesScreenState extends State<SearchQuizzesScreen> {
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _quizzes = [];

  @override
  void initState() {
    super.initState();
    _fetchQuizzes();
  }

  Future<void> _fetchQuizzes() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Simulate API call with delay
      await Future.delayed(const Duration(seconds: 1));

      // TODO: Replace with actual API call
      // Here we're using the filterParams to simulate different results
      if (widget.filterParams.containsKey('mockData')) {
        _quizzes = widget.filterParams['mockData'];
      } else if (widget.filterParams.containsKey('category')) {
        _quizzes = _getMockQuizzesByCategory(widget.filterParams['category']);
      } else if (widget.filterParams.containsKey('difficulty')) {
        _quizzes = _getMockQuizzesByDifficulty(widget.filterParams['difficulty']);
      } else if (widget.filterParams.containsKey('query')) {
        _quizzes = _getMockQuizzesBySearch(widget.filterParams['query']);
      } else if (widget.filterParams.containsKey('recent')) {
        _quizzes = _getMockRecentQuizzes();
      } else if (widget.filterParams.containsKey('favorite')) {
        _quizzes = _getMockFavoriteQuizzes();
      } else {
        _quizzes = _getMockAllQuizzes();
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = "Failed to load quizzes: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            if (widget.icon != null)
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Icon(widget.icon, size: 20, color: widget.iconColor ?? cs.primary),
              ),
            Text(
              widget.title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                fontFamily: 'BricolageGrotesque',
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(PhosphorIconsRegular.sliders),
            onPressed: () {
              // Show filter options
              _showFilterBottomSheet();
            },
          ),
        ],
        centerTitle: false,
      ),
      body: _buildBody(cs),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.pushNamed(AppRoute.generateQuiz.name),
        tooltip: 'Create Quiz',
        child: const Icon(PhosphorIconsRegular.plus),
      ),
    );
  }

  Widget _buildBody(ColorScheme cs) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              PhosphorIconsRegular.warning,
              size: 64,
              color: cs.error.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: TextStyle(
                fontSize: 16,
                color: cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _fetchQuizzes,
              icon: const Icon(PhosphorIconsRegular.arrowClockwise),
              label: const Text("Try Again"),
            ),
          ],
        ),
      );
    }

    if (_quizzes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              PhosphorIconsRegular.clipboard,
              size: 64,
              color: cs.onSurfaceVariant.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No quizzes found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: cs.onSurfaceVariant,
              ),
            ),
            if (widget.filterParams.containsKey('query'))
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  'Try using different search terms',
                  style: TextStyle(
                    fontSize: 14,
                    color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                  ),
                ),
              ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchQuizzes,
      child: AnimationLimiter(
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _quizzes.length,
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          itemBuilder: (context, index) {
            final quiz = _quizzes[index];
            return AnimationConfiguration.staggeredList(
              position: index,
              duration: const Duration(milliseconds: 400),
              child: SlideAnimation(
                horizontalOffset: 50,
                child: FadeInAnimation(
                  child: _buildQuizCard(context, quiz),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _showFilterBottomSheet() {
    final cs = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: cs.onSurface.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "Filter Quizzes",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "Difficulty",
              style: TextStyle(fontWeight: FontWeight.w500, color: cs.onSurface),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                _buildFilterChip(cs, "Easy", true),
                _buildFilterChip(cs, "Medium", false),
                _buildFilterChip(cs, "Hard", false),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              "Categories",
              style: TextStyle(fontWeight: FontWeight.w500, color: cs.onSurface),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                _buildFilterChip(cs, "Science", true),
                _buildFilterChip(cs, "Math", false),
                _buildFilterChip(cs, "Language", false),
                _buildFilterChip(cs, "History", false),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(color: cs.primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text("Reset", style: TextStyle(color: cs.primary)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _fetchQuizzes();
                    },
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: cs.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text("Apply", style: TextStyle(color: cs.onPrimary)),
                  ),
                ),
              ],
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(ColorScheme cs, String label, bool selected) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (value) {},
      backgroundColor: cs.surface,
      labelStyle: TextStyle(color: selected ? cs.primary : cs.onSurfaceVariant),
      selectedColor: cs.primary.withValues(alpha: 0.2),
      checkmarkColor: cs.primary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: selected ? cs.primary : cs.surfaceDim),
      ),
    );
  }

  Widget _buildQuizCard(BuildContext context, Map<String, dynamic> quiz) {
    final cs = Theme.of(context).colorScheme;
    final diffColor = _getDifficultyColor(quiz['difficulty'], context);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: cs.surfaceDim),
      ),
      child: InkWell(
        onTap: () {
          if (quiz.containsKey('questionCount')) {
            // For sample data, generate mock questions
            final mockQuestions = List.generate(
              quiz['questionCount'],
                  (index) => {
                'question': 'Sample question ${index + 1} for ${quiz['title']}?',
                'options': [
                  'Option A',
                  'Option B',
                  'Option C',
                  'Option D'
                ],
                'answer': index % 4,
                'explanation': 'This is the explanation for question ${index + 1}.'
              },
            );

            context.pushNamed(
              AppRoute.doQuizzes.name,
              extra: {
                'quizzes': mockQuestions,
                'prevRoute': null,
              },
            );
          } else {
            // If it's already a quiz with questions format
            context.pushNamed(
              AppRoute.doQuizzes.name,
              extra: {
                'quizzes': [quiz],
                'prevRoute': null,
              },
            );
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          quiz['title'],
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: cs.onSurface,
                          ),
                        ),
                        if (quiz.containsKey('description'))
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              quiz['description'],
                              style: TextStyle(
                                fontSize: 14,
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Icon(
                    PhosphorIconsRegular.caretRight,
                    color: cs.onSurfaceVariant,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (quiz.containsKey('difficulty'))
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: diffColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        quiz['difficulty'],
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: diffColor,
                        ),
                      ),
                    ),
                  if (quiz.containsKey('tag'))
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: cs.primaryContainer.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        quiz['tag'],
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: cs.primary,
                        ),
                      ),
                    ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: cs.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: cs.surfaceDim),
                    ),
                    child: Text(
                      "${quiz['questionCount'] ?? quiz.length} Q",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: cs.onSurfaceVariant,
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

  Color _getDifficultyColor(dynamic difficulty, BuildContext context) {
    if (difficulty == null) return Theme.of(context).colorScheme.primary;
    return difficulty == 'Easy'
        ? Colors.green
        : difficulty == 'Medium'
        ? Colors.orange
        : Colors.red;
  }

  // Mock data methods
  List<Map<String, dynamic>> _getMockAllQuizzes() {
    return List.generate(
      10,
          (index) => {
        'id': 'quiz_$index',
        'title': 'Quiz ${index + 1}',
        'description': 'This is a sample quiz with random questions',
        'difficulty': index % 3 == 0 ? 'Easy' : index % 3 == 1 ? 'Medium' : 'Hard',
        'questionCount': 10 + index,
        'tag': index % 4 == 0 ? 'Science' : index % 4 == 1 ? 'Math' : index % 4 == 2 ? 'Language' : 'History',
      },
    );
  }

  List<Map<String, dynamic>> _getMockQuizzesByCategory(String category) {
    return List.generate(
      5,
          (index) => {
        'id': '${category.toLowerCase()}_$index',
        'title': '$category Quiz ${index + 1}',
        'description': 'Quiz related to $category',
        'difficulty': index % 3 == 0 ? 'Easy' : index % 3 == 1 ? 'Medium' : 'Hard',
        'questionCount': 8 + index,
        'tag': category,
      },
    );
  }

  List<Map<String, dynamic>> _getMockQuizzesByDifficulty(String difficulty) {
    return List.generate(
      5,
          (index) => {
        'id': '${difficulty.toLowerCase()}_$index',
        'title': '$difficulty Level Quiz ${index + 1}',
        'description': 'A $difficulty difficulty quiz',
        'difficulty': difficulty,
        'questionCount': difficulty == 'Easy' ? 5 + index : difficulty == 'Medium' ? 10 + index : 15 + index,
        'tag': index % 4 == 0 ? 'Science' : index % 4 == 1 ? 'Math' : index % 4 == 2 ? 'Language' : 'History',
      },
    );
  }

  List<Map<String, dynamic>> _getMockQuizzesBySearch(String query) {
    // Simple mock implementation that returns quizzes that contain the query in title
    final allQuizzes = _getMockAllQuizzes();
    return allQuizzes.where((quiz) =>
    quiz['title'].toString().toLowerCase().contains(query.toLowerCase()) ||
        quiz['description'].toString().toLowerCase().contains(query.toLowerCase()) ||
        quiz['tag'].toString().toLowerCase().contains(query.toLowerCase())
    ).toList();
  }

  List<Map<String, dynamic>> _getMockRecentQuizzes() {
    return List.generate(
      5,
          (index) => {
        'id': 'recent_$index',
        'title': 'Recent Quiz ${index + 1}',
        'description': 'Created on ${DateTime.now().subtract(Duration(days: index)).toString().substring(0, 10)}',
        'difficulty': index % 3 == 0 ? 'Easy' : index % 3 == 1 ? 'Medium' : 'Hard',
        'questionCount': 1,
        'tag': index % 2 == 0 ? 'Science' : 'Math',
      },
    );
  }

  List<Map<String, dynamic>> _getMockFavoriteQuizzes() {
    return List.generate(
      3,
          (index) => {
        'id': 'fav_$index',
        'title': 'Favorite Quiz ${index + 1}',
        'description': 'Last used: ${DateTime.now().subtract(Duration(days: index * 2)).toString().substring(0, 10)}',
        'difficulty': index % 3 == 0 ? 'Easy' : index % 3 == 1 ? 'Medium' : 'Hard',
        'questionCount': 8 + index,
        'tag': index % 2 == 0 ? 'History' : 'Biology',
      },
    );
  }
}