import 'package:couple_note/core/services/lib/core/services/filter_config_factory.dart';
import 'package:couple_note/data/models/filter_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

class FilterNotifier extends StateNotifier<FilterState> {
  final String? userId;
  final List<String>? userTags;
  final PageType pageType;

  FilterNotifier(this.pageType, {this.userId, this.userTags})
    : super(
        FilterState(
          pageType: pageType,
          sections: FilterConfigFactory.createConfig(
            pageType,
            userTags: userTags,
            userId: userId,
          ).availableSections,
          dateRanges: FilterConfigFactory.createConfig(
            pageType,
            userTags: userTags,
            userId: userId,
          ).dateRanges,
        ),
      );

  bool _hasBeenInitialized = false;

  void restoreFromQuery(Map<String, dynamic> query) {
    print('=== RESTORE FROM QUERY START ===');
    print('Page Type: $pageType');
    print('Input Query: $query');
    print('Already initialized: $_hasBeenInitialized');

    // Remove userId from processing since it's just for identification
    final filterQuery = Map<String, dynamic>.from(query);
    filterQuery.remove('userId');

    if (filterQuery.isEmpty) {
      print('No filters to restore');
      _hasBeenInitialized = true;
      return;
    }

    final sections = List<FilterSection>.from(state.sections);
    final dateRanges = List<DateRangeFilter>.from(state.dateRanges);
    bool hasChanges = false;

    // Restore options selections
    for (int sectionIndex = 0; sectionIndex < sections.length; sectionIndex++) {
      final section = sections[sectionIndex];
      final options = List<FilterOption>.from(section.options);

      List<String>? selectedIds = _getSelectedIdsForSection(
        section,
        filterQuery,
      );

      if (selectedIds != null && selectedIds.isNotEmpty) {
        bool sectionChanged = false;
        print('Restoring section ${section.type} with IDs: $selectedIds');

        for (int optionIndex = 0; optionIndex < options.length; optionIndex++) {
          final currentOption = options[optionIndex];
          final shouldBeSelected = selectedIds.contains(currentOption.id);

          if (currentOption.isSelected != shouldBeSelected) {
            options[optionIndex] = currentOption.copyWith(
              isSelected: shouldBeSelected,
            );
            sectionChanged = true;
            hasChanges = true;

            print('Option ${currentOption.id} set to $shouldBeSelected');
          }
        }

        if (sectionChanged) {
          sections[sectionIndex] = section.copyWith(options: options);
        }
      }
    }

    // Restore date ranges
    for (int dateIndex = 0; dateIndex < dateRanges.length; dateIndex++) {
      final dateRange = dateRanges[dateIndex];
      final (startDate, endDate) = _parseDateRangeFromQuery(
        dateRange,
        filterQuery,
      );

      if (startDate != dateRange.startDate || endDate != dateRange.endDate) {
        dateRanges[dateIndex] = dateRange.copyWith(
          startDate: startDate,
          endDate: endDate,
        );
        hasChanges = true;

        print('DateRange ${dateRange.type} updated: $startDate to $endDate');
      }
    }

    // Determine if should show date range
    bool shouldShowDateRange = dateRanges.any(
      (dr) => dr.startDate != null || dr.endDate != null,
    );

    if (hasChanges || shouldShowDateRange != state.showDateRange) {
      state = state.copyWith(
        sections: sections,
        dateRanges: dateRanges,
        showDateRange: shouldShowDateRange,
      );
    }

    _hasBeenInitialized = true;
    print('=== RESTORE COMPLETED ===');
    print('Has changes: $hasChanges');
    print(
      'Selected options: ${getSelectedOptions().map((o) => o.id).toList()}',
    );
  }

  void syncWithQuery(Map<String, dynamic>? query) {
    if (query != null && query.isNotEmpty && !_hasBeenInitialized) {
      restoreFromQuery(query);
    }
  }

  List<String>? _getSelectedIdsForSection(
    FilterSection section,
    Map<String, dynamic> query,
  ) {
    switch (section.type) {
      case FilterType.status:
        final statusList = query['status'];
        return statusList != null ? List<String>.from(statusList) : null;
      case FilterType.priority:
        final priorityList = query['priority'];
        return priorityList != null ? List<String>.from(priorityList) : null;
      case FilterType.recurringType:
        final recurringTypeList = query['recurringType'];
        return recurringTypeList != null
            ? List<String>.from(recurringTypeList)
            : null;
      case FilterType.tags:
        final tagsList = query['tags'];
        return tagsList != null ? List<String>.from(tagsList) : null;
      case FilterType.sort:
        return query['sort'] != null ? [query['sort'] as String] : null;
      default:
        final key = section.type.toString().split('.').last;
        final value = query[key];
        return value != null ? List<String>.from(value) : null;
    }
  }

  (DateTime?, DateTime?) _parseDateRangeFromQuery(
    DateRangeFilter dateRange,
    Map<String, dynamic> query,
  ) {
    String typeKey;

    switch (dateRange.type) {
      case FilterType.createdDate:
        typeKey = 'createdDate';
        break;
      case FilterType.modifiedDate:
        typeKey = 'modifiedDate';
        break;
      case FilterType.reminderDate:
        typeKey = 'reminderDate';
        break;
      default:
        typeKey = dateRange.type.toString().split('.').last;
    }

    final startDateStr = query['${typeKey}_start'];
    final endDateStr = query['${typeKey}_end'];

    DateTime? startDate;
    DateTime? endDate;

    if (startDateStr != null) {
      startDate = DateTime.tryParse(startDateStr);
      print('Parsed start date: $startDate from $startDateStr');
    }
    if (endDateStr != null) {
      endDate = DateTime.tryParse(endDateStr);
      print('Parsed end date: $endDate from $endDateStr');
    }

    return (startDate, endDate);
  }

  void clearAllFilters() {
    print('=== CLEAR ALL FILTERS ===');

    final sections = state.sections.map((section) {
      final clearedOptions = section.options.map((option) {
        return option.copyWith(isSelected: false);
      }).toList();
      return section.copyWith(options: clearedOptions);
    }).toList();

    final clearedDateRanges = state.dateRanges.map((dateRange) {
      return dateRange.copyWith(startDate: null, endDate: null);
    }).toList();

    state = state.copyWith(
      sections: sections,
      dateRanges: clearedDateRanges,
      showDateRange: false,
    );

    _hasBeenInitialized = false; // ✅ Reset initialization flag
    print('=== CLEAR COMPLETED ===');
  }

  void updateOption(FilterSection section, FilterOption option) {
    print('=== UPDATE OPTION ===');
    print(
      'Section: ${section.type}, Option: ${option.id}, Current: ${option.isSelected}',
    );

    final sections = List<FilterSection>.from(state.sections);
    final sectionIndex = sections.indexWhere((s) => s.type == section.type);

    if (sectionIndex == -1) {
      print('Warning: Section ${section.type} not found');
      return;
    }

    final currentSection = sections[sectionIndex];
    final options = List<FilterOption>.from(currentSection.options);
    final optionIndex = options.indexWhere((o) => o.id == option.id);

    if (optionIndex == -1) {
      print(
        'Warning: Option ${option.id} not found in section ${section.type}',
      );
      return;
    }

    if (currentSection.allowMultiSelect) {
      // Multi-select: toggle the clicked option
      options[optionIndex] = option.copyWith(isSelected: !option.isSelected);
      print('Multi-select: ${option.id} -> ${!option.isSelected}');
    } else {
      // Single-select: clear all others and select this one
      for (int i = 0; i < options.length; i++) {
        final newSelected = i == optionIndex;
        options[i] = options[i].copyWith(isSelected: newSelected);
        if (newSelected) {
          print('Single-select: ${options[i].id} -> true');
        }
      }
    }

    sections[sectionIndex] = currentSection.copyWith(options: options);
    state = state.copyWith(sections: sections);

    print('=== UPDATE COMPLETED ===');
  }

  void updateDateRange(DateRangeFilter dateRange) {
    print('=== UPDATE DATE RANGE ===');
    print(
      'Type: ${dateRange.type}, Start: ${dateRange.startDate}, End: ${dateRange.endDate}',
    );

    final dateRanges = List<DateRangeFilter>.from(state.dateRanges);
    final index = dateRanges.indexWhere((dr) => dr.type == dateRange.type);

    if (index != -1) {
      dateRanges[index] = dateRange;
    } else {
      dateRanges.add(dateRange);
    }

    // Auto-show date range if any date is set
    bool shouldShowDateRange = dateRanges.any(
      (dr) => dr.startDate != null || dr.endDate != null,
    );

    state = state.copyWith(
      dateRanges: dateRanges,
      showDateRange: shouldShowDateRange,
    );

    print('=== DATE RANGE UPDATED ===');
  }

  void toggleDateRangeVisibility() {
    state = state.copyWith(showDateRange: !state.showDateRange);
    print('Date range visibility toggled: ${state.showDateRange}');
  }

  Map<String, dynamic> buildFilterQuery() {
    final query = <String, dynamic>{};

    query['userId'] = userId ?? '';

    // Build filter options
    final selectedByType = state.getSelectedOptionsByType();
    selectedByType.forEach((type, options) {
      if (options.isNotEmpty) {
        switch (type) {
          case FilterType.status:
            query['status'] = options.map((o) => o.id).toList();
            break;
          case FilterType.approvalStatus:
            query['approvalStatus'] = options.map((o) => o.id).toList();
            break;
          case FilterType.priority:
            query['priority'] = options.map((o) => o.id).toList();
            break;
          case FilterType.recurringType:
            query['recurringType'] = options.map((o) => o.id).toList();
            break;
          case FilterType.tags:
            query['tags'] = options.map((o) => o.id).toList();
            break;
          case FilterType.sort:
            query['sort'] = options.first.id;
            break;
          default:
            final key = type.toString().split('.').last;
            query[key] = options.map((o) => o.id).toList();
        }
      }
    });

    // Build date ranges
    for (var dateRange in state.dateRanges) {
      if (dateRange.startDate != null || dateRange.endDate != null) {
        String key;

        switch (dateRange.type) {
          case FilterType.createdDate:
            key = 'createdDate';
            break;
          case FilterType.modifiedDate:
            key = 'modifiedDate';
            break;
          case FilterType.reminderDate:
            key = 'reminderDate';
            break;
          default:
            key = dateRange.type.toString().split('.').last;
        }

        if (dateRange.startDate != null) {
          query['${key}_start'] = dateRange.startDate!.toIso8601String();
        }
        if (dateRange.endDate != null) {
          query['${key}_end'] = dateRange.endDate!.toIso8601String();
        }
      }
    }

    print('=== BUILT FILTER QUERY ===');
    print('Query: $query');
    print(
      'Selected options: ${getSelectedOptions().map((o) => '${o.id}:${o.isSelected}').toList()}',
    );

    return query;
  }

  // Helper methods
  bool get hasActiveFilters {
    final selectedOptions = getSelectedOptions();
    final activeDateRanges = state.dateRanges.where(
      (dr) => dr.startDate != null || dr.endDate != null,
    );

    return selectedOptions.isNotEmpty || activeDateRanges.isNotEmpty;
  }

  List<FilterOption> getSelectedOptions() {
    return state.sections
        .expand((section) => section.options)
        .where((option) => option.isSelected)
        .toList();
  }

  int getActiveFiltersCount() {
    final selectedOptions = getSelectedOptions();
    final activeDateRanges = state.dateRanges
        .where((dr) => dr.startDate != null || dr.endDate != null)
        .length;

    return selectedOptions.length + activeDateRanges;
  }

  String getFilterSummary() {
    if (!hasActiveFilters) return 'Không có bộ lọc';

    final selectedByType = state.getSelectedOptionsByType();
    final summaryParts = <String>[];

    selectedByType.forEach((type, options) {
      if (options.isNotEmpty) {
        switch (type) {
          case FilterType.status:
            summaryParts.add(
              'Trạng thái: ${options.map((o) => o.label).join(", ")}',
            );
            break;
          case FilterType.priority:
            summaryParts.add(
              'Ưu tiên: ${options.map((o) => o.label).join(", ")}',
            );
            break;
          case FilterType.tags:
            summaryParts.add('Tags: ${options.map((o) => o.label).join(", ")}');
            break;
          case FilterType.recurringType:
            summaryParts.add('Loại: ${options.map((o) => o.label).join(", ")}');
            break;
          default:
            break;
        }
      }
    });

    final activeDateRanges = state.dateRanges.where(
      (dr) => dr.startDate != null || dr.endDate != null,
    );

    if (activeDateRanges.isNotEmpty) {
      summaryParts.add('Có lọc theo ngày');
    }

    return summaryParts.join(' • ');
  }
}

final noteFilterProvider =
    StateNotifierProvider.family<FilterNotifier, FilterState, FilterParams>((
      ref,
      params,
    ) {
      return FilterNotifier(
        PageType.note,
        userId: params.userId,
        userTags: params.userTags,
      );
    });

final todoFilterProvider =
    StateNotifierProvider.family<FilterNotifier, FilterState, FilterParams>((
      ref,
      params,
    ) {
      return FilterNotifier(
        PageType.todo,
        userId: params.userId,
        userTags: params.userTags,
      );
    });

final reminderFilterProvider =
    StateNotifierProvider.family<FilterNotifier, FilterState, FilterParams>((
      ref,
      params,
    ) {
      return FilterNotifier(
        PageType.reminder,
        userId: params.userId,
        userTags: params.userTags,
      );
    });
