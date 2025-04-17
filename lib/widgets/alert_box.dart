import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

enum AlertBoxType {
  error,
  warning,
  info,
  success,
}

class AlertBox extends StatefulWidget {
  final AlertBoxType type;
  final String? title;
  final String? subtitle;
  final IconData? icon;
  final bool? border;
  final EdgeInsets padding;
  final EdgeInsets margin;
  final BorderRadius borderRadius;
  final VoidCallback? onOk;
  final VoidCallback? onCancel;
  final Widget? okButton;
  final Widget? cancelButton;

  const AlertBox({
    super.key,
    this.title,
    this.type = AlertBoxType.info,
    this.subtitle,
    this.icon,
    this.border,
    this.okButton,
    this.cancelButton,
    this.onCancel,
    this.onOk,
    this.padding = const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
    this.margin = const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
    this.borderRadius = const BorderRadius.all(Radius.circular(20)),
  });

  @override
  State<AlertBox> createState() => _AlertBoxState();
}

class _AlertBoxState extends State<AlertBox> {
  bool isVisible = true;

  @override
  Widget build(BuildContext context) {
    if (!isVisible) return const SizedBox.shrink();

    final cs = Theme.of(context).colorScheme;
    final Color color;

    if (widget.type == AlertBoxType.error) {
      color = cs.error;
    } else if (widget.type == AlertBoxType.warning) {
      color = cs.secondary;
    } else if (widget.type == AlertBoxType.info) {
      color = cs.primary;
    } else if (widget.type == AlertBoxType.success) {
      color = cs.tertiary;
    } else {
      color = cs.primary;
    }

    return Card(
      margin: widget.margin,
      elevation: 0,
      color: color.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(borderRadius: widget.borderRadius),
      child: Padding(
        padding: widget.padding,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            if (widget.icon != null) Icon(widget.icon, color: color, size: 30),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.title != null)
                    Text(
                      widget.title!,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  if (widget.subtitle != null)
                    Padding(
                      padding: EdgeInsets.only(top: widget.title != null ? 5 : 0),
                      child: Text(
                        widget.subtitle!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: color.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (widget.onOk != null)
              TextButton(
                style: ButtonStyle(
                  overlayColor: WidgetStatePropertyAll(
                    color.withValues(alpha: 0.12),
                  ),
                ),
                onPressed: widget.onOk,
                child: widget.okButton ?? Text("OK", style: TextStyle(color: color)),
              ),
            IconButton(
              style: ButtonStyle(
                overlayColor: WidgetStatePropertyAll(
                  color.withValues(alpha: 0.12),
                ),
              ),
              onPressed: widget.onCancel ?? () {
                setState(() {
                  isVisible = false;
                });
              },
              icon: widget.cancelButton ?? Icon(PhosphorIconsRegular.x, size: 20, color: color.withValues(alpha: 0.7),),
            ),
          ],
        ),
      ),
    );
  }
}