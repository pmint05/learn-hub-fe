import 'package:flutter/material.dart';

class SelectMenuTile extends StatefulWidget {
  final ValueNotifier<dynamic> groupController;
  final Widget prefixIcon;
  final Widget title;
  final bool autoHide;
  final Widget details;
  final List<Widget> menu;

  const SelectMenuTile({
    super.key,
    required this.groupController,
    required this.prefixIcon,
    required this.title,
    this.autoHide = false,
    required this.details,
    required this.menu,
  });

  @override
  State<SelectMenuTile> createState() => _SelectMenuTileState();
}

class _SelectMenuTileState extends State<SelectMenuTile> {
  bool isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              setState(() {
                isExpanded = !isExpanded;
              });
            },
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                border: Border.all(color: cs.surfaceDim),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  widget.prefixIcon,
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        widget.title,
                        SizedBox(height: 4),
                        widget.details,
                      ],
                    ),
                  ),
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: cs.onSurface,
                  ),
                ],
              ),
            ),
          ),
        ),
        AnimatedCrossFade(
          duration: Duration(milliseconds: 200),
          crossFadeState: isExpanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          firstChild: SizedBox(height: 0),
          secondChild: Container(
            margin: EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: cs.surface,
              border: Border.all(color: cs.surfaceDim),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: widget.menu.map((item) {
                if (item is SelectTile) {
                  return InkWell(
                    onTap: () {
                      widget.groupController.value = item.value;
                      if (widget.autoHide) {
                        setState(() {
                          isExpanded = false;
                        });
                      }
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          Expanded(child: item.title),
                          if (widget.groupController.value == item.value)
                            Icon(Icons.check, color: cs.primary, size: 20),
                        ],
                      ),
                    ),
                  );
                }
                return item;
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}

class SelectTile extends StatelessWidget {
  final dynamic value;
  final Widget title;

  const SelectTile({
    super.key,
    required this.value,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      child: title,
    );
  }
}