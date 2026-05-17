import 'package:flutter/material.dart';

class CustomMenuItem {
  final String value;
  final IconData icon;
  final String label;
  final Color? iconColor;
  final Color? textColor;
  final bool isDivider;

  CustomMenuItem({
    required this.value,
    required this.icon,
    required this.label,
    this.iconColor,
    this.textColor,
    this.isDivider = false,
  });

  CustomMenuItem.divider()
    : value = '',
      icon = Icons.clear,
      label = '',
      iconColor = null,
      textColor = null,
      isDivider = true;
}

class CustomPopupMenu extends StatelessWidget {
  final List<CustomMenuItem> items;
  final Function(String) onSelected;
  final IconData? buttonIcon;
  final double? buttonSize;
  final Color? buttonColor;
  final EdgeInsetsGeometry? padding;
  final String? tooltip;
  final Color? backgroundColor;
  final double? elevation;
  final BorderRadius? borderRadius;

  const CustomPopupMenu({
    Key? key,
    required this.items,
    required this.onSelected,
    this.buttonIcon = Icons.more_vert,
    this.buttonSize = 24,
    this.buttonColor,
    this.padding,
    this.tooltip,
    this.backgroundColor,
    this.elevation = 8,
    this.borderRadius,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      padding: padding ?? EdgeInsets.zero,
      tooltip: tooltip ?? 'Menu',
      icon: Icon(
        buttonIcon,
        size: buttonSize,
        color: buttonColor ?? Theme.of(context).iconTheme.color,
      ),
      elevation: elevation!,
      shape: RoundedRectangleBorder(
        borderRadius: borderRadius ?? BorderRadius.circular(12),
      ),
      color: backgroundColor,
      onSelected: onSelected,
      itemBuilder: (BuildContext context) {
        return items.map((item) {
          if (item.isDivider) {
            return PopupMenuItem<String>(
              enabled: false,
              height: 1,
              padding: EdgeInsets.zero,
              child: Divider(height: 1, thickness: 1),
            );
          }

          return PopupMenuItem<String>(
            value: item.value,
            child: Row(
              children: [
                Icon(
                  item.icon,
                  size: 20,
                  color: item.iconColor ?? Theme.of(context).iconTheme.color,
                ),
                SizedBox(width: 12),
                Text(
                  item.label,
                  style: TextStyle(
                    color:
                        item.textColor ??
                        Theme.of(context).textTheme.bodyLarge?.color,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }).toList();
      },
    );
  }
}
