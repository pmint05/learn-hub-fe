import 'package:firebase_auth/firebase_auth.dart';
import 'package:learn_hub/const/constants.dart';

class SearchQuizConfig {
  final String? currentUserId = FirebaseAuth.instance.currentUser?.uid;

  final String? searchText;
  final bool isPublic;
  final List<String>? categories;
  final DifficultyLevel? difficulty;
  final String? minCreatedDate;
  final String? maxCreatedDate;
  final String? minLastModifiedDate;
  final String? maxLastModifiedDate;
  final int size;
  final int start;

  SearchQuizConfig({
    this.minCreatedDate,
    this.maxCreatedDate,
    this.minLastModifiedDate,
    this.maxLastModifiedDate,
    this.categories,
    this.difficulty,
    required this.searchText,
    required this.isPublic,
    required this.size,
    required this.start,
  });

  Map<String, dynamic> toJson() {
    return {
      'user_id': currentUserId,
      'search_text': searchText,
      'is_public': isPublic,
      'categories': categories,
      'difficulty': difficulty?.name,
      'min_created_date': minCreatedDate,
      'max_created_date': maxCreatedDate,
      'min_last_modified_date': minLastModifiedDate,
      'max_last_modified_date': maxLastModifiedDate,
      'size': size,
      'start': start,
    };
  }

}
