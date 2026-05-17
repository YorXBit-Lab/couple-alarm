import 'package:couple_note/core/services/filter_config_factory.dart';
import 'package:couple_note/core/common/filter_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'filter_provider.g.dart';

@riverpod
class FilterNotifier extends _$FilterNotifier {
  bool _hasBeenInitialized = false;

  @override
  FilterState build(FilterParams params) {
    final config = FilterConfigFactory.createConfig(
      params.pageType,
      userTags: params.userTags,
      userId: params.userId,
    );
    return FilterState(
      pageType: params.pageType,
      sections: config.availableSections,
      dateRanges: config.dateRanges,
    );
  }

  void restoreFromQuery(Map<String, dynamic> query) {
    final filterQuery = Map<String, dynamic>.from(query);
    filterQuery.remove('userId');

    if (filterQuery.isEmpty) {
      _hasBeenInitialized = true;
      return;
    }

    final sections = List<FilterSection>.from(state.sections);
    final dateRanges = List<DateRangeFilter>.from(state.dateRanges);
    bool hasChanges = false;

    for (int sectionIndex = 0; sectionIndex < sections.length; sectionIndex++) {
      final section = sections[sectionIndex];
      final options = List<FilterOption>.from(section.options);

      List<String>? selectedIds = _getSelectedIdsForSection(
        section,
        filterQuery,
      );

      if (selectedIds != null && selectedIds.isNotEmpty) {
        bool sectionChanged = false;

        for (int optionIndex = 0; optionIndex < options.length; optionIndex++) {
          final currentOption = options[optionIndex];
          final shouldBeSelected = selectedIds.contains(currentOption.id);

          if (currentOption.isSelected != shouldBeSelected) {
            options[optionIndex] = currentOption.copyWith(
              isSelected: shouldBeSelected,
            );
            sectionChanged = true;
            hasChanges = true;
          }
        }

        if (sectionChanged) {
          sections[sectionIndex] = section.copyWith(options: options);
        }
      }
    }

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
      }
    }

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
    }
    if (endDateStr != null) {
      endDate = DateTime.tryParse(endDateStr);
    }

    return (startDate, endDate);
  }

  void clearAllFilters() {
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

    _hasBeenInitialized = false;
  }

  void updateOption(FilterSection section, FilterOption option) {
    final sections = List<FilterSection>.from(state.sections);
    final sectionIndex = sections.indexWhere((s) => s.type == section.type);

    if (sectionIndex == -1) return;

    final currentSection = sections[sectionIndex];
    final options = List<FilterOption>.from(currentSection.options);
    final optionIndex = options.indexWhere((o) => o.id == option.id);

    if (optionIndex == -1) return;

    if (currentSection.allowMultiSelect) {
      options[optionIndex] = option.copyWith(isSelected: !option.isSelected);
    } else {
      for (int i = 0; i < options.length; i++) {
        options[i] = options[i].copyWith(isSelected: i == optionIndex);
      }
    }

    sections[sectionIndex] = currentSection.copyWith(options: options);
    state = state.copyWith(sections: sections);
  }

  void updateDateRange(DateRangeFilter dateRange) {
    final dateRanges = List<DateRangeFilter>.from(state.dateRanges);
    final index = dateRanges.indexWhere((dr) => dr.type == dateRange.type);

    if (index != -1) {
      dateRanges[index] = dateRange;
    } else {
      dateRanges.add(dateRange);
    }

    bool shouldShowDateRange = dateRanges.any(
      (dr) => dr.startDate != null || dr.endDate != null,
    );

    state = state.copyWith(
      dateRanges: dateRanges,
      showDateRange: shouldShowDateRange,
    );
  }

  void toggleDateRangeVisibility() {
    state = state.copyWith(showDateRange: !state.showDateRange);
  }

  Map<String, dynamic> buildFilterQuery() {
    final query = <String, dynamic>{};

    query['userId'] = state.pageType.toString();

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

    return query;
  }

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
