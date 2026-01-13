// import 'package:couple_note/core/services/lib/core/services/filter_extension.dart';
// import 'package:couple_note/data/models/filter_model.dart';
// import 'package:couple_note/presentation/themes/colors.dart';
// import 'package:couple_note/presentation/widgets/filter/filter_bottom_sheet.dart.dart';
// import 'package:couple_note/provider/filter_provider.dart';
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';

// class FilterSummaryWidget extends ConsumerWidget {
//   final PageType pageType;
//   final String? userId;
//   final List<String>? userTags;
//   final VoidCallback? onFilterPressed;

//   const FilterSummaryWidget({
//     Key? key,
//     required this.pageType,
//     this.userId,
//     this.userTags,
//     this.onFilterPressed,
//   }) : super(key: key);

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final filterParams = FilterParams(userId: userId, userTags: userTags);
//     final filterState = _getFilterState(ref, filterParams);
//     final hasActiveFilters = filterState.hasActiveFilters();
//     final activeCount = filterState.getActiveFilterCount();

//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//       child: Row(
//         children: [
//           InkWell(
//             onTap:
//                 onFilterPressed ??
//                 () => _showFilterBottomSheet(context, ref, filterParams),
//             borderRadius: BorderRadius.circular(12),
//             child: Container(
//               padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//               decoration: BoxDecoration(
//                 color: hasActiveFilters
//                     ? AppColors.primary.withValues(alpha:0.1)
//                     : Colors.grey[100],
//                 borderRadius: BorderRadius.circular(12),
//                 border: Border.all(
//                   color: hasActiveFilters
//                       ? AppColors.primary
//                       : Colors.grey[300]!,
//                 ),
//               ),
//               child: Row(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   Icon(
//                     Icons.tune,
//                     size: 16,
//                     color: hasActiveFilters
//                         ? AppColors.primary
//                         : Colors.grey[600],
//                   ),
//                   const SizedBox(width: 6),
//                   Text(
//                     'Bộ lọc',
//                     style: TextStyle(
//                       fontSize: 14,
//                       color: hasActiveFilters
//                           ? AppColors.primary
//                           : Colors.grey[600],
//                       fontWeight: hasActiveFilters
//                           ? FontWeight.w600
//                           : FontWeight.w500,
//                     ),
//                   ),
//                   if (hasActiveFilters) ...[
//                     const SizedBox(width: 4),
//                     Container(
//                       padding: const EdgeInsets.symmetric(
//                         horizontal: 6,
//                         vertical: 2,
//                       ),
//                       decoration: BoxDecoration(
//                         color: AppColors.primary,
//                         borderRadius: BorderRadius.circular(10),
//                       ),
//                       child: Text(
//                         activeCount.toString(),
//                         style: const TextStyle(
//                           color: Colors.white,
//                           fontSize: 12,
//                           fontWeight: FontWeight.w600,
//                         ),
//                       ),
//                     ),
//                   ],
//                 ],
//               ),
//             ),
//           ),

//           if (hasActiveFilters) ...[
//             const SizedBox(width: 8),
//             Expanded(
//               child: SingleChildScrollView(
//                 scrollDirection: Axis.horizontal,
//                 child: Row(children: _buildActiveFilterChips(filterState)),
//               ),
//             ),
//             const SizedBox(width: 8),
//             InkWell(
//               onTap: () => _clearAllFilters(ref, filterParams),
//               borderRadius: BorderRadius.circular(16),
//               child: Container(
//                 padding: const EdgeInsets.all(4),
//                 child: Icon(Icons.clear, size: 16, color: Colors.grey[600]),
//               ),
//             ),
//           ],
//         ],
//       ),
//     );
//   }

//   FilterState _getFilterState(WidgetRef ref, FilterParams params) {
//     switch (pageType) {
//       case PageType.note:
//         return ref.watch(noteFilterProvider(params));
//       case PageType.todo:
//         return ref.watch(todoFilterProvider(params));
//       case PageType.reminder:
//         return ref.watch(reminderFilterProvider(params));
//       case PageType.general:
//         return FilterState(pageType: pageType, sections: []);
//     }
//   }

//   void _showFilterBottomSheet(
//     BuildContext context,
//     WidgetRef ref,
//     FilterParams params,
//   ) {
//     final filterState = _getFilterState(ref, params);

//     showUniversalFilterBottomSheet(
//       context,
//       pageType,
//       filterState: filterState,
//       userTags: userTags,
//       userId: userId,
//       onApply: () {
//         final query = _getFilterNotifier(ref, params).buildFilterQuery();
//         print('Applied filters: $query');
//       },
//       onReset: () => _clearAllFilters(ref, params),
//       onOptionChanged: (section, option) {
//         _getFilterNotifier(ref, params).updateOption(section, option);
//       },
//       onDateRangeChanged: (dateRange) {
//         _getFilterNotifier(ref, params).updateDateRange(dateRange);
//       },
//     );
//   }

//   FilterNotifier _getFilterNotifier(WidgetRef ref, FilterParams params) {
//     switch (pageType) {
//       case PageType.note:
//         return ref.read(noteFilterProvider(params).notifier);
//       case PageType.todo:
//         return ref.read(todoFilterProvider(params).notifier);
//       case PageType.reminder:
//         return ref.read(reminderFilterProvider(params).notifier);
//       case PageType.general:
//         return FilterNotifier(pageType, userId: userId, userTags: userTags);
//     }
//   }

//   void _clearAllFilters(WidgetRef ref, FilterParams params) {
//     _getFilterNotifier(ref, params).clearAllFilters();
//   }

//   // Rest of the methods remain the same...
//   List<Widget> _buildActiveFilterChips(FilterState filterState) {
//     List<Widget> chips = [];

//     for (var section in filterState.sections) {
//       final selectedOptions = section.options
//           .where((o) => o.isSelected)
//           .toList();
//       for (var option in selectedOptions) {
//         chips.add(
//           Container(
//             margin: const EdgeInsets.only(right: 6),
//             padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//             decoration: BoxDecoration(
//               color: AppColors.primary.withValues(alpha:0.1),
//               borderRadius: BorderRadius.circular(12),
//               border: Border.all(color: AppColors.primary.withValues(alpha:0.3)),
//             ),
//             child: Row(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 Icon(option.icon, size: 12, color: AppColors.primary),
//                 const SizedBox(width: 4),
//                 Text(
//                   option.label,
//                   style: TextStyle(
//                     fontSize: 12,
//                     color: AppColors.primary,
//                     fontWeight: FontWeight.w500,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         );
//       }
//     }

//     for (var dateRange in filterState.dateRanges) {
//       if (dateRange.startDate != null || dateRange.endDate != null) {
//         String label = '';
//         if (dateRange.startDate != null && dateRange.endDate != null) {
//           label =
//               '${_formatDate(dateRange.startDate!)} - ${_formatDate(dateRange.endDate!)}';
//         } else if (dateRange.startDate != null) {
//           label = 'Từ ${_formatDate(dateRange.startDate!)}';
//         } else if (dateRange.endDate != null) {
//           label = 'Đến ${_formatDate(dateRange.endDate!)}';
//         }

//         if (label.isNotEmpty) {
//           chips.add(
//             Container(
//               margin: const EdgeInsets.only(right: 6),
//               padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//               decoration: BoxDecoration(
//                 color: AppColors.primary.withValues(alpha:0.1),
//                 borderRadius: BorderRadius.circular(12),
//                 border: Border.all(color: AppColors.primary.withValues(alpha:0.3)),
//               ),
//               child: Row(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   Icon(Icons.date_range, size: 12, color: AppColors.primary),
//                   const SizedBox(width: 4),
//                   Text(
//                     label,
//                     style: TextStyle(
//                       fontSize: 12,
//                       color: AppColors.primary,
//                       fontWeight: FontWeight.w500,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           );
//         }
//       }
//     }

//     return chips;
//   }

//   String _formatDate(DateTime date) {
//     return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
//   }
// }
