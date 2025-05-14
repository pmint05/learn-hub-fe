import 'dart:ui';

final emailRegex = RegExp(
  r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+",
);
final usernameRegex = RegExp(r"^[a-zA-Z0-9._-]{5,}$");

enum DifficultyLevel { all, easy, medium, hard, unknown }

enum FileExtension { all, pdf, docx, doc, txt, md }

enum SortOption { nameAsc, nameDesc, dateAsc, dateDesc, sizeAsc, sizeDesc }

enum QuestionType {
  multipleChoice,
  trueFalse,
  fillInTheBlank,
  shortAnswer,
  essay,
}

final availableCategories = [
  {
    "name": "Mathematics",
    "description": "Knowledge and quizzes related to mathematics.",
    "icon": "📐",
    "color": Color(0xFFF44336),
  },
  {
    "name": "Physics",
    "description": "Physics laws, mechanics, electricity, and more.",
    "icon": "🔭",
    "color": Color(0xFF3F51B5),
  },
  {
    "name": "Chemistry",
    "description": "Chemical reactions, elements, and periodic table.",
    "icon": "⚗️",
    "color": Color(0xFF009688),
  },
  {
    "name": "Biology",
    "description": "Life sciences, organisms, and ecosystems.",
    "icon": "🧬",
    "color": Color(0xFF4CAF50),
  },
  {
    "name": "History",
    "description": "Events, civilizations, and historical figures.",
    "icon": "📜",
    "color": Color(0xFF795548),
  },
  {
    "name": "Geography",
    "description": "Maps, countries, and geographical knowledge.",
    "icon": "🌍",
    "color": Color(0xFF2196F3),
  },
  {
    "name": "English",
    "description": "Grammar, vocabulary, and comprehension.",
    "icon": "📘",
    "color": Color(0xFF3F51B5),
  },
  {
    "name": "Literature",
    "description": "Prose, poetry, and literary analysis.",
    "icon": "📖",
    "color": Color(0xFF9C27B0),
  },
  {
    "name": "Informatics",
    "description": "Computing, algorithms, and data handling.",
    "icon": "💻",
    "color": Color(0xFF607D8B),
  },
  {
    "name": "Civics",
    "description": "Law, society, and moral education.",
    "icon": "⚖️",
    "color": Color(0xFFFF9800),
  },
  {
    "name": "Technology",
    "description": "Engineering, tools, and innovation.",
    "icon": "🛠️",
    "color": Color(0xFF795548),
  },
  {
    "name": "Astronomy",
    "description": "Planets, stars, and space exploration.",
    "icon": "🌌",
    "color": Color(0xFF673AB7),
  },
  {
    "name": "Programming",
    "description": "Coding languages, logic, and projects.",
    "icon": "👨‍💻",
    "color": Color(0xFF4CAF50),
  },
  {
    "name": "Psychology",
    "description": "Mind, behavior, and human psychology.",
    "icon": "🧠",
    "color": Color(0xFF9E9E9E),
  },
  {
    "name": "Philosophy",
    "description": "Thinking, logic, and philosophical questions.",
    "icon": "📚",
    "color": Color(0xFF607D8B),
  },
  {
    "name": "Economics",
    "description": "Supply, demand, and market systems.",
    "icon": "💰",
    "color": Color(0xFF8BC34A),
  },
  {
    "name": "Politics",
    "description": "Governments, ideologies, and political theory.",
    "icon": "🏛️",
    "color": Color(0xFFFFC107),
  },
  {
    "name": "Art",
    "description": "Visual arts, creativity, and aesthetics.",
    "icon": "🎨",
    "color": Color(0xFFE91E63),
  },
  {
    "name": "Music",
    "description": "Theory, instruments, and famous compositions.",
    "icon": "🎵",
    "color": Color(0xFF00BCD4),
  },
  {
    "name": "Sports",
    "description": "Games, physical activity, and health.",
    "icon": "⚽",
    "color": Color(0xFFFF5722),
  },
  {
    "name": "Others",
    "description": "General quizzes and miscellaneous topics.",
    "icon": "📦",
    "color": Color(0xFF9E9E9E),
  },
];

final commonFirebaseErrors = {
  'auth/claims-too-large':
      'The claims payload exceeds the maximum allowed size.',
  'auth/email-already-exists':
      'The email is already in use by another account.',
  'auth/id-token-expired': 'Your session has expired. Please log in again.',
  'auth/id-token-revoked':
      'Your session has been revoked. Please log in again.',
  'auth/insufficient-permission':
      'Insufficient permissions to perform this action.',
  'auth/internal-error':
      'An unexpected error occurred. Please try again later.',
  'auth/invalid-argument': 'An invalid argument was provided.',
  'auth/invalid-claims': 'The custom claims provided are invalid.',
  'auth/invalid-continue-uri': 'The continue URL is invalid.',
  'auth/invalid-creation-time':
      'The creation time must be a valid UTC date string.',
  'auth/invalid-credential': 'The provided credential is invalid.',
  'auth/invalid-disabled-field': 'The disabled field must be a boolean.',
  'auth/invalid-display-name': 'The display name must be a non-empty string.',
  'auth/invalid-dynamic-link-domain':
      'The dynamic link domain is not authorized.',
  'auth/invalid-email': 'The email address is invalid.',
  'auth/invalid-email-verified': 'The email verified field must be a boolean.',
  'auth/invalid-hash-algorithm': 'The hash algorithm is not supported.',
  'auth/invalid-hash-block-size': 'The hash block size must be valid.',
  'auth/invalid-hash-derived-key-length':
      'The hash derived key length must be valid.',
  'auth/invalid-hash-key': 'The hash key must be a valid byte buffer.',
  'auth/invalid-hash-memory-cost': 'The hash memory cost must be valid.',
  'auth/invalid-hash-parallelization':
      'The hash parallelization must be valid.',
  'auth/invalid-hash-rounds': 'The hash rounds must be valid.',
  'auth/invalid-hash-salt-separator': 'The hash salt separator must be valid.',
  'auth/invalid-id-token': 'The ID token is invalid.',
  'auth/invalid-last-sign-in-time':
      'The last sign-in time must be a valid UTC date string.',
  'auth/invalid-page-token': 'The page token is invalid.',
  'auth/invalid-password': 'The password must be at least six characters long.',
  'auth/invalid-password-hash': 'The password hash must be valid.',
  'auth/invalid-password-salt': 'The password salt must be valid.',
  'auth/invalid-phone-number': 'The phone number is invalid.',
  'auth/invalid-photo-url': 'The photo URL is invalid.',
  'auth/invalid-provider-data': 'The provider data must be valid.',
  'auth/invalid-provider-id': 'The provider ID is invalid.',
  'auth/invalid-oauth-responsetype':
      'Only one OAuth response type should be set to true.',
  'auth/invalid-session-cookie-duration':
      'The session cookie duration must be between 5 minutes and 2 weeks.',
  'auth/invalid-uid':
      'The UID must be a non-empty string with at most 128 characters.',
  'auth/invalid-user-import': 'The user record to import is invalid.',
  'auth/maximum-user-count-exceeded':
      'The maximum number of users to import has been exceeded.',
  'auth/missing-android-pkg-name': 'An Android package name is required.',
  'auth/missing-continue-uri': 'A valid continue URL is required.',
  'auth/missing-hash-algorithm':
      'A hashing algorithm is required to import users with password hashes.',
  'auth/missing-ios-bundle-id': 'A Bundle ID is required.',
  'auth/missing-uid': 'A UID is required for this operation.',
  'auth/missing-oauth-client-secret': 'The OAuth client secret is required.',
  'auth/operation-not-allowed':
      'This operation is not allowed. Enable it in the Firebase console.',
  'auth/phone-number-already-exists':
      'The phone number is already in use by another account.',
  'auth/project-not-found':
      'No Firebase project was found for the provided credentials.',
  'auth/reserved-claims':
      'One or more custom claims are reserved and cannot be used.',
  'auth/session-cookie-expired': 'The session cookie has expired.',
  'auth/session-cookie-revoked': 'The session cookie has been revoked.',
  'auth/too-many-requests': 'Too many requests. Please try again later.',
  'auth/uid-already-exists': 'The UID is already in use by another account.',
  'auth/unauthorized-continue-uri':
      'The domain of the continue URL is not whitelisted.',
  'auth/user-not-found': 'No user found for the provided identifier.',
};
