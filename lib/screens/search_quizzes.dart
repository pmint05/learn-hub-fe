import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:go_router/go_router.dart';
import 'package:learn_hub/configs/router_config.dart';
import 'package:learn_hub/const/constants.dart';
import 'package:learn_hub/const/search_quiz_config.dart';
import 'package:learn_hub/models/quiz.dart';
import 'package:learn_hub/services/quiz_manager.dart';
import 'package:learn_hub/utils/string_helpers.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class SearchQuizzesExtra {
  final Widget title;
  final SearchQuizConfig searchConfig;
  final bool? showSearchBar;

  SearchQuizzesExtra({
    required this.title,
    required this.searchConfig,
    this.showSearchBar,
  });
}

class SearchQuizzesScreen extends StatefulWidget {
  final SearchQuizzesExtra searchExtra;

  const SearchQuizzesScreen({super.key, required this.searchExtra});

  @override
  State<SearchQuizzesScreen> createState() => _SearchQuizzesScreenState();
}

class _SearchQuizzesScreenState extends State<SearchQuizzesScreen> {
  late ColorScheme cs = Theme.of(context).colorScheme;
  late final maxBottomSheetHeight = MediaQuery.of(context).size.height * 0.85;

  final _pageSize = 10;
  int? _currentPage = 0;
  bool? _canLoadMore = true;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _error;
  DifficultyLevel? _selectedDifficulty;
  List<String> _selectedCategories = [];
  String? _selectedSortBy;
  int? _sortOrder;
  late SearchQuizConfig _currentSearchConfig;

  List<Map<String, dynamic>> _quizzes = [];

  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _currentSearchConfig = widget.searchExtra.searchConfig;
    _selectedDifficulty = _currentSearchConfig.difficulty;
    _selectedCategories = _currentSearchConfig.categories ?? [];
    _selectedSortBy = _currentSearchConfig.sortBy;
    _sortOrder = _currentSearchConfig.sortOrder;
    if (widget.searchExtra.showSearchBar ?? false) {
      _searchController.text = _currentSearchConfig.searchText ?? "";
    }
    _scrollController.addListener(_onScroll);
    _searchQuiz(reset: true);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoading &&
        !_isLoadingMore &&
        _canLoadMore!) {
      _loadMoreQuiz();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    cs = Theme.of(context).colorScheme;
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _searchQuiz({bool reset = false}) async {
    if (reset) {
      setState(() {
        _currentPage = 0;
        _quizzes.clear();
        _canLoadMore = true;
      });
    }

    setState(() {
      _isLoading = reset;
      _error = null;
    });

    try {
      final config = SearchQuizConfig(
        includeUserId: _currentSearchConfig.includeUserId,
        searchText: _searchController.text.trim(),
        isPublic: _currentSearchConfig.isPublic,
        categories: _selectedCategories.isNotEmpty ? _selectedCategories : null,
        difficulty: _selectedDifficulty,
        sortBy: _selectedSortBy,
        sortOrder: _sortOrder,
        size: _pageSize,
        start: _currentPage! * _pageSize,
      );

      final response = await QuizManager.instance.getQuizzes(config: config);

      if (response['status'] == 'success' && response['data'] != null) {
        final newQuizzes = List<Map<String, dynamic>>.from(response['data']);
        print('Got total ${response['total']} quizzes');

        setState(() {
          if (reset) {
            _quizzes = newQuizzes;
          } else {
            _quizzes.addAll(newQuizzes);
          }
          _isLoading = false;
          _isLoadingMore = false;
          _canLoadMore = response['total'] == _pageSize;
          // print("can load more: $_canLoadMore");
        });
      } else {
        print("Error fetching quizzes: ${response['message']}");
        print(response);
        print(config.toJson());
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
          _error = "Failed to load quizzes: ${response['message']}";
        });
      }
    } catch (e) {
      print("Error fetching quizzes: $e");
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
        _error = "Failed to load quizzes: $e";
      });
    }
  }

  void _loadMoreQuiz() async {
    print("Loading more quiz...");
    if (_canLoadMore!) {
      setState(() {
        _isLoadingMore = true;
        _currentPage = _currentPage! + 1;
      });
      await _searchQuiz();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: (widget.searchExtra.title),
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
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.pushNamed(AppRoute.generateQuiz.name),
        tooltip: 'Create Quiz',
        child: const Icon(PhosphorIconsRegular.plus),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Column(
        children: [
          if (widget.searchExtra.showSearchBar ?? false) _buildSearchBar(),
          Expanded(child: const Center(child: CircularProgressIndicator())),
        ],
      );
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
              style: TextStyle(fontSize: 16, color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _searchQuiz(reset: true),
              icon: const Icon(PhosphorIconsRegular.arrowClockwise),
              label: const Text("Try Again"),
            ),
          ],
        ),
      );
    }

    if (_quizzes.isEmpty) {
      return Column(
        children: [
          if (widget.searchExtra.showSearchBar ?? false) _buildSearchBar(),
          Expanded(
            child: Center(
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
                ],
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        if (widget.searchExtra.showSearchBar ?? false) _buildSearchBar(),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              _searchQuiz(reset: true);
            },
            child: AnimationLimiter(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: _quizzes.length + 1,
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                itemBuilder: (context, index) {
                  if (index == _quizzes.length) {
                    return _isLoadingMore
                        ? Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 16.0,
                        ),
                        child: CircularProgressIndicator(),
                      ),
                    )
                        : SizedBox(
                      height:
                      _quizzes.isEmpty
                          ? MediaQuery.of(context).size.height *
                          0.6
                          : 40,
                    );
                  }
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
          ),
        ),
      ],
    );
  }

  void _showFilterBottomSheet() {
    List<String> tempCategories = List.from(_selectedCategories);
    DifficultyLevel? tempDifficulty = _selectedDifficulty;
    String? tempSortBy = _selectedSortBy;
    int? tempSortOrder = _sortOrder;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => StatefulBuilder(
            builder: (context, setModalState) {
              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cs.surface,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                ),
                constraints: BoxConstraints(maxHeight: maxBottomSheetHeight),
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
                    const SizedBox(height: 10),
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 10),
                            Text(
                              "Sort Quizzes",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: cs.onSurface,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Wrap(
                              spacing: 8,
                              children: [
                                ChoiceChip(
                                  label: Text("Newest"),
                                  selected:
                                      tempSortBy == "created_date" &&
                                      tempSortOrder == -1,
                                  onSelected: (selected) {
                                    setModalState(() {
                                      tempSortBy = "created_date";
                                      tempSortOrder = -1;
                                    });
                                  },
                                  backgroundColor: cs.surface,
                                  labelStyle: TextStyle(
                                    color:
                                        tempSortBy == 'created_date' &&
                                                tempSortOrder == -1
                                            ? cs.primary
                                            : cs.onSurfaceVariant,
                                  ),
                                  selectedColor: cs.primary.withValues(
                                    alpha: 0.2,
                                  ),
                                  checkmarkColor: cs.primary,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    side: BorderSide(
                                      color:
                                          tempSortBy == 'created_date' &&
                                                  tempSortOrder == -1
                                              ? cs.primary
                                              : cs.surfaceDim,
                                    ),
                                  ),
                                ),
                                ChoiceChip(
                                  label: Text("Oldest"),
                                  selected:
                                      tempSortBy == "created_date" &&
                                      tempSortOrder == 1,
                                  onSelected: (selected) {
                                    setModalState(() {
                                      tempSortBy = "created_date";
                                      tempSortOrder = 1;
                                    });
                                  },
                                  backgroundColor: cs.surface,
                                  labelStyle: TextStyle(
                                    color:
                                        tempSortBy == 'created_date' &&
                                                tempSortOrder == 1
                                            ? cs.primary
                                            : cs.onSurfaceVariant,
                                  ),
                                  selectedColor: cs.primary.withValues(
                                    alpha: 0.2,
                                  ),
                                  checkmarkColor: cs.primary,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    side: BorderSide(
                                      color:
                                          tempSortBy == 'created_date' &&
                                                  tempSortOrder == -1
                                              ? cs.primary
                                              : cs.surfaceDim,
                                    ),
                                  ),
                                ),
                                ChoiceChip(
                                  label: Text("Number of Questions (Asc)"),
                                  selected:
                                      tempSortBy == "num_question" &&
                                      tempSortOrder == 1,
                                  onSelected: (selected) {
                                    setModalState(() {
                                      tempSortBy = "num_question";
                                      tempSortOrder = 1;
                                    });
                                  },
                                  backgroundColor: cs.surface,
                                  labelStyle: TextStyle(
                                    color:
                                        tempSortBy == "num_question" &&
                                                tempSortOrder == 1
                                            ? cs.primary
                                            : cs.onSurfaceVariant,
                                  ),
                                  selectedColor: cs.primary.withValues(
                                    alpha: 0.2,
                                  ),
                                  checkmarkColor: cs.primary,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    side: BorderSide(
                                      color:
                                          tempSortBy == "num_question" &&
                                                  tempSortOrder == 1
                                              ? cs.primary
                                              : cs.surfaceDim,
                                    ),
                                  ),
                                ),
                                ChoiceChip(
                                  label: Text("Number of Questions (Desc)"),
                                  selected:
                                      tempSortBy == "num_question" &&
                                      tempSortOrder == -1,
                                  onSelected: (selected) {
                                    setModalState(() {
                                      tempSortBy = "num_question";
                                      tempSortOrder = -1;
                                    });
                                  },
                                  backgroundColor: cs.surface,
                                  labelStyle: TextStyle(
                                    color:
                                        tempSortBy == "num_question" &&
                                                tempSortOrder == -1
                                            ? cs.primary
                                            : cs.onSurfaceVariant,
                                  ),
                                  selectedColor: cs.primary.withValues(
                                    alpha: 0.2,
                                  ),
                                  checkmarkColor: cs.primary,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    side: BorderSide(
                                      color:
                                          tempSortBy == "num_question" &&
                                                  tempSortOrder == -1
                                              ? cs.primary
                                              : cs.surfaceDim,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
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
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                color: cs.onSurface,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              children:
                                  DifficultyLevel.values
                                      .where(
                                        (d) =>
                                            d != DifficultyLevel.unknown &&
                                            d != DifficultyLevel.all,
                                      )
                                      .map(
                                        (difficulty) => FilterChip(
                                          label: Text(
                                            StringHelpers.capitalize(
                                              difficulty.name,
                                            ),
                                          ),
                                          selected:
                                              tempDifficulty == difficulty,
                                          onSelected: (selected) {
                                            setModalState(() {
                                              tempDifficulty =
                                                  selected ? difficulty : null;
                                            });
                                          },
                                          backgroundColor: cs.surface,
                                          labelStyle: TextStyle(
                                            color:
                                                tempDifficulty == difficulty
                                                    ? cs.primary
                                                    : cs.onSurfaceVariant,
                                          ),
                                          selectedColor: cs.primary.withValues(
                                            alpha: 0.2,
                                          ),
                                          checkmarkColor: cs.primary,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                            side: BorderSide(
                                              color:
                                                  tempDifficulty == difficulty
                                                      ? cs.primary
                                                      : cs.surfaceDim,
                                            ),
                                          ),
                                        ),
                                      )
                                      .toList(),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              "Categories",
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                color: cs.onSurface,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              children:
                                  availableCategories.map((category) {
                                    final isSelected = tempCategories.contains(
                                      category['name'] as String,
                                    );
                                    return FilterChip(
                                      label: Text(category['name'] as String),
                                      selected: isSelected,
                                      onSelected: (selected) {
                                        setModalState(() {
                                          if (selected) {
                                            tempCategories.add(
                                              category['name'] as String,
                                            );
                                          } else {
                                            tempCategories.remove(
                                              category['name'] as String,
                                            );
                                          }
                                        });
                                      },
                                      backgroundColor: cs.surface,
                                      labelStyle: TextStyle(
                                        color:
                                            isSelected
                                                ? cs.primary
                                                : cs.onSurfaceVariant,
                                      ),
                                      selectedColor: cs.primary.withValues(
                                        alpha: 0.2,
                                      ),
                                      checkmarkColor: cs.primary,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        side: BorderSide(
                                          color:
                                              isSelected
                                                  ? cs.primary
                                                  : cs.surfaceDim,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                            ),
                            const SizedBox(height: 30),
                          ],
                        ),
                      ),
                    ),

                    Container(
                      padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
                      decoration: BoxDecoration(
                        color: cs.surface,
                        border: Border(
                          top: BorderSide(
                            color: cs.surfaceDim.withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                setModalState(() {
                                  tempCategories.clear();
                                  tempDifficulty = null;
                                  tempSortOrder = null;
                                  tempSortBy = null;
                                });
                              },
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                side: BorderSide(color: cs.primary),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                "Reset",
                                style: TextStyle(color: cs.primary),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton(
                              onPressed: () {
                                Navigator.pop(context);
                                setState(() {
                                  _selectedCategories = tempCategories;
                                  _selectedDifficulty = tempDifficulty;
                                  _selectedSortBy = tempSortBy;
                                  _sortOrder = tempSortOrder;
                                });
                                _searchQuiz(reset: true);
                              },
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                backgroundColor: cs.primary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                "Apply",
                                style: TextStyle(color: cs.onPrimary),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // SizedBox(height: MediaQuery.of(context).padding.bottom),
                  ],
                ),
              );
            },
          ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: TextField(
        controller: _searchController,
        // onChanged: (value) {
        //   setState(() {
        //     _quizzes = _getMockQuizzesBySearch(value);
        //   });
        // },
        onSubmitted: (value) {
          _searchQuiz(reset: true);
        },
        decoration: InputDecoration(
          hintText: "Search quizzes...",
          prefixIcon: Icon(PhosphorIconsRegular.magnifyingGlass),
          filled: true,
          fillColor: cs.surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, bool selected) {
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
    final diffColor = _getDifficultyColor(
      DifficultyLevel.values.firstWhere(
        (e) => e.name == quiz['difficulty'].toString().toLowerCase(),
        orElse: () => DifficultyLevel.unknown,
      ),
      context,
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: cs.surfaceDim),
      ),
      child: InkWell(
        onTap: () {
          context.pushNamed(
            AppRoute.doQuizzes.name,
            extra: {'quiz': Quiz.fromJson(quiz), 'prevRoute': null},
          );
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
                          quiz['title'] ?? 'Untitled Quiz',
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
              const SizedBox(height: 8),
              if (quiz.containsKey('categories') &&
                  quiz['categories'].isNotEmpty)
                Text(
                  quiz['categories'].join(', '),
                  style: TextStyle(
                    fontSize: 12,
                    color: cs.primary,
                    fontStyle: FontStyle.italic,
                  ),
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
                        StringHelpers.capitalize(quiz['difficulty']),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: diffColor,
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
                      "${quiz['num_question'] ?? quiz.length} Q",
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

  Color _getDifficultyColor(DifficultyLevel difficulty, BuildContext context) {
    return difficulty == DifficultyLevel.easy
        ? Colors.green
        : difficulty == DifficultyLevel.medium
        ? Colors.orange
        : difficulty == DifficultyLevel.hard
        ? Colors.red
        : difficulty == DifficultyLevel.all
        ? Colors.blueAccent
        : Colors.grey;
  }
}
