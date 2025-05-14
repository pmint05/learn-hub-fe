import 'package:firebase_auth/firebase_auth.dart';

class CreateResultConfig {
  final String? currentUserId = FirebaseAuth.instance.currentUser?.uid;
  final String quizId;

  CreateResultConfig({required this.quizId});

  Map<String, dynamic> toJson() {
    return {'user_id': currentUserId, 'quiz_id': quizId};
  }
}

class GetResultsByUserIdConfig {
  final String? currentUserId = FirebaseAuth.instance.currentUser?.uid;
  final int? size;
  final int? start;
  final String? sortBy;
  final int? sortOrder;

  GetResultsByUserIdConfig({
    this.size,
    this.start,
    this.sortBy = 'last_modified_date',
    this.sortOrder = -1,
  });

  Map<String, dynamic> toJson() {
    return {
      'user_id': currentUserId,
      if (size != null) 'limit': size,
      if (start != null) 'skip': start,
      if (sortBy != null) 'sort_by': sortBy,
      if (sortOrder != null) 'sort_order': sortOrder,
    };
  }}