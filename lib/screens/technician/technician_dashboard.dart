import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/ticket_provider.dart';
import '../../models/ticket_model.dart';
import 'ticket_detail_screen.dart';

class TechnicianDashboard extends StatefulWidget {
  @override
  _TechnicianDashboardState createState() => _TechnicianDashboardState();
}

class _TechnicianDashboardState extends State<TechnicianDashboard> {
  // Toggle between 'Open' (Available) and 'In Progress'/'Resolved' (My Tickets)
  bool _showOpenTickets = true;

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    return Scaffold(
      appBar: AppBar(
        title: Text('Dashboard Teknisi'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () => authProvider.logout(),
          )
        ],
      ),
      body: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _showOpenTickets ? Colors.blue[800] : Colors.grey[200],
                    foregroundColor: _showOpenTickets ? Colors.white : Colors.black,
                  ),
                  onPressed: () => setState(() => _showOpenTickets = true),
                  child: Text('Tiket Tersedia (Open)'),
                ),
              ),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: !_showOpenTickets ? Colors.blue[800] : Colors.grey[200],
                    foregroundColor: !_showOpenTickets ? Colors.white : Colors.black,
                  ),
                  onPressed: () => setState(() => _showOpenTickets = false),
                  child: Text('Tiket Saya'),
                ),
              ),
            ],
          ),
          Expanded(
            child: StreamBuilder<List<TicketModel>>(
              stream: Provider.of<TicketProvider>(context, listen: false).fetchTickets(
                role: 'technician',
                uid: user?.uid,
                status: _showOpenTickets ? 'Open' : null,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text("Terjadi kesalahan."));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text("Tidak ada tiket."));
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
                      child: ListTile(
                        title: Text(ticket.category, style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Lokasi: ${ticket.location ?? "-"}'),
                            Text(
                              DateFormat('dd MMM yyyy, HH:mm').format(ticket.createdAt),
                              style: TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                          ],
                        ),
                        trailing: Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(
                            builder: (_) => TicketDetailScreen(ticket: ticket),
                          ));
                        },
                      ),
                    );
                  },
                );
              },
            ),
          )
        ],
      ),
    );
  }
}
