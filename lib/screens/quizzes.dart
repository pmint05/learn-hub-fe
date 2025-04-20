import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:go_router/go_router.dart';
import 'package:learn_hub/configs/router_config.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

final Map<String, PhosphorIconData> subjectCategories = {
  "Science": PhosphorIconsRegular.microscope,
  "Math": PhosphorIconsRegular.pi,
  "Language": PhosphorIconsRegular.translate,
  "History": PhosphorIconsRegular.bookOpen,
  "Biology": PhosphorIconsRegular.heart,
  "Physics": PhosphorIconsRegular.atom,
  "Chemistry": PhosphorIconsRegular.flask,
  "Geography": PhosphorIconsRegular.mapPin,
  "Literature": PhosphorIconsRegular.book,
  "Art": PhosphorIconsRegular.paintBrush,
  "Music": PhosphorIconsRegular.musicNote,
  "Philosophy": PhosphorIconsRegular.brain,
  "Technology": PhosphorIconsRegular.laptop,
  "Engineering": PhosphorIconsRegular.gear,
  "Computer Science": PhosphorIconsRegular.code,
  "Programming": PhosphorIconsRegular.code,
};

enum Difficulty { all, easy, medium, hard }

class QuizzesScreen extends StatefulWidget {
  final List<Map<String, dynamic>>? quizList;

  const QuizzesScreen({super.key, this.quizList});

  @override
  State<QuizzesScreen> createState() => _QuizzesScreenState();
}

class _QuizzesScreenState extends State<QuizzesScreen> {
  final TextEditingController _searchController = TextEditingController();

  final recentQuizzes = List.generate(
    5,
    (index) => {
      'id': 'quiz_$index',
      'title': 'Quiz ${index + 1}',
      'description':
          'Created on ${DateTime.now().subtract(Duration(days: index)).toString().substring(0, 10)}',
      'difficulty':
          index % 3 == 0
              ? 'Easy'
              : index % 3 == 1
              ? 'Medium'
              : 'Hard',
      'questionCount': 10 + index,
      'tag': index % 2 == 0 ? 'Science' : 'Math',
    },
  );

  final favoriteQuizzes = List.generate(
    3,
    (index) => {
      'id': 'fav_$index',
      'title': 'Favorite Quiz ${index + 1}',
      'description':
          'Last used: ${DateTime.now().subtract(Duration(days: index * 2)).toString().substring(0, 10)}',
      'difficulty':
          index % 3 == 0
              ? 'Easy'
              : index % 3 == 1
              ? 'Medium'
              : 'Hard',
      'questionCount': 8 + index,
      'tag': index % 2 == 0 ? 'History' : 'Biology',
    },
  );

  final categoryQuizzes = {
    'Science': List.generate(
      3,
      (index) => {
        'id': 'sci_$index',
        'title': 'Science Quiz ${index + 1}',
        'description': 'Physics, Chemistry, Biology',
        'difficulty':
            index % 3 == 0
                ? 'Easy'
                : index % 3 == 1
                ? 'Medium'
                : 'Hard',
        'questionCount': 12 + index,
      },
    ),
    'Math': List.generate(
      2,
      (index) => {
        'id': 'math_$index',
        'title': 'Math Quiz ${index + 1}',
        'description': 'Algebra, Geometry, Calculus',
        'difficulty': index % 2 == 0 ? 'Easy' : 'Medium',
        'questionCount': 15 + index,
      },
    ),
    'Language': List.generate(
      2,
      (index) => {
        'id': 'lang_$index',
        'title': 'Language Quiz ${index + 1}',
        'description': 'Grammar, Vocabulary, Writing',
        'difficulty': index % 2 == 0 ? 'Medium' : 'Hard',
        'questionCount': 20 + index,
      },
    ),
  };

  Difficulty selectedDifficulty = Difficulty.all;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: AnimationLimiter(
        child: Column(
          children: [
            _buildSearchBar(cs),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  // Implement quiz refresh logic
                  await Future.delayed(const Duration(seconds: 1));
                },
                child: ListView(
                  padding: const EdgeInsets.only(bottom: 120),
                  physics: const BouncingScrollPhysics(),
                  children: AnimationConfiguration.toStaggeredList(
                    duration: const Duration(milliseconds: 600),
                    childAnimationBuilder:
                        (widget) => SlideAnimation(
                          horizontalOffset: 50.0,
                          child: FadeInAnimation(child: widget),
                        ),
                    children: [
                      if (widget.quizList != null &&
                          widget.quizList!.isNotEmpty)
                        _buildNewlyGeneratedQuizzes(cs),
                      _buildRecentQuizzes(cs),
                      _buildFavoriteQuizzes(cs),
                      _buildCategorizedQuizzes(cs),
                      _buildDifficultyQuizzes(cs),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),

      // floatingActionButton: Padding(
      //   padding: const EdgeInsets.only(bottom: 72.0),
      //   child: FloatingActionButton.extended(
      //     onPressed: () {
      //       showGeneralDialog(
      //         context: context,
      //         barrierDismissible: true,
      //         barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      //         barrierColor: Colors.black54,
      //         transitionDuration: const Duration(milliseconds: 300),
      //         pageBuilder: (context, animation, secondaryAnimation) {
      //           return const GenerateQuizzesScreen();
      //         },
      //         transitionBuilder: (context, animation, secondaryAnimation, child) {
      //           final curvedAnimation = CurvedAnimation(
      //             parent: animation,
      //             curve: Curves.easeInOut,
      //           );
      //
      //           return FadeTransition(
      //             opacity: Tween<double>(begin: 0.0, end: 1.0).animate(curvedAnimation),
      //             child: ScaleTransition(
      //               scale: Tween<double>(begin: 0.9, end: 1).animate(curvedAnimation),
      //               child: child,
      //             ),
      //           );
      //         },
      //       );
      //     },
      //     backgroundColor: cs.primary,
      //     foregroundColor: cs.onPrimary,
      //     icon: const Icon(PhosphorIconsRegular.plus),
      //     label: const Text("Create Quiz"),
      //     shape: RoundedRectangleBorder(
      //       borderRadius: BorderRadius.circular(30),
      //     ),
      //   ),
      // ),

      // floatingActionButton: Padding(
      //   padding: const EdgeInsets.only(bottom: 72.0),
      //   child: OpenContainer(
      //     routeSettings: RouteSettings(name: AppRoute.generateQuiz.name),
      //     openBuilder: (BuildContext context, VoidCallback _) {
      //       if (mounted) {
      //         Future.microtask(
      //           () => context.pushNamed(AppRoute.generateQuiz.name),
      //         );
      //       }
      //       // Return an empty container as we're handling navigation differently
      //       return Container(color: Theme.of(context).scaffoldBackgroundColor);
      //     },
      //     openColor: cs.surface,
      //     closedElevation: 0,
      //     openElevation: 0,
      //     middleColor: Colors.transparent,
      //     closedShape: const RoundedRectangleBorder(
      //       borderRadius: BorderRadius.all(Radius.circular(25)),
      //     ),
      //     transitionType: ContainerTransitionType.fade,
      //     transitionDuration: Duration(milliseconds: 500),
      //     closedColor: Colors.transparent,
      //     closedBuilder: (BuildContext context, VoidCallback openContainer) {
      //       return FloatingActionButton.extended(
      //         onPressed: openContainer,
      //         backgroundColor: cs.primary,
      //         foregroundColor: cs.onPrimary,
      //         icon: const Icon(PhosphorIconsRegular.plus),
      //         label: const Text("Create Quiz"),
      //         shape: RoundedRectangleBorder(
      //           borderRadius: BorderRadius.circular(30),
      //         ),
      //       );
      //     },
      //   ),
      // ),
      //
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 72.0),
        child: FloatingActionButton.extended(
          onPressed: () {
            context.pushNamed(AppRoute.generateQuiz.name);
          },
          backgroundColor: cs.primary,
          foregroundColor: cs.onPrimary,
          icon: const Icon(PhosphorIconsRegular.plus),
          label: const Text("Create Quiz"),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
      ),

      // Padding(
      //   padding: EdgeInsets.only(bottom: 96),
      //   child: FloatingActionButton.extended(
      //     onPressed: () {
      //       Navigator.push(
      //         context,
      //         MaterialPageRoute(
      //           builder: (context) => const GenerateQuizzesScreen(),
      //         ),
      //       );
      //     },
      //     backgroundColor: cs.primary,
      //     foregroundColor: cs.onPrimary,
      //     icon: const Icon(PhosphorIconsRegular.plus),
      //     label: const Text("Create Quiz"),
      //     shape: RoundedRectangleBorder(
      //       borderRadius: BorderRadius.circular(30)
      //     ),
      //   ),
      // ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildSearchBar(ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: cs.surface.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: cs.shadow.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: "Search quizList...",
                  hintStyle: TextStyle(
                    color: cs.onSurface.withValues(alpha: 0.5),
                  ),
                  prefixIcon: Icon(
                    PhosphorIconsRegular.magnifyingGlass,
                    color: cs.onSurfaceVariant,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ),
          ),
          IconButton(
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => _buildFilterBottomSheet(cs),
              );
            },
            icon: Icon(PhosphorIconsRegular.sliders, color: cs.onSurface),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBottomSheet(ColorScheme cs) {
    return Container(
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
              _buildFilterChip(cs, "All", false),
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
    );
  }

  Widget _buildFilterChip(ColorScheme cs, String label, bool selected) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (value) {

      },
      backgroundColor: cs.surface,
      selectedColor: cs.primary.withValues(alpha: 0.2),
      labelStyle: TextStyle(color: selected ? cs.primary : cs.onSurfaceVariant),
      checkmarkColor: cs.primary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: selected ? cs.primary : Colors.transparent),
      ),
    );
  }

  Widget _buildNewlyGeneratedQuizzes(ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Generated Quizzes",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'BricolageGrotesque',
                  color: cs.primary,
                ),
              ),
              TextButton(
                onPressed: () {
                  context.pushNamed(AppRoute.searchQuizzes.name, extra: {
                    'title': 'Generated Quizzes',
                    'filterParams': {
                      'difficulty': 'All',
                      'categories': [],
                    },
                    'icon': PhosphorIconsRegular.sparkle,
                  });
                },
                child: Text("View All", style: TextStyle(color: cs.primary)),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 180,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: widget.quizList!.length,
            itemBuilder: (context, index) {
              final quiz = widget.quizList![index];
              return _buildGeneratedQuizCard(cs, quiz, index);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildGeneratedQuizCard(
    ColorScheme cs,
    Map<String, dynamic> quiz,
    int index,
  ) {
    return GestureDetector(
      onTap: () {
        // Navigate to quiz detail or start quiz
        // Navigator.push(
        //   context,
        //   MaterialPageRoute(
        //     builder: (context) => QuizzesScreen(quizList: widget.quizList),
        //   ),
        // );
      },
      child: Container(
        width: 200,
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: cs.primaryContainer.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cs.primary.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: cs.primary,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(15),
                  topRight: Radius.circular(15),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    PhosphorIconsRegular.sparkle,
                    color: cs.onPrimary,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      "Auto-Generated",
                      style: TextStyle(
                        color: cs.onPrimary,
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Quiz ${index + 1}",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: cs.onSurface,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    quiz.containsKey('question')
                        ? quiz['question']
                        : "Contains ${quiz.length} questions",
                    style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: cs.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          "${quiz.length} Q",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: cs.primary,
                          ),
                        ),
                      ),
                      Icon(
                        PhosphorIconsRegular.arrowRight,
                        color: cs.primary,
                        size: 20,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentQuizzes(ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Recent Quizzes",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'BricolageGrotesque',
                  color: cs.onSurface,
                ),
              ),
              TextButton(
                onPressed: () {
                  context.pushNamed(
                    AppRoute.searchQuizzes.name,
                    extra: {
                      'title': 'Recent Quizzes',
                      'filterParams': {'recent': true},
                      'icon': PhosphorIconsRegular.clockCounterClockwise,
                    },
                  );
                },
                child: Text("View All", style: TextStyle(color: cs.primary)),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 120,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: recentQuizzes.length,
            itemBuilder: (context, index) {
              final quiz = recentQuizzes[index];
              return _buildQuizCard(cs, quiz);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildQuizCard(ColorScheme cs, Map<String, dynamic> quiz) {
    final diffColor =
        quiz['difficulty'] == 'Easy'
            ? Colors.green
            : quiz['difficulty'] == 'Medium'
            ? Colors.orange
            : Colors.red;

    return GestureDetector(
      onTap: () {
        // Navigate to quiz detail or start quiz
      },
      child: Container(
        width: 200,
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cs.surfaceDim),
          boxShadow: [
            BoxShadow(
              color: cs.shadow.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                quiz['title'],
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: cs.onSurface,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                quiz['description'],
                style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
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
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: cs.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: cs.surfaceDim),
                    ),
                    child: Text(
                      "${quiz['questionCount']} Q",
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

  Widget _buildFavoriteQuizzes(ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(PhosphorIconsFill.heart, size: 18, color: Colors.red),
                  const SizedBox(width: 8),
                  Text(
                    "Favorite Quizzes",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'BricolageGrotesque',
                      color: cs.onSurface,
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: () {
                  context.pushNamed(
                    AppRoute.searchQuizzes.name,
                    extra: {
                      'title': 'Favorite Quizzes',
                      'filterParams': {'favorite': true},
                      'icon': PhosphorIconsFill.heart,
                      'iconColor': Colors.red,
                    },
                  );
                },
                child: Text("View All", style: TextStyle(color: cs.primary)),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 120,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: favoriteQuizzes.length,
            itemBuilder: (context, index) {
              final quiz = favoriteQuizzes[index];
              return _buildQuizCard(cs, quiz);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCategorizedQuizzes(ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
          child: Text(
            "Categories",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'BricolageGrotesque',
              color: cs.onSurface,
            ),
          ),
        ),
        ListView.builder(
          padding: EdgeInsets.zero,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: categoryQuizzes.length,
          itemBuilder: (context, index) {
            final category = categoryQuizzes.keys.elementAt(index);
            final quizList = categoryQuizzes[category]!;
            return _buildCategorySection(cs, category, quizList);
          },
        ),
      ],
    );
  }

  Widget _buildCategorySection(
    ColorScheme cs,
    String category,
    List<Map<String, dynamic>> quizList,
  ) {
    return ExpansionTile(
      title: Text(
        category,
        style: TextStyle(fontWeight: FontWeight.bold, color: cs.onSurface),
      ),
      leading: Icon(
        subjectCategories[category] ?? PhosphorIconsRegular.question,
        color: cs.primary,
      ),
      children: quizList.map((quiz) => _buildQuizListItem(cs, quiz)).toList(),
    );
  }

  Widget _buildQuizListItem(ColorScheme cs, Map<String, dynamic> quiz) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      title: Text(
        quiz['title'],
        style: TextStyle(fontWeight: FontWeight.w500, color: cs.onSurface),
      ),
      subtitle: Text(
        quiz['description'],
        style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: cs.surfaceDim,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              "${quiz['questionCount']} Q",
              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
            ),
          ),
          const SizedBox(width: 8),
          Icon(PhosphorIconsRegular.arrowRight, color: cs.onSurfaceVariant),
        ],
      ),
      onTap: () {
        // Navigate to quiz detail or start quiz
      },
    );
  }

  Widget _buildDifficultyQuizzes(ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
          child: Text(
            "By Difficulty",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'BricolageGrotesque',
              color: cs.onSurface,
            ),
          ),
        ),
        Row(
          children: [
            Expanded(
              child: _buildDifficultyCard(
                cs,
                "Easy",
                Colors.green,
                PhosphorIconsRegular.lightbulb,
              ),
            ),
            Expanded(
              child: _buildDifficultyCard(
                cs,
                "Medium",
                Colors.orange,
                PhosphorIconsRegular.puzzlePiece,
              ),
            ),
            Expanded(
              child: _buildDifficultyCard(
                cs,
                "Hard",
                Colors.red,
                PhosphorIconsRegular.brain,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDifficultyCard(
    ColorScheme cs,
    String level,
    Color color,
    IconData icon,
  ) {
    return Container(
      height: 120,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () {
          // Navigate to difficulty filtered quizList
        },
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              level,
              style: TextStyle(fontWeight: FontWeight.bold, color: color),
            ),
            Text(
              "${level == 'Easy'
                  ? 10
                  : level == 'Medium'
                  ? 15
                  : 8} quizList",
              style: TextStyle(
                fontSize: 12,
                color: color.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
