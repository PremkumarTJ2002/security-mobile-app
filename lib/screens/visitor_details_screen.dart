import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';

class VisitorDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> data;

  const VisitorDetailsScreen({super.key, required this.data});

  Future<void> _confirmAndUpdateStatus(
      BuildContext context, String status) async {
    final action = status == 'checked-in' ? 'Approve' : 'Deny';
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('$action Visitor'),
        content: Text('Are you sure you want to $action this visitor?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(action)),
        ],
      ),
    );

    if (confirm == true) {
      _updateVisitorStatus(context, status);
    }
  }

  void _updateVisitorStatus(BuildContext context, String status) async {
    try {
      final docId = data['docId'] ?? data['id']; // ✅ fix: prefer docId passed from list
      if (docId != null) {
        await FirebaseFirestore.instance
            .collection('visitors')
            .doc(docId)
            .update({'status': status});

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Visitor marked as $status')),
        );
        Navigator.pop(context);
      } else {
        throw Exception("Document ID not found.");
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error updating status: $e');
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update status')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = data['name'] ?? 'Unknown';
    final phone = data['phone'] ?? 'N/A';
    final purpose = data['purpose'] ?? 'N/A';
    final category = data['productCategory'] ?? 'N/A';
    final status = data['status'] ?? 'N/A';
    final photoUrl = data['photoUrl'] ?? '';
    final photoUrl2 = data['photoUrl2'] ?? '';

    // 🔑 Permission logic
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final approvableByAll = data['approvableByAll'] == true;
    final assignedUid = data['assignedOwnerUid'] as String?;
    final assignedOwnerName = data['assignedOwnerName'] ?? 'All Owners';
    final canAct =
        approvableByAll || (assignedUid != null && assignedUid == uid);

    final List<String> imageUrls = [
      if (photoUrl.isNotEmpty) photoUrl,
      if (photoUrl2.isNotEmpty) photoUrl2,
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Visitor Details'),
        backgroundColor: const Color.fromARGB(255, 255, 105, 60),
        foregroundColor: const Color.fromARGB(255, 255, 194, 161),
      ),
      body: Column(
        children: [
          // Image Carousel
          if (imageUrls.isNotEmpty)
            Expanded(
              flex: 4,
              child: PageView.builder(
                itemCount: imageUrls.length,
                itemBuilder: (context, index) {
                  return CachedNetworkImage(
                    imageUrl: imageUrls[index],
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (context, url) =>
                        const Center(child: CircularProgressIndicator()),
                    errorWidget: (context, url, error) =>
                        const Icon(Icons.broken_image, size: 100),
                  );
                },
              ),
            )
          else
            const Expanded(
              flex: 4,
              child: Center(
                child: Icon(Icons.image_not_supported, size: 100),
              ),
            ),

          // Info and Buttons
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow('Name:', name),
                  _buildInfoRow('Phone:', phone),
                  _buildInfoRow('Purpose:', purpose),
                  _buildInfoRow('Product Category:', category),
                  _buildInfoRow('Status:', status,
                      valueColor: _statusColor(status)),
                  _buildInfoRow('Assigned To:', assignedOwnerName),
                  const SizedBox(height: 24),

                  if (status == 'pending' && canAct)
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () =>
                                _confirmAndUpdateStatus(context, 'checked-in'),
                            icon: const Icon(Icons.check),
                            label: const Text('Approve'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () =>
                                _confirmAndUpdateStatus(context, 'denied'),
                            icon: const Icon(Icons.close),
                            label: const Text('Deny'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                      ],
                    )
                  else if (status == 'pending')
                    Text(
                      "Assigned to $assignedOwnerName — you cannot act.",
                      style: const TextStyle(color: Colors.grey),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label ',
            style: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 16),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 16, color: valueColor ?? Colors.black),
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'checked-in':
        return Colors.green;
      case 'denied':
        return Colors.red;
      case 'checked-out':
        return Colors.grey;
      default:
        return Colors.black;
    }
  }
}
