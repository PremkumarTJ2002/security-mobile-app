import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../models/visitor.dart';

class VisitorService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Collection reference
  CollectionReference get _visitorsCollection =>
      _firestore.collection('visitors');

  // Add a new visitor
  Future<void> addVisitor(Visitor visitor) async {
    try {
      await _visitorsCollection.doc(visitor.id).set(visitor.toMap());
    } catch (e) {
      print('Error adding visitor: $e');
      rethrow;
    }
  }

  // Get all visitors
  Stream<List<Visitor>> getVisitors() {
    return _visitorsCollection
        .orderBy('entryTime', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
            return Visitor.fromMap(data);
          }).toList();
        });
  }

  // Get visitors by status
  Stream<List<Visitor>> getVisitorsByStatus(String status) {
    return _visitorsCollection
        .where('status', isEqualTo: status)
        .orderBy('entryTime', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
            return Visitor.fromMap(data);
          }).toList();
        });
  }

  // Update visitor (check out)
  Future<void> checkOutVisitor(String visitorId) async {
    try {
      await _visitorsCollection.doc(visitorId).update({
        'exitTime': DateTime.now().toIso8601String(),
        'status': 'checked-out',
      });
    } catch (e) {
      print('Error checking out visitor: $e');
      rethrow;
    }
  }

  // Delete visitor
  Future<void> deleteVisitor(String visitorId) async {
    try {
      await _visitorsCollection.doc(visitorId).delete();
    } catch (e) {
      print('Error deleting visitor: $e');
      rethrow;
    }
  }

  // Upload image to Firebase Storage
  Future<String> uploadImage(File imageFile, String path) async {
    try {
      Reference ref = _storage.ref().child(path);
      UploadTask uploadTask = ref.putFile(imageFile);
      TaskSnapshot snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      print('Error uploading image: $e');
      rethrow;
    }
  }

  // Search visitors by name or phone
  Stream<List<Visitor>> searchVisitors(String query) {
    return _visitorsCollection
        .where('name', isGreaterThanOrEqualTo: query)
        .where('name', isLessThan: query + '\uf8ff')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
            return Visitor.fromMap(data);
          }).toList();
        });
  }

  // Approve visitor
  Future<void> approveVisitor(String visitorId, String ownerId) async {
    try {
      await _visitorsCollection.doc(visitorId).update({
        'status': 'approved',
        'approvalTime': DateTime.now().toIso8601String(),
        'approvedBy': ownerId,
        'denialTime': null,
        'denialReason': null,
      });
    } catch (e) {
      print('Error approving visitor: $e');
      rethrow;
    }
  }

  // Deny visitor with reason
  Future<void> denyVisitor(
    String visitorId,
    String ownerId,
    String reason,
  ) async {
    try {
      await _visitorsCollection.doc(visitorId).update({
        'status': 'denied',
        'denialTime': DateTime.now().toIso8601String(),
        'denialReason': reason,
        'approvedBy': ownerId,
        'approvalTime': null,
      });
    } catch (e) {
      print('Error denying visitor: $e');
      rethrow;
    }
  }
}
