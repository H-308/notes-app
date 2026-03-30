/// Application-wide constants
class AppConstants {
  // Firestore Collections
  static const String usersCollection = 'users';
  static const String notesCollection = 'notes';

  // Error Messages
  static const String emailInUseError = 'Email is already in use';
  static const String userNotFoundError = 'User not found';
  static const String wrongPasswordError = 'Wrong password';
  static const String invalidEmailError = 'Invalid email address';
  static const String weakPasswordError = 'Password is too weak';
  static const String userDisabledError = 'User account is disabled';
  static const String networkError = 'Network error occurred';
  static const String unknownError = 'An unknown error occurred';
  static const String locationError = 'Failed to get location';

  // Validation
  static const int minPasswordLength = 6;
  static const int minTitleLength = 1;
  static const int minBodyLength = 1;

  // Location Israel
  static const double defaultLatitude = 31.5;
  static const double defaultLongitude = 34.75;
  static const double defaultZoom = 7.5;

  // UI Constants
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Duration locationFetchTimeout = Duration(seconds: 30);
}
