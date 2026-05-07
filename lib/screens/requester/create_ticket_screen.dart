import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/auth_provider.dart';
import '../../providers/ticket_provider.dart';

class CreateTicketScreen extends StatefulWidget {
  @override
  _CreateTicketScreenState createState() => _CreateTicketScreenState();
}

class _CreateTicketScreenState extends State<CreateTicketScreen> {
  final _formKey = GlobalKey<FormState>();
  String _category = 'Laptop';
  String _priority = 'Medium';
  final _descController = TextEditingController();
  final _locationController = TextEditingController();

  XFile? _imageFile;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    setState(() {
      _imageFile = image;
    });
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      final user = Provider.of<AuthProvider>(context, listen: false).user;
      if (user == null) return;

      try {
        await Provider.of<TicketProvider>(context, listen: false).submitTicket(
          requesterId: user.uid,
          category: _category,
          description: _descController.text,
          priority: _priority,
          location: _locationController.text,
          imageFile: _imageFile,
        );
        if (!mounted) return;
        Navigator.pop(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Tiket berhasil dibuat!')));
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal membuat tiket: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    var isLoading = Provider.of<TicketProvider>(context).isLoading;

    return Scaffold(
      appBar: AppBar(
        title: Text('Buat Tiket Baru'),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.arrow_back_ios_new, color: Colors.white),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<String>(
                value: _category,
                decoration: InputDecoration(
                  labelText: 'Kategori Kerusakan',

                ),
                items: ['Laptop', 'Printer', 'Jaringan', 'Proyektor', 'Lainnya']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (val) {
                  setState(() => _category = val!);
                },
              ),
              SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _priority,
                decoration: InputDecoration(
                  labelText: 'Prioritas',

                ),
                items: ['Low', 'Medium', 'High']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (val) {
                  setState(() => _priority = val!);
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _locationController,
                decoration: InputDecoration(
                  labelText: 'Lokasi (mis: Lab Komputer SBM)',

                ),
                validator: (val) => val!.isEmpty ? 'Wajib diisi' : null,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _descController,
                decoration: InputDecoration(
                  labelText: 'Detail Masalah',

                  floatingLabelBehavior: FloatingLabelBehavior.always,
                ),
                maxLines: 4,
                validator: (val) => val!.isEmpty ? 'Wajib diisi' : null,
              ),
              SizedBox(height: 16),
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 150,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey),
                  ),
                  child: _imageFile != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            File(_imageFile!.path),
                            fit: BoxFit.cover,
                          ),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.camera_alt,
                              size: 40,
                              color: Colors.grey[600],
                            ),
                            SizedBox(height: 8),
                            Text('Ketuk untuk unggah foto (opsional)'),
                          ],
                        ),
                ),
              ),
              SizedBox(height: 32),
              ElevatedButton(
                onPressed: isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.blue[800],
                  foregroundColor: Colors.white,
                ),
                child: isLoading
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text('Kirim Tiket', style: TextStyle(fontSize: 18)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
