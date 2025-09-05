import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../models/visitor.dart';

class VisitorService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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

  // Upload image to AWS S3 using pre-signed URL
  Future<List<String>> uploadTwoImagesToS3(File imageFile1, File imageFile2) async {
    final String fileName1 = imageFile1.path.split('/').last;
    final String fileName2 = imageFile2.path.split('/').last;
    const String contentType = 'image/jpg';

    final Uri lambdaUrl = Uri.parse(
      'https://3jhiu14um3.execute-api.us-east-1.amazonaws.com/dev/generate-url',
    );

    try {
      final lambdaResponse = await http.post(
        lambdaUrl,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'fileName1': fileName1,
          'fileName2': fileName2,
          'ContentType': contentType,
        }),
      );

      if (lambdaResponse.statusCode != 200) {
        throw Exception('Failed to get pre-signed URLs');
      }

      final responseJson = json.decode(lambdaResponse.body);
      final String uploadUrl1 = responseJson['uploadUrl1'];
      final String uploadUrl2 = responseJson['uploadUrl2'];

      final Uint8List imageBytes1 = await imageFile1.readAsBytes();
      final Uint8List imageBytes2 = await imageFile2.readAsBytes();

      final uploadResponse1 = await http.put(
        Uri.parse(uploadUrl1),
        headers: {'Content-Type': contentType},
        body: imageBytes1,
      );

      final uploadResponse2 = await http.put(
        Uri.parse(uploadUrl2),
        headers: {'Content-Type': contentType},
        body: imageBytes2,
      );

      if (uploadResponse1.statusCode != 200 || uploadResponse2.statusCode != 200) {
        throw Exception('One or both image uploads failed');
      }

      return [uploadUrl1.split('?').first, uploadUrl2.split('?').first];
    } catch (e) {
      print('Upload error: $e');
      rethrow;
    }
  }

  // Get all visitors
  Stream<List<Visitor>> getVisitors() {
    return _visitorsCollection
        .orderBy('entryTime', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map((doc) {
            return Visitor.fromFirestore(doc);
          }).toList(),
        );
  }

  // Get visitors by status
  Stream<List<Visitor>> getVisitorsByStatus(String status) {
    return _visitorsCollection
        .where('status', isEqualTo: status)
        .orderBy('entryTime', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map((doc) {
            return Visitor.fromFirestore(doc);
          }).toList(),
        );
  }

  // Check-out visitor
  Future<void> checkOutVisitor(String visitorId) async {
    try {
      await _visitorsCollection.doc(visitorId).update({
        'exitTime': Timestamp.now(),
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

  // Search visitors by name
  Stream<List<Visitor>> searchVisitors(String query) {
    return _visitorsCollection
        .where('name', isGreaterThanOrEqualTo: query)
        .where('name', isLessThan: query + '\uf8ff')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map((doc) {
            return Visitor.fromFirestore(doc);
          }).toList(),
        );
  }

  // Approve visitor
  Future<void> approveVisitor(String visitorId) async {
    try {
      await _visitorsCollection.doc(visitorId).update({
        'status': 'approved',
        'approvalTime': DateTime.now().toIso8601String(),
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
    String reason,
  ) async {
    try {
      await _visitorsCollection.doc(visitorId).update({
        'status': 'denied',
        'denialTime': DateTime.now().toIso8601String(),
        'denialReason': reason,
        'approvalTime': null,
      });
    } catch (e) {
      print('Error denying visitor: $e');
      rethrow;
    }
  }
}
