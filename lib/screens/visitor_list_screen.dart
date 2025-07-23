import 'package:flutter/material.dart';
import '../models/visitor.dart';
import '../services/visitor_service.dart';

class VisitorListScreen extends StatefulWidget {
  final String? filterStatus;

  const VisitorListScreen({Key? key, this.filterStatus}) : super(key: key);

  @override
  _VisitorListScreenState createState() => _VisitorListScreenState();
}

class _VisitorListScreenState extends State<VisitorListScreen> {
  final VisitorService _visitorService = VisitorService();
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.filterStatus != null
              ? '${widget.filterStatus!.split('-').map((e) => e[0].toUpperCase() + e.substring(1)).join(' ')} Visitors'
              : 'All Visitors',
        ),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              _showSearchDialog();
            },
          ),
        ],
      ),
      body: StreamBuilder<List<Visitor>>(
        stream: widget.filterStatus != null
            ? _visitorService.getVisitorsByStatus(widget.filterStatus!)
            : _visitorService.getVisitors(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          List<Visitor> visitors = snapshot.data ?? [];

          if (visitors.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No visitors found',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: visitors.length,
            itemBuilder: (context, index) {
              final visitor = visitors[index];
              return Card(
                margin: EdgeInsets.only(bottom: 12),
                elevation: 2,
                child: ListTile(
                  contentPadding: EdgeInsets.all(16),
                  leading: CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.blue[100],
                    child: visitor.photoUrl != null
                        ? ClipOval(
                            child: Image.network(
                              visitor.photoUrl!,
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(
                                  Icons.person,
                                  size: 30,
                                  color: Colors.blue[700],
                                );
                              },
                            ),
                          )
                        : Icon(Icons.person, size: 30, color: Colors.blue[700]),
                  ),
                  title: Text(
                    visitor.name,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 4),
                      Text('Phone: ${visitor.phone}'),
                      Text('Purpose: ${visitor.purpose}'),
                      Text('Host: ${visitor.hostName}'),
                      Text(
                        'Entry: ${_formatDateTime(visitor.entryTime)}',
                        style: TextStyle(fontSize: 12),
                      ),
                      if (visitor.exitTime != null)
                        Text(
                          'Exit: ${_formatDateTime(visitor.exitTime!)}',
                          style: TextStyle(fontSize: 12),
                        ),
                      SizedBox(height: 8),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: visitor.status == 'checked-in'
                              ? Colors.green[100]
                              : Colors.red[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          visitor.status == 'checked-in'
                              ? 'Checked In'
                              : 'Checked Out',
                          style: TextStyle(
                            color: visitor.status == 'checked-in'
                                ? Colors.green[800]
                                : Colors.red[800],
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  trailing: visitor.status == 'checked-in'
                      ? PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'checkout') {
                              _checkOutVisitor(visitor);
                            } else if (value == 'delete') {
                              _deleteVisitor(visitor);
                            }
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 'checkout',
                              child: Row(
                                children: [
                                  Icon(Icons.exit_to_app, color: Colors.orange),
                                  SizedBox(width: 8),
                                  Text('Check Out'),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete, color: Colors.red),
                                  SizedBox(width: 8),
                                  Text('Delete'),
                                ],
                              ),
                            ),
                          ],
                        )
                      : PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'delete') {
                              _deleteVisitor(visitor);
                            }
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete, color: Colors.red),
                                  SizedBox(width: 8),
                                  Text('Delete'),
                                ],
                              ),
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

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _checkOutVisitor(Visitor visitor) async {
    try {
      await _visitorService.checkOutVisitor(visitor.id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Visitor checked out successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error checking out visitor: $e')));
    }
  }

  Future<void> _deleteVisitor(Visitor visitor) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Visitor'),
        content: Text('Are you sure you want to delete ${visitor.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _visitorService.deleteVisitor(visitor.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Visitor deleted successfully!')),
        );
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error deleting visitor: $e')));
      }
    }
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Search Visitors'),
        content: TextField(
          decoration: InputDecoration(
            labelText: 'Search by name',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
            });
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Implement search functionality
            },
            child: Text('Search'),
          ),
        ],
      ),
    );
  }
}
