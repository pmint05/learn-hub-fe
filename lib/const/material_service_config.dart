import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:learn_hub/const/constants.dart';

class FileUploadConfig {
  final File file;
  final PlatformFile fileInfo;
  final bool isPublic;
  final currentUserId = FirebaseAuth.instance.currentUser?.uid;

  FileUploadConfig({
    required this.file,
    required this.isPublic,
    required this.fileInfo,
  });

  Map<String, dynamic> toJson() {
    return {
      'user_id': currentUserId,
      'is_public': isPublic,
      'file': file,
      'file_info': fileInfo,
    };
  }
}

class SearchMaterialConfig {
  final String? currentUserId = FirebaseAuth.instance.currentUser?.uid;

  final String? searchText;
  final FileExtension? fileExtension;
  final bool isPublic;
  final String? minCreatedDate;
  final String? maxCreatedDate;
  final int size;
  final int start;

  SearchMaterialConfig({
    this.minCreatedDate,
    this.maxCreatedDate,
    this.fileExtension,
    required this.searchText,
    required this.isPublic,
    required this.size,
    required this.start,
  });

  Map<String, dynamic> toJson() {
    return {
      'user_id': currentUserId,
      'is_public': isPublic,
      if (searchText != null) 'filename': searchText,
      if (fileExtension != null) 'file_extension': fileExtension?.name,
      if (minCreatedDate != null) 'min_date': minCreatedDate,
      if (maxCreatedDate != null) 'max_date': maxCreatedDate,
      'size': size,
      'start': start,
    };
  }
}
