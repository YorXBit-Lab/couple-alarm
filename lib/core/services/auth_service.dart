import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/services.dart';
import 'dart:async';

class AuthException implements Exception {
  final String message;
  final String code;

  AuthException(this.message, {this.code = 'unknown'});

  @override
  String toString() => 'AuthException: $message (Code: $code)';
}

class AuthService {
  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;
  GoogleSignInAccount? _currentUser;
  StreamSubscription<GoogleSignInAuthenticationEvent>? _authSubscription;
  bool _isInitialized = false;
  final List<String> _scopes;
  final String? _hostedDomain;

  AuthService({
    FirebaseAuth? firebaseAuth,
    List<String>? scopes,
    String? hostedDomain,
  }) : _auth = firebaseAuth ?? FirebaseAuth.instance,
       _googleSignIn = GoogleSignIn.instance,
       _scopes = scopes ?? ['email'], // Thêm scope mặc định
       _hostedDomain = hostedDomain {
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      if (_isInitialized) return;

      await _googleSignIn.initialize(hostedDomain: _hostedDomain);

      _authSubscription = _googleSignIn.authenticationEvents.listen(
        _handleAuthenticationEvent,
        onError: _handleAuthenticationError,
      );

      _isInitialized = true;
    } catch (e) {
      throw AuthException(
        'Failed to initialize Google Sign-In: ${e.toString()}',
      );
    }
  }

  Future<void> _handleAuthenticationEvent(
    GoogleSignInAuthenticationEvent event,
  ) async {
    _currentUser = switch (event) {
      GoogleSignInAuthenticationEventSignIn() => event.user,
      GoogleSignInAuthenticationEventSignOut() => null,
    };
  }

  Future<void> _handleAuthenticationError(Object e) async {
    _currentUser = null;
    debugPrint('Google Sign-In stream error: $e');
  }

  Future<UserCredential> _signInToFirebase(
    GoogleSignInAccount googleUser,
  ) async {
    try {
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      String? accessToken;

      // Chỉ lấy accessToken nếu có scopes
      if (_scopes.isNotEmpty) {
        try {
          final GoogleSignInClientAuthorization? authorization =
              await googleUser.authorizationClient.authorizationForScopes(
                _scopes,
              );

          if (authorization != null) {
            accessToken = authorization.accessToken;
          }
        } catch (e) {
          debugPrint('Failed to get authorization: $e');
        }
      }

      final credential = GoogleAuthProvider.credential(
        accessToken: accessToken,
        idToken: googleAuth.idToken,
      );

      return await _auth.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      throw AuthException(_getFirebaseAuthErrorMessage(e.code), code: e.code);
    } on FirebaseException catch (e) {
      throw AuthException(
        'Lỗi Firebase: ${e.message}',
        code: e.code ?? 'firebase-error',
      );
    }
  }

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  GoogleSignInAccount? get currentGoogleUser => _currentUser;

  bool get isSignedIn => _auth.currentUser != null;

  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Nếu có scopes, sử dụng scopeHint
      final GoogleSignInAccount? googleUser = _scopes.isNotEmpty
          ? await _googleSignIn.authenticate(scopeHint: _scopes)
          : await _googleSignIn.authenticate();

      if (googleUser != null) {
        debugPrint('Google sign-in successful for user: ${googleUser.email}');
        return await _signInToFirebase(googleUser);
      } else {
        throw AuthException('Google sign-in was cancelled', code: 'canceled');
      }
    } on GoogleSignInException catch (e) {
      debugPrint('GoogleSignInException: ${e.code} - ${e.description}');
      throw AuthException(
        _errorMessageFromSignInException(e),
        code: e.code.name,
      );
    } on AuthException {
      rethrow;
    } catch (e) {
      debugPrint('Unexpected error during Google sign-in: $e');
      throw AuthException(
        'Unexpected error during Google sign-in: ${e.toString()}',
        code: 'unexpected',
      );
    }
  }

  Future<void> signOut() async {
    try {
      await Future.wait([_auth.signOut(), _googleSignIn.signOut()]);
    } catch (e) {
      throw AuthException(
        'Unexpected error during sign out: ${e.toString()}',
        code: 'unexpected',
      );
    }
  }

  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw AuthException('No user is currently signed in', code: 'no-user');
    }

    try {
      final lastSignInTime = user.metadata.lastSignInTime;
      if (lastSignInTime != null &&
          DateTime.now().difference(lastSignInTime).inMinutes > 5) {
        await _reauthenticateUser(user);
      }

      await user.delete();
      await _googleSignIn.disconnect();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        await _reauthenticateUser(user);
        await deleteAccount();
      } else {
        throw AuthException(_getFirebaseAuthErrorMessage(e.code), code: e.code);
      }
    } catch (e) {
      throw AuthException(
        'Unexpected error during account deletion: ${e.toString()}',
        code: 'unexpected',
      );
    }
  }

  Future<void> _reauthenticateUser(User user) async {
    try {
      if (_currentUser == null) {
        throw AuthException('No Google user available for reauthentication');
      }

      final GoogleSignInAuthentication googleAuth =
          await _currentUser!.authentication;

      String? accessToken;

      if (_scopes.isNotEmpty) {
        try {
          final GoogleSignInClientAuthorization? authorization =
              await _currentUser!.authorizationClient.authorizationForScopes(
                _scopes,
              );

          if (authorization != null) {
            accessToken = authorization.accessToken;
          }
        } catch (e) {
          debugPrint('Failed to get authorization for reauth: $e');
        }
      }

      final credential = GoogleAuthProvider.credential(
        accessToken: accessToken,
        idToken: googleAuth.idToken,
      );

      await user.reauthenticateWithCredential(credential);
    } catch (e) {
      throw AuthException(
        'Unexpected error during re-authentication: ${e.toString()}',
        code: 'unexpected',
      );
    }
  }

  // Request specific scopes for Google APIs
  Future<void> requestScopes(List<String> scopes) async {
    if (_currentUser == null) {
      throw AuthException('No user is currently signed in', code: 'no-user');
    }

    if (scopes.isEmpty) {
      throw AuthException(
        'Scopes list cannot be empty',
        code: 'invalid-argument',
      );
    }

    try {
      await _currentUser!.authorizationClient.authorizeScopes(scopes);
    } on GoogleSignInException catch (e) {
      throw AuthException(
        _errorMessageFromSignInException(e),
        code: e.code.name,
      );
    }
  }

  // Get authorization headers for Google APIs
  Future<Map<String, String>?> getAuthorizationHeaders() async {
    if (_currentUser == null) {
      throw AuthException('No user is currently signed in', code: 'no-user');
    }

    if (_scopes.isEmpty) {
      throw AuthException(
        'No scopes configured. Cannot get authorization headers',
        code: 'no-scopes',
      );
    }

    try {
      return await _currentUser!.authorizationClient.authorizationHeaders(
        _scopes,
      );
    } catch (e) {
      throw AuthException(
        'Failed to get authorization headers: ${e.toString()}',
        code: 'unexpected',
      );
    }
  }

  // Check if user has authorized specific scopes
  Future<bool> hasAuthorizedScopes(List<String> scopes) async {
    if (_currentUser == null) return false;
    if (scopes.isEmpty) return false;

    try {
      final authorization = await _currentUser!.authorizationClient
          .authorizationForScopes(scopes);
      return authorization != null;
    } catch (e) {
      return false;
    }
  }

  // Get server auth code for backend authentication
  Future<String?> getServerAuthCode() async {
    if (_currentUser == null) {
      throw AuthException('No user is currently signed in', code: 'no-user');
    }

    if (_scopes.isEmpty) {
      throw AuthException(
        'No scopes configured. Cannot get server auth code',
        code: 'no-scopes',
      );
    }

    try {
      final serverAuth = await _currentUser!.authorizationClient
          .authorizeServer(_scopes);
      return serverAuth?.serverAuthCode;
    } on GoogleSignInException catch (e) {
      throw AuthException(
        _errorMessageFromSignInException(e),
        code: e.code.name,
      );
    }
  }

  Map<String, dynamic>? get userProfile {
    final user = _auth.currentUser;
    if (user == null) return null;

    return {
      'uid': user.uid,
      'email': user.email,
      'displayName': user.displayName,
      'photoURL': user.photoURL,
      'emailVerified': user.emailVerified,
      'isAnonymous': user.isAnonymous,
      'creationTime': user.metadata.creationTime?.toIso8601String(),
      'lastSignInTime': user.metadata.lastSignInTime?.toIso8601String(),
    };
  }

  Map<String, dynamic>? get googleUserProfile {
    final user = _currentUser;
    if (user == null) return null;

    return {
      'id': user.id,
      'email': user.email,
      'displayName': user.displayName,
      'photoUrl': user.photoUrl,
    };
  }

  Future<void> updateProfile({String? displayName, String? photoURL}) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw AuthException('No user is currently signed in', code: 'no-user');
    }

    try {
      await user.updateDisplayName(displayName);
      if (photoURL != null) {
        await user.updatePhotoURL(photoURL);
      }
      await user.reload();
    } catch (e) {
      throw AuthException(
        'Unexpected error during profile update: ${e.toString()}',
        code: 'unexpected',
      );
    }
  }

  void dispose() {
    _authSubscription?.cancel();
  }

  String _errorMessageFromSignInException(GoogleSignInException e) {
    return switch (e.code) {
      GoogleSignInExceptionCode.canceled => 'Đăng nhập đã bị huỷ',
      GoogleSignInExceptionCode.clientConfigurationError =>
        'Lỗi cấu hình client',
      GoogleSignInExceptionCode.interrupted => 'Đăng nhập bị gián đoạn',
      GoogleSignInExceptionCode.providerConfigurationError =>
        'Lỗi không xác định: Lỗi cấu hình provider',
      GoogleSignInExceptionCode.uiUnavailable =>
        'Giao diện đăng nhập không khả dụng',
      GoogleSignInExceptionCode.unknownError => 'Lỗi không xác định',
      GoogleSignInExceptionCode.userMismatch => 'Người dùng không khớp',
      GoogleSignInExceptionCode.values =>
        'Lỗi không xác định: ${e.description}',
      _ => 'Lỗi không xác định: ${e.description}',
    };
  }

  String _getFirebaseAuthErrorMessage(String code) {
    switch (code) {
      case 'account-exists-with-different-credential':
        return 'Tài khoản đã tồn tại với thông tin đăng nhập khác';
      case 'invalid-credential':
        return 'Thông tin đăng nhập không hợp lệ';
      case 'operation-not-allowed':
        return 'Thao tác không được phép';
      case 'user-disabled':
        return 'Tài khoản đã bị vô hiệu hóa';
      case 'user-not-found':
        return 'Không tìm thấy tài khoản';
      case 'wrong-password':
        return 'Mật khẩu không đúng';
      case 'invalid-verification-code':
        return 'Mã xác minh không hợp lệ';
      case 'invalid-verification-id':
        return 'ID xác minh không hợp lệ';
      case 'network-request-failed':
        return 'Lỗi kết nối mạng';
      case 'too-many-requests':
        return 'Quá nhiều yêu cầu. Vui lòng thử lại sau';
      case 'requires-recent-login':
        return 'Yêu cầu đăng nhập gần đây để thực hiện thao tác này';
      case 'weak-password':
        return 'Mật khẩu quá yếu';
      case 'email-already-in-use':
        return 'Email đã được sử dụng bởi tài khoản khác';
      case 'invalid-email':
        return 'Email không hợp lệ';
      case 'app-check-error':
        return 'Lỗi xác minh bảo mật ứng dụng';
      default:
        return 'Đã xảy ra lỗi không xác định';
    }
  }
}

class MockUserCredential implements UserCredential {
  @override
  final User user;

  MockUserCredential(this.user);

  @override
  AdditionalUserInfo? get additionalUserInfo => null;

  @override
  AuthCredential? get credential => null;
}
