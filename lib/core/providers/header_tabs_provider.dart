import 'package:couple_note/core/common/user_tab_model.dart';
import 'package:flutter/foundation.dart';

class HeaderTabsConfig {
  final List<UserTab> userTabs;
  final String initialTab;

  const HeaderTabsConfig({required this.userTabs, required this.initialTab});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is HeaderTabsConfig &&
        listEquals(other.userTabs, userTabs) &&
        other.initialTab == initialTab;
  }

  @override
  int get hashCode => Object.hash(Object.hashAll(userTabs), initialTab);
}
