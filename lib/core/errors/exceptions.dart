// import 'package:cloud_firestore/cloud_firestore.dart' as firebase_firestore;
// import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
// import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;

// abstract class AppException implements Exception {
//   final String message;
//   final String? code;
//   final dynamic originalError;

//   const AppException(this.message, {this.code, this.originalError});

//   @override
//   String toString() => message;
// }

// // Server/API related exceptions
// class ServerException extends AppException {
//   const ServerException(String message, {String? code, dynamic originalError})
//     : super(message, code: code, originalError: originalError);
// }

// class NetworkException extends AppException {
//   const NetworkException(String message, {String? code, dynamic originalError})
//     : super(message, code: code, originalError: originalError);
// }

// class TimeoutException extends AppException {
//   const TimeoutException(String message, {String? code, dynamic originalError})
//     : super(message, code: code, originalError: originalError);
// }

// // Authentication related exceptions
// class AuthException extends AppException {
//   const AuthException(String message, {String? code, dynamic originalError})
//     : super(message, code: code, originalError: originalError);
// }

// class UnauthorizedException extends AuthException {
//   const UnauthorizedException(
//     String message, {
//     String? code,
//     dynamic originalError,
//   }) : super(message, code: code, originalError: originalError);
// }

// class TokenExpiredException extends AuthException {
//   const TokenExpiredException(
//     String message, {
//     String? code,
//     dynamic originalError,
//   }) : super(message, code: code, originalError: originalError);
// }

// // Cache related exceptions
// class CacheException extends AppException {
//   const CacheException(String message, {String? code, dynamic originalError})
//     : super(message, code: code, originalError: originalError);
// }

// // Validation exceptions
// class ValidationException extends AppException {
//   const ValidationException(
//     String message, {
//     String? code,
//     dynamic originalError,
//   }) : super(message, code: code, originalError: originalError);
// }

// // Database exceptions
// class DatabaseException extends AppException {
//   const DatabaseException(String message, {String? code, dynamic originalError})
//     : super(message, code: code, originalError: originalError);
// }

// // Firebase specific exceptions
// class FirebaseAuthException extends AuthException {
//   const FirebaseAuthException(
//     String message, {
//     String? code,
//     dynamic originalError,
//   }) : super(message, code: code, originalError: originalError);
// }

// class FirestoreException extends ServerException {
//   const FirestoreException(
//     String message, {
//     String? code,
//     dynamic originalError,
//   }) : super(message, code: code, originalError: originalError);
// }

// // Storage exceptions
// class StorageException extends AppException {
//   const StorageException(String message, {String? code, dynamic originalError})
//     : super(message, code: code, originalError: originalError);
// }

// // Permission exceptions
// class PermissionException extends AppException {
//   const PermissionException(
//     String message, {
//     String? code,
//     dynamic originalError,
//   }) : super(message, code: code, originalError: originalError);
// }

// // Not found exceptions
// class NotFoundException extends AppException {
//   const NotFoundException(String message, {String? code, dynamic originalError})
//     : super(message, code: code, originalError: originalError);
// }

// // User related exceptions
// class UserNotFoundException extends NotFoundException {
//   const UserNotFoundException(
//     String message, {
//     String? code,
//     dynamic originalError,
//   }) : super(message, code: code, originalError: originalError);
// }

// class UserAlreadyExistsException extends AppException {
//   const UserAlreadyExistsException(
//     String message, {
//     String? code,
//     dynamic originalError,
//   }) : super(message, code: code, originalError: originalError);
// }

// // Couple related exceptions
// class CoupleNotFoundException extends NotFoundException {
//   const CoupleNotFoundException(
//     String message, {
//     String? code,
//     dynamic originalError,
//   }) : super(message, code: code, originalError: originalError);
// }

// class CoupleAlreadyExistsException extends AppException {
//   const CoupleAlreadyExistsException(
//     String message, {
//     String? code,
//     dynamic originalError,
//   }) : super(message, code: code, originalError: originalError);
// }

// // Note related exceptions
// class NoteNotFoundException extends NotFoundException {
//   const NoteNotFoundException(
//     String message, {
//     String? code,
//     dynamic originalError,
//   }) : super(message, code: code, originalError: originalError);
// }

// // Media related exceptions
// class MediaUploadException extends AppException {
//   const MediaUploadException(
//     String message, {
//     String? code,
//     dynamic originalError,
//   }) : super(message, code: code, originalError: originalError);
// }

// class MediaDownloadException extends AppException {
//   const MediaDownloadException(
//     String message, {
//     String? code,
//     dynamic originalError,
//   }) : super(message, code: code, originalError: originalError);
// }

// // Notification exceptions
// class NotificationException extends AppException {
//   const NotificationException(
//     String message, {
//     String? code,
//     dynamic originalError,
//   }) : super(message, code: code, originalError: originalError);
// }

// // Synchronization exceptions
// class SyncException extends AppException {
//   const SyncException(String message, {String? code, dynamic originalError})
//     : super(message, code: code, originalError: originalError);
// }

// // Rate limiting exceptions
// class RateLimitException extends AppException {
//   const RateLimitException(
//     String message, {
//     String? code,
//     dynamic originalError,
//   }) : super(message, code: code, originalError: originalError);
// }

// // Payment/Subscription exceptions
// class PaymentException extends AppException {
//   const PaymentException(String message, {String? code, dynamic originalError})
//     : super(message, code: code, originalError: originalError);
// }

// class SubscriptionException extends AppException {
//   const SubscriptionException(
//     String message, {
//     String? code,
//     dynamic originalError,
//   }) : super(message, code: code, originalError: originalError);
// }

// // Helper class for exception handling
// class ExceptionHandler {
//   static AppException handleFirebaseAuthException(dynamic error) {
//     if (error is firebase_auth.FirebaseAuthException) {
//       switch (error.code) {
//         case 'user-not-found':
//           return const UserNotFoundException('User not found');
//         case 'wrong-password':
//           return const AuthException('Invalid password');
//         case 'user-disabled':
//           return const AuthException('User account has been disabled');
//         case 'too-many-requests':
//           return const RateLimitException(
//             'Too many requests. Please try again later',
//           );
//         case 'operation-not-allowed':
//           return const AuthException('Operation not allowed');
//         case 'invalid-email':
//           return const ValidationException('Invalid email address');
//         case 'email-already-in-use':
//           return const UserAlreadyExistsException('Email already in use');
//         case 'weak-password':
//           return const ValidationException('Password is too weak');
//         case 'network-request-failed':
//           return const NetworkException('Network request failed');
//         case 'requires-recent-login':
//           return const AuthException('Please login again to continue');
//         default:
//           return FirebaseAuthException(
//             error.message ?? 'Authentication failed',
//             code: error.code,
//             originalError: error,
//           );
//       }
//     }
//     return AuthException(
//       'Authentication failed: ${error.toString()}',
//       originalError: error,
//     );
//   }

//   static AppException handleFirestoreException(dynamic error) {
//     if (error is firebase_firestore.FirebaseException) {
//       switch (error.code) {
//         case 'permission-denied':
//           return const PermissionException('Permission denied');
//         case 'not-found':
//           return const NotFoundException('Document not found');
//         case 'already-exists':
//           return const ValidationException('Document already exists');
//         case 'resource-exhausted':
//           return const RateLimitException('Resource exhausted');
//         case 'failed-precondition':
//           return const ValidationException('Failed precondition');
//         case 'aborted':
//           return const ServerException('Operation aborted');
//         case 'out-of-range':
//           return const ValidationException('Out of range');
//         case 'unimplemented':
//           return const ServerException('Unimplemented');
//         case 'internal':
//           return const ServerException('Internal server error');
//         case 'unavailable':
//           return const NetworkException('Service unavailable');
//         case 'data-loss':
//           return const ServerException('Data loss');
//         case 'unauthenticated':
//           return const UnauthorizedException('Unauthenticated');
//         case 'deadline-exceeded':
//           return const TimeoutException('Request timeout');
//         default:
//           return FirestoreException(
//             error.message ?? 'Firestore error',
//             code: error.code,
//             originalError: error,
//           );
//       }
//     }
//     return ServerException(
//       'Database error: ${error.toString()}',
//       originalError: error,
//     );
//   }

//   static AppException handleStorageException(dynamic error) {
//     if (error is firebase_storage.FirebaseException) {
//       switch (error.code) {
//         case 'object-not-found':
//           return const NotFoundException('File not found');
//         case 'bucket-not-found':
//           return const NotFoundException('Bucket not found');
//         case 'project-not-found':
//           return const NotFoundException('Project not found');
//         case 'quota-exceeded':
//           return const RateLimitException('Storage quota exceeded');
//         case 'unauthenticated':
//           return const UnauthorizedException('Unauthenticated');
//         case 'unauthorized':
//           return const PermissionException('Unauthorized');
//         case 'retry-limit-exceeded':
//           return const NetworkException('Retry limit exceeded');
//         case 'invalid-checksum':
//           return const ValidationException('Invalid checksum');
//         case 'canceled':
//           return const MediaUploadException('Upload canceled');
//         default:
//           return StorageException(
//             error.message ?? 'Storage error',
//             code: error.code,
//             originalError: error,
//           );
//       }
//     }
//     return StorageException(
//       'Storage error: ${error.toString()}',
//       originalError: error,
//     );
//   }

//   static AppException handleGenericException(dynamic error) {
//     if (error is AppException) {
//       return error;
//     }

//     if (error is firebase_auth.FirebaseAuthException) {
//       return handleFirebaseAuthException(error);
//     }

//     if (error is firebase_firestore.FirebaseException) {
//       return handleFirestoreException(error);
//     }

//     if (error is firebase_storage.FirebaseException) {
//       return handleStorageException(error);
//     }

//     return ServerException(
//       'An unexpected error occurred: ${error.toString()}',
//       originalError: error,
//     );
//   }
// }

// // Common exception messages
// class ExceptionMessages {
//   static const String networkError = 'Network connection error';
//   static const String serverError = 'Server error occurred';
//   static const String authError = 'Authentication failed';
//   static const String permissionDenied = 'Permission denied';
//   static const String userNotFound = 'User not found';
//   static const String invalidInput = 'Invalid input provided';
//   static const String operationFailed = 'Operation failed';
//   static const String timeout = 'Request timeout';
//   static const String unknown = 'Unknown error occurred';
// }
