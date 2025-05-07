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

  GetResultsByUserIdConfig({
    this.size,
    this.start,
  });

  Map<String, dynamic> toJson() {
    return {
      'user_id': currentUserId,
      if (size != null) 'size': size,
      if (start != null) 'start': start,
    };
  }}