import 'dart:math';

import 'package:flutter/material.dart';
import 'package:learn_hub/configs/routes.dart';
import 'nav_item.dart';
import 'nav_profile.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onItemTapped;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onItemTapped,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Flexible(
            child: ClipRRect(
              borderRadius: BorderRadius.all(Radius.circular(50)),
              child: Container(
                decoration: BoxDecoration(
                  color: cs.surface,
                  borderRadius: BorderRadius.circular(50),
                  border: Border.all(
                    color: cs.surfaceDim,
                  ),
                  boxShadow:
                      !isDark
                          ? [
                            BoxShadow(
                              color: cs.onSurface.withValues(alpha: 0.2),
                              blurRadius: 10,
                              spreadRadius: 0,
                              offset: Offset.fromDirection(pi / 2, 8),
                            ),
                          ]
                          : null,
                ),
                child: ShaderMask(
                  shaderCallback: (Rect bounds) {
                    return LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        cs.surface.withValues(alpha:0),
                        Colors.white,
                        Colors.white,
                        cs.surface.withValues(alpha:0),
                      ],
                      stops: const [0.0, 0.038, 0.95, 1.0],
                    ).createShader(bounds);
                  },
                  blendMode: BlendMode.dstIn,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(
                      decelerationRate: ScrollDecelerationRate.fast,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 16,
                        children: [
                          ...routes
                              .asMap()
                              .entries
                              .where((entry) => entry.value["showOnNav"])
                              .map((entry) {
                                int idx = entry.key;
                                var item = entry.value;
                              return NavItem(
                                  icon: item['icon']['regular'],
                                  activatedIcon: item['icon']['filled'],
                                  label: item['label'],
                                  index: idx,
                                  currentIndex: currentIndex,
                                  onTap: onItemTapped,
                                );
                              }),
                          ProfileIcon(
                            index: 4,
                            currentIndex: currentIndex,
                            onTap: onItemTapped,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
