import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/ticket_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/ticket_model.dart';

class TicketDetailScreen extends StatelessWidget {
  final TicketModel ticket;

  TicketDetailScreen({required this.ticket});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    final ticketProvider = Provider.of<TicketProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Detail Tiket'),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.arrow_back_ios_new, color: Colors.white),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // if (ticket.imageUrl != null)
            //   ClipRRect(
            //     borderRadius: BorderRadius.circular(12),
            //     child: Image.network(ticket.imageUrl!, height: 200, width: double.infinity, fit: BoxFit.cover),
            //   )
            // else
            //   Container(
            //     height: 200,
            //     width: double.infinity,
            //     decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(12)),
            //     child: Icon(Icons.image_not_supported, size: 50, color: Colors.grey[600]),
            //   ),
            // SizedBox(height: 16),
            Text(
              ticket.category,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.orange[100],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                ticket.status,
                style: TextStyle(
                  color: Colors.orange[800],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.person, color: Colors.blue[800]),
              title: Text('Pelapor'),
              subtitle: FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(ticket.requesterId)
                    .get(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Text('Memuat...');
                  }
                  if (snapshot.hasError ||
                      !snapshot.hasData ||
                      !snapshot.data!.exists) {
                    return Text('Tidak diketahui');
                  }
                  var userData = snapshot.data!.data() as Map<String, dynamic>;
                  return Text(userData['name'] ?? 'Tidak diketahui');
                },
              ),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.location_on, color: Colors.blue[800]),
              title: Text('Lokasi'),
              subtitle: Text(ticket.location ?? 'Tidak diketahui'),
              trailing: Icon(Icons.navigate_next, color: Colors.blue[800]),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.description, color: Colors.blue[800]),
              title: Text('Deskripsi'),
              subtitle: Text(ticket.description),
            ),
            SizedBox(height: 32),
            if (ticket.status == 'Open')
              ElevatedButton(
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
                  minimumSize: Size(double.infinity, 50),
                  backgroundColor: Colors.blue[800],
                  foregroundColor: Colors.white,
                ),
                child: ticketProvider.isLoading
                    ? CircularProgressIndicator()
                    : Text('Ambil Tiket Ini'),
              )
            else if (ticket.status == 'In Progress' &&
                ticket.technicianId == user?.uid)
              ElevatedButton(
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
                  minimumSize: Size(double.infinity, 50),
                  backgroundColor: Colors.green[700],
                  foregroundColor: Colors.white,
                ),
                child: ticketProvider.isLoading
                    ? CircularProgressIndicator()
                    : Text('Tandai Selesai'),
              ),
          ],
        ),
      ),
    );
  }
}
