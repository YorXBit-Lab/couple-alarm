import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:couple_note/domain/entities/reminder.dart';

class TabCache<T> {
  final List<T> items;
  final Map<String, dynamic>? activeFilterQuery;
  final DocumentSnapshot? lastDocument;
  final bool hasMoreData;
  final DateTime lastUpdated;

  const TabCache({
    required this.items,
    this.activeFilterQuery,
    this.lastDocument,
    required this.hasMoreData,
    required this.lastUpdated,
  });

  TabCache<T> copyWith({
    List<T>? items,
    Map<String, dynamic>? activeFilterQuery,
    DocumentSnapshot? lastDocument,
    bool? hasMoreData,
    DateTime? lastUpdated,
    bool clearFilter = false,
    bool clearLastDocument = false,
  }) {
    return TabCache<T>(
      items: items ?? this.items,
      activeFilterQuery: clearFilter
          ? null
          : (activeFilterQuery ?? this.activeFilterQuery),
      lastDocument: clearLastDocument
          ? null
          : (lastDocument ?? this.lastDocument),
      hasMoreData: hasMoreData ?? this.hasMoreData,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  bool get isValid {
    final now = DateTime.now();
    const cacheValidDuration = Duration(minutes: 5);
    return now.difference(lastUpdated) < cacheValidDuration;
  }
}

typedef ReminderTabCache = TabCache<ReminderEntity>;
