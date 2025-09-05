// lib/models/visitor.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Visitor {
  final String id;
  final String name;
  final String phone;
  final String purpose;
  final String hostName; // who created the record (security uid)
  final DateTime entryTime;
  final DateTime? exitTime;

  // Photos / proofs
  final String? photoUrl;   // primary photo (face)
  final String? photoUrl2;  // secondary photo (second capture)
  final String? idProofUrl; // optional id proof link (if used)

  // status: pending, checked-in, checked-out, denied, etc.
  final String status;

  // Product category (new field)
  final String productCategory;

  // Assignment fields (owner selection behavior)
  final String? assignedOwnerUid;   // uid of owner (if a specific owner)
  final String? assignedOwnerName;  // name or display of owner
  final String? assignedOwnerEmail; // owner's email
  final bool approvableByAll;       // true if any owner can approve

  Visitor({
    required this.id,
    required this.name,
    required this.phone,
    required this.purpose,
    required this.hostName,
    required this.entryTime,
    this.exitTime,
    this.photoUrl,
    this.photoUrl2,
    this.idProofUrl,
    this.status = 'pending',
    this.productCategory = 'general',
    this.assignedOwnerUid,
    this.assignedOwnerName,
    this.assignedOwnerEmail,
    this.approvableByAll = false,
  });

  /// Convert to Firestore-friendly map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'purpose': purpose,
      'hostName': hostName,
      'entryTime': Timestamp.fromDate(entryTime),
      'exitTime': exitTime != null ? Timestamp.fromDate(exitTime!) : null,
      'photoUrl': photoUrl,
      'photoUrl2': photoUrl2,
      'idProofUrl': idProofUrl,
      'status': status,
      'productCategory': productCategory,
      'assignedOwnerUid': assignedOwnerUid,
      'assignedOwnerName': assignedOwnerName,
      'assignedOwnerEmail': assignedOwnerEmail,
      'approvableByAll': approvableByAll,
    };
  }

  /// Create a Visitor from a Firestore DocumentSnapshot
  factory Visitor.fromFirestore(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? <String, dynamic>{};

    return Visitor(
      id: data['id'] ?? doc.id,
      name: data['name'] ?? '',
      phone: data['phone'] ?? '',
      purpose: data['purpose'] ?? '',
      hostName: data['hostName'] ?? '',
      entryTime: _parseDateSafe(data['entryTime']),
      exitTime: data['exitTime'] != null ? _parseDateNullable(data['exitTime']) : null,
      photoUrl: data['photoUrl'],
      photoUrl2: data['photoUrl2'],
      idProofUrl: data['idProofUrl'],
      status: data['status'] ?? 'pending',
      productCategory: data['productCategory'] ?? 'general',
      assignedOwnerUid: data['assignedOwnerUid'],
      assignedOwnerName: data['assignedOwnerName'],
      assignedOwnerEmail: data['assignedOwnerEmail'],
      approvableByAll: (data['approvableByAll'] ?? false) as bool,
    );
  }

  /// Safe parsing helpers: accept Timestamp, ISO-String or null
  static DateTime _parseDateSafe(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    } else if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (_) {
        return DateTime.now();
      }
    } else if (value is DateTime) {
      return value;
    } else {
      // fallback to now if missing — entryTime should ideally exist
      return DateTime.now();
    }
  }

  static DateTime? _parseDateNullable(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (_) {
        return null;
      }
    }
    if (value is DateTime) return value;
    return null;
  }

  /// Clone with changes
  Visitor copyWith({
    String? id,
    String? name,
    String? phone,
    String? purpose,
    String? hostName,
    DateTime? entryTime,
    DateTime? exitTime,
    String? photoUrl,
    String? photoUrl2,
    String? idProofUrl,
    String? status,
    String? productCategory,
    String? assignedOwnerUid,
    String? assignedOwnerName,
    String? assignedOwnerEmail,
    bool? approvableByAll,
  }) {
    return Visitor(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      purpose: purpose ?? this.purpose,
      hostName: hostName ?? this.hostName,
      entryTime: entryTime ?? this.entryTime,
      exitTime: exitTime ?? this.exitTime,
      photoUrl: photoUrl ?? this.photoUrl,
      photoUrl2: photoUrl2 ?? this.photoUrl2,
      idProofUrl: idProofUrl ?? this.idProofUrl,
      status: status ?? this.status,
      productCategory: productCategory ?? this.productCategory,
      assignedOwnerUid: assignedOwnerUid ?? this.assignedOwnerUid,
      assignedOwnerName: assignedOwnerName ?? this.assignedOwnerName,
      assignedOwnerEmail: assignedOwnerEmail ?? this.assignedOwnerEmail,
      approvableByAll: approvableByAll ?? this.approvableByAll,
    );
  }

  @override
  String toString() {
    return 'Visitor(id: $id, name: $name, phone: $phone, purpose: $purpose, status: $status, assignedOwner: $assignedOwnerName/$assignedOwnerEmail, approvableByAll: $approvableByAll)';
  }
}
