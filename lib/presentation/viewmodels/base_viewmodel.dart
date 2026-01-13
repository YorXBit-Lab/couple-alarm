import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:couple_note/core/common/tab_cache.dart';
import 'package:couple_note/data/models/user_tab_model.dart';

class BaseState {
  final List<UserTab> tabs;
  final String currentTab;
  final bool isLoading;
  final bool isActionLoading;
  final String? errorMessage;
  final Map<String, dynamic>? activeFilterQuery;
  final bool hasMoreData;
  final DocumentSnapshot? lastDocument;

  final Map<String, TabCache<Object>> tabCaches;

  const BaseState({
    required this.tabs,
    required this.currentTab,
    this.isLoading = false,
    this.isActionLoading = false,
    this.errorMessage,
    this.activeFilterQuery,
    this.hasMoreData = true,
    this.lastDocument,
    this.tabCaches = const {},
  });

  BaseState copyWith({
    List<UserTab>? tabs,
    String? currentTab,
    bool? isLoading,
    bool? isActionLoading,
    String? errorMessage,
    bool clearSelectedReminder = false,
    bool clearError = false,
    bool clearFilter = false,
    Map<String, dynamic>? activeFilterQuery,
    bool? hasMoreData,
    DocumentSnapshot? lastDocument,
    bool clearLastDocument = false,
    Map<String, TabCache<Object>>? tabCaches,
  }) {
    return BaseState(
      tabs: tabs ?? this.tabs,
      currentTab: currentTab ?? this.currentTab,
      isLoading: isLoading ?? this.isLoading,
      isActionLoading: isActionLoading ?? this.isActionLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      activeFilterQuery: clearFilter
          ? null
          : (activeFilterQuery ?? this.activeFilterQuery),
      hasMoreData: hasMoreData ?? this.hasMoreData,
      lastDocument: clearLastDocument
          ? null
          : (lastDocument ?? this.lastDocument),
      tabCaches: tabCaches ?? this.tabCaches,
    );
  }

  TabCache<Object>? getCacheForTab(String tabKey) => tabCaches[tabKey];

  bool hasCacheForTab(String tabKey) => tabCaches.containsKey(tabKey);

  bool isCacheValidForTab(String tabKey) {
    final cache = getCacheForTab(tabKey);
    return cache?.isValid ?? false;
  }
}
