import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:couple_note/core/common/api_response.dart';
import 'package:couple_note/core/common/tab_cache.dart';
import 'package:couple_note/core/config/app_constants.dart';
import 'package:couple_note/core/constants/trans_keys.dart';
import 'package:couple_note/core/services/alarm/alarm_service.dart';
import 'package:couple_note/core/services/lib/core/services/connectivity_service.dart';
import 'package:couple_note/core/utils/utils.dart';
import 'package:couple_note/data/models/filter_model.dart';
import 'package:couple_note/data/models/user_tab_model.dart';
import 'package:couple_note/domain/entities/reminder.dart';
import 'package:couple_note/domain/entities/user.dart';
import 'package:couple_note/domain/repositories/reminder_repository.dart';
import 'package:couple_note/domain/usecases/reminder/create_reminder.dart';
import 'package:couple_note/domain/usecases/reminder/delete_reminder.dart';
import 'package:couple_note/domain/usecases/reminder/get_filter_reminder.dart';
import 'package:couple_note/domain/usecases/reminder/get_reminder_by_id.dart';
import 'package:couple_note/domain/usecases/reminder/get_reminders_by_user.dart';
import 'package:couple_note/domain/usecases/reminder/toggle_reminder_status.dart';
import 'package:couple_note/domain/usecases/reminder/update_reminder.dart';
import 'package:couple_note/presentation/widgets/filter/filter_bottom_sheet.dart.dart';
import 'package:couple_note/providers/auth_provider.dart';
import 'package:couple_note/providers/filter_provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

class ReminderState {
  final String currentTab;
  final List<ReminderEntity> reminders;
  final ReminderEntity? selectedReminder;
  final bool isLoading;
  final bool isActionLoading;
  final String? errorMessage;
  final Map<String, dynamic>? activeFilterQuery;
  final bool hasMoreData;
  final DocumentSnapshot? lastDocument;

  final Map<String, ReminderTabCache> tabCaches;

  final bool isOffline;
  final bool hasPendingSync;

  final bool isSelectionMode;
  final List<ReminderEntity> selectedReminders;

  const ReminderState({
    required this.currentTab,
    this.reminders = const [],
    this.selectedReminder,
    this.isLoading = false,
    this.isActionLoading = false,
    this.errorMessage,
    this.activeFilterQuery,
    this.hasMoreData = true,
    this.lastDocument,
    this.tabCaches = const {},

    this.isOffline = false,
    this.hasPendingSync = false,

    this.isSelectionMode = false,
    this.selectedReminders = const [],
  });

  ReminderState copyWith({
    String? currentTab,
    List<ReminderEntity>? reminders,
    ReminderEntity? selectedReminder,
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
    Map<String, ReminderTabCache>? tabCaches,

    bool? isOffline,
    bool? hasPendingSync,

    bool? isSelectionMode,
    List<ReminderEntity>? selectedReminders,
  }) {
    return ReminderState(
      currentTab: currentTab ?? this.currentTab,
      reminders: reminders ?? this.reminders,
      selectedReminder: clearSelectedReminder
          ? null
          : (selectedReminder ?? this.selectedReminder),
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

      isOffline: isOffline ?? this.isOffline,
      hasPendingSync: hasPendingSync ?? this.hasPendingSync,

      isSelectionMode: isSelectionMode ?? this.isSelectionMode,
      selectedReminders: selectedReminders ?? this.selectedReminders,
    );
  }

  ReminderTabCache? getCacheForTab(String tabKey) => tabCaches[tabKey];

  bool hasCacheForTab(String tabKey) => tabCaches.containsKey(tabKey);

  bool isCacheValidForTab(String tabKey) {
    final cache = getCacheForTab(tabKey);
    return cache?.isValid ?? false;
  }
}

class ReminderUseCases {
  final CreateReminder createReminderUseCase;
  final DeleteReminder deleteReminderUseCase;
  final UpdateReminder updateReminderUseCase;
  final GetRemindersByUser getRemindersByUserUseCase;
  final GetReminderById getReminderByIdUseCase;
  final GetFiltereRemindersWithOptionsUseCase getRemindersWithFilterUseCase;
  final ToggleReminderStatusUseCase toggleReminderStatusUseCase;

  const ReminderUseCases({
    required this.createReminderUseCase,
    required this.deleteReminderUseCase,
    required this.updateReminderUseCase,
    required this.getRemindersByUserUseCase,
    required this.getReminderByIdUseCase,
    required this.getRemindersWithFilterUseCase,
    required this.toggleReminderStatusUseCase,
  });
}

class ReminderViewModel extends StateNotifier<ReminderState> {
  final ReminderUseCases _useCases;
  final UserEntity? partner;
  final Ref ref;

  String? currentUserTabId;
  FilterNotifier? _cachedFilterNotifier;

  final ConnectivityService _connectivityService;
  StreamSubscription<bool>? _connectivitySubscription;

  StreamSubscription<ApiResponse<List<ReminderEntity>>>? _currentTabStream;

  String? _activeStreamTab;

  StreamSubscription<QuerySnapshot>? _globalChangeListener;

  ReminderViewModel({
    required ReminderUseCases useCases,
    required this.currentUserTabId,
    required ConnectivityService connectivityService,
    this.partner,
    required this.ref,
  }) : _useCases = useCases,
       _connectivityService = connectivityService,
       super(_initialState(partner)) {
    loadRemindersWithExistingFilter();
    _setupGlobalChangeListener();
    _listenToConnectivity();
  }

  void _setupGlobalChangeListener() {
    final userIds = [
      _getUserIdForTab('mine'),
      _getUserIdForTab('partner'),
      _getUserIdForTab('couple'),
    ].whereType<String>().toList();

    if (userIds.isEmpty) return;

    _globalChangeListener = FirebaseFirestore.instance
        .collection('reminders')
        .where('ownerId', whereIn: userIds)
        .snapshots(includeMetadataChanges: false)
        .listen((snapshot) {
          if (!mounted) return;

          for (final change in snapshot.docChanges) {
            if (change.type == DocumentChangeType.added ||
                change.type == DocumentChangeType.modified ||
                change.type == DocumentChangeType.removed) {
              final ownerId = change.doc.data()?['ownerId'];
              final affectedTab = _getTabKeyByOwnerId(ownerId);

              if (affectedTab != null && affectedTab != state.currentTab) {
                _invalidateCacheForTab(affectedTab);
              }
            }
          }
        });
  }

  String? _getTabKeyByOwnerId(String? ownerId) {
    if (ownerId == null) return null;

    if (ownerId == _getUserIdForTab('mine')) return 'mine';
    if (ownerId == _getUserIdForTab('partner')) return 'partner';
    if (ownerId == _getUserIdForTab('couple')) return 'couple';

    return null;
  }

  void _invalidateCacheForTab(String tabKey) {
    if (!mounted) return;

    final updatedCaches = Map<String, ReminderTabCache>.from(state.tabCaches);
    final oldCache = updatedCaches[tabKey];

    if (oldCache != null) {
      updatedCaches[tabKey] = oldCache.copyWith(lastUpdated: DateTime(2000));

      state = state.copyWith(tabCaches: updatedCaches);
    }
  }

  void _listenToConnectivity() {
    _connectivitySubscription = _connectivityService.connectionStatus.listen((
      isOnline,
    ) {
      if (mounted) {
        state = state.copyWith(isOffline: !isOnline);

        if (isOnline && state.hasPendingSync) {
          refreshReminders();
        }
      }
    });
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _connectivitySubscription = null;
    super.dispose();
  }

  static ReminderState _initialState(UserEntity? partner) {
    return ReminderState(currentTab: 'mine');
  }

  void changeTab(String tabKey) {
    if (state.currentTab == tabKey) return;

    _cancelCurrentTabStream();

    currentUserTabId = _getUserIdForTab(tabKey);

    _cachedFilterNotifier?.clearAllFilters();
    _cachedFilterNotifier = null;

    state = state.copyWith(
      currentTab: tabKey,
      clearFilter: true,
      clearLastDocument: true,
    );

    exitSelectionMode();

    if (_shouldUseCacheForTab(tabKey)) {
      _loadFromCache(tabKey);
      _startStreamForCurrentTab();
    } else {
      _loadRemindersWithFilterOptions(null, isRefresh: true);
    }
  }

  void _startStreamForCurrentTab() {
    if (_activeStreamTab == state.currentTab) return;

    _cancelCurrentTabStream();
    final currentUserId = ref.read(currentUserProvider)?.uid ?? '';
    currentUserTabId ??= _getUserIdForTab(state.currentTab);
    if (currentUserTabId == null) return;

    _activeStreamTab = state.currentTab;
    final requestTab = state.currentTab;
    final requestUserId = currentUserTabId!;

    final filterOptions = hasActiveFilters
        ? _convertQueryToFilterOptions(state.activeFilterQuery!)
        : ReminderFilterOptions(limit: 50);

    _currentTabStream = _useCases
        .getRemindersWithFilterUseCase(
          requestUserId,
          filterOptions,
          currentUserId,
        )
        .listen(
          (result) {
            if (mounted &&
                state.currentTab == requestTab &&
                currentUserTabId == requestUserId) {
              if (result.isSuccess) {
                final reminders = result.data ?? <ReminderEntity>[];

                state = state.copyWith(
                  reminders: currentUserTabId != partner?.uid
                      ? reminders
                      : reminders.where((t) => t.isPrivate == false).toList(),
                  isLoading: false,
                  hasMoreData: reminders.length >= 50,
                );

                if (!hasActiveFilters) {
                  _saveCurrentTabToCache();
                }
              }
            }
          },
          onError: (e) {
            if (mounted && state.currentTab == requestTab) {
              state = state.copyWith(isLoading: false);
            }
          },
        );
  }

  void _cancelCurrentTabStream() {
    _currentTabStream?.cancel();
    _currentTabStream = null;
    _activeStreamTab = null;
  }

  void _saveCurrentTabToCache() {
    if (!mounted) return;

    final cache = ReminderTabCache(
      items: state.reminders,
      activeFilterQuery: state.activeFilterQuery,
      lastDocument: state.lastDocument,
      hasMoreData: state.hasMoreData,
      lastUpdated: DateTime.now(),
    );

    final updatedCaches = Map<String, ReminderTabCache>.from(state.tabCaches);
    updatedCaches[state.currentTab] = cache;

    state = state.copyWith(tabCaches: updatedCaches);
  }

  bool _shouldUseCacheForTab(String tabKey) {
    return state.hasCacheForTab(tabKey) && state.isCacheValidForTab(tabKey);
  }

  void _loadFromCache(String tabKey) {
    if (!mounted) return;

    final cache = state.getCacheForTab(tabKey);
    if (cache == null) {
      _loadRemindersWithFilterOptions(null, isRefresh: true);
      return;
    }

    state = state.copyWith(
      reminders: cache.items,
      activeFilterQuery: null,
      lastDocument: cache.lastDocument,
      hasMoreData: cache.hasMoreData,
      isLoading: false,
    );
  }

  String? _getUserIdForTab(String tabKey) {
    switch (tabKey) {
      case 'mine':
        return ref.read(currentUserProvider)?.uid;
      case 'partner':
        return ref.read(partnerProvider).value?.data?.uid;
      case 'couple':
        return ref.read(coupleProvider).value?.data?.id;
      default:
        return null;
    }
  }

  void clearCacheForTab(String tabKey) {
    if (!mounted) return;

    final updatedCaches = Map<String, ReminderTabCache>.from(state.tabCaches);
    updatedCaches.remove(tabKey);
    state = state.copyWith(tabCaches: updatedCaches);
  }

  void _setLoadingState(bool isRefresh) {
    if (!mounted) return;

    if (isRefresh) {
      state = state.copyWith(
        isLoading: true,
        clearError: true,
        clearLastDocument: true,
        hasMoreData: true,
      );
    } else {
      state = state.copyWith(isLoading: true, clearError: true);
    }
  }

  Future<bool> createReminder(ReminderEntity reminder) async {
    final isOnline = _connectivityService.isOnline;

    final res = await _useCases.createReminderUseCase(reminder);
    if (res.isFailure) {
      return false;
    }

    if (!isOnline) {
      state = state.copyWith(hasPendingSync: true);
    }

    selectReminder(res.data!);

    return true;
  }

  Future<bool> updateReminder(ReminderEntity reminder) async {
    final res = await _useCases.updateReminderUseCase(reminder);
    if (res.isFailure) {
      return false;
    }

    selectReminder(res.data!);

    return true;
  }

  Future<ReminderEntity?> getReminderById(String id) async {
    final res = await _useCases.getReminderByIdUseCase(id);
    if (res.isFailure) {
      return null;
    }
    return res.data;
  }

  Future<bool> deleteReminder(ReminderEntity reminder, String userId) async {
    if (!mounted) return false;

    final res = await _useCases.deleteReminderUseCase(reminder, userId);
    if (res.isFailure) {
      return false;
    }
    return true;
  }

  Future<bool> toggleReminderStatus(ReminderEntity reminder) async {
    if (!mounted) return false;

    state = state.copyWith(isActionLoading: false, clearError: true);

    final result = await _useCases.toggleReminderStatusUseCase(
      reminder,
      currentUserTabId ?? '',
    );

    if (!mounted) return false;

    if (result.isSuccess) {
      clearCacheForTab(state.currentTab);
      state = state.copyWith(isActionLoading: false);
      selectReminder(result.data!);
      return true;
    } else {
      state = state.copyWith(
        errorMessage: result.error,
        isActionLoading: false,
      );
      return false;
    }
  }

  FilterNotifier get _filterNotifier {
    _cachedFilterNotifier ??= ref.read(
      reminderFilterProvider(FilterParams(userId: currentUserTabId)).notifier,
    );
    return _cachedFilterNotifier!;
  }

  FilterState get currentFilterState => _filterNotifier.state;

  void showFilterSheet(BuildContext context) {
    showUniversalFilterBottomSheet(
      context,
      PageType.reminder,
      userId: currentUserTabId,
      initialFilterQuery: null,
      filterNotifier: _filterNotifier,
      onApply: _onFilterApply,
      onReset: _onFilterReset,
    );
  }

  void _onFilterApply() {
    final query = _filterNotifier.buildFilterQuery();

    state = state.copyWith(activeFilterQuery: query, clearLastDocument: true);
    final filterOptions = _convertQueryToFilterOptions(query);

    clearCacheForTab(state.currentTab);
    _loadRemindersWithFilterOptions(filterOptions, isRefresh: true);
  }

  void _onFilterReset() {
    _filterNotifier.clearAllFilters();
    state = state.copyWith(clearFilter: true, clearLastDocument: true);

    clearCacheForTab(state.currentTab);
    _loadRemindersWithFilterOptions(null, isRefresh: true);
  }

  Future<void> _loadRemindersWithFilterOptions(
    ReminderFilterOptions? filterOptions, {
    bool isRefresh = false,
  }) async {
    currentUserTabId ??= _getUserIdForTab(state.currentTab);
    if (currentUserTabId == null) {
      if (mounted) {
        state = state.copyWith(reminders: [], isLoading: false);
      }
      return;
    }

    _setLoadingState(isRefresh);

    _cancelCurrentTabStream();
    _startStreamForCurrentTab();
  }

  void loadRemindersWithExistingFilter() {
    final filterOptions = hasActiveFilters
        ? _convertQueryToFilterOptions(state.activeFilterQuery!)
        : null;
    _loadRemindersWithFilterOptions(filterOptions, isRefresh: true);
  }

  Future<void> refreshReminders() async {
    clearCacheForTab(state.currentTab);
    loadRemindersWithExistingFilter();
  }

  ReminderFilterOptions _convertQueryToFilterOptions(
    Map<String, dynamic> query,
  ) {
    final filterQuery = Map<String, dynamic>.from(query)..remove('userId');
    final sortOptions = _extractSortOptions(filterQuery);

    final recurringType = _extractListFromQuery(filterQuery, 'recurringType');

    return ReminderFilterOptions(
      approvalStatus: _extractListFromQuery(filterQuery, 'approvalStatus'),
      reminderStatus: _extractListFromQuery(filterQuery, 'status'),
      tags: _extractListFromQuery(filterQuery, 'tags'),
      recurringType: recurringType != null
          ? (recurringType.first.trim() == "oneTime"
                ? RecurringType.none
                : recurringType.first.trim() == "daily"
                ? RecurringType.daily
                : RecurringType.weekly)
          : null,
      remindAtStart: _extractDateFromQuery(filterQuery, 'reminderDate_start'),
      remindAtEnd: _extractDateFromQuery(filterQuery, 'reminderDate_end'),
      createdAtStart: _extractDateFromQuery(filterQuery, 'createdDate_start'),
      createdAtEnd: _extractDateFromQuery(filterQuery, 'createdDate_end'),
      sortBy: sortOptions['sortBy'] as String?,
      ascending: sortOptions['ascending'] as bool?,
      searchKeyword: _extractStringFromQuery(filterQuery, 'search'),
      limit: 50,
    );
  }

  List<String>? _extractListFromQuery(Map<String, dynamic> query, String key) {
    if (query[key] != null && query[key] is List) {
      final list = List<String>.from(query[key]);
      print('$key filters: $list');
      return list;
    }
    return null;
  }

  DateTime? _extractDateFromQuery(Map<String, dynamic> query, String key) {
    return query[key] != null ? DateTime.tryParse(query[key]) : null;
  }

  String? _extractStringFromQuery(Map<String, dynamic> query, String key) {
    return query[key] != null && query[key] is String ? query[key] : null;
  }

  Map<String, dynamic> _extractSortOptions(Map<String, dynamic> query) {
    if (query['sort'] == null) return {};

    final sortMap = _parseSortString(query['sort'] as String);
    print('Sort: ${sortMap['sortBy']}, Ascending: ${sortMap['ascending']}');
    return sortMap;
  }

  Map<String, dynamic> _parseSortString(String sortStr) {
    switch (sortStr) {
      case 'created_desc':
        return {'sortBy': 'createdAt', 'ascending': false};
      case 'created_asc':
        return {'sortBy': 'createdAt', 'ascending': true};
      case 'reminderDate':
        return {'sortBy': 'reminderDate', 'ascending': true};
      case 'title':
        return {'sortBy': 'title', 'ascending': true};
      default:
        return {};
    }
  }

  bool get hasActiveFilters {
    return state.activeFilterQuery != null &&
        state.activeFilterQuery!.isNotEmpty &&
        state.activeFilterQuery!.keys.any((key) => key != 'userId');
  }

  List<ReminderEntity> getRemindersByApprovalStatus(ApprovalStatus status) {
    return state.reminders
        .where((reminder) => reminder.approvalStatus == status)
        .toList();
  }

  List<ReminderEntity> getRemindersByDateRange(
    DateTime startDate,
    DateTime endDate,
    bool isCreatedDate,
  ) {
    final endDateInclusive = endDate.add(const Duration(days: 1));
    return state.reminders.where((reminder) {
      final createdAt = reminder.createdAt!;
      return createdAt.isAfter(startDate) &&
          createdAt.isBefore(endDateInclusive);
    }).toList();
  }

  Future<bool> deleteAllReminders() async {
    final currentUserId = ref.read(currentUserProvider)?.uid ?? '';
    if (!mounted) return false;

    state = state.copyWith(isActionLoading: true, clearError: true);

    final allReminders = state.reminders.toList();

    if (allReminders.isEmpty) {
      state = state.copyWith(isActionLoading: false);
      return true;
    }

    await Future.wait(
      allReminders.map(
        (reminder) async =>
            (await _useCases.deleteReminderUseCase(reminder, currentUserId),),
      ),
    );

    state = state.copyWith(isActionLoading: false);
    return true;
  }

  void selectReminder(ReminderEntity reminder) {
    if (mounted) {
      state = state.copyWith(selectedReminder: reminder);
    }
  }

  void reset() {
    if (mounted) {
      state = _initialState(partner).copyWith(tabCaches: {});
    }
    _cachedFilterNotifier = null;
  }

  //Selection mode
  void enterSelectionMode(ReminderEntity reminder) {
    if (!mounted) return;

    final selectedReminders = List<ReminderEntity>.from(state.selectedReminders)
      ..add(reminder);

    state = state.copyWith(
      isSelectionMode: true,
      selectedReminders: selectedReminders,
    );
  }

  void exitSelectionMode() {
    if (!mounted) return;

    state = state.copyWith(isSelectionMode: false, selectedReminders: []);
  }

  bool isReminderSelected(ReminderEntity reminder) {
    return state.selectedReminders.contains(reminder);
  }

  void toggleReminderSelection(ReminderEntity reminder) {
    if (!mounted) return;

    final currentSelections = List<ReminderEntity>.from(
      state.selectedReminders,
    );

    if (currentSelections.contains(reminder)) {
      currentSelections.remove(reminder);
    } else {
      currentSelections.add(reminder);
    }

    if (currentSelections.isEmpty) {
      exitSelectionMode();
    } else {
      state = state.copyWith(selectedReminders: currentSelections);
    }
  }

  void selectOrDeselectAll() {
    if (!mounted) return;

    if (state.reminders.length == state.selectedReminders.length)
      state = state.copyWith(selectedReminders: [], isSelectionMode: false);
    else {
      state = state.copyWith(
        selectedReminders: state.reminders,
        isSelectionMode: true,
      );
    }
  }

  void deselectAll() {
    if (!mounted) return;

    state = state.copyWith(selectedReminders: [], isSelectionMode: false);
  }

  Future<bool> deleteSelectedReminders() async {
    final currentUserId = ref.read(currentUserProvider)?.uid ?? '';
    if (!mounted || state.selectedReminders.isEmpty) return false;

    state = state.copyWith(isActionLoading: true, clearError: true);

    final failures = <String>[];

    for (final reminder in state.selectedReminders) {
      if (!mounted) break;

      AlarmService.cancel(reminder.alarmId!);
      await _useCases.deleteReminderUseCase(reminder, currentUserId);
    }

    if (!mounted) return false;

    exitSelectionMode();

    if (failures.isEmpty) {
      state = state.copyWith(isActionLoading: false);
      clearCacheForTab(state.currentTab);
      refreshReminders();
      return true;
    } else {
      state = state.copyWith(
        isActionLoading: false,
        errorMessage: 'Không thể xóa ${failures.length} nhắc nhở',
      );
      return false;
    }
  }
}
