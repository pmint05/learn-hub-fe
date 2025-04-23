import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:go_router/go_router.dart';
import 'package:learn_hub/configs/router_config.dart';
import 'package:learn_hub/const/header_action.dart';
import 'package:learn_hub/models/user.dart';
import 'package:learn_hub/providers/appbar_provider.dart';
import 'package:learn_hub/providers/app_auth_provider.dart';
import 'package:learn_hub/providers/theme_provider.dart';
import 'package:learn_hub/screens/generate_quizzes.dart';
import 'package:learn_hub/screens/quizzes.dart';
import 'package:learn_hub/widgets/alert_box.dart';
import 'package:moment_dart/moment_dart.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';

enum QuizCardType { recent, created, incorrect }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  final scrollController = ScrollController();
  bool showFloatingButton = true;

  // Mock data - replace with actual data later
  final List<Map<String, dynamic>> recentQuizzes = [
    {'title': 'Flutter Basics', 'completion': 0.7, 'questionCount': 15},
    {'title': 'Dart Programming', 'completion': 0.3, 'questionCount': 20},
    {'title': 'UI/UX Principles', 'completion': 1.0, 'questionCount': 12},
  ];

  final List<Map<String, dynamic>> mostIncorrectQuizzes = [
    {
      'title': 'Advanced Flutter',
      'completion': 0.1,
      'questionCount': 10,
      'incorrectCount': 5,
    },
    {
      'title': 'Data Structures',
      'completion': 0.2,
      'questionCount': 25,
      'incorrectCount': 8,
    },
    {
      'title': 'Algorithms',
      'completion': 0.4,
      'questionCount': 18,
      'incorrectCount': 3,
    },
  ];

  final List<Map<String, dynamic>> recentCreatedQuizzes = [
    {'title': 'Math Quiz', 'questionCount': 10, 'createdAt': DateTime.now()},
    {
      'title': 'Science Quiz',
      'questionCount': 15,
      'createdAt': DateTime.fromMillisecondsSinceEpoch(1672531199000),
    },
    {
      'title': 'Geography Quiz',
      'questionCount': 12,
      'createdAt': DateTime.fromMillisecondsSinceEpoch(1672617599000),
    },
    {
      'title': 'History Quiz',
      'questionCount': 20,
      'createdAt': DateTime.fromMillisecondsSinceEpoch(1672703999000),
    },
    {
      'title': 'Literature Quiz',
      'questionCount': 8,
      'createdAt': DateTime.fromMillisecondsSinceEpoch(1672790399000),
    },
  ];

  final List<Map<String, dynamic>> sources = [
    {
      'title': 'PDF Document',
      'icon': PhosphorIconsFill.filePdf,
      'color': Colors.red,
    },
    {
      'title': 'Word Document',
      'icon': PhosphorIconsFill.fileDoc,
      'color': Colors.blue,
    },
    {
      'title': 'Text File',
      'icon': PhosphorIconsFill.fileText,
      'color': Colors.green,
    },
    {'title': 'URL', 'icon': PhosphorIconsFill.globe, 'color': Colors.purple},
    {
      'title': 'Camera Scan',
      'icon': PhosphorIconsFill.camera,
      'color': Colors.orange,
    },
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..forward();

    scrollController.addListener(_scrollListener);
  }

  void _scrollListener() {
    if (scrollController.position.userScrollDirection ==
        ScrollDirection.reverse) {
      if (showFloatingButton) {
        setState(() {
          showFloatingButton = false;
        });
      }
    } else if (scrollController.position.userScrollDirection ==
        ScrollDirection.forward) {
      if (!showFloatingButton) {
        setState(() {
          showFloatingButton = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AppAuthProvider>(context);
    final currentUser = authProvider.appUser;
    final cs = Theme.of(context).colorScheme;
    // print("User ${authProvider.user}");
    // print("AppUser ${authProvider.appUser}");
    // print("Current User ${currentUser}");

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AppBarProvider>(context, listen: false).setHeaderAction(
        HeaderAction(
          type: AppBarActionType.notifications,
          callback: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Notifications tapped')),
            );
          },
          notificationCount: 3,
        ),
      );
    });

    return Scaffold(
      body: AnimationLimiter(
        child: ShaderMask(
          shaderCallback:
              (bounds) => LinearGradient(
                colors: [
                  cs.surface.withValues(alpha:0),
                  Colors.white,
                  Colors.white,
                  cs.surface.withValues(alpha:0),
                ],
                stops: [0, 0.05, 0.88, 1],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ).createShader(bounds),
          child: ListView(
            controller: scrollController,
            padding: EdgeInsets.zero,
            children: AnimationConfiguration.toStaggeredList(
              duration: const Duration(milliseconds: 600),
              childAnimationBuilder:
                  (widget) => SlideAnimation(
                    horizontalOffset: 50.0,
                    child: FadeInAnimation(child: widget),
                  ),
              children: [
                _buildHeader(cs, currentUser),
                _buildWelcomeCard(cs, ),
                _buildQuickStats(cs, ),
                AlertBox(
                  subtitle: "✨ Upgrade to PRO for more features and benefits.",
                  type: AlertBoxType.warning,
                  onOk: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Upgrade tapped')),
                    );
                  },
                  okButton: Text(
                    "Upgrade",
                    style: TextStyle(
                      color: cs.secondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                _buildRecentQuizzes(cs),
                _buildRecentCreatedQuizzes(cs),
                _buildMostIncorrectQuizzes(cs),
                _buildSourcesSection(cs),
                _buildPopularCategories(cs),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ),
      // floatingActionButton: Padding(
      //   padding: const EdgeInsets.only(bottom: 72),
      //   child: AnimatedSize(
      //     duration: const Duration(milliseconds: 300),
      //     // si: showFloatingButton ? 1 : 0,
      //     child: FloatingActionButton.extended(
      //       heroTag: "create_quiz",
      //       shape: RoundedRectangleBorder(borderRadius: BorderRadiusGeometry.all(Radius.circular(30))),
      //       onPressed:
      //           () => {
      //             Navigator.of(context).push(
      //               MaterialPageRoute(
      //                 builder: (context) => const GenerateQuizzesScreen(),
      //               ),
      //             ),
      //           },
      //       label: const Text('Create Quiz'),
      //       icon: const Icon(PhosphorIconsRegular.plus),
      //     ),
      //   ),
      // ),
    );
  }

  Widget _buildHeader(ColorScheme cs,AppUser? currentUser) {
    final name =
        currentUser?.displayName?.isNotEmpty == true
            ? currentUser!.displayName!
            : currentUser?.username?.isNotEmpty == true
            ? currentUser!.username!
            : (currentUser?.email ?? "??");

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
      decoration: BoxDecoration(
        // gradient: LinearGradient(
        //   colors: [Theme.of(context).scaffoldBackgroundColor, cs.primary],
        //   begin: const FractionalOffset(0.0, 0.0),
        //   end: const FractionalOffset(0.0, 1.0),
        //   stops: [0.1, 1.0],
        //   tileMode: TileMode.clamp,
        // ),
        color: cs.primary,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: cs.onPrimary.withValues(alpha: 0.2),
                radius: 24,
                backgroundImage:
                    currentUser?.photoURL != null && currentUser!.photoURL!.isNotEmpty && currentUser.photoURL!.startsWith("http")
                        ? NetworkImage(currentUser.photoURL!)
                        : null,
                child:
                    currentUser?.photoURL == null || !currentUser!.photoURL!.startsWith("http")
                        ? Text(name.substring(0, 2)
                              .toUpperCase(),
                          style: TextStyle(
                            color: cs.onPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                        : null,
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hello, $name!',
                    style: TextStyle(
                      color: cs.onPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Ready to learn something new?',
                    style: TextStyle(
                      color: cs.onPrimary.withValues(alpha: 0.8),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeCard(ColorScheme cs) {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 0,
      color: cs.primaryContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Create Quiz from Any Material',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: cs.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Upload documents, enter number of questions, choose difficulty level, and get quizzes generated in seconds.',
              style: TextStyle(
                fontSize: 14,
                color: cs.onPrimaryContainer.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed:
                  () => {
                    context.pushNamed(AppRoute.generateQuiz.name),
                  },
              icon: const Icon(PhosphorIconsRegular.plus),
              label: const Text('Get Started'),
              style: OutlinedButton.styleFrom(
                foregroundColor: cs.onPrimaryContainer,
                side: BorderSide(
                  color: cs.onPrimaryContainer.withValues(alpha: 0.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStats(ColorScheme cs) {
    return Container(
      height: 100,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              cs,
              'Quizzes Taken',
              '24',
              PhosphorIconsFill.checkCircle,
              Colors.green,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              cs,
              'Quiz Created',
              '5',
              PhosphorIconsFill.notepad,
              Colors.orange,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              cs,
              'Points',
              '2450',
              PhosphorIconsFill.star,
              Colors.amber,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    ColorScheme cs,
    String label,
    String value,
    IconData icon,
    Color iconColor,
  ) {
    return Card(
      elevation: 0,
      color: cs.surface.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: cs.onSurface,
            ),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRecentQuizzes(ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Continue Learning',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: cs.onSurface,
                ),
              ),
              TextButton(onPressed: () {}, child: Text('See All')),
            ],
          ),
        ),
        SizedBox(
          height: 100,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: recentQuizzes.length,
            itemBuilder: (context, index) {
              final quiz = recentQuizzes[index];
              return _buildQuizCard(cs, quiz, QuizCardType.recent);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRecentCreatedQuizzes(ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recently Created Quizzes',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: cs.onSurface,
                ),
              ),
              TextButton(onPressed: () {}, child: Text('See All')),
            ],
          ),
        ),
        SizedBox(
          height: 100,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: recentCreatedQuizzes.length,
            itemBuilder: (context, index) {
              final quiz = recentCreatedQuizzes[index];
              return _buildQuizCard(cs, quiz, QuizCardType.created);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMostIncorrectQuizzes(ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Most Incorrect Quizzes',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: cs.onSurface,
                ),
              ),
              TextButton(onPressed: () {}, child: Text('See All')),
            ],
          ),
        ),
        SizedBox(
          height: 100,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: mostIncorrectQuizzes.length,
            itemBuilder: (context, index) {
              final quiz = mostIncorrectQuizzes[index];
              return _buildQuizCard(cs, quiz, QuizCardType.incorrect);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildQuizCard(
    ColorScheme cs,
    Map<String, dynamic> quiz,
    QuizCardType type,
  ) {
    Widget additionalInfo;

    if (type == QuizCardType.incorrect) {
      additionalInfo = Container(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: cs.error.withValues(alpha: 0.12),
        ),
        child: Text(
          "${quiz['incorrectCount']} Incorrect",
          style: TextStyle(
            fontSize: 12,
            color: cs.error.withValues(alpha: 0.8),
          ),
        ),
      );
    } else if (type == QuizCardType.created) {
      additionalInfo = Text(
        Moment(quiz['createdAt']).fromNow(),
        style: TextStyle(
          fontSize: 12,
          color: cs.onSurfaceVariant.withValues(alpha: 0.6),
        ),
      );
    } else if (type == QuizCardType.recent) {
      additionalInfo = Text(
        "${quiz['completion'] * 100}%",
        style: TextStyle(
          fontSize: 12,
          color: cs.primary,
          fontWeight: FontWeight.w600,
        ),
      );
    } else {
      additionalInfo = const SizedBox.shrink();
    }

    return Container(
      width: 260,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Card(
        elevation: 0,
        color: cs.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: cs.surfaceDim),
        ),
        child: InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            vertical: 4,
                            horizontal: 12,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: cs.surfaceDim),
                          ),
                          child: Text(
                            "${quiz['questionCount']} Q",
                            style: TextStyle(
                              fontSize: 12,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ),
                        const Spacer(),
                        additionalInfo,
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSourcesSection(ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Text(
            'Create Quiz From',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: cs.onSurface,
            ),
          ),
        ),
        SizedBox(
          height: 110,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: sources.length,
            itemBuilder: (context, index) {
              final source = sources[index];
              return _buildSourceCard(cs, source);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSourceCard(ColorScheme cs, Map<String, dynamic> source) {
    return Container(
      width: 100,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: source['color'].withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(source['icon'], color: source['color'], size: 32),
          ),
          const SizedBox(height: 8),
          Text(
            source['title'],
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: cs.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPopularCategories(ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Text(
            'Popular Categories',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: cs.onSurface,
            ),
          ),
        ),
        GridView.count(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.5,
          children: [
            _buildCategoryCard(
              cs,
              'Programming',
              PhosphorIconsFill.code,
              Colors.blue,
            ),
            _buildCategoryCard(
              cs,
              'Mathematics',
              PhosphorIconsFill.mathOperations,
              Colors.green,
            ),
            _buildCategoryCard(
              cs,
              'Language',
              PhosphorIconsFill.translate,
              Colors.purple,
            ),
            _buildCategoryCard(
              cs,
              'Science',
              PhosphorIconsFill.atom,
              Colors.orange,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCategoryCard(
    ColorScheme cs,
    String title,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 0,
      color: cs.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: cs.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateQuizBottomSheet(ColorScheme cs,BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Container(
            height: MediaQuery.of(context).size.height * 0.75,
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: cs.onSurfaceVariant.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Create New Quiz',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: cs.onSurface,
                    ),
                  ),
                ),
                Expanded(
                  child: GridView.count(
                    padding: const EdgeInsets.all(16),
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 0.9,
                    children:
                        sources.map((source) {
                          return AnimationConfiguration.staggeredGrid(
                            position: sources.indexOf(source),
                            columnCount: 2,
                            duration: const Duration(milliseconds: 400),
                            child: ScaleAnimation(
                              child: FadeInAnimation(
                                child: Card(
                                  elevation: 0,
                                  color: source['color'].withValues(alpha: 0.1),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: InkWell(
                                    onTap: () => Navigator.pop(context),
                                    borderRadius: BorderRadius.circular(16),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          source['icon'],
                                          color: source['color'],
                                          size: 48,
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          source['title'],
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: cs.onSurface,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Upload a ${source['title']}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: cs.onSurfaceVariant,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                  ),
                ),
              ],
            ),
          ),
    );
  }
}
