import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activatedIcon;
  final String label;
  final int index;
  final int currentIndex;
  final Function(int) onTap;

  const NavItem({
    super.key,
    required this.icon,
    required this.activatedIcon,
    required this.label,
    required this.index,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    bool isSelected = currentIndex == index;
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => onTap(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.ease,
        padding: EdgeInsets.symmetric(
          vertical: 8,
          horizontal: isSelected ? 10 : 5,
        ),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? (!isDark ? cs.primary : cs.onSurface)
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(50),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            PhosphorIcon(
              isSelected ? activatedIcon : icon,
              size: 24,
              color:
                  isSelected
                      ? (!isDark ? cs.onPrimary : cs.surface)
                      : cs.onSurface.withValues(alpha: 0.66),
            ),
            // Icon(
            //   SolarIconsBold.homeAdd,
            //   size: 24,
            // ),
            if (isSelected) const SizedBox(width: 3),
            if (isSelected)
              Text(
                label,
                style: TextStyle(
                  color: (!isDark ? cs.onPrimary : cs.surface),
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
