import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

enum PageType { note, todo, reminder, general }

enum FilterType {
  status,
  approvalStatus,
  priority,
  dateRange,
  tags,
  recurringType,
  sort,
  createdDate,
  modifiedDate,
  reminderDate,
  completed,
  favorite,
  shared,
  custom,
}

enum FilterSectionType { status, priority, type, sort, dateRange, tags, custom }

class FilterOption {
  final String id;
  final String label;
  final IconData icon;
  final bool isSelected;
  final Color? color;
  final dynamic value;

  FilterOption({
    required this.id,
    required this.label,
    required this.icon,
    this.isSelected = false,
    this.color,
    this.value,
  });

  FilterOption copyWith({
    String? id,
    String? label,
    IconData? icon,
    bool? isSelected,
    Color? color,
    dynamic value,
  }) {
    return FilterOption(
      id: id ?? this.id,
      label: label ?? this.label,
      icon: icon ?? this.icon,
      isSelected: isSelected ?? this.isSelected,
      color: color ?? this.color,
      value: value ?? this.value,
    );
  }
}

class FilterSection {
  final String title;
  final FilterType type;
  final List<FilterOption> options;
  final bool allowMultiSelect;
  final bool isVisible;
  final String? description;

  FilterSection({
    required this.title,
    required this.type,
    required this.options,
    this.allowMultiSelect = false,
    this.isVisible = true,
    this.description,
  });

  FilterSection copyWith({
    String? title,
    FilterType? type,
    List<FilterOption>? options,
    bool? allowMultiSelect,
    bool? isVisible,
    String? description,
  }) {
    return FilterSection(
      title: title ?? this.title,
      type: type ?? this.type,
      options: options ?? this.options,
      allowMultiSelect: allowMultiSelect ?? this.allowMultiSelect,
      isVisible: isVisible ?? this.isVisible,
      description: description ?? this.description,
    );
  }
}

class DateRangeFilter {
  final DateTime? startDate;
  final DateTime? endDate;
  final FilterType type;

  DateRangeFilter({
    this.startDate,
    this.endDate,
    this.type = FilterType.dateRange,
  });

  DateRangeFilter copyWith({
    DateTime? startDate,
    DateTime? endDate,
    FilterType? type,
  }) {
    return DateRangeFilter(
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      type: type ?? this.type,
    );
  }
}

class FilterState {
  final PageType pageType;
  final List<FilterSection> sections;
  final List<DateRangeFilter> dateRanges;
  final bool showDateRange;

  FilterState({
    required this.pageType,
    required this.sections,
    this.dateRanges = const [],
    this.showDateRange = true,
  });

  FilterState copyWith({
    PageType? pageType,
    List<FilterSection>? sections,
    List<DateRangeFilter>? dateRanges,
    bool? showDateRange,
  }) {
    return FilterState(
      pageType: pageType ?? this.pageType,
      sections: sections ?? this.sections,
      dateRanges: dateRanges ?? this.dateRanges,
      showDateRange: showDateRange ?? this.showDateRange,
    );
  }

  List<FilterOption> getSelectedOptions() {
    List<FilterOption> selected = [];
    for (var section in sections) {
      selected.addAll(section.options.where((option) => option.isSelected));
    }
    return selected;
  }

  Map<FilterType, List<FilterOption>> getSelectedOptionsByType() {
    Map<FilterType, List<FilterOption>> result = {};
    for (var section in sections) {
      if (section.options.any((option) => option.isSelected)) {
        result[section.type] = section.options
            .where((option) => option.isSelected)
            .toList();
      }
    }
    return result;
  }
}

class FilterConfig {
  final PageType pageType;
  final String title;
  final String resetButtonText;
  final String applyButtonText;
  final String cancelButtonText;
  final List<FilterSection> availableSections;
  final List<DateRangeFilter> dateRanges;

  FilterConfig({
    required this.pageType,
    required this.title,
    required this.availableSections,
    this.resetButtonText = 'Reset',
    this.applyButtonText = 'Apply',
    this.cancelButtonText = 'Cancel',
    this.dateRanges = const [],
  });

  FilterConfig copyWith({
    PageType? pageType,
    String? title,
    String? resetButtonText,
    String? applyButtonText,
    String? cancelButtonText,
    List<FilterSection>? availableSections,
    List<DateRangeFilter>? dateRanges,
  }) {
    return FilterConfig(
      pageType: pageType ?? this.pageType,
      title: title ?? this.title,
      resetButtonText: resetButtonText ?? this.resetButtonText,
      applyButtonText: applyButtonText ?? this.applyButtonText,
      cancelButtonText: cancelButtonText ?? this.cancelButtonText,
      availableSections: availableSections ?? this.availableSections,
      dateRanges: dateRanges ?? this.dateRanges,
    );
  }
}

class FilterParams {
  final String? userId;
  final List<String>? userTags;

  const FilterParams({this.userId, this.userTags});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FilterParams &&
        other.userId == userId &&
        listEquals(other.userTags, userTags);
  }

  @override
  int get hashCode => Object.hash(userId, userTags);
}

extension DateRangeFilterExt on DateRangeFilter {
  DateRangeFilter copyWith({
    FilterType? type,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return DateRangeFilter(
      type: type ?? this.type,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
    );
  }
}

extension FilterOptionExt on FilterOption {
  FilterOption copyWith({
    String? id,
    String? label,
    IconData? icon,
    Color? color,
    bool? isSelected,
  }) {
    return FilterOption(
      id: id ?? this.id,
      label: label ?? this.label,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      isSelected: isSelected ?? this.isSelected,
    );
  }
}

extension FilterSectionExt on FilterSection {
  FilterSection copyWith({
    String? title,
    FilterType? type,
    List<FilterOption>? options,
    bool? allowMultiSelect,
    bool? isVisible,
    String? description,
  }) {
    return FilterSection(
      title: title ?? this.title,
      type: type ?? this.type,
      options: options ?? this.options,
      allowMultiSelect: allowMultiSelect ?? this.allowMultiSelect,
      isVisible: isVisible ?? this.isVisible,
      description: description ?? this.description,
    );
  }
}

extension FilterStateExt on FilterState {
  FilterState copyWith({
    PageType? pageType,
    List<FilterSection>? sections,
    List<DateRangeFilter>? dateRanges,
    bool? showDateRange,
  }) {
    return FilterState(
      pageType: pageType ?? this.pageType,
      sections: sections ?? this.sections,
      dateRanges: dateRanges ?? this.dateRanges,
      showDateRange: showDateRange ?? this.showDateRange,
    );
  }

  FilterState clearAllFilters() {
    final clearedSections = sections.map((section) {
      final clearedOptions = section.options.map((option) {
        return option.copyWith(isSelected: false);
      }).toList();
      return section.copyWith(options: clearedOptions);
    }).toList();

    final clearedDateRanges = dateRanges.map((dateRange) {
      return dateRange.copyWith(startDate: null, endDate: null);
    }).toList();

    return copyWith(sections: clearedSections, dateRanges: clearedDateRanges);
  }

  List<FilterOption> getSelectedOptions() {
    final selected = <FilterOption>[];
    for (final section in sections) {
      selected.addAll(section.options.where((option) => option.isSelected));
    }
    return selected;
  }

  Map<FilterType, List<FilterOption>> getSelectedOptionsByType() {
    final Map<FilterType, List<FilterOption>> result = {};
    for (final section in sections) {
      final selectedOptions = section.options
          .where((option) => option.isSelected)
          .toList();
      if (selectedOptions.isNotEmpty) {
        result[section.type] = selectedOptions;
      }
    }
    return result;
  }
}
