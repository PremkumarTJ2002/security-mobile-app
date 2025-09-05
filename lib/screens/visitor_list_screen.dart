import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';

class VisitorListScreen extends StatelessWidget {
  final String? filterStatus;

  const VisitorListScreen({Key? key, this.filterStatus}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;

    // Base collection
    Query<Map<String, dynamic>> baseQuery =
        FirebaseFirestore.instance.collection('visitors');

    // Apply status filter if provided
    if (filterStatus != null) {
      baseQuery = baseQuery.where('status', isEqualTo: filterStatus);
    }

    // ✅ Restrict to assigned owner unless security
    final currentUser = FirebaseAuth.instance.currentUser;
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser?.uid)
          .get(),
      builder: (context, userSnapshot) {
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
          return const Scaffold(
            body: Center(child: Text('User data not found')),
          );
        }

        final role = userSnapshot.data!.get('role') ?? 'unknown';

        Query<Map<String, dynamic>> visitorQuery;

        if (role == 'security') {
          // 🔓 Security sees all
          visitorQuery = baseQuery.orderBy('entryTime', descending: true);
        } else {
          // 🔐 Owners see only theirs or approvableByAll
          visitorQuery = baseQuery
              .where(
                Filter.or(
                  Filter('assignedOwnerUid', isEqualTo: currentUid),
                  Filter('approvableByAll', isEqualTo: true),
                ),
              )
              .orderBy('entryTime', descending: true);
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(filterStatus != null
                ? '${filterStatus![0].toUpperCase()}${filterStatus!.substring(1)} Visitors'
                : 'All Visitors'),
            backgroundColor: const Color.fromARGB(255, 255, 105, 60),
            foregroundColor: const Color.fromARGB(255, 255, 194, 161),
          ),
          body: StreamBuilder<QuerySnapshot>(
            stream: visitorQuery.snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final visitors = snapshot.data?.docs ?? [];

              if (visitors.isEmpty) {
                return Center(
                  child: Text(
                    'No visitors found.',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                );
              }

              return ListView.builder(
                itemCount: visitors.length,
                itemBuilder: (context, index) {
                  final doc = visitors[index];
                  final data = doc.data() as Map<String, dynamic>;
                  final status = data['status'] ?? 'unknown';

                  Color getStatusColor(String status) {
                    switch (status) {
                      case 'pending':
                        return Colors.orange;
                      case 'checked-in':
                        return Colors.green;
                      case 'checked-out':
                        return Colors.grey;
                      default:
                        return Colors.black54;
                    }
                  }

                  return Card(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 30,
                                backgroundColor: Colors.grey[300],
                                child: ClipOval(
                                  child: data['photoUrl'] != null
                                      ? CachedNetworkImage(
                                          imageUrl: data['photoUrl'],
                                          width: 60,
                                          height: 60,
                                          fit: BoxFit.cover,
                                          placeholder: (context, url) =>
                                              const Center(
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          ),
                                          errorWidget:
                                              (context, url, error) =>
                                                  const Icon(Icons.error,
                                                      color: Colors.red),
                                          memCacheWidth: 120,
                                          memCacheHeight: 120,
                                        )
                                      : const Icon(Icons.person,
                                          color: Colors.white),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(data['name'] ?? 'No name',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 4),
                                    Text('Purpose: ${data['purpose'] ?? ''}'),
                                    Text(
                                      'Assigned to: ${data['assignedOwnerName'] ?? 'All Owners'}',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    Text(
                                        'Product Category: ${data['productCategory'] ?? 'N/A'}',
                                        style: const TextStyle(fontSize: 12)),
                                    Text('Phone: ${data['phone'] ?? 'N/A'}'),
                                    Text(
                                      'Entry Time: ${data['entryTime'] != null ? (data['entryTime'] as Timestamp).toDate().toLocal().toString() : 'N/A'}',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: getStatusColor(status),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  status.toUpperCase(),
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}
