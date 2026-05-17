import 'package:flutter/material.dart';

class TagsWidget extends StatelessWidget {
  final List<String> tags;
  final int maxVisibleTags;
  final double spacing;
  final double runSpacing;
  final double fontSize;
  final double iconSize;
  final double horizontalPadding;
  final double verticalPadding;
  final double borderRadius;
  final Color tagColor;
  final Color overflowColor;
  final Color textColor;
  final Color? iconColor;
  final bool showIcon;
  final IconData? iconData;

  const TagsWidget({
    Key? key,
    required this.tags,
    this.maxVisibleTags = 4,
    this.spacing = 4,
    this.runSpacing = 4,
    this.fontSize = 9,
    this.iconSize = 8,
    this.horizontalPadding = 4,
    this.verticalPadding = 2,
    this.borderRadius = 6,
    this.tagColor = const Color(0x1A9CA3AF),
    this.overflowColor = const Color(0x339CA3AF),
    this.textColor = const Color(0xFF4B5563),
    this.iconColor,
    this.showIcon = true,
    this.iconData = Icons.tag,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final visibleTags = tags.take(maxVisibleTags).toList();
    final remainingCount = tags.length - visibleTags.length;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          ...visibleTags.map(
            (tag) => Padding(
              padding: EdgeInsets.only(right: spacing),
              child: _buildTagChip(tag),
            ),
          ),
          if (remainingCount > 0)
            _buildTagChip('+$remainingCount', isOverflow: true),
        ],
      ),
    );
  }

  Widget _buildTagChip(String text, {bool isOverflow = false}) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: verticalPadding,
      ),
      decoration: BoxDecoration(
        color: isOverflow ? overflowColor : tagColor,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!isOverflow && showIcon && iconData != null) ...[
            Icon(iconData, size: iconSize, color: iconColor ?? textColor),
            SizedBox(width: 2),
          ],
          Text(
            text,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w500,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
