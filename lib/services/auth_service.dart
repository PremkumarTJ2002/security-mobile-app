import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Register a user with email, password, name and role
  Future<String?> registerUser({
    required String email,
    required String password,
    required String name,
    required String role,
  }) async {
    try {
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(
            email: email.trim(),
            password: password.trim(),
          );

      // Save user data to Firestore
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'uid': userCredential.user!.uid,
        'email': email.trim(),
        'name': name.trim(),
        'role': role,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return null; // success
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      return 'An unexpected error occurred';
    }
  }

  /// Login user and return their role
  Future<Map<String, dynamic>?> loginUser({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      final userDoc = await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

      if (!userDoc.exists) {
        return {'error': 'User data not found in Firestore'};
      }

      final data = userDoc.data();
      final role = data?['role'];

      if (role == null) {
        return {'error': 'Role not set for this user'};
      }

      return {
        'uid': userCredential.user!.uid,
        'role': role,
        'name': data?['name'],
        'email': data?['email'],
      };
    } on FirebaseAuthException catch (e) {
      return {'error': e.message};
    } catch (e) {
      return {'error': 'Unexpected error during login'};
    }
  }

  /// Logout current user
  Future<void> logout() async {
    await _auth.signOut();
  }

  /// Get current user ID
  String? getCurrentUserId() {
    return _auth.currentUser?.uid;
  }
  
  User? get currentUser {

    // Replace with the actual logic to retrieve the current user

    return FirebaseAuth.instance.currentUser;

  }

  /// Get current user role
  Future<String?> getCurrentUserRole() async {
    final uid = getCurrentUserId();
    if (uid == null) return null;

    final userDoc = await _firestore.collection('users').doc(uid).get();
    return userDoc.data()?['role'];
  }
}
