import 'package:flutter/material.dart';

class FilterOption {
  final String key;
  final String title;
  final IconData icon;
  final Color? iconColor;
  final int? count;

  FilterOption({
    required this.key,
    required this.title,
    required this.icon,
    this.iconColor,
    this.count,
  });
}

class FilterBottomSheet {
  static void show({
    required BuildContext context,
    required String title,
    required List<FilterOption> options,
    required String currentFilter,
    required Function(String) onSelected,
    bool showCount = true,
  }) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20),

              ...options.map(
                (option) => ListTile(
                  leading: Icon(option.icon, color: option.iconColor),
                  title: Row(
                    children: [
                      Expanded(child: Text(option.title)),
                      if (showCount && option.count != null)
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${option.count}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                    ],
                  ),
                  trailing: currentFilter == option.key
                      ? Icon(Icons.check, color: Colors.green)
                      : null,
                  onTap: () {
                    onSelected(option.key);
                    Navigator.pop(context);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
