import 'package:flutter/material.dart';

class PageHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final VoidCallback? onFilterTap;
  final VoidCallback? onBackTap;
  final List<Widget>? actions;

  const PageHeader({
    Key? key,
    required this.title,
    this.subtitle,
    this.onFilterTap,
    this.onBackTap,
    this.actions,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          if (onBackTap != null) ...[
            IconButton(
              onPressed: onBackTap,
              icon: Icon(Icons.arrow_back_ios, color: Colors.grey[700]),
            ),
            SizedBox(width: 10),
          ],

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
              ],
            ),
          ),

          if (actions != null) ...actions!,

          if (onFilterTap != null)
            IconButton(
              onPressed: onFilterTap,
              icon: Icon(Icons.filter_list, color: Colors.grey[700]),
            ),
        ],
      ),
    );
  }
}
