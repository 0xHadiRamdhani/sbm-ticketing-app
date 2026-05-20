// lib/screens/shared/ticket_card.dart
// Shared widgets untuk Ticket List di semua dashboard
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../models/ticket_model.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_colors.dart';
import 'package:provider/provider.dart';
import '../technician/ticket_detail_screen.dart';
import '../requester/requester_ticket_detail_screen.dart';
import '../admin/admin_ticket_detail_screen.dart';

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
  final bool isSelectionMode;
  final bool isSelected;
  final ValueChanged<bool?>? onSelect;

  const TicketCard({
    super.key, 
    required this.ticket,
    this.isSelectionMode = false,
    this.isSelected = false,
    this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final shortId =
        '#TKT-${ticket.ticketId.substring(0, 4).toUpperCase()}-${ticket.ticketId.substring(4, 8).toUpperCase()}';

    return GestureDetector(
      onTap: isSelectionMode 
          ? () => onSelect?.call(!isSelected)
          : () {
        final user = Provider.of<AuthProvider>(context, listen: false).user;
        if (user?.role == 'student' || user?.role == 'staff' || (user?.role == 'technician' && user?.uid == ticket.requesterId)) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => RequesterTicketDetailScreen(ticket: ticket)));
        } else if (user?.role == 'admin') {
          Navigator.push(context, MaterialPageRoute(builder: (_) => AdminTicketDetailScreen(ticket: ticket)));
        } else {
          Navigator.push(context, MaterialPageRoute(builder: (_) => TicketDetailScreen(ticket: ticket)));
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(c.isDark ? 0.2 : 0.05),
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
              decoration: BoxDecoration(
                color: c.cardHeader,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  Text(
                    shortId,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: c.primary,
                    ),
                  ),
                  if (isSelectionMode) ...[
                    const SizedBox(width: 12),
                    SizedBox(
                      height: 24,
                      width: 24,
                      child: Checkbox(
                        value: isSelected,
                        onChanged: onSelect,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                        activeColor: c.primary,
                      ),
                    ),
                  ],
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                          color: c.accentLight,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(categoryIcon(ticket.category),
                            size: 22, color: c.accent),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              ticket.category.toUpperCase(),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: c.textLabel,
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              ticket.description.length > 40
                                  ? '${ticket.description.substring(0, 40)}...'
                                  : ticket.description,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: c.textPrimary,
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
                    TicketInfoRow(icon: Icons.location_on_outlined, text: ticket.location!),
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
                    style: TextStyle(fontSize: 12, color: c.textMuted),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      final user = Provider.of<AuthProvider>(context, listen: false).user;
                      if (user?.role == 'student' || user?.role == 'staff' || (user?.role == 'technician' && user?.uid == ticket.requesterId)) {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => RequesterTicketDetailScreen(ticket: ticket)));
                      } else if (user?.role == 'admin') {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => AdminTicketDetailScreen(ticket: ticket)));
                      } else {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => TicketDetailScreen(ticket: ticket)));
                      }
                    },
                    child: Text(
                      'Detail',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: c.accent,
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
    final c = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 15, color: c.textMuted),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 13, color: c.textSecondary),
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
      future: FirebaseFirestore.instance.collection('users').doc(requesterId).get(),
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
        return TicketInfoRow(icon: Icons.person_outline_rounded, text: display);
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
  const DashboardBottomNav({
    super.key,
    required this.selected,
    required this.onTap,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      height: 72,
      decoration: BoxDecoration(
        color: c.navBg,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(c.isDark ? 0.3 : 0.07),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
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
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: sel ? c.navSelected : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      items[i].icon,
                      size: 22,
                      color: sel ? Colors.white : c.navUnselected,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    items[i].label,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: sel ? c.navSelected : c.navUnselected,
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
  const DashboardEmptyState({super.key, required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 64, color: c.textMuted),
          const SizedBox(height: 16),
          Text(message, style: TextStyle(fontSize: 15, color: c.textSecondary)),
        ],
      ),
    );
  }
}

// ─── Shared AppBar ────────────────────────────────────────────────────────────
PreferredSizeWidget buildSbmAppBar({
  BuildContext? context,
  VoidCallback? onSettingsTap,
  List<Widget>? extraActions,
  bool showBackButton = false,
  VoidCallback? onBackPressed,
  String? titleText,
}) {
  return _SbmAppBar(
    context: context,
    onSettingsTap: onSettingsTap,
    extraActions: extraActions,
    showBackButton: showBackButton,
    onBackPressed: onBackPressed,
    titleText: titleText,
  );
}

class _SbmAppBar extends StatelessWidget implements PreferredSizeWidget {
  final BuildContext? externalContext;
  final VoidCallback? onSettingsTap;
  final List<Widget>? extraActions;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final String? titleText;

  const _SbmAppBar({
    BuildContext? context,
    this.onSettingsTap,
    this.extraActions,
    this.showBackButton = false,
    this.onBackPressed,
    this.titleText,
  }) : externalContext = context;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return AppBar(
      backgroundColor: c.appBarBg,
      elevation: 0.5,
      shadowColor: c.appBarShadow,
      automaticallyImplyLeading: showBackButton,
      leading: showBackButton
          ? IconButton(
              icon: Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: c.primary),
              onPressed: onBackPressed,
            )
          : null,
      titleSpacing: showBackButton ? 0 : 16,
      title: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: c.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: const Text('ITB',
                style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 10),
          Text(
            titleText ?? 'SBM ITB Support',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: c.appBarFg,
            ),
          ),
        ],
      ),
      actions: [
        if (extraActions != null) ...extraActions!,
        if (onSettingsTap != null)
          IconButton(
            icon: Icon(Icons.settings_outlined, color: c.primary, size: 24),
            tooltip: 'Pengaturan',
            onPressed: onSettingsTap,
          ),
        const SizedBox(width: 4),
      ],
    );
  }
}
