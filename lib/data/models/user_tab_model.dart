import 'package:flutter/material.dart';

class UserTab {
  final String key;
  final String label;
  final IconData? icon;
  final String? id;

  const UserTab({required this.key, required this.label, this.icon, this.id});

  UserTab copyWith({
    String? key,
    String? label,
    IconData? icon,
    int? count,
    String? id,
  }) {
    return UserTab(
      key: key ?? this.key,
      label: label ?? this.label,
      icon: icon ?? this.icon,
      id: id ?? this.id,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserTab &&
        other.key == key &&
        other.label == label &&
        other.icon == icon &&
        other.id == id;
  }

  @override
  int get hashCode {
    return key.hashCode ^ label.hashCode ^ icon.hashCode ^ id.hashCode;
  }
}
