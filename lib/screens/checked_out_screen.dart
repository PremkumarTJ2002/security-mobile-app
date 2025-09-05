import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/visitor.dart';

class CheckedOutVisitorsScreen extends StatelessWidget {
  const CheckedOutVisitorsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Checked-Out Visitors")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('visitors')
            .where('status', isEqualTo: 'checked-out')
            .orderBy('exitTime', descending: true) // ✅ Sorting by checkout time
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Text("Error loading visitors"));
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

          final visitors = snapshot.data!.docs.map((doc) => Visitor.fromFirestore(doc)).toList();

          if (visitors.isEmpty) {
            return const Center(child: Text("No checked-out visitors."));
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
                subtitle: Text(
                  "Phone: ${visitor.phone}\n"
                  "Purpose: ${visitor.purpose}\n"
                  "Checked Out At: ${visitor.exitTime != null ? (visitor.exitTime as Timestamp).toDate().toLocal().toString() : 'N/A'}",
                ),
              );
            },
          );
        },
      ),
    );
  }
}
