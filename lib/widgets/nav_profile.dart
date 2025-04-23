import 'package:flutter/material.dart';
import 'package:learn_hub/providers/app_auth_provider.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';

class ProfileIcon extends StatelessWidget {
  final int index;
  final int currentIndex;
  final Function(int) onTap;

  const ProfileIcon({
    super.key,
    required this.index,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AppAuthProvider>(context);
    final user = authProvider.user;
    bool isSelected = currentIndex == index;
    final profileURL = user?.photoURL ?? "assets/images/logo.png";
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => onTap(index),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        curve: Curves.ease,
        margin: const EdgeInsets.all(4),
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          border: Border.all(
            color:
                isSelected
                    ? (!isDark ? cs.primary : cs.onSurface)
                    : Colors.transparent,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(50),
        ),
        child: CircleAvatar(
          backgroundImage:
              profileURL.isNotEmpty && profileURL.startsWith("http")
                  ? Uri.tryParse(profileURL)?.hasAbsolutePath == true
                      ? NetworkImage(profileURL)
                      : AssetImage(
                            profileURL ?? 'assets/images/default_logo.png',
                          )
                          as ImageProvider
                  : AssetImage('assets/images/logo.png'),
          radius: 12,
          child:
              profileURL.isEmpty
                  ? Icon(
                    PhosphorIconsFill.user,
                    color:
                        isSelected
                            ? cs.primary
                            : cs.onSurface.withValues(alpha: 0.66),
                    size: 24,
                  )
                  : null,
        ),
      ),
    );
  }
}
