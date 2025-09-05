import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import './visitor_details_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';

class OwnerApprovalScreen extends StatelessWidget {
  const OwnerApprovalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pending Visitor Approvals'),
        backgroundColor: const Color.fromARGB(255, 255, 105, 60),
        foregroundColor: const Color.fromARGB(255, 255, 194, 161),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final shouldLogout = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Confirm Logout'),
                  content: const Text('Are you sure you want to log out?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('Logout'),
                    ),
                  ],
                ),
              );

              if (shouldLogout == true) {
                await FirebaseAuth.instance.signOut();
                Navigator.of(context).pushReplacementNamed('/login');
              }
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('visitors')
            .where('status', isEqualTo: 'pending')
            .where(
              Filter.or(
                Filter('assignedOwnerUid', isEqualTo: currentUid),
                Filter('approvableByAll', isEqualTo: true),
              ),
            )
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Something went wrong.'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return const Center(child: Text('No pending visitors.'));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final docId = docs[index].id;

              final name = data['name'] ?? 'Unknown';
              final purpose = data['purpose'] ?? 'No purpose';
              final imageUrl = data['photoUrl'] ?? '';

              // 🔑 Permission logic
              final approvableByAll = data['approvableByAll'] == true;
              final assignedUid = data['assignedOwnerUid'] as String?;
              final canAct =
                  approvableByAll || (assignedUid != null && currentUid == assignedUid);

              return Card(
                margin: const EdgeInsets.all(10),
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => VisitorDetailsScreen(data: {
                          ...data,
                          'docId': docId,
                        }),
                      ),
                    );
                  },
                  contentPadding: const EdgeInsets.all(16),
                  leading: imageUrl.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: CachedNetworkImage(
                            imageUrl: imageUrl,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => const SizedBox(
                              width: 60,
                              height: 60,
                              child: Center(
                                  child: CircularProgressIndicator(strokeWidth: 2)),
                            ),
                            errorWidget: (context, url, error) =>
                                const Icon(Icons.broken_image, size: 50),
                          ),
                        )
                      : const Icon(Icons.image_not_supported, size: 50),
                  title: Text(
                    name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Purpose: $purpose'),
                      Text(
                        'Assigned to: ${data['assignedOwnerName'] ?? 'All Owners'}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                  trailing: canAct
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.check, color: Colors.green),
                              onPressed: () {
                                _updateStatus(docId, 'checked-in');
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.clear, color: Colors.red),
                              onPressed: () {
                                _updateStatus(docId, 'denied');
                              },
                            ),
                          ],
                        )
                      : const Icon(Icons.lock, color: Colors.grey),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _updateStatus(String docId, String newStatus) {
    FirebaseFirestore.instance
        .collection('visitors')
        .doc(docId)
        .update({'status': newStatus});
  }
}
