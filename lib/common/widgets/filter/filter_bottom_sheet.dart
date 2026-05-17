import 'package:couple_note/core/constants/trans_keys.dart';
import 'package:couple_note/core/services/filter_config_factory.dart';
import 'package:couple_note/core/common/filter_model.dart';
import 'package:couple_note/core/config/theme/app_colors.dart';
import 'package:couple_note/core/providers/filter_provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class UniversalFilterWidget extends ConsumerStatefulWidget {
  final PageType pageType;
  final FilterConfig config;
  final String userId;
  final List<String>? userTags;
  final VoidCallback? onApply;
  final VoidCallback? onReset;
  final Map<String, dynamic>? initialFilterQuery;
  final FilterNotifierProvider? externalFilterProvider;

  const UniversalFilterWidget({
    Key? key,
    required this.pageType,
    required this.config,
    required this.userId,
    this.userTags,
    this.onApply,
    this.onReset,
    this.initialFilterQuery,
    this.externalFilterProvider,
  }) : super(key: key);

  @override
  ConsumerState<UniversalFilterWidget> createState() =>
      _UniversalFilterWidgetState();
}

class _UniversalFilterWidgetState extends ConsumerState<UniversalFilterWidget> {
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();

    if (widget.initialFilterQuery != null &&
        widget.initialFilterQuery!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _initializeFilterWithQuery();
      });
    }
  }

  void _initializeFilterWithQuery() {
    if (!_isInitialized && widget.initialFilterQuery != null) {
      final filterNotifier = _getFilterNotifier();
      filterNotifier.restoreFromQuery(widget.initialFilterQuery!);
      setState(() {
        _isInitialized = true;
      });
    }
  }

  FilterNotifier _getFilterNotifier() {
    if (widget.externalFilterProvider != null) {
      return ref.read(widget.externalFilterProvider!.notifier);
    }

    return ref.read(
      filterProvider(
        FilterParams(
          pageType: widget.pageType,
          userId: widget.userId,
          userTags: widget.userTags ?? [],
        ),
      ).notifier,
    );
  }

  FilterState _getFilterState() {
    if (widget.externalFilterProvider != null) {
      return ref.watch(widget.externalFilterProvider!);
    }

    return ref.watch(
      filterProvider(
        FilterParams(
          pageType: widget.pageType,
          userId: widget.userId,
          userTags: widget.userTags ?? [],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filterState = _getFilterState();
    final filterNotifier = _getFilterNotifier();

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          _buildHeader(filterNotifier),

          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  ...filterState.sections
                      .where((section) => section.isVisible)
                      .map((section) {
                        return _buildFilterSection(
                          context,
                          section,
                          filterNotifier,
                        );
                      }),

                  if (filterState.showDateRange &&
                      filterState.dateRanges.isNotEmpty)
                    ...filterState.dateRanges.map((dateRange) {
                      return _buildDateRangeSection(
                        context,
                        dateRange,
                        filterNotifier,
                      );
                    }),

                  if (filterState.dateRanges.isNotEmpty)
                    _buildDateRangeToggle(filterState, filterNotifier),

                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),

          _buildBottomButtons(context, filterNotifier),
        ],
      ),
    );
  }

  Widget _buildHeader(FilterNotifier filterNotifier) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.tune, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              widget.config.title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
          ),
          TextButton.icon(
            onPressed: () {
              filterNotifier.clearAllFilters();
              widget.onReset?.call();
            },
            icon: Icon(Icons.refresh, size: 18, color: AppColors.primary),
            label: Text(
              // widget.config.resetButtonText,
              TransKeys.reset_real.tr(),
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection(
    BuildContext context,
    FilterSection section,
    FilterNotifier notifier,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(section),
          const SizedBox(height: 12),
          _buildOptions(context, section, notifier),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(FilterSection section) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 20,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                section.title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
              if (section.description != null) ...[
                const SizedBox(height: 4),
                Text(
                  section.description!,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOptions(
    BuildContext context,
    FilterSection section,
    FilterNotifier notifier,
  ) {
    if (section.options.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          TransKeys.no_options_available.tr(),
          style: TextStyle(color: Colors.grey[600], fontSize: 14),
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: section.options.map((option) {
        return _buildOptionChip(context, section, option, notifier);
      }).toList(),
    );
  }

  Widget _buildOptionChip(
    BuildContext context,
    FilterSection section,
    FilterOption option,
    FilterNotifier notifier,
  ) {
    final isSelected = option.isSelected;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: InkWell(
        onTap: () {
          notifier.updateOption(section, option);
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withValues(alpha: (0.1))
                : Colors.grey[100],
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? AppColors.primary : Colors.grey[300]!,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                option.icon,
                size: 16,
                color: isSelected
                    ? AppColors.primary
                    : option.color ?? Colors.grey[600],
              ),
              const SizedBox(width: 6),
              Text(
                option.label,
                style: TextStyle(
                  fontSize: 13,
                  color: isSelected ? AppColors.primary : Colors.grey[700],
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
              if (isSelected) ...[
                const SizedBox(width: 4),
                Icon(Icons.check, size: 14, color: AppColors.primary),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateRangeSection(
    BuildContext context,
    DateRangeFilter dateRange,
    FilterNotifier notifier,
  ) {
    String title = _getDateRangeTitle(dateRange.type);

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 3,
                height: 20,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildDateField(
                  context: context,
                  date: dateRange.startDate,
                  placeholder: TransKeys.from_date.tr(),
                  onTap: () => _selectStartDate(context, dateRange, notifier),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildDateField(
                  context: context,
                  date: dateRange.endDate,
                  placeholder: TransKeys.to_date.tr(),
                  onTap: () => _selectEndDate(context, dateRange, notifier),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDateRangeToggle(
    FilterState filterState,
    FilterNotifier notifier,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: TextButton.icon(
        onPressed: () => notifier.toggleDateRangeVisibility(),
        icon: Icon(
          filterState.showDateRange ? Icons.expand_less : Icons.expand_more,
          color: AppColors.primary,
        ),
        label: Text(
          filterState.showDateRange
              ? TransKeys.hide_filter_date.tr()
              : TransKeys.show_filter_date.tr(),
          style: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Future<void> _selectStartDate(
    BuildContext context,
    DateRangeFilter dateRange,
    FilterNotifier notifier,
  ) async {
    final now = DateTime.now();
    final maxDate = dateRange.endDate ?? DateTime(2030);

    DateTime initialDate = dateRange.startDate ?? now;
    if (initialDate.isBefore(DateTime(2020))) {
      initialDate = DateTime(2020);
    }
    if (initialDate.isAfter(maxDate)) {
      initialDate = maxDate;
    }

    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: maxDate,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(primary: AppColors.primary),
          ),
          child: child!,
        );
      },
    );
    if (date != null) {
      notifier.updateDateRange(dateRange.copyWith(startDate: date));
    }
  }

  Future<void> _selectEndDate(
    BuildContext context,
    DateRangeFilter dateRange,
    FilterNotifier notifier,
  ) async {
    final now = DateTime.now();
    final minDate = dateRange.startDate ?? DateTime(2020);

    DateTime initialDate = dateRange.endDate ?? now;
    if (initialDate.isBefore(minDate)) {
      initialDate = minDate;
    }
    if (initialDate.isAfter(DateTime(2030))) {
      initialDate = DateTime(2030);
    }

    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: minDate,
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(primary: AppColors.primary),
          ),
          child: child!,
        );
      },
    );
    if (date != null) {
      notifier.updateDateRange(dateRange.copyWith(endDate: date));
    }
  }

  String _getDateRangeTitle(FilterType type) {
    switch (type) {
      case FilterType.dateRange:
        return TransKeys.hide_filter_date.tr();
      case FilterType.createdDate:
        return TransKeys.created_date.tr();
      case FilterType.modifiedDate:
        return TransKeys.updated_date.tr();
      case FilterType.reminderDate:
        return TransKeys.reminder_date.tr();
      default:
        return TransKeys.hide_filter_date.tr();
    }
  }

  Widget _buildDateField({
    required BuildContext context,
    required DateTime? date,
    required String placeholder,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
            color: date != null ? AppColors.primary : Colors.grey[300]!,
            width: date != null ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                date != null
                    ? '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}'
                    : placeholder,
                style: TextStyle(
                  fontSize: 14,
                  color: date != null ? Colors.grey[800] : Colors.grey[500],
                  fontWeight: date != null
                      ? FontWeight.w500
                      : FontWeight.normal,
                ),
              ),
            ),
            Icon(
              Icons.calendar_today,
              size: 16,
              color: date != null ? AppColors.primary : Colors.grey[600],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomButtons(
    BuildContext context,
    FilterNotifier filterNotifier,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  side: BorderSide(color: Colors.grey[300]!),
                ),
                child: Text(
                  // widget.config.cancelButtonText,
                  TransKeys.cancel.tr(),
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  widget.onApply?.call();
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: Text(
                  // widget.config.applyButtonText,
                  TransKeys.apply.tr(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void showUniversalFilterBottomSheet(
  BuildContext context,
  PageType pageType, {
  String? userId,
  List<String>? userTags,
  VoidCallback? onApply,
  VoidCallback? onReset,
  Map<String, dynamic>? initialFilterQuery,
  FilterNotifierProvider? filterNotifier,
}) {
  final config = FilterConfigFactory.createConfig(
    pageType,
    userTags: userTags,
    userId: userId,
  );

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    backgroundColor: Colors.transparent,
    enableDrag: true,
    isDismissible: true,
    builder: (context) {
      return DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return UniversalFilterWidget(
            pageType: pageType,
            config: config,
            userId: userId ?? '',
            userTags: userTags,
            onApply: onApply,
            onReset: onReset,
            initialFilterQuery: initialFilterQuery,
            externalFilterProvider: filterNotifier,
          );
        },
      );
    },
  );
}
