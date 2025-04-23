import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:learn_hub/configs/router_config.dart';
import 'package:learn_hub/const/header_action.dart';
import 'package:learn_hub/models/user.dart';
import 'package:learn_hub/providers/app_auth_provider.dart';
import 'package:learn_hub/providers/appbar_provider.dart';
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
  int? _questSets;
  int? _questAsked;
  int? _questAnswered;
  int? _quizzesDone;

  // Moved _showSettings into State to access context
  void _showSettings() {
    context.pushNamed(AppRoute.settings.name).then((_) {
      // Refresh data when returning from settings
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
    // Safe to access context-dependent resources here
    cs = Theme.of(context).colorScheme;
    _loadUserData();
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
      _questSets = 0;
      _questAsked = 0;
      _questAnswered = 0;
      _quizzesDone = 0;
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
      body: Column(
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

          // Points Box
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

          const SizedBox(height: 24),

          // Scrollable content with rounded corners
          Expanded(
            child: ShaderMask(
              shaderCallback: (Rect bounds) {
                return LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white,
                    Colors.white,
                    Colors.white,
                    cs.surface.withValues(alpha: 0),
                  ],
                  stops: const [0.0, 0, 0.9, 1.0],
                ).createShader(bounds);
              },
              child: Container(
                clipBehavior: Clip.hardEdge,
                decoration: BoxDecoration(
                  color: cs.surface,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(36),
                    topRight: Radius.circular(36),
                  ),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // OVERVIEW
                      Text(
                        "Overview",
                        style: TextStyle(
                          color: cs.onSurface,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 72,
                              child: _buildOverviewBox(
                                number: "$_questSets",
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
                                number: "$_questAsked",
                                label: "Quiz Completed",
                                icon: PhosphorIconsFill.listChecks,
                                backgroundColor: cs.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 72,
                              child: _buildOverviewBox(
                                number: "$_quizzesDone",
                                label: "Perfect Quiz",
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
                                number: "$_questAnswered",
                                label: "File Uploaded",
                                icon: PhosphorIconsFill.files,
                                backgroundColor: Colors.pinkAccent,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // FEATURES
                      Text(
                        "Features",
                        style: TextStyle(
                          color: cs.onSurface,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildFeatureItem(
                        icon: PhosphorIconsFill.star,
                        iconColor: cs.primary,
                        text: "Buy more credits",
                        onClick: () {
                          // TODO: Implement buy credits functionality
                          // context.pushNamed(AppRoute.buyCredits.name);
                          print('Buy more credits clicked');
                        },
                      ),
                      const SizedBox(height: 8),
                      _buildFeatureItem(
                        icon: PhosphorIconsDuotone.sketchLogo,
                        iconColor: cs.secondary,
                        text: "You've been VIP since Jan. 2025",
                        onClick: () {
                          // TODO: Implement VIP details functionality
                          // context.pushNamed(AppRoute.vipDetails.name);
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
                      const SizedBox(height: 64),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      extendBody: true,
    );
  }

  Widget _buildOverviewBox({
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
                Text(
                  number,
                  style: TextStyle(
                    color: backgroundColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
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
}
