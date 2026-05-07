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
                MaterialPageRoute(
                  builder: (_) => ChatScreen(ticket: ticket),
                ),
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
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: ticketProvider.isLoading
                        ? null
                        : () async {
                            await ticketProvider.updateTicketStatus(
                              ticket.ticketId,
                              'Resolved',
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
                            'Tandai Selesai',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
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
