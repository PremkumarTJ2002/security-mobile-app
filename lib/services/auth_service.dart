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
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

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

      final userDoc =
          await _firestore.collection('users').doc(userCredential.user!.uid).get();

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

  /// Get current user instance
  User? get currentUser {
    return FirebaseAuth.instance.currentUser;
  }

  /// Get current user role
  Future<String?> getCurrentUserRole() async {
    final uid = getCurrentUserId();
    if (uid == null) return null;

    final userDoc = await _firestore.collection('users').doc(uid).get();
    return userDoc.data()?['role'];
  }

  /// Get recent visitors ordered by check-in time
  Future<List<Map<String, dynamic>>> getRecentVisitors({int limit = 5}) async {
    try {
      final snapshot = await _firestore
          .collection('visitors')
          .where('status', isEqualTo: 'checked-in')
          .orderBy('entryTime', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'name': data['name'] ?? 'Unknown',
          'status': data['status'] ?? 'Unknown',
          'time': _formatTimestamp(data['entryTime']), // ✅ corrected field
        };
      }).toList();
    } catch (e) {
      print('Error fetching recent visitors: $e');
      return [];
    }
  }

  /// Format Firestore timestamp to readable string
  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return '';
    final dateTime = timestamp.toDate();
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  // 🔹 NEW METHOD: Get visitors assigned to the current logged-in owner
  Future<List<Map<String, dynamic>>> getVisitorsForCurrentOwner() async {
    final user = _auth.currentUser;
    if (user == null) return [];

    try {
      final query = await _firestore
          .collection('visitors')
          .where(
            Filter.or(
              Filter('assignedOwnerUid', isEqualTo: user.uid),
              Filter('approvableByAll', isEqualTo: true),
            ),
          )
          .orderBy('entryTime', descending: true)
          .get();

      return query.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'name': data['name'] ?? 'Unknown',
          'phone': data['phone'] ?? '',
          'purpose': data['purpose'] ?? '',
          'status': data['status'] ?? 'pending',
          'productCategory': data['productCategory'] ?? 'N/A',
          'assignedOwnerEmail': data['assignedOwnerEmail'] ?? '',
          'time': _formatTimestamp(data['entryTime']),
        };
      }).toList();
    } catch (e) {
      print("Error fetching visitors for owner: $e");
      return [];
    }
  }
}
