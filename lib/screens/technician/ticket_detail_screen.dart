import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/ticket_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../models/ticket_model.dart';
import '../chat_screen.dart';

class TicketDetailScreen extends StatelessWidget {
  final TicketModel ticket;

  TicketDetailScreen({required this.ticket});

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'open':
        return Colors.red;
      case 'in progress':
        return Colors.orange.shade700;
      case 'resolved':
        return Colors.green;
      default:
        return Colors.grey.shade700;
    }
  }

  Color _getStatusBgColor(String status) {
    switch (status.toLowerCase()) {
      case 'open':
        return Colors.red.shade50;
      case 'in progress':
        return Colors.orange.shade50;
      case 'resolved':
        return Colors.green.shade50;
      default:
        return Colors.grey.shade100;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    final ticketProvider = Provider.of<TicketProvider>(context);

    return Scaffold(
      backgroundColor: Colors.grey[50], // Lighter background
      appBar: AppBar(
        title: Text(
          'Detail Tiket',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
        ),
        centerTitle: true,
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.arrow_back_ios_new, size: 20),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.chat_bubble_outline),
            tooltip: 'Chat',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ChatScreen(ticket: ticket)),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Badge
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: _getStatusBgColor(ticket.status),
                borderRadius: BorderRadius.circular(
                  6,
                ), // Slightly rounded instead of circular
                border: Border.all(
                  color: _getStatusColor(ticket.status).withOpacity(0.3),
                ),
              ),
              child: Text(
                ticket.status.toUpperCase(),
                style: TextStyle(
                  color: _getStatusColor(ticket.status),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            SizedBox(height: 16),

            // Category Title
            Text(
              ticket.category,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 24),

            Text(
              'Lampiran Foto',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                ticket.imageUrl!,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 150,
                    color: Colors.grey[200],
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.broken_image,
                      color: Colors.grey[400],
                      size: 50,
                    ),
                  );
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    height: 150,
                    color: Colors.grey[100],
                    alignment: Alignment.center,
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 24),

            // Detail Cards
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10), // Not too round
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildDetailRow(
                    icon: Icons.person_outline,
                    title: 'Pelapor',
                    child: FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('users')
                          .doc(ticket.requesterId)
                          .get(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Text(
                            'Memuat...',
                            style: TextStyle(color: Colors.grey),
                          );
                        }
                        if (snapshot.hasError ||
                            !snapshot.hasData ||
                            !snapshot.data!.exists) {
                          return Text(
                            'Tidak diketahui',
                            style: TextStyle(fontWeight: FontWeight.w500),
                          );
                        }
                        var userData =
                            snapshot.data!.data() as Map<String, dynamic>;
                        return Text(
                          userData['name'] ?? 'Tidak diketahui',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 15,
                          ),
                        );
                      },
                    ),
                  ),
                  Divider(height: 1, color: Colors.grey.shade100),
                  _buildDetailRow(
                    icon: Icons.calendar_today_outlined,
                    title: 'Tanggal',
                    child: Text(
                      DateFormat('dd MMM yyyy, HH:mm').format(ticket.createdAt),
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  Divider(height: 1, color: Colors.grey.shade100),
                  _buildDetailRow(
                    icon: Icons.location_on_outlined,
                    title: 'Lokasi',
                    child: Text(
                      ticket.location ?? 'Tidak diketahui',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24),

            // Description
            Text(
              'Deskripsi Masalah',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10), // Not too round
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Text(
                ticket.description,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.5,
                  color: Colors.black87,
                ),
              ),
            ),

            // // Image Attachment
            // if (ticket.imageUrl != null && ticket.imageUrl!.isNotEmpty) ...[
            //   SizedBox(height: 24),
            //   Text(
            //     'Lampiran Foto',
            //     style: TextStyle(
            //       fontSize: 16,
            //       fontWeight: FontWeight.w600,
            //       color: Colors.grey[800],
            //     ),
            //   ),
            //   SizedBox(height: 12),
            //   ClipRRect(
            //     borderRadius: BorderRadius.circular(10),
            //     child: Image.network(
            //       ticket.imageUrl!,
            //       width: double.infinity,
            //       fit: BoxFit.cover,
            //       errorBuilder: (context, error, stackTrace) {
            //         return Container(
            //           height: 150,
            //           color: Colors.grey[200],
            //           alignment: Alignment.center,
            //           child: Icon(Icons.broken_image, color: Colors.grey[400], size: 50),
            //         );
            //       },
            //     ),
            //   ),
            // ],

            // Resolved Image Attachments
            if (ticket.resolvedImageUrls != null &&
                ticket.resolvedImageUrls!.isNotEmpty) ...[
              SizedBox(height: 12),
              Text(
                'Bukti Penyelesaian',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
              SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ticket.resolvedImageUrls!
                    .map(
                      (url) => ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          url,
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 100,
                              height: 100,
                              color: Colors.grey[200],
                              alignment: Alignment.center,
                              child: Icon(
                                Icons.broken_image,
                                color: Colors.grey[400],
                                size: 30,
                              ),
                            );
                          },
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],

            SizedBox(height: 40),

            // Technician Action Buttons
            if (user?.role == 'technician') ...[
              if (ticket.status == 'Open')
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: ticketProvider.isLoading
                        ? null
                        : () async {
                            await ticketProvider.updateTicketStatus(
                              ticket.ticketId,
                              'In Progress',
                              technicianId: user?.uid,
                            );
                            if (!context.mounted) return;
                            Navigator.pop(context);
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[800],
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ), // Semi-rounded corners
                    ),
                    child: ticketProvider.isLoading
                        ? SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            'Ambil Tiket Ini',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                )
              else if (ticket.status == 'In Progress' &&
                  ticket.technicianId == user?.uid)
                _ResolveTicketAction(
                  ticketId: ticket.ticketId,
                  ticketProvider: ticketProvider,
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: Colors.blue[700]),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[500],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 4),
                child,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ResolveTicketAction extends StatefulWidget {
  final String ticketId;
  final TicketProvider ticketProvider;

  _ResolveTicketAction({required this.ticketId, required this.ticketProvider});

  @override
  __ResolveTicketActionState createState() => __ResolveTicketActionState();
}

class __ResolveTicketActionState extends State<_ResolveTicketAction> {
  List<XFile> _resolvedImages = [];
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImages() async {
    if (_resolvedImages.length >= 3) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Maksimal 3 foto')));
      return;
    }
    final List<XFile> selectedImages = await _picker.pickMultiImage();
    if (selectedImages.isNotEmpty) {
      setState(() {
        _resolvedImages.addAll(selectedImages);
        if (_resolvedImages.length > 3) {
          _resolvedImages = _resolvedImages.sublist(0, 3);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Hanya 3 foto pertama yang diambil')),
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_resolvedImages.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _resolvedImages
                .map(
                  (img) => Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          File(img.path),
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        right: 0,
                        top: 0,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _resolvedImages.remove(img);
                            });
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            padding: EdgeInsets.all(2),
                            child: Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
                .toList(),
          ),
        SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _resolvedImages.length < 3 ? _pickImages : null,
          icon: Icon(Icons.add_a_photo),
          label: Text('Tambah Foto Bukti (Maks 3)'),
          style: OutlinedButton.styleFrom(
            padding: EdgeInsets.symmetric(vertical: 12),
          ),
        ),
        SizedBox(height: 12),
        SizedBox(
          height: 50,
          child: ElevatedButton(
            onPressed: widget.ticketProvider.isLoading
                ? null
                : () async {
                    await widget.ticketProvider.updateTicketStatus(
                      widget.ticketId,
                      'Resolved',
                      resolvedImages: _resolvedImages,
                    );
                    if (!context.mounted) return;
                    Navigator.pop(context);
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[700],
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: widget.ticketProvider.isLoading
                ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    'Tandai Selesai',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
          ),
        ),
      ],
    );
  }
}
