import 'package:flutter/material.dart';
import '../data/post_background.dart';

class PostBackgroundCard extends StatelessWidget {
  const PostBackgroundCard({
    super.key,
    required this.content,
    required this.background,
    this.padding = const EdgeInsets.all(20),
    this.minHeight = 140,
  });

  final String content;
  final PostBackground background;
  final EdgeInsetsGeometry padding;
  final double minHeight;

  @override
  Widget build(BuildContext context) {
    final bgCol = background.backgroundColor(context);
    final textCol = background.textColor(context);

    return Container(
      width: double.infinity,
      constraints: BoxConstraints(minHeight: minHeight),
      padding: padding,
      decoration: BoxDecoration(
        color: bgCol,
        borderRadius: BorderRadius.circular(12),
        boxShadow: background.isDefault
            ? null
            : [
                BoxShadow(
                  color: bgCol.withAlpha(76),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
      ),
      child: Center(
        child: Text(
          content,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: textCol,
            fontSize: background.isDefault ? 15 : 18,
            fontWeight: background.isDefault ? FontWeight.normal : FontWeight.bold,
            height: 1.4,
          ),
        ),
      ),
    );
  }
}
