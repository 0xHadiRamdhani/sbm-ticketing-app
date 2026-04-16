import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/ticket_provider.dart';
import '../../models/ticket_model.dart';
import 'create_ticket_screen.dart';

class RequesterDashboard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    return Scaffold(
      appBar: AppBar(
        title: Text('Tiket Saya'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () {
              authProvider.logout();
            },
          )
        ],
      ),
      body: StreamBuilder<List<TicketModel>>(
        stream: Provider.of<TicketProvider>(context, listen: false).fetchTickets(
          role: user?.role,
          uid: user?.uid,
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Terjadi kesalahan sistem."));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text("Belum ada tiket yang diajukan."));
          }

          final tickets = snapshot.data!;
          return ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: tickets.length,
            itemBuilder: (context, index) {
              final ticket = tickets[index];
              return Card(
                elevation: 3,
                margin: EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  contentPadding: EdgeInsets.all(16),
                  title: Text(
                    ticket.category,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 8),
                      Text(ticket.description, maxLines: 2, overflow: TextOverflow.ellipsis),
                      SizedBox(height: 8),
                      Text(
                        DateFormat('dd MMM yyyy, HH:mm').format(ticket.createdAt),
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                  trailing: Chip(
                    label: Text(
                      ticket.status,
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    backgroundColor: _getStatusColor(ticket.status),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => CreateTicketScreen()));
        },
        icon: Icon(Icons.add),
        label: Text('Buat Tiket'),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Open': return Colors.blue;
      case 'In Progress': return Colors.orange;
      case 'Resolved': return Colors.green;
      default: return Colors.grey;
    }
  }
}
