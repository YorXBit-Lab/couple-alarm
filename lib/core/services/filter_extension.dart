import 'package:couple_note/core/common/filter_model.dart';

extension FilterStateExtensions on FilterState {
  bool hasActiveFilters() {
    return sections.any(
          (section) => section.options.any((option) => option.isSelected),
        ) ||
        dateRanges.any((dr) => dr.startDate != null || dr.endDate != null);
  }

  int getActiveFilterCount() {
    int count = 0;
    for (var section in sections) {
      count += section.options.where((option) => option.isSelected).length;
    }
    count += dateRanges
        .where((dr) => dr.startDate != null || dr.endDate != null)
        .length;
    return count;
  }

  FilterState clearAllFilters() {
    final clearedSections = sections.map((section) {
      final clearedOptions = section.options.map((option) {
        return option.copyWith(isSelected: false);
      }).toList();
      return section.copyWith(options: clearedOptions);
    }).toList();

    final clearedDateRanges = dateRanges.map((dr) {
      return DateRangeFilter(type: dr.type);
    }).toList();

    return copyWith(sections: clearedSections, dateRanges: clearedDateRanges);
  }
}
