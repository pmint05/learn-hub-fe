import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:learn_hub/configs/router_config.dart';
import 'package:learn_hub/const/header_action.dart';
import 'package:learn_hub/const/search_quiz_config.dart';
import 'package:learn_hub/models/user.dart';
import 'package:learn_hub/providers/app_auth_provider.dart';
import 'package:learn_hub/providers/appbar_provider.dart';
import 'package:learn_hub/services/statistic_service.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'dart:math';

import 'package:provider/provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late ColorScheme cs = Theme.of(context).colorScheme;
  late AppUser? currentUser =
      Provider.of<AppAuthProvider>(context, listen: false).appUser;
  String? _displayName;
  String? _username;
  String? _photoURL;
  int? _credits;
  bool? _isVip;
  DateTime? _vipExpiration;
  int? _quizCreated;
  int? _quizCompleted;
  int? _fileUploaded;
  int? _perfectQuiz;
  int? _totalQuizAttempts;

  bool _isCountingCreatedQuiz = false;
  bool _isCountingTotalQuizAttempts = false;

  StatisticService _statisticService = StatisticService();

  void _showSettings() {
    context.pushNamed(AppRoute.settings.name).then((_) {
      _loadUserData();
    });
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    cs = Theme.of(context).colorScheme;
    _loadUserData();
    _getStatistics();
    print("ProfileScreen didChangeDependencies");
  }

  void _loadUserData() {
    // Get fresh user data
    currentUser = Provider.of<AppAuthProvider>(context, listen: false).appUser;
    _initializeUserData();
  }

  void _initializeUserData() {
    if (currentUser != null) {
      _displayName = currentUser!.displayName ?? "";
      _username = currentUser!.username ?? "Username";
      _credits = currentUser?.credits ?? 0;
      _photoURL = currentUser!.photoURL ?? "";
      _isVip = currentUser!.isVIP ?? false;
      _vipExpiration = currentUser!.vipExpiration;
      _quizCreated = 0;
      _quizCompleted = 0;
      _fileUploaded = 0;
      _perfectQuiz = 0;
    }
  }

  void _getStatistics() {
    _countCreatedQuiz();
    _countTotalQuizAttempts();
  }

  void _countCreatedQuiz() async {
    try {
      setState(() {
        _isCountingCreatedQuiz = true;
      });
      final response = await _statisticService.countQuiz(
        SearchQuizConfig(searchText: '', includeUserId: true),
      );
      print(response);
      final status = response['status'];
      if (status != 'success') {
        print('Error: ${response['message']}');
        return;
      }
      final count = response['count'];
      setState(() {
        _quizCreated = count;
      });
    } catch (e) {
      print('Error when getting statistics: $e');
    } finally {
      setState(() {
        _isCountingCreatedQuiz = false;
      });
    }
  }

  void _countTotalQuizAttempts() async {
    try {
      setState(() {
        _isCountingTotalQuizAttempts = true;
      });
      final response = await _statisticService.countTotalQuizAttempts();
      print(response);
      final status = response['status'];
      if (status != 'success') {
        print('Error: ${response['message']}');
        return;
      }
      final count = response['count'];
      setState(() {
        _totalQuizAttempts = count;
      });
    } catch (e) {
      print('Error when getting statistics: $e');
    } finally {
      setState(() {
        _isCountingTotalQuizAttempts = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AppBarProvider>(context, listen: false).setHeaderAction(
        HeaderAction(type: AppBarActionType.settings, callback: _showSettings),
      );
    });

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              color: Theme.of(context).scaffoldBackgroundColor,
              padding: const EdgeInsets.only(top: 16, bottom: 24),
              child: Column(
                children: [
                  // Avatar with optional VIP badge
                  _buildUserInfoSection(),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Container(
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(36),
                  topRight: Radius.circular(36),
                ),
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // OVERVIEW section
                  _buildOverviewSection(),
                  const SizedBox(height: 16),
                  // FEATURES section
                  _buildFeatureSection(),
                  const SizedBox(height: 64),
                ],
              ),
            ),
          ),
        ],
      ),
      extendBody: true,
    );
  }

  Widget _buildOverviewBox({
    bool isLoading = false,
    required String number,
    required String label,
    required IconData icon,
    required Color backgroundColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      clipBehavior: Clip.hardEdge,
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          Positioned(
            top: -10,
            right: -10,
            child: Transform.rotate(
              angle: pi / 8,
              child: Icon(
                icon,
                color: backgroundColor.withValues(alpha: 0.2),
                size: 56,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!isLoading)
                  Text(
                    number,
                    style: TextStyle(
                      color: backgroundColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                    ),
                  ),
                if (isLoading)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 7.0),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: backgroundColor,
                        strokeWidth: 2,
                      ),
                    ),
                  ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    color: backgroundColor.withValues(alpha: 0.6),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Overview",
          style: TextStyle(
            color: cs.onSurface,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        const SizedBox(height: 12),

        // Overview stats - first row
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 72,
                child: _buildOverviewBox(
                  isLoading: _isCountingCreatedQuiz,
                  number: "$_quizCreated",
                  label: "Quiz Created",
                  icon: PhosphorIconsFill.listBullets,
                  backgroundColor: cs.secondary,
                ),
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: SizedBox(
                height: 72,
                child: _buildOverviewBox(
                  number: "$_quizCompleted",
                  label: "Quiz Completed",
                  icon: PhosphorIconsFill.listChecks,
                  backgroundColor: cs.primary,
                ),
              ),
            ),
          ],
        ),

        // Overview stats - second row
        const SizedBox(height: 15),
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 72,
                child: _buildOverviewBox(
                  isLoading: _isCountingTotalQuizAttempts,
                  number: "$_totalQuizAttempts",
                  label: "Total Quiz Attempts",
                  icon: PhosphorIconsFill.checks,
                  backgroundColor: cs.tertiary,
                ),
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: SizedBox(
                height: 72,
                child: _buildOverviewBox(
                  number: "$_fileUploaded",
                  label: "File Uploaded",
                  icon: PhosphorIconsFill.files,
                  backgroundColor: Colors.pinkAccent,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required Color iconColor,
    required String text,
    required Function()? onClick,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onClick,
        borderRadius: BorderRadius.circular(12),
        splashColor: iconColor.withValues(alpha: 0.2),
        highlightColor: iconColor.withValues(alpha: 0.1),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(color: cs.onSurface, fontSize: 14),
                ),
              ),
              Icon(
                PhosphorIconsRegular.caretRight,
                color: cs.onSurface.withValues(alpha: 0.4),
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Features",
          style: TextStyle(
            color: cs.onSurface,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        const SizedBox(height: 8),
        _buildFeatureItem(
          icon: PhosphorIconsFill.star,
          iconColor: cs.primary,
          text: "Buy more credits",
          onClick: () {
            print('Buy more credits clicked');
          },
        ),
        const SizedBox(height: 8),
        _buildFeatureItem(
          icon: PhosphorIconsDuotone.sketchLogo,
          iconColor: cs.secondary,
          text: "You've been VIP since Jan. 2025",
          onClick: () {
            print('VIP details clicked');
          },
        ),
        const SizedBox(height: 8),
        _buildFeatureItem(
          icon: PhosphorIconsFill.headset,
          iconColor: cs.error,
          text: "Support",
          onClick: () {},
        ),
        const SizedBox(height: 8),
        _buildFeatureItem(
          icon: PhosphorIconsFill.shareNetwork,
          iconColor: cs.tertiary,
          text: "Share the app",
          onClick: () {},
        ),
        const SizedBox(height: 8),
        _buildFeatureItem(
          icon: PhosphorIconsFill.telegramLogo,
          iconColor: cs.primary,
          text: "LearnHub on Telegram",
          onClick: () {},
        ),
      ],
    );
  }

  Widget _buildUserInfoSection() {
    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomCenter,
          clipBehavior: Clip.none,
          children: [
            Container(
              decoration: BoxDecoration(
                border:
                    _isVip == true
                        ? Border.all(color: cs.secondary, width: 2)
                        : null,
                borderRadius: BorderRadius.circular(100),
              ),
              child: CircleAvatar(
                radius: 36,
                backgroundColor: cs.surfaceDim,
                child:
                    _photoURL != null && _photoURL!.isNotEmpty
                        ? ClipOval(child: Image.network(_photoURL!))
                        : Icon(
                          PhosphorIconsRegular.user,
                          size: 36,
                          color: cs.onSurface.withValues(alpha: 0.5),
                        ),
              ),
            ),
            if (_isVip == true)
              Positioned(
                bottom: -6,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: cs.secondary,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      width: 2,
                    ),
                  ),
                  child: Text(
                    "PRO",
                    style: TextStyle(
                      color: cs.onSecondary,
                      fontWeight: FontWeight.w700,
                      fontSize: 7,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),

        // User name and username
        _displayName!.isNotEmpty
            ? Text(
              _displayName!,
              style: TextStyle(
                color: cs.onSurface,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            )
            : Text(
              "Open settings to set your name",
              style: TextStyle(
                color: cs.onSurface,
                fontSize: 12,
                fontWeight: FontWeight.w200,
                fontStyle: FontStyle.italic,
              ),
            ),

        _username!.isNotEmpty
            ? Text(
              _username!,
              style: TextStyle(
                color: cs.onSurface.withValues(alpha: 0.6),
                fontSize: 14,
              ),
            )
            : Text(
              "Open settings to set your username",
              style: TextStyle(
                color: cs.onSurface,
                fontSize: 12,
                fontWeight: FontWeight.w200,
                fontStyle: FontStyle.italic,
              ),
            ),
        const SizedBox(height: 8),

        // Credits display
        Container(
          padding: const EdgeInsets.fromLTRB(6, 6, 12, 6),
          decoration: BoxDecoration(
            color: cs.primary.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 8,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: cs.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: EdgeInsets.all(4),
                child: Icon(
                  PhosphorIconsFill.star,
                  color: cs.onPrimary,
                  size: 16,
                ),
              ),
              Text(
                "${_credits ?? 0}",
                style: TextStyle(
                  color: cs.primary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
