final emailRegex = RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+");
final usernameRegex = RegExp(r"^[a-zA-Z0-9._-]{5,}$");
enum DifficultyLevel {
  all,
  easy,
  medium,
  hard,
}

enum FileExtension {
  all,
  pdf,
  docx,
  doc,
  txt,
  md
}

enum SortOption { nameAsc, nameDesc, dateAsc, dateDesc, sizeAsc, sizeDesc }