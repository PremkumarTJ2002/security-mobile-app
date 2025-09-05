import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/visitor.dart';
import '../services/visitor_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import '../screens/visitor_list_screen.dart';

class AddVisitorScreen extends StatefulWidget {
  const AddVisitorScreen({Key? key}) : super(key: key);

  @override
  State<AddVisitorScreen> createState() => _AddVisitorScreenState();
}

class _AddVisitorScreenState extends State<AddVisitorScreen> {
  final _formKey = GlobalKey<FormState>();
  final VisitorService _visitorService = VisitorService();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();

  File? _imageFile1; // Face photo
  File? _imageFile2; // ID proof

  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();

  // Owner dropdown
  String? _selectedOwnerId;
  String? _selectedOwnerName;
  String? _selectedOwnerEmail;
  bool _approvableByAll = false;
  List<Map<String, dynamic>> _owners = [];

  // Product Category dropdown
  String? _selectedCategory;
  final List<String> _categories = [
    'M.Sand',
    'P.Sand',
    '20mm',
    '40mm',
    '12mm',
    '6mm',
    'GSB',
    'Wet Mix',
    'Bolders',
    'Hill Earth',
  ];

  @override
  void initState() {
    super.initState();
    _ensureSignedInAndFetchOwners();
  }

  Future<void> _ensureSignedInAndFetchOwners() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        // optionally auto sign-in
      }
      await _fetchOwners();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to authenticate or load owners')),
      );
    }
  }

  Future<void> _fetchOwners() async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'owner')
          .get();

      final ownersList = querySnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'name': data['name'] ?? 'Unnamed',
          'email': data['email'] ?? '',
        };
      }).toList();

      final allOwnersOption = {'id': 'ALL', 'name': 'All Owners', 'email': ''};

      if (!mounted) return;
      setState(() {
        _owners = [allOwnersOption, ...ownersList];

        if (_owners.isNotEmpty) {
          _selectedOwnerId = _owners.first['id'];
          _selectedOwnerName = _owners.first['name'];
          _selectedOwnerEmail = _owners.first['email'];
          _approvableByAll = _selectedOwnerId == 'ALL';
        }
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load owners')),
      );
    }
  }

  Future<void> captureTwoImages() async {
    try {
      final firstImage = await _picker.pickImage(source: ImageSource.camera);
      if (firstImage == null) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('First image not captured')));
        return;
      }
      final secondImage = await _picker.pickImage(source: ImageSource.camera);
      if (secondImage == null) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Second image not captured')));
        return;
      }

      if (!mounted) return;
      setState(() {
        _imageFile1 = File(firstImage.path);
        _imageFile2 = File(secondImage.path);
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Failed to capture images')));
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate() ||
        _imageFile1 == null ||
        _imageFile2 == null ||
        _selectedOwnerId == null ||
        _selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please fill all fields, select owner & category, and take photos')),
      );
      return;
    }

    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) throw Exception('User not logged in');

      final imageUrls = await _visitorService.uploadTwoImagesToS3(
        _imageFile1!,
        _imageFile2!,
      );

      _approvableByAll = _selectedOwnerId == 'ALL';

      final visitor = Visitor(
        id: const Uuid().v4(),
        name: _nameController.text.trim(),
        phone: _mobileController.text.trim(),
        purpose: _reasonController.text.trim(),
        hostName: _approvableByAll ? "ALL" : _selectedOwnerName ?? "",
        entryTime: DateTime.now(),
        photoUrl: imageUrls[0],
        photoUrl2: imageUrls[1],
        status: 'pending',
        productCategory: _selectedCategory ?? 'N/A',
        assignedOwnerUid: _approvableByAll ? null : _selectedOwnerId,
        assignedOwnerName: _approvableByAll ? null : _selectedOwnerName,
        assignedOwnerEmail: _approvableByAll ? null : _selectedOwnerEmail,
        approvableByAll: _approvableByAll,
      );

      await _visitorService.addVisitor(visitor);

      if (!mounted) return;

      // ✅ Navigate first
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const VisitorListScreen()),
      );

      // ✅ Show success AFTER navigation
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Visitor added successfully!')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to add visitor')),
      );
    } finally {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Visitor')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Form(
                key: _formKey,
                child: ListView(
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Name'),
                      validator: (value) =>
                          value == null || value.isEmpty ? 'Enter name' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _mobileController,
                      decoration: const InputDecoration(labelText: 'Mobile Number'),
                      keyboardType: TextInputType.phone,
                      validator: (value) =>
                          value == null || value.isEmpty ? 'Enter mobile number' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _reasonController,
                      decoration: const InputDecoration(labelText: 'Reason for Visit'),
                      validator: (value) =>
                          value == null || value.isEmpty ? 'Enter reason' : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      decoration: const InputDecoration(
                        labelText: 'Product Category',
                        border: OutlineInputBorder(),
                      ),
                      items: _categories.map((category) {
                        return DropdownMenuItem(
                          value: category,
                          child: Text(category),
                        );
                      }).toList(),
                      onChanged: (value) => setState(() => _selectedCategory = value),
                      validator: (value) =>
                          value == null ? 'Select a category' : null,
                    ),
                    const SizedBox(height: 16),
                    _owners.isEmpty
                        ? const Text("No owners available")
                        : DropdownButtonFormField<String>(
                            value: _selectedOwnerId,
                            decoration: const InputDecoration(
                              labelText: "Whom to Visit (Owner)",
                              border: OutlineInputBorder(),
                            ),
                            items: _owners.map((owner) {
                              return DropdownMenuItem<String>(
                                value: owner["id"],
                                child: Text("${owner['name']}"),
                              );
                            }).toList(),
                            onChanged: (value) {
                              final owner =
                                  _owners.firstWhere((o) => o["id"] == value);
                              setState(() {
                                _selectedOwnerId = value;
                                _selectedOwnerName = owner["name"];
                                _selectedOwnerEmail = owner["email"];
                                _approvableByAll = value == 'ALL';
                              });
                            },
                            validator: (value) =>
                                value == null ? "Please select an owner" : null,
                          ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: captureTwoImages,
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Capture Images'),
                    ),
                    const SizedBox(height: 16),
                    if (_imageFile1 != null || _imageFile2 != null)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          if (_imageFile1 != null)
                            Image.file(_imageFile1!, height: 120, width: 120, fit: BoxFit.cover),
                          if (_imageFile2 != null)
                            Image.file(_imageFile2!, height: 120, width: 120, fit: BoxFit.cover),
                        ],
                      ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: _submitForm,
                        icon: const Icon(Icons.check_circle, size: 24),
                        label: const Text(
                          'Submit Visitor',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade600,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
