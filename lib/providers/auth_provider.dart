import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'badge_provider.dart';
import 'history_provider.dart';
import 'streak_provider.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../models/user_profile.dart';

/// The four possible authentication states of the app
enum AuthStatus {
  /// Initial state — still waiting for Firebase to resolve
  unknown,
  /// User is signed in with a real Firebase account
  authenticated,
  /// User has no Firebase account and is not signed in
  unauthenticated,
  /// User chose to skip login and use the app locally only
  guest,
}

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();

  AuthStatus _status = AuthStatus.unknown;
  User? _firebaseUser;
  UserProfile? _userProfile;
  bool _isLoading = false;
  String? _errorMessage;
  VoidCallback? onAuthResolved;

  // ── Getters ────────────────────────────────────────────────────

  AuthStatus get status => _status;
  User? get firebaseUser => _firebaseUser;
  UserProfile? get userProfile => _userProfile;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isGuest => _status == AuthStatus.guest;
  bool get isLoggedIn => _status == AuthStatus.authenticated;

  /// Display name — prefers Firestore profile, falls back to Firebase
  /// user display name, then defaults to "PhishCatch User"
  String get displayName =>
      _userProfile?.displayName ??
      _firebaseUser?.displayName ??
      'PhishCatch User';

  /// Email of the signed-in user, empty string if guest
  String get email => _firebaseUser?.email ?? '';

  /// UID of the signed-in user, null if guest
  String? get uid => _firebaseUser?.uid;

  /// Avatar initials derived from display name
  /// "John Doe" → "JD", "Alice" → "A", unknown → "U"
  String get initials {
    final name = displayName;
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : 'U';
  }

  // ── Constructor ────────────────────────────────────────────────

  AuthProvider() {
    // Listen to Firebase auth state for the entire lifetime of this provider
    _authService.authStateChanges.listen(_onAuthStateChanged);
  }

  // ── Auth state listener ────────────────────────────────────────

  Future<void> _onAuthStateChanged(User? user) async {
    _firebaseUser = user;

    if (user != null) {
      _status = AuthStatus.authenticated;
      _userProfile = await _firestoreService.getUserProfile(user.uid);
      notifyListeners();

      // Trigger data reload on every authentication event.
      onAuthResolved?.call();

      // Then trigger history load from Firestore in the background
      // This is called from outside via initHistory — see note below
    } else if (_status != AuthStatus.guest) {
      _status = AuthStatus.unauthenticated;
      _userProfile = null;
      notifyListeners();
    }
    // If status is guest, do nothing — guest state is managed manually
  }

  /// Call this from main.dart or HomeScaffold after providers are ready.
  /// Loads user-scoped data for history, streak, and badge progress.
  Future<void> initUserData(
    HistoryProvider historyProvider,
    StreakProvider streakProvider,
    BadgeProvider badgeProvider,
  ) async {
    final userUid = _firebaseUser?.uid;

    await historyProvider.init(uid: userUid);
    await streakProvider.init(uid: userUid);

    if (userUid != null) {
      await badgeProvider.loadFromCloud(userUid);
    }
  }

  // ── Sign in ────────────────────────────────────────────────────

  /// Sign in with email and password
  /// Returns true on success, false on failure
  /// Sets errorMessage on failure for display in UI
  Future<bool> signIn(String email, String password) async {
    _setLoading(true);

    try {
      await _authService.signInWithEmail(email, password);
      _setLoading(false);
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _authService.getErrorMessage(e);
      _setLoading(false);
      return false;
    } catch (_) {
      _errorMessage = 'Something went wrong. Please try again.';
      _setLoading(false);
      return false;
    }
  }

  // ── Sign up ────────────────────────────────────────────────────

  /// Create a new account and Firestore profile
  /// Returns true on success, false on failure
  /// Sets errorMessage on failure for display in UI
  Future<bool> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    _setLoading(true);

    try {
      final credential = await _authService.signUpWithEmail(
        email: email,
        password: password,
        displayName: displayName,
      );

      if (credential.user != null) {
        final profile = UserProfile(
          uid: credential.user!.uid,
          displayName: displayName.trim(),
          email: email.trim(),
          createdAt: DateTime.now(),
        );
        await _firestoreService.createUserProfile(profile);
        _userProfile = profile;
      }

      _setLoading(false);
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _authService.getErrorMessage(e);
      _setLoading(false);
      return false;
    } catch (_) {
      _errorMessage = 'Something went wrong. Please try again.';
      _setLoading(false);
      return false;
    }
  }

  // ── Guest mode ─────────────────────────────────────────────────

  /// Set the app into guest mode — no Firebase account
  /// Data stays on device only via Hive/SharedPreferences
  void continueAsGuest() {
    _status = AuthStatus.guest;
    _firebaseUser = null;
    _userProfile = null;
    notifyListeners();
  }

  // ── Sign out ───────────────────────────────────────────────────

  /// Sign out the current user or clear guest state
  /// Always navigates back to unauthenticated state
  Future<void> signOut() async {
    if (_status == AuthStatus.authenticated) {
      await _authService.signOut();
    }
    _status = AuthStatus.unauthenticated;
    _userProfile = null;
    _firebaseUser = null;
    notifyListeners();
  }

  // ── Delete account ─────────────────────────────────────────────

  /// Permanently delete the Firebase account
  /// Returns true on success, false on failure
  /// Note: user must have signed in recently — if session is old
  /// this will fail with requires-recent-login error
  Future<bool> deleteAccount() async {
    try {
      await _authService.deleteAccount();
      _status = AuthStatus.unauthenticated;
      _userProfile = null;
      _firebaseUser = null;
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  // ── Utility ────────────────────────────────────────────────────

  /// Clear the current error message
  /// Call this when the user dismisses an error or starts a new action
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}

