// lib/screens/shared/ticket_card.dart
// Shared widgets untuk Ticket List di semua dashboard
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../models/ticket_model.dart';
import '../technician/ticket_detail_screen.dart';

// ─── Category Icons ───────────────────────────────────────────────────────────
IconData categoryIcon(String category) {
  final c = category.toLowerCase();
  if (c.contains('laptop') || c.contains('komputer') || c.contains('it') ||
      c.contains('proyektor')) return Icons.laptop_outlined;
  if (c.contains('printer')) return Icons.print_outlined;
  if (c.contains('jaringan') || c.contains('wifi') || c.contains('network'))
    return Icons.wifi_outlined;
  if (c.contains('ac') || c.contains('fasilitas') || c.contains('kran') ||
      c.contains('toilet')) return Icons.build_outlined;
  return Icons.confirmation_number_outlined;
}

// ─── Status helpers ───────────────────────────────────────────────────────────
Color statusDotColor(String s) {
  switch (s.toLowerCase()) {
    case 'in progress': return const Color(0xFF1A73E8);
    case 'resolved':    return const Color(0xFF1E8C45);
    case 'pending':     return const Color(0xFFF29900);
    case 'open':        return const Color(0xFF9E9E9E);
    default:            return const Color(0xFF9E9E9E);
  }
}

String statusLabel(String s) {
  switch (s.toLowerCase()) {
    case 'in progress': return 'IN PROGRESS';
    case 'resolved':    return 'RESOLVED';
    case 'pending':     return 'PENDING';
    case 'open':        return 'OPEN';
    default:            return s.toUpperCase();
  }
}

String timeAgo(DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inSeconds < 60)  return 'Baru saja';
  if (diff.inMinutes < 60)  return 'Update ${diff.inMinutes} menit lalu';
  if (diff.inHours < 24)    return 'Update ${diff.inHours} jam lalu';
  if (diff.inDays == 1)     return 'Update 1 hari lalu';
  return 'Update ${diff.inDays} hari lalu';
}

// ─── Ticket Card ──────────────────────────────────────────────────────────────
class TicketCard extends StatelessWidget {
  final TicketModel ticket;
  const TicketCard({super.key, required this.ticket});

  @override
  Widget build(BuildContext context) {
    final shortId =
        '#TKT-${ticket.ticketId.substring(0, 4).toUpperCase()}-${ticket.ticketId.substring(4, 8).toUpperCase()}';

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => TicketDetailScreen(ticket: ticket)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            // ── Header ────────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: const BoxDecoration(
                color: Color(0xFFF0F4FF),
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  Text(
                    shortId,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A3A5C),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusDotColor(ticket.status).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: statusDotColor(ticket.status),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          statusLabel(ticket.status),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: statusDotColor(ticket.status),
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Content ───────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEF2FF),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(categoryIcon(ticket.category),
                            size: 22, color: const Color(0xFF1A73E8)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              ticket.category.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF9CA3AF),
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              ticket.description.length > 40
                                  ? '${ticket.description.substring(0, 40)}...'
                                  : ticket.description,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1A1A2E),
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (ticket.location != null && ticket.location!.isNotEmpty)
                    TicketInfoRow(
                        icon: Icons.location_on_outlined,
                        text: ticket.location!),
                  RequesterInfoRow(requesterId: ticket.requesterId),
                ],
              ),
            ),

            // ── Footer ────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  Text(
                    timeAgo(ticket.createdAt),
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF9CA3AF)),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => TicketDetailScreen(ticket: ticket)),
                    ),
                    child: const Text(
                      'Detail',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A73E8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Info Row ─────────────────────────────────────────────────────────────────
class TicketInfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const TicketInfoRow({super.key, required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 15, color: const Color(0xFF9CA3AF)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Requester Row (async) ────────────────────────────────────────────────────
class RequesterInfoRow extends StatelessWidget {
  final String requesterId;
  const RequesterInfoRow({super.key, required this.requesterId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(requesterId)
          .get(),
      builder: (_, snap) {
        String display = 'Memuat...';
        if (snap.hasData && snap.data!.exists) {
          final d = snap.data!.data() as Map<String, dynamic>;
          final name = d['name'] ?? '-';
          final role = d['role'] ?? '';
          String roleLabel = '';
          if (role == 'student') roleLabel = 'Mahasiswa';
          else if (role == 'staff') roleLabel = 'Dosen';
          else if (role == 'admin') roleLabel = 'Admin';
          else roleLabel = role;
          display = roleLabel.isNotEmpty ? '$name ($roleLabel)' : name;
        }
        return TicketInfoRow(
            icon: Icons.person_outline_rounded, text: display);
      },
    );
  }
}

// ─── Bottom Nav Item ──────────────────────────────────────────────────────────
class NavItem {
  final IconData icon;
  final String label;
  const NavItem({required this.icon, required this.label});
}

// ─── Dashboard Bottom Nav ─────────────────────────────────────────────────────
class DashboardBottomNav extends StatelessWidget {
  final int selected;
  final void Function(int) onTap;
  final List<NavItem> items;
  const DashboardBottomNav(
      {super.key,
      required this.selected,
      required this.onTap,
      required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.07),
              blurRadius: 12,
              offset: const Offset(0, -3)),
        ],
      ),
      child: Row(
        children: List.generate(items.length, (i) {
          final sel = selected == i;
          return Expanded(
            child: GestureDetector(
              onTap: () => onTap(i),
              behavior: HitTestBehavior.opaque,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: sel
                          ? const Color(0xFF1A3A5C)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      items[i].icon,
                      size: 22,
                      color:
                          sel ? Colors.white : const Color(0xFF9CA3AF),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    items[i].label,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: sel
                          ? const Color(0xFF1A3A5C)
                          : const Color(0xFF9CA3AF),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────
class DashboardEmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  const DashboardEmptyState(
      {super.key, required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 64, color: const Color(0xFFD1D5DB)),
          const SizedBox(height: 16),
          Text(message,
              style: const TextStyle(
                  fontSize: 15, color: Color(0xFF9CA3AF))),
        ],
      ),
    );
  }
}

// ─── Shared AppBar ────────────────────────────────────────────────────────────
PreferredSizeWidget buildSbmAppBar({VoidCallback? onSettingsTap, List<Widget>? extraActions}) {
  return AppBar(
    backgroundColor: Colors.white,
    elevation: 0.5,
    shadowColor: Colors.black12,
    automaticallyImplyLeading: false,
    titleSpacing: 16,
    title: Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFF1A3A5C),
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: const Text('ITB',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold)),
        ),
        const SizedBox(width: 10),
        const Text(
          'SBM ITB Support',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A3A5C),
          ),
        ),
      ],
    ),
    actions: [
      if (extraActions != null) ...extraActions,
      IconButton(
        icon: const Icon(Icons.settings_outlined,
            color: Color(0xFF1A3A5C), size: 24),
        tooltip: 'Pengaturan',
        onPressed: onSettingsTap,
      ),
      const SizedBox(width: 4),
    ],
  );
}
