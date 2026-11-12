import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

/// Production authentication repository using Firebase Phone Auth & Google Sign-In.
///
/// Replaces the previous mock auth that accepted a fixed demo OTP ('123456').
/// Now sends real SMS OTPs via Firebase and supports Google Sign-In.
class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  /// Stores the verification ID returned by Firebase after sending OTP.
  String? _verificationId;
  int? _resendToken;

  /// Stream of auth state changes — emits when user logs in/out.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// The currently signed-in Firebase user, or null.
  User? get currentUser => _auth.currentUser;

  // ---------------------------------------------------------------------------
  // Phone OTP Authentication
  // ---------------------------------------------------------------------------

  /// Sends an OTP to the given [phone] number via Firebase.
  ///
  /// On Android, Firebase may auto-verify the OTP without user input
  /// (handled by [verificationCompleted]).
  ///
  /// Throws [FirebaseAuthException] on failure (invalid number, quota exceeded).
  Future<void> sendOtp(String phone) async {
    final completer = Completer<void>();

    await _auth.verifyPhoneNumber(
      phoneNumber: '+91$phone',
      timeout: const Duration(seconds: 60),
      forceResendingToken: _resendToken,

      /// Called on Android when the OTP is auto-resolved from the SMS.
      verificationCompleted: (PhoneAuthCredential credential) async {
        // Auto-sign-in (Android only)
        await _auth.signInWithCredential(credential);
      },

      /// Called when verification fails (e.g. invalid phone, quota exceeded).
      verificationFailed: (FirebaseAuthException e) {
        if (!completer.isCompleted) {
          completer.completeError(_mapAuthError(e));
        }
      },

      /// Called when the OTP is sent successfully.
      codeSent: (String verificationId, int? resendToken) {
        _verificationId = verificationId;
        _resendToken = resendToken;
        if (!completer.isCompleted) {
          completer.complete();
        }
      },

      /// Called when the auto-retrieval timeout expires.
      codeAutoRetrievalTimeout: (String verificationId) {
        _verificationId = verificationId;
      },
    );

    return completer.future;
  }

  /// Verifies the [otp] entered by the user against the stored verification ID.
  ///
  /// Returns a [UserModel] fetched from (or created in) Firestore.
  /// Throws an [Exception] if the OTP is invalid or expired.
  Future<UserModel> verifyOtp(String phone, String otp) async {
    if (_verificationId == null) {
      throw Exception('No OTP request in progress. Please request a new OTP.');
    }

    final credential = PhoneAuthProvider.credential(
      verificationId: _verificationId!,
      smsCode: otp,
    );

    try {
      final userCredential = await _auth.signInWithCredential(credential);
      return _getOrCreateUserProfile(userCredential.user!);
    } on FirebaseAuthException catch (e) {
      throw _mapAuthError(e);
    }
  }

  // ---------------------------------------------------------------------------
  // Google Sign-In
  // ---------------------------------------------------------------------------

  /// Signs in with Google and returns a [UserModel].
  ///
  /// Opens the Google Sign-In picker. On success, creates a Firebase session
  /// and fetches/creates the user profile in Firestore.
  Future<UserModel> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        throw Exception('Google Sign-In was cancelled.');
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      return _getOrCreateUserProfile(userCredential.user!);
    } on FirebaseAuthException catch (e) {
      throw _mapAuthError(e);
    }
  }

  // ---------------------------------------------------------------------------
  // Logout
  // ---------------------------------------------------------------------------

  /// Signs out from both Firebase and Google.
  Future<void> logout() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  // ---------------------------------------------------------------------------
  // Firestore User Profile
  // ---------------------------------------------------------------------------

  /// Fetches the user profile from Firestore. If the user doesn't have a
  /// profile yet (first login), creates one with default values.
  Future<UserModel> _getOrCreateUserProfile(User firebaseUser) async {
    final docRef = _firestore.collection('users').doc(firebaseUser.uid);
    final doc = await docRef.get();

    if (doc.exists) {
      return UserModel.fromMap(doc.data()!);
    }

    // First time login — create profile
    final newUser = UserModel(
      id: firebaseUser.uid,
      name: firebaseUser.displayName ?? 'MyTickets User',
      phone: firebaseUser.phoneNumber ?? '',
      email: firebaseUser.email,
      avatarUrl: firebaseUser.photoURL,
      bookingsCount: 0,
      savedCount: 0,
      rewardPoints: 0,
    );

    await docRef.set(newUser.toMap());
    return newUser;
  }

  /// Fetches the current user's profile from Firestore.
  Future<UserModel?> getUserProfile() async {
    final user = _auth.currentUser;
    if (user == null) {
      return null;
    }

    final doc = await _firestore.collection('users').doc(user.uid).get();
    if (doc.exists) {
      return UserModel.fromMap(doc.data()!);
    }
    return null;
  }

  /// Updates the user's profile fields in Firestore.
  Future<void> updateUserProfile({String? name, String? email}) async {
    final user = _auth.currentUser;
    if (user == null) {
      return;
    }

    final updates = <String, dynamic>{};
    if (name != null) {
      updates['name'] = name;
    }
    if (email != null) {
      updates['email'] = email;
    }

    if (updates.isNotEmpty) {
      await _firestore.collection('users').doc(user.uid).update(updates);
    }
  }

  // ---------------------------------------------------------------------------
  // Error Mapping
  // ---------------------------------------------------------------------------

  /// Maps Firebase auth error codes to user-friendly messages.
  Exception _mapAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-phone-number':
        return Exception('Invalid phone number. Please check and try again.');
      case 'too-many-requests':
        return Exception('Too many attempts. Please try again later.');
      case 'invalid-verification-code':
        return Exception('Invalid OTP. Please check and try again.');
      case 'session-expired':
        return Exception('OTP has expired. Please request a new one.');
      case 'quota-exceeded':
        return Exception('SMS quota exceeded. Please try again later.');
      case 'account-exists-with-different-credential':
        return Exception(
          'An account already exists with this email. '
          'Try signing in with a different method.',
        );
      case 'network-request-failed':
        return Exception('Network error. Please check your connection.');
      default:
        return Exception(e.message ?? 'Authentication failed. Please try again.');
    }
  }
}
