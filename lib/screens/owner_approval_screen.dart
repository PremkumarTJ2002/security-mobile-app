import 'package:flutter/material.dart';
import '../models/visitor.dart';
import '../services/visitor_service.dart';

class OwnerApprovalScreen extends StatefulWidget {
  final String ownerId; // Pass the logged-in owner's user ID

  const OwnerApprovalScreen({Key? key, required this.ownerId})
    : super(key: key);

  @override
  _OwnerApprovalScreenState createState() => _OwnerApprovalScreenState();
}

class _OwnerApprovalScreenState extends State<OwnerApprovalScreen> {
  final VisitorService _visitorService = VisitorService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Pending Visitor Approvals')),
      body: StreamBuilder<List<Visitor>>(
        stream: _visitorService.getVisitorsByStatus('pending'),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No pending visitors.'));
          }
          final visitors = snapshot.data!;
          return ListView.builder(
            itemCount: visitors.length,
            itemBuilder: (context, index) {
              final visitor = visitors[index];
              return Card(
                margin: EdgeInsets.all(8),
                child: ListTile(
                  title: Text(visitor.name),
                  subtitle: Text(
                    'Purpose: ${visitor.purpose}\nPhone: ${visitor.phone}',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.check, color: Colors.green),
                        onPressed: () async {
                          await _visitorService.approveVisitor(
                            visitor.id,
                            widget.ownerId,
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Visitor approved!')),
                          );
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: Colors.red),
                        onPressed: () {
                          _showDenyDialog(visitor.id);
                        },
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
  }

  void _showDenyDialog(String visitorId) {
    final TextEditingController _reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Deny Visitor'),
        content: TextField(
          controller: _reasonController,
          decoration: InputDecoration(labelText: 'Reason for denial'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final reason = _reasonController.text.trim();
              if (reason.isNotEmpty) {
                await _visitorService.denyVisitor(
                  visitorId,
                  widget.ownerId,
                  reason,
                );
                Navigator.pop(context);
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('Visitor denied!')));
              }
            },
            child: Text('Deny'),
          ),
        ],
      ),
    );
  }
}
