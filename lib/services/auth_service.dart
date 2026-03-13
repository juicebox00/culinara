import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:culinara/services/recipe_store_service.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _firebaseAuth.currentUser;

  // Register with email and password
  Future<UserCredential> registerWithEmail({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      // Create user account
      UserCredential userCredential = await _firebaseAuth
          .createUserWithEmailAndPassword(
            email: email.trim(),
            password: password,
          );

      // Send email verification
      await userCredential.user!.sendEmailVerification();

      // Save user data to Firestore
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'uid': userCredential.user!.uid,
        'name': name,
        'email': email.trim(),
        'createdAt': DateTime.now(),
      });

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Login with email and password
  Future<UserCredential> loginWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      return await _firebaseAuth
          .signInWithEmailAndPassword(email: email.trim(), password: password);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Sign in with Google
  Future<UserCredential> signInWithGoogle() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: [
          'email',
          'profile',
        ],
      );
      
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        throw 'Google sign-in was cancelled';
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential =
          await _firebaseAuth.signInWithCredential(credential);

      // Save user data to Firestore if new user
      final userDoc = await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

      if (!userDoc.exists) {
        await _firestore.collection('users').doc(userCredential.user!.uid).set({
          'uid': userCredential.user!.uid,
          'name': userCredential.user!.displayName ?? 'User',
          'email': userCredential.user!.email ?? '',
          'createdAt': DateTime.now(),
        });
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Google sign-in failed, Couldn\'t find your Google account.';
    }
  }

  Future<void> changeEmail({
    required String currentPassword,
    required String newEmail,
  }) async {
    try {
      final user = currentUser;
      if (user == null) throw 'User not authenticated';

      // Only allow email change for email/password users
      bool hasPasswordProvider = user.providerData
          .any((provider) => provider.providerId == 'password');
      
      if (!hasPasswordProvider) {
        throw 'Email change is only available for email/password accounts.';
      }

      final credential = EmailAuthProvider.credential(
        email: user.email ?? '',
        password: currentPassword,
      );

      await user.reauthenticateWithCredential(credential);
      await user.verifyBeforeUpdateEmail(newEmail.trim());
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final user = currentUser;
      if (user == null) throw 'User not authenticated';

      final credential = EmailAuthProvider.credential(
        email: user.email ?? '',
        password: currentPassword,
      );

      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  Future<void> deleteAccount({required String currentPassword}) async {
    try {
      final user = currentUser;
      if (user == null) throw 'User not authenticated';

      final uid = user.uid;

      // Check if user has email/password provider
      bool hasPasswordProvider = user.providerData
          .any((provider) => provider.providerId == 'password');
      bool hasGoogleProvider = user.providerData
          .any((provider) => provider.providerId == 'google.com');

      // If user has password (email/password auth), require reauthentication
      if (hasPasswordProvider) {
        if (currentPassword.isEmpty) {
          throw 'Current password is required.';
        }
        final credential = EmailAuthProvider.credential(
          email: user.email ?? '',
          password: currentPassword,
        );
        await user.reauthenticateWithCredential(credential);
      } else if (hasGoogleProvider) {
        // Reauthenticate Google user
        final GoogleSignIn googleSignIn = GoogleSignIn();
        final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
        if (googleUser == null) {
          throw 'Google reauthentication cancelled.';
        }
        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        await user.reauthenticateWithCredential(credential);
      }

      // Delete all user recipes
      final recipes = await _firestore
          .collection('users')
          .doc(uid)
          .collection('recipes')
          .get();
      for (final recipe in recipes.docs) {
        await recipe.reference.delete();
      }

      // Delete user document from Firestore
      await _firestore.collection('users').doc(uid).delete();
      
      // Delete user account from Firebase Auth (this will invalidate the current user session)
      await user.delete();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        // This error might occur after user deletion; it's expected
        throw 'Account deleted successfully.';
      }
      throw _handleAuthException(e);
    } catch (e) {
      if (e.toString().contains('User not found')) {
        // User already deleted, this is success
        return;
      }
      throw 'Failed to delete account: $e';
    }
  }

  // Logout
  Future<void> logout() async {
    try {
      // Clear local recipe cache when logging out
      await RecipeStoreService.clearLocalCache();
      await _firebaseAuth.signOut();
    } catch (e) {
      throw 'Failed to logout';
    }
  }

  // Handle Firebase Auth exceptions
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'The password provided is too weak.';
      case 'email-already-in-use':
        return 'An account already exists for that email.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'operation-not-allowed':
        return 'Operation not allowed.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'user-not-found':
        return 'No user found with that email.';
      case 'wrong-password':
        return 'Wrong password provided.';
      case 'requires-recent-login':
        return 'Please log in again and retry this action.';
      case 'too-many-requests':
        return 'Too many failed login attempts. Please try again later.';
      case 'invalid-credential':
        return 'Invalid email or password.';
      default:
        return 'An error occurred: ${e.message}';
    }
  }
}
