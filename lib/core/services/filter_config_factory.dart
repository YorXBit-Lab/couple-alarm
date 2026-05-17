import 'package:couple_note/core/constants/trans_keys.dart';
import 'package:couple_note/core/common/filter_model.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class CommonFilterOptions {
  static List<FilterOption> getTagsOptions(List<String> userTags) {
    return userTags
        .map((tag) => FilterOption(id: tag, label: tag, icon: Icons.tag))
        .toList();
  }

  static List<FilterOption> getReminderStatusOptions() {
    return [
      FilterOption(
        id: 'doing',
        label: TransKeys.doing.tr(),
        icon: Icons.pending,
        color: Colors.orange,
      ),
      FilterOption(
        id: 'done',
        label: TransKeys.done.tr(),
        icon: Icons.check_circle,
        color: Colors.green,
      ),
      FilterOption(
        id: 'overdue',
        label: TransKeys.overdue.tr(),
        icon: Icons.warning,
        color: Colors.red,
      ),
    ];
  }

  static List<FilterOption> getBasicApprovalStatusOptions() {
    return [
      FilterOption(
        id: 'pending',
        label: TransKeys.pending_approval.tr(),
        icon: Icons.pending,
        color: Colors.orange,
      ),
      FilterOption(
        id: 'accepted',
        label: TransKeys.accepted.tr(),
        icon: Icons.check_circle,
        color: Colors.green,
      ),
      // FilterOption(
      //   id: 'rejected',
      //   label: TransKeys.rejected.tr(),
      //   icon: Icons.warning,
      //   color: Colors.red,
      // ),
    ];
  }

  static List<FilterOption> getBasicPriorityOptions() {
    return [
      FilterOption(
        id: 'high',
        label: TransKeys.high.tr(),
        icon: Icons.keyboard_arrow_up,
        color: Colors.red,
      ),
      FilterOption(
        id: 'medium',
        label: TransKeys.medium.tr(),
        icon: Icons.remove,
        color: Colors.orange,
      ),
      FilterOption(
        id: 'normal',
        label: TransKeys.low.tr(),
        icon: Icons.keyboard_arrow_down,
        color: Colors.green,
      ),
    ];
  }

  static List<FilterOption> getBasicSortOptions() {
    return [
      FilterOption(
        id: 'created_desc',
        label: TransKeys.newest.tr(),
        icon: Icons.star,
      ),
      FilterOption(
        id: 'created_asc',
        label: TransKeys.oldest.tr(),
        icon: Icons.history,
      ),
    ];
  }

  static List<FilterOption> getReminderSortOptions() {
    final basic = getBasicSortOptions();
    basic.insertAll(0, [
      FilterOption(
        id: 'reminderDate',
        label: TransKeys.reminder_time.tr(),
        icon: Icons.schedule,
      ),
      FilterOption(id: 'title', label: TransKeys.title.tr(), icon: Icons.title),
    ]);
    return basic;
  }

  static List<FilterOption> getReminderTypeOptions() {
    return [
      FilterOption(
        id: 'oneTime',
        label: TransKeys.once.tr(),
        icon: Icons.looks_one,
      ),
      FilterOption(id: 'daily', label: TransKeys.daily.tr(), icon: Icons.today),
      FilterOption(
        id: 'weekly',
        label: TransKeys.weekly.tr(),
        icon: Icons.calendar_view_week,
      ),
    ];
  }
}

class FilterConfigFactory {
  static FilterSection createSection({
    required String title,
    required FilterType type,
    required List<FilterOption> options,
    bool allowMultiSelect = false,
    bool isVisible = true,
    String? description,
  }) {
    return FilterSection(
      title: title,
      type: type,
      options: options,
      allowMultiSelect: allowMultiSelect,
      isVisible: isVisible,
      description: description,
    );
  }

  static FilterConfig createReminderFilterConfig({List<String>? userTags}) {
    return FilterConfig(
      pageType: PageType.reminder,
      title: TransKeys.reminder_filter.tr(),
      availableSections: [
        createSection(
          title: TransKeys.status.tr(),
          type: FilterType.status,
          options: CommonFilterOptions.getReminderStatusOptions(),
          allowMultiSelect: true,
        ),
        createSection(
          title: TransKeys.approval_status.tr(),
          type: FilterType.approvalStatus,
          options: CommonFilterOptions.getBasicApprovalStatusOptions(),
          allowMultiSelect: true,
        ),
        createSection(
          title: TransKeys.reminder_type.tr(),
          type: FilterType.recurringType,
          options: CommonFilterOptions.getReminderTypeOptions(),
          allowMultiSelect: false,
        ),
        createSection(
          title: TransKeys.sort_by.tr(),
          type: FilterType.sort,
          options: CommonFilterOptions.getReminderSortOptions(),
          allowMultiSelect: false,
        ),
        if (userTags != null && userTags.isNotEmpty)
          createSection(
            title: 'Tags',
            type: FilterType.tags,
            options: CommonFilterOptions.getTagsOptions(userTags),
            allowMultiSelect: true,
          ),
      ],
      dateRanges: [
        DateRangeFilter(type: FilterType.reminderDate),
        DateRangeFilter(type: FilterType.createdDate),
      ],
    );
  }

  static FilterConfig customizeConfig({
    required FilterConfig baseConfig,
    List<FilterSection>? additionalSections,
    List<FilterSection>? sectionsToRemove,
    Map<FilterType, List<FilterOption>>? customOptions,
  }) {
    var sections = List<FilterSection>.from(baseConfig.availableSections);

    // Remove sections if specified
    if (sectionsToRemove != null) {
      sections.removeWhere(
        (section) =>
            sectionsToRemove.any((remove) => remove.type == section.type),
      );
    }

    // Add additional sections
    if (additionalSections != null) {
      sections.addAll(additionalSections);
    }

    // Customize options for existing sections
    if (customOptions != null) {
      for (int i = 0; i < sections.length; i++) {
        if (customOptions.containsKey(sections[i].type)) {
          sections[i] = sections[i].copyWith(
            options: customOptions[sections[i].type],
          );
        }
      }
    }

    return baseConfig.copyWith(availableSections: sections);
  }

  static FilterConfig createConfig(
    PageType pageType, {
    List<String>? userTags,
    String? userId,
  }) {
    switch (pageType) {
      case PageType.reminder:
        return createReminderFilterConfig(userTags: userTags);
      case PageType.general:
        return FilterConfig(
          pageType: PageType.general,
          title: TransKeys.filter.tr(),
          availableSections: [],
        );
    }
  }
}
