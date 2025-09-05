import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/visitor.dart';
import '../services/visitor_service.dart';

class CheckedInVisitorsScreen extends StatefulWidget {
  const CheckedInVisitorsScreen({super.key});

  @override
  State<CheckedInVisitorsScreen> createState() => _CheckedInVisitorsScreenState();
}

class _CheckedInVisitorsScreenState extends State<CheckedInVisitorsScreen> {
  final VisitorService _visitorService = VisitorService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Checked-In Visitors")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('visitors')
            .where('status', isEqualTo: 'checked-in')
            .orderBy('entryTime', descending: true) // ✅ Ensures consistent sort & avoids index error
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Text("Error loading visitors"));
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

          final visitors = snapshot.data!.docs.map((doc) => Visitor.fromFirestore(doc)).toList();

          if (visitors.isEmpty) {
            return const Center(child: Text("No checked-in visitors."));
          }

          return ListView.builder(
            itemCount: visitors.length,
            itemBuilder: (context, index) {
              final visitor = visitors[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: visitor.photoUrl != null && visitor.photoUrl!.isNotEmpty
                      ? NetworkImage(visitor.photoUrl!)
                      : const AssetImage('assets/images/default_avatar.png') as ImageProvider,
                ),
                title: Text(visitor.name),
                subtitle: Text("Phone: ${visitor.phone}\nPurpose: ${visitor.purpose}"),
                trailing: ElevatedButton(
                  onPressed: () async {
                    await _visitorService.checkOutVisitor(visitor.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Visitor checked out")),
                    );
                  },
                  child: const Text("Check Out"),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
