import "dart:math" show pi;
import 'package:flutter/material.dart';
import 'package:learn_hub/const/header_action.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class Header extends StatelessWidget implements PreferredSizeWidget {
  final double height;
  final String title;
  final String? logoURL;
  final AppBarActionType actionType;
  final int notificationCount;
  final VoidCallback? onPostfixActionTap;
  final IconData? prefixActionIcon;
  final VoidCallback? onPrefixActionTap;

  const Header({
    super.key,
    this.height = 60.0,
    this.title = 'LearnHub',
    this.logoURL,
    this.actionType = AppBarActionType.none,
    this.notificationCount = 0,
    this.onPostfixActionTap,
    this.onPrefixActionTap,
    this.prefixActionIcon,
  });

  @override
  Size get preferredSize => Size.fromHeight(height);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (onPostfixActionTap != null && prefixActionIcon != null)
              _buildPrefixAction(cs, context),
            _buildLogoAndTitle(cs, isDark),
            _buildPostfixAction(cs),
          ],
        ),
      ),
    );
  }

  Widget _buildPrefixAction(ColorScheme cs, BuildContext context) {
    return IconButton(
      onPressed: () {
        onPrefixActionTap!();
      },
      icon: PhosphorIcon(prefixActionIcon!, color: cs.onSurface, size: 24),
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.all(cs.surface),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(50),
            side: BorderSide(
              color: cs.onSurface.withValues(alpha: 0.08),
              width: 1,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoAndTitle(ColorScheme cs, bool isDark) {
    return Container(
      padding: EdgeInsets.fromLTRB(8, 8, title == "" ? 8 : 10, 8),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: cs.onSurface.withValues(alpha: 0.08)),
        boxShadow:
            !isDark
                ? [
                  BoxShadow(
                    color: cs.onSurface.withValues(alpha: 0.08),
                    blurRadius: 10,
                    spreadRadius: 0,
                    offset: Offset.fromDirection(pi / 2, 3),
                  ),
                ]
                : null,
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundImage: logoURL != null && (logoURL!.startsWith('http') || logoURL!.startsWith('https'))
                ? NetworkImage(logoURL!, scale: 1.0)
                : AssetImage(logoURL ?? '') as ImageProvider,
            radius: 12,
            child: logoURL == null || logoURL!.isEmpty
                ? Text(title.substring(0, 1))
                : null,
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildPostfixAction(ColorScheme cs) {
    final defaultStyle = ButtonStyle(
      backgroundColor: WidgetStateProperty.all(cs.surface),
      shape: WidgetStateProperty.all(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(50),
          side: BorderSide(
            color: cs.onSurface.withValues(alpha: 0.08),
            width: 1,
          ),
        ),
      ),
    );
    switch (actionType) {
      case AppBarActionType.notifications:
        final icon =
            notificationCount > 0
                ? PhosphorIconsFill.bellSimple
                : PhosphorIconsBold.bell;
        return Stack(
          children: [
            IconButton(
              onPressed: onPostfixActionTap,
              icon: PhosphorIcon(icon, color: cs.onSurface, size: 24),
              style: defaultStyle,
            ),
            if (notificationCount > 0)
              Positioned(
                right: 6,
                top: 6,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$notificationCount',
                    style: TextStyle(color: cs.onSurface, fontSize: 10),
                  ),
                ),
              ),
          ],
        );

      case AppBarActionType.chatHistory:
        return IconButton(
          onPressed: onPostfixActionTap,
          icon: PhosphorIcon(
            PhosphorIconsBold.clockCounterClockwise,
            color: cs.onSurface,
            size: 24,
          ),
          style: defaultStyle,
        );

      case AppBarActionType.closeChat:
        return IconButton(
          onPressed: onPostfixActionTap,
          icon: PhosphorIcon(
            PhosphorIconsBold.x,
            color: cs.onSurface,
            size: 24,
          ),
          style: defaultStyle,
        );

      case AppBarActionType.settings:
        return IconButton(
          onPressed: onPostfixActionTap,
          icon: Transform.rotate(
            angle: 90 * pi / 180,
            child: PhosphorIcon(
              PhosphorIconsBold.gearSix,
              color: cs.onSurface,
              size: 24,
            ),
          ),
          style: defaultStyle,
        );

      case AppBarActionType.none:
        return const SizedBox.shrink();
    }
  }
}
