class Visitor {
  final String id;
  final String name;
  final String phone;
  final String purpose;
  final String hostName;
  final DateTime entryTime;
  final DateTime? exitTime;
  final String? photoUrl;
  final String? idProofUrl;
  final String status; // 'checked-in', 'checked-out'

  Visitor({
    required this.id,
    required this.name,
    required this.phone,
    required this.purpose,
    required this.hostName,
    required this.entryTime,
    this.exitTime,
    this.photoUrl,
    this.idProofUrl,
    this.status = 'checked-in',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'purpose': purpose,
      'hostName': hostName,
      'entryTime': entryTime.toIso8601String(),
      'exitTime': exitTime?.toIso8601String(),
      'photoUrl': photoUrl,
      'idProofUrl': idProofUrl,
      'status': status,
    };
  }

  factory Visitor.fromMap(Map<String, dynamic> map) {
    return Visitor(
      id: map['id'],
      name: map['name'],
      phone: map['phone'],
      purpose: map['purpose'],
      hostName: map['hostName'],
      entryTime: DateTime.parse(map['entryTime']),
      exitTime: map['exitTime'] != null
          ? DateTime.parse(map['exitTime'])
          : null,
      photoUrl: map['photoUrl'],
      idProofUrl: map['idProofUrl'],
      status: map['status'] ?? 'checked-in',
    );
  }

  Visitor copyWith({
    String? id,
    String? name,
    String? phone,
    String? purpose,
    String? hostName,
    DateTime? entryTime,
    DateTime? exitTime,
    String? photoUrl,
    String? idProofUrl,
    String? status,
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
      status: status ?? this.status,
    );
  }
}
