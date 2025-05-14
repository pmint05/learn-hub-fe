import 'package:firebase_auth/firebase_auth.dart';
import 'package:learn_hub/const/constants.dart';

class SearchQuizConfig {
  final String? currentUserId = FirebaseAuth.instance.currentUser?.uid;

  final String? searchText;
  final bool? isPublic;
  final List<String>? categories;
  final DifficultyLevel? difficulty;
  final String? minCreatedDate;
  final String? maxCreatedDate;
  final String? minLastModifiedDate;
  final String? maxLastModifiedDate;
  final int? size;
  final int? start;
  final bool includeUserId;
  final String? sortBy;
  final int? sortOrder;

  SearchQuizConfig({
    this.minCreatedDate,
    this.maxCreatedDate,
    this.minLastModifiedDate,
    this.maxLastModifiedDate,
    this.categories,
    this.difficulty,
    required this.searchText,
    this.isPublic,
    required this.includeUserId,
    this.size,
    this.start,
    this.sortBy,
    this.sortOrder,
  });

  Map<String, dynamic> toJson() {
    return {
      if (includeUserId) 'user_id': currentUserId,
      if (searchText != null && searchText!.isNotEmpty) 'title': searchText,
      if (isPublic != null) 'is_public': isPublic,
      if (categories != null) 'categories': categories,
      if (difficulty != null) 'difficulty': difficulty?.name,
      if (minCreatedDate != null) 'min_created_date': minCreatedDate,
      if (maxCreatedDate != null) 'max_created_date': maxCreatedDate,
      if (minLastModifiedDate != null)
        'min_last_modified_date': minLastModifiedDate,
      if (maxLastModifiedDate != null)
        'max_last_modified_date': maxLastModifiedDate,
      if (size != null) 'size': size,
      if (start != null) 'start': start,
      if (sortBy != null && sortOrder != null) ...{
        'sort_by': sortBy,
        'sort_order': sortOrder,
      },
    };
  }
}
