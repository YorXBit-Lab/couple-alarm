import 'package:couple_note/data/models/user_tab_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

class HeaderTabsState {
  final List<UserTab> userTabs;
  final String currentUserTab;
  final int currentIndex;
  final bool isLoading;

  const HeaderTabsState({
    required this.userTabs,
    required this.currentUserTab,
    required this.currentIndex,
    this.isLoading = false,
  });

  HeaderTabsState copyWith({
    List<UserTab>? userTabs,
    String? currentUserTab,
    int? currentIndex,
    bool? isLoading,
  }) {
    return HeaderTabsState(
      userTabs: userTabs ?? this.userTabs,
      currentUserTab: currentUserTab ?? this.currentUserTab,
      currentIndex: currentIndex ?? this.currentIndex,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class HeaderTabsViewModel extends StateNotifier<HeaderTabsState> {
  HeaderTabsViewModel(List<UserTab> initialTabs, String initialTab)
    : super(
        HeaderTabsState(
          userTabs: initialTabs,
          currentUserTab: initialTab,
          currentIndex: _getIndexFromUserTab(initialTabs, initialTab),
        ),
      );

  static int _getIndexFromUserTab(List<UserTab> tabs, String userTab) {
    for (int i = 0; i < tabs.length; i++) {
      if (tabs[i].key == userTab) return i;
    }
    return 0;
  }

  void changeUserTab(String tabKey) {
    final newIndex = _getIndexFromUserTab(state.userTabs, tabKey);
    if (newIndex != state.currentIndex) {
      state = state.copyWith(currentUserTab: tabKey, currentIndex: newIndex);
    }
  }

  void setLoading(bool loading) {
    state = state.copyWith(isLoading: loading);
  }
}
