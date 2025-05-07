import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:learn_hub/const/constants.dart';
import 'package:learn_hub/configs/router_config.dart';
import 'package:learn_hub/const/header_action.dart';
import 'package:learn_hub/const/search_quiz_config.dart';
import 'package:learn_hub/models/quiz.dart';
import 'package:learn_hub/providers/appbar_provider.dart';
import 'package:learn_hub/screens/search_quizzes.dart';
import 'package:learn_hub/services/quiz_manager.dart';
import 'package:learn_hub/utils/date_helper.dart';
import 'package:learn_hub/utils/string_helpers.dart';
import 'package:moment_dart/moment_dart.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';

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

final difficultyColors = {
  'easy': Colors.green,
  'medium': Colors.orange,
  'hard': Colors.red,
  'all': Colors.blue,
  'unknown': Colors.grey,
};

final difficultyShortDescriptions = {
  DifficultyLevel.easy: "Some simple questions to get you started.",
  DifficultyLevel.medium: "Moderate questions to challenge your knowledge.",
  DifficultyLevel.hard: "Advanced questions for the experts.",
};

class QuizzesScreen extends StatefulWidget {
  final List<Map<String, dynamic>>? quizList;

  const QuizzesScreen({super.key, this.quizList});

  @override
  State<QuizzesScreen> createState() => _QuizzesScreenState();
}

class _QuizzesScreenState extends State<QuizzesScreen> {
  late ColorScheme cs = Theme.of(context).colorScheme;
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> recentQuizzes = [];
  List<Map<String, dynamic>> favoriteQuizzes = [];
  Map<String, List<Map<String, dynamic>>> categoryQuizzes = {};
  Map<String, List<Map<String, dynamic>>> difficultyQuizzes = {};
  List<Map<String, dynamic>> first5Quizzes = [];

  bool isLoadingRecent = true;
  bool isLoadingFavorites = true;
  bool isLoadingCategories = true;
  bool isLoadingDifficulty = true;

  bool get isLoading =>
      isLoadingRecent ||
      isLoadingFavorites ||
      isLoadingCategories ||
      isLoadingDifficulty;

  DifficultyLevel selectedDifficultyLevel = DifficultyLevel.all;

  Future<void> fetchAllQuizData() async {
    fetchRecentQuizzes();
    // fetchFavoriteQuizzes();
    // fetchCategoryQuizzes();
    // fetchDifficultyQuizzes();
  }

  Future<List<Map<String, dynamic>>> fetchQuizzes({
    required SearchQuizConfig config,
    required String errorMessage,
  }) async {
    try {
      final response = await QuizManager.instance.getQuizzes(config: config);
      if (response['status'] == 'success' && response['data'] != null) {
        return List<Map<String, dynamic>>.from(response['data']);
      } else {
        print("Error fetching quizzes: ${response['message']}");
        print(response);
        print(config.toJson());
        return [];
      }
    } catch (e) {
      print("$errorMessage: $e");
      return [];
    }
  }

  Future<void> fetchRecentQuizzes() async {
    isLoadingRecent = true;
    if (mounted) setState(() {});

    final config = SearchQuizConfig(
      includeUserId: true,
      searchText: "",
      size: 8,
      start: 0,
      minCreatedDate: DateFormat(
        'dd/MM/yyyy',
      ).format(DateTime.now().subtract(const Duration(days: 30))),
      sortBy: 'created_date',
      sortOrder: -1,
    );

    recentQuizzes = await fetchQuizzes(
      config: config,
      errorMessage: "Error fetching recent quizzes",
    );
    recentQuizzes.sort(
      (a, b) => DateTime.parse(
        b['created_date'],
      ).compareTo(DateTime.parse(a['created_date'])),
    );

    isLoadingRecent = false;
    if (mounted) setState(() {});
  }

  Future<void> fetchFavoriteQuizzes() async {
    isLoadingFavorites = true;
    if (mounted) setState(() {});

    // Note: Assuming there's a way to filter favorite quizzes
    // You might need to update this based on your backend API
    final config = SearchQuizConfig(
      includeUserId: true,
      searchText: "",
      isPublic: false,
      size: 5,
      start: 0,
    );

    favoriteQuizzes = await fetchQuizzes(
      config: config,
      errorMessage: "Error fetching favorite quizzes",
    );

    isLoadingFavorites = false;
    if (mounted) setState(() {});
  }

  Future<void> fetchCategoryQuizzes() async {
    isLoadingCategories = true;
    if (mounted) setState(() {});

    categoryQuizzes = {};
    final categories = ["Science", "Math", "Language"];

    for (final category in categories) {
      final config = SearchQuizConfig(
        includeUserId: false,
        searchText: "",
        isPublic: true,
        size: 5,
        start: 0,
        categories: [category],
      );

      final quizzes = await fetchQuizzes(
        config: config,
        errorMessage: "Error fetching $category quizzes",
      );

      if (quizzes.isNotEmpty) {
        categoryQuizzes[category] = quizzes;
      }
    }

    isLoadingCategories = false;
    if (mounted) setState(() {});
  }

  Future<void> fetchDifficultyQuizzes() async {
    isLoadingDifficulty = true;
    if (mounted) setState(() {});

    difficultyQuizzes = {};
    final difficulties = [
      DifficultyLevel.easy,
      DifficultyLevel.medium,
      DifficultyLevel.hard,
    ];

    for (final difficulty in difficulties) {
      final config = SearchQuizConfig(
        includeUserId: false,
        searchText: "",
        isPublic: true,
        size: 5,
        start: 0,
        difficulty: difficulty,
      );

      final quizzes = await fetchQuizzes(
        config: config,
        errorMessage: "Error fetching $difficulty quizzes",
      );

      if (quizzes.isNotEmpty) {
        difficultyQuizzes[difficulty.name] = quizzes;
      }
    }

    isLoadingDifficulty = false;
    if (mounted) setState(() {});
  }

  void _showDoQuizHistory() {
    context.pushNamed(
      AppRoute.doQuizHistory.name,
    );
  }

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      final searchText = _searchController.text;
      print("Searching for: $searchText");
    });
    fetchAllQuizData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AppBarProvider>(context, listen: false).setHeaderAction(
        HeaderAction(
            type: AppBarActionType.doQuizHistory, callback: _showDoQuizHistory),
      );
    });

    return Scaffold(
      body: AnimationLimiter(
        child: Column(
          children: [
            _buildSearchBar(),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  await fetchAllQuizData();
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
                        _buildNewlyGeneratedQuizzes(),
                      _buildRecentQuizzes(),
                      // _buildFavoriteQuizzes(),
                      // _buildCategorizedQuizzes(),
                      _buildCategories(),
                      _buildDifficultyLevelQuizzes(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),

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
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      child: Row(
        spacing: 8,
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
          ElevatedButton.icon(
            style: ButtonStyle(
              backgroundColor: WidgetStatePropertyAll(cs.primary),
              padding: WidgetStatePropertyAll(
                EdgeInsets.symmetric(vertical: 12, horizontal: 20),
              ),
              shape: WidgetStatePropertyAll(
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            onPressed: () {
              context.pushNamed(
                AppRoute.searchQuizzes.name,
                extra: SearchQuizzesExtra(
                  title: Text("Search"),
                  searchConfig: SearchQuizConfig(
                    includeUserId: true,
                    searchText: _searchController.value.text,
                    size: 10,
                    start: 0,
                  ),
                  showSearchBar: true,
                ),
              );
            },
            label: Text("Search"),
          ),
        ],
      ),
    );
  }

  Widget _buildNewlyGeneratedQuizzes() {
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
                  context.pushNamed(
                    AppRoute.searchQuizzes.name,
                    extra: SearchQuizzesExtra(
                      title: Text('Generated Quizzes'),
                      searchConfig: SearchQuizConfig(
                        includeUserId: true,
                        searchText: "",
                        isPublic: true,
                        size: 5,
                        start: 0,
                      ),
                    ),
                  );
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
              return _buildGeneratedQuizCard(quiz, index);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildGeneratedQuizCard(Map<String, dynamic> quiz, int index) {
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

  Widget _buildRecentQuizzes() {
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
                    extra: SearchQuizzesExtra(
                      title: Text('Recent Quizzes'),
                      searchConfig: SearchQuizConfig(
                        includeUserId: true,
                        searchText: "",
                        size: 10,
                        start: 0,
                        sortOrder: -1,
                        sortBy: 'created_date'
                      ),
                      showSearchBar: true
                    ),
                  );
                },
                child: Text("View All", style: TextStyle(color: cs.primary)),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 120,
          child:
              isLoadingRecent
                  ? _buildLoadingIndicator()
                  : recentQuizzes.isEmpty
                  ? _buildEmptyState("No recent quizzes")
                  : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    itemCount: recentQuizzes.length,
                    itemBuilder: (context, index) {
                      final quiz = recentQuizzes[index];
                      if (quiz['created_date'] != null) {
                        quiz['subtitle'] =
                            'Created ${Moment(DateHelper.utcStringToLocal(quiz['created_date'])).fromNow()}';
                      }
                      return _buildQuizCard(quiz);
                    },
                  ),
        ),
      ],
    );
  }

  Widget _buildFavoriteQuizzes() {
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
                    extra: SearchQuizzesExtra(
                      title: Row(
                        children: [
                          Icon(
                            PhosphorIconsFill.heart,
                            size: 18,
                            color: Colors.red,
                          ),
                          const SizedBox(width: 8),
                          Text('Favorite Quizzes'),
                        ],
                      ),
                      searchConfig: SearchQuizConfig(
                        includeUserId: true,
                        searchText: "",
                        isPublic: false,
                        size: 5,
                        start: 0,
                      ),
                    ),
                  );
                },
                child: Text("View All", style: TextStyle(color: cs.primary)),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 120,
          child:
              isLoadingFavorites
                  ? _buildLoadingIndicator()
                  : favoriteQuizzes.isEmpty
                  ? _buildEmptyState("No favorite quizzes")
                  : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    itemCount: favoriteQuizzes.length,
                    itemBuilder: (context, index) {
                      final quiz = favoriteQuizzes[index];
                      return _buildQuizCard(quiz);
                    },
                  ),
        ),
      ],
    );
  }

  Widget _buildCategorizedQuizzes() {
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
            return _buildCategorySection(category, quizList);
          },
        ),
      ],
    );
  }

  Widget _buildCategories() {
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
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                availableCategories.map((category) {
                  return _buildCategoryButton(category);
                }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryButton(Map<String, dynamic> category) {
    return GestureDetector(
      onTap: () {
        context.pushNamed(
          AppRoute.searchQuizzes.name,
          extra: SearchQuizzesExtra(
            title: Text('${category['icon']}  ${category['name']}'),
            searchConfig: SearchQuizConfig(
              includeUserId: false,
              searchText: "",
              isPublic: true,
              categories: [category['name']],
              size: 5,
              start: 0,
            ),
            showSearchBar: true
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: cs.surface.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: cs.shadow.withValues(alpha: 0.088),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          '${category['icon']}  ${category['name']}',
          style: TextStyle(color: cs.onSurface),
        ),
      ),
    );
  }

  Widget _buildCategorySection(
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
      children: quizList.map((quiz) => _buildQuizListItem(quiz)).toList(),
    );
  }

  Widget _buildQuizListItem(Map<String, dynamic> quiz) {
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

  Widget _buildDifficultyLevelQuizzes() {
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
              child: _buildDifficultyLevelCard(
                DifficultyLevel.easy,
                Colors.green,
                PhosphorIconsRegular.lightbulb,
              ),
            ),
            Expanded(
              child: _buildDifficultyLevelCard(
                DifficultyLevel.medium,
                Colors.orange,
                PhosphorIconsRegular.puzzlePiece,
              ),
            ),
            Expanded(
              child: _buildDifficultyLevelCard(
                DifficultyLevel.hard,
                Colors.red,
                PhosphorIconsRegular.brain,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDifficultyLevelCard(
    DifficultyLevel level,
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
          context.pushNamed(
            AppRoute.searchQuizzes.name,
            extra: SearchQuizzesExtra(
              title: Text('${StringHelpers.capitalize(level.name)} Quizzes'),
              searchConfig: SearchQuizConfig(
                includeUserId: false,
                searchText: "",
                difficulty: level,
              ),
              showSearchBar: true,
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              StringHelpers.capitalize(level.name),
              style: TextStyle(fontWeight: FontWeight.bold, color: color),
            ),
            // Text(
            //   "${level == 'Easy'
            //       ? 10
            //       : level == 'Medium'
            //       ? 15
            //       : 8} quizList",
            //   style: TextStyle(
            //     fontSize: 12,
            //     color: color.withValues(alpha: 0.8),
            //   ),
            // ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuizCard(Map<String, dynamic> quiz) {
    final diffColor =
        difficultyColors[quiz['difficulty']?.toString().toLowerCase()] ??
        difficultyColors['unknown']!;

    return GestureDetector(
      onTap: () {
        if (mounted) {
          context.pushNamed(
            AppRoute.doQuizzes.name,
            extra: {
              'quiz': Quiz(
                quizId: quiz['_id'],
                createdBy: quiz['user_id'],
                isPublic: quiz['is_public'],
                numberOfQuestions: quiz['num_question'],
                questions: quiz['questions'] ?? [],
              ),
              'prevRoute': AppRoute.quizzes,
            },
          );
        }
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
                quiz['title'] ?? "Untitled Quiz",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: cs.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                quiz['subtitle'] ?? "No description available",
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
                      quiz['difficulty'] != null ? StringHelpers.capitalize(quiz['difficulty']) : "Unknown",
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
                      "${quiz['num_question']} Q",
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

  Widget _buildLoadingIndicator() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2, color: cs.primary),
          ),
          const SizedBox(height: 8),
          Text(
            "Loading...",
            style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            PhosphorIconsRegular.fileX,
            size: 24,
            color: cs.onSurfaceVariant.withOpacity(0.5),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(
              fontSize: 12,
              color: cs.onSurfaceVariant.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }
}
