import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/ticket_provider.dart';
import '../../models/ticket_model.dart';
import '../../services/notification_service.dart';
import 'ticket_detail_screen.dart';
import 'dart:async';

class TechnicianDashboard extends StatefulWidget {
  @override
  _TechnicianDashboardState createState() => _TechnicianDashboardState();
}

class _TechnicianDashboardState extends State<TechnicianDashboard> {
  // Toggle between 'Open' (Available) and 'In Progress'/'Resolved' (My Tickets)
  bool _showOpenTickets = true;
  StreamSubscription<List<TicketModel>>? _notificationSubscription;
  bool _isFirstNotificationLoad = true;
  Set<String> _knownOpenTickets = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startNotificationListener();
    });
  }

  void _startNotificationListener() {
    final provider = Provider.of<TicketProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    _notificationSubscription = provider
        .fetchTickets(
          role: 'technician',
          uid: authProvider.user?.uid,
          status: 'Open',
        )
        .listen((tickets) {
          if (_isFirstNotificationLoad) {
            _knownOpenTickets = tickets.map((t) => t.ticketId).toSet();
            _isFirstNotificationLoad = false;
            return;
          }

          for (var ticket in tickets) {
            if (!_knownOpenTickets.contains(ticket.ticketId)) {
              _knownOpenTickets.add(ticket.ticketId);
              NotificationService().showNotification(
                id: ticket.ticketId.hashCode,
                title: 'Tiket Baru Masuk!',
                body:
                    '${ticket.category} - ${ticket.location ?? "Tanpa Lokasi"}',
              );
            }
          }
        });
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    super.dispose();
  }

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
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.all(5),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _showOpenTickets
                          ? Colors.blue[800]
                          : Colors.grey[200],
                      foregroundColor: _showOpenTickets
                          ? Colors.white
                          : Colors.black,
                    ),
                    onPressed: () => setState(() => _showOpenTickets = true),
                    child: Text('Tiket Tersedia (Open)'),
                  ),
                ),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: !_showOpenTickets
                          ? Colors.blue[800]
                          : Colors.grey[200],
                      foregroundColor: !_showOpenTickets
                          ? Colors.white
                          : Colors.black,
                    ),
                    onPressed: () => setState(() => _showOpenTickets = false),
                    child: Text('Tiket Saya'),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<TicketModel>>(
              stream: Provider.of<TicketProvider>(context, listen: false)
                  .fetchTickets(
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
                      child: ListTile(
                        title: Text(
                          ticket.category,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Lokasi: ${ticket.location ?? "-"}'),
                            Text(
                              DateFormat(
                                'dd MMM yyyy, HH:mm',
                              ).format(ticket.createdAt),
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        trailing: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusBgColor(ticket.status),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: _getStatusColor(
                                ticket.status,
                              ).withOpacity(0.3),
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
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  TicketDetailScreen(ticket: ticket),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

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
}
