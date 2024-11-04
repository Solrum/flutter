import 'package:flutter/material.dart';

class SelectionWidget extends StatelessWidget {
  final double? height;
  final double radius;
  final Color borderColor;
  final Color? backgroundColor;
  final String valueShow;
  final TextStyle style;
  final VoidCallback onTap;
  final bool enable;

  const SelectionWidget({
    super.key,
    required this.height,
    required this.radius,
    required this.borderColor,
    required this.valueShow,
    required this.onTap,
    required this.style,
    this.backgroundColor,
    this.enable = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enable ? onTap : null,
      child: Opacity(
        opacity: enable ? 1.0 : 0.5,
        child: Container(
          height: height,
          constraints: BoxConstraints(
            maxWidth: MediaQuery.sizeOf(context).width,
          ),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            color: backgroundColor,
            border: Border.all(
              color: borderColor,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                valueShow,
                style: style,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
