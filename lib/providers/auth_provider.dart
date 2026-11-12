import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/models/user_model.dart';
import '../data/repositories/auth_repository.dart';
import '../data/services/local_storage_service.dart';

final localStorageServiceProvider = Provider<LocalStorageService>(
  (ref) => LocalStorageService(),
);

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(),
);

/// Provides a stream of Firebase auth state changes.
/// Use this to reactively update UI when the user logs in or out.
final firebaseAuthStreamProvider = StreamProvider<User?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

class AuthState {
  final UserModel? user;
  final bool isLoading;
  final String? error;

  const AuthState({this.user, this.isLoading = false, this.error});

  bool get isLoggedIn => user != null;

  AuthState copyWith({UserModel? user, bool? isLoading, String? error}) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;
  final LocalStorageService _storage;

  AuthNotifier(this._repository, this._storage) : super(const AuthState()) {
    _restoreSession();
  }

  /// Restores the user session from local storage or Firebase.
  ///
  /// If a Firebase user is signed in, fetches their profile from Firestore.
  /// Falls back to local storage for offline session restoration.
  void _restoreSession() async {
    final firebaseUser = _repository.currentUser;

    if (firebaseUser != null) {
      // Firebase session exists — fetch real profile from Firestore
      try {
        final profile = await _repository.getUserProfile();
        if (profile != null) {
          state = AuthState(user: profile);
          // Keep local storage in sync
          await _storage.saveSession(
            phone: profile.phone,
            name: profile.name,
          );
          return;
        }
      } catch (_) {
        // Firestore fetch failed — fall through to local storage
      }
    }

    // Fallback: restore from local storage (offline support)
    if (_storage.isLoggedIn) {
      state = AuthState(
        user: UserModel(
          id: 'u_${_storage.userPhone}',
          name: _storage.userName ?? 'MyTickets User',
          phone: _storage.userPhone ?? '',
        ),
      );
    }
  }

  /// Sends an OTP to the given phone number via Firebase.
  Future<bool> sendOtp(String phone) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repository.sendOtp(phone);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  /// Verifies the OTP and signs in the user.
  Future<bool> verifyOtp(String phone, String otp) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final user = await _repository.verifyOtp(phone, otp);
      await _storage.saveSession(phone: user.phone, name: user.name);
      state = AuthState(user: user);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  /// Signs in with Google and creates/fetches user profile.
  Future<bool> signInWithGoogle() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final user = await _repository.signInWithGoogle();
      await _storage.saveSession(phone: user.phone, name: user.name);
      state = AuthState(user: user);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  /// Signs out from Firebase and clears local session.
  Future<void> logout() async {
    await _repository.logout();
    await _storage.clearSession();
    state = const AuthState();
  }

  /// Updates the user's profile both in memory and Firestore.
  void updateProfile({String? name, String? email}) async {
    if (state.user == null) {
      return;
    }

    state = state.copyWith(
      user: state.user!.copyWith(name: name, email: email),
    );

    // Persist to Firestore
    try {
      await _repository.updateUserProfile(name: name, email: email);
    } catch (_) {
      // Silently fail — local state is already updated
    }
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(
    ref.watch(authRepositoryProvider),
    ref.watch(localStorageServiceProvider),
  );
});
