import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../utils/app_colors.dart';

// ── Breakpoints ───────────────────────────────────────────────────────────────
const double kDesktopBreak = 900;
const double kTabletBreak = 600;

// ── Nav items (role-aware) ────────────────────────────────────────────────────
class WebNavItem {
  final IconData icon;
  final IconData iconActive;
  final String label;
  const WebNavItem({
    required this.icon,
    required this.iconActive,
    required this.label,
  });
}

List<WebNavItem> getNavItemsForRole(String role) {
  switch (role) {
    case 'admin':
      return const [
        WebNavItem(icon: Icons.dashboard_outlined, iconActive: Icons.dashboard_rounded, label: 'Dashboard'),
        WebNavItem(icon: Icons.confirmation_number_outlined, iconActive: Icons.confirmation_number_rounded, label: 'Tiket'),
        WebNavItem(icon: Icons.bar_chart_outlined, iconActive: Icons.bar_chart_rounded, label: 'Statistik'),
        WebNavItem(icon: Icons.people_outline_rounded, iconActive: Icons.people_rounded, label: 'Pengguna'),
      ];
    case 'technician':
      return const [
        WebNavItem(icon: Icons.dashboard_outlined, iconActive: Icons.dashboard_rounded, label: 'Dashboard'),
        WebNavItem(icon: Icons.assignment_outlined, iconActive: Icons.assignment_rounded, label: 'Tiket Saya'),
        WebNavItem(icon: Icons.bar_chart_outlined, iconActive: Icons.bar_chart_rounded, label: 'Statistik'),
      ];
    case 'student':
    case 'staff':
    default:
      return const [
        WebNavItem(icon: Icons.dashboard_outlined, iconActive: Icons.dashboard_rounded, label: 'Dashboard'),
        WebNavItem(icon: Icons.confirmation_number_outlined, iconActive: Icons.confirmation_number_rounded, label: 'Tiket Saya'),
        WebNavItem(icon: Icons.bar_chart_outlined, iconActive: Icons.bar_chart_rounded, label: 'Laporan'),
      ];
  }
}

// ── Public layout shell ───────────────────────────────────────────────────────
class WebLayout extends StatefulWidget {
  final int selectedIndex;
  final ValueChanged<int> onNavSelected;
  final Widget child;

  const WebLayout({
    Key? key,
    required this.selectedIndex,
    required this.onNavSelected,
    required this.child,
  }) : super(key: key);

  @override
  State<WebLayout> createState() => _WebLayoutState();
}

class _WebLayoutState extends State<WebLayout> {
  bool _sidebarCollapsed = false;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final role = context.watch<AuthProvider>().user?.role ?? 'student';

    if (width >= kDesktopBreak) {
      return _DesktopLayout(
        selectedIndex: widget.selectedIndex,
        onNavSelected: widget.onNavSelected,
        collapsed: _sidebarCollapsed,
        onToggleCollapse: () => setState(() => _sidebarCollapsed = !_sidebarCollapsed),
        role: role,
        child: widget.child,
      );
    } else if (width >= kTabletBreak) {
      return _TabletLayout(
        selectedIndex: widget.selectedIndex,
        onNavSelected: widget.onNavSelected,
        role: role,
        child: widget.child,
      );
    } else {
      return _MobileLayout(
        selectedIndex: widget.selectedIndex,
        onNavSelected: widget.onNavSelected,
        role: role,
        child: widget.child,
      );
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  DESKTOP LAYOUT (≥ 900px) — premium persistent sidebar
// ─────────────────────────────────────────────────────────────────────────────
class _DesktopLayout extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onNavSelected;
  final bool collapsed;
  final VoidCallback onToggleCollapse;
  final String role;
  final Widget child;

  const _DesktopLayout({
    required this.selectedIndex,
    required this.onNavSelected,
    required this.collapsed,
    required this.onToggleCollapse,
    required this.role,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final navItems = getNavItemsForRole(role);
    final user = context.watch<AuthProvider>().user;

    return Scaffold(
      backgroundColor: c.background,
      body: Row(
        children: [
          // ── Premium Sidebar ──────────────────────────────────────────────
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            width: collapsed ? 72 : 240,
            decoration: BoxDecoration(
              color: c.isDark ? const Color(0xFF0F1923) : const Color(0xFF0F2240),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.25),
                  blurRadius: 20,
                  offset: const Offset(4, 0),
                ),
              ],
            ),
            child: Column(
              children: [
                // Logo/Header area
                Container(
                  height: 68,
                  padding: EdgeInsets.symmetric(horizontal: collapsed ? 0 : 20),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.white.withOpacity(0.08)),
                    ),
                  ),
                  child: collapsed
                      ? Center(
                          child: Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.all(4),
                            child: Image.asset(
                              'assets/itb.png',
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => const Icon(Icons.confirmation_num_rounded, color: Color(0xFF1D4ED8), size: 22),
                            ),
                          ),
                        )
                      : Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: const EdgeInsets.all(4),
                              child: Image.asset(
                                'assets/itb.png',
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => const Icon(Icons.confirmation_num_rounded, color: Color(0xFF1D4ED8), size: 22),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  'SBM ITB',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                Text(
                                  'Admin Panel',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF94A3B8),
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                ),

                // Nav items
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: ListView.builder(
                      padding: EdgeInsets.zero,
                      itemCount: navItems.length,
                      itemBuilder: (ctx, i) {
                        final item = navItems[i];
                        final selected = i == selectedIndex;
                        return _SidebarNavTile(
                          icon: selected ? item.iconActive : item.icon,
                          label: item.label,
                          selected: selected,
                          collapsed: collapsed,
                          onTap: () => onNavSelected(i),
                        );
                      },
                    ),
                  ),
                ),

                // Bottom section — user info + collapse toggle
                Container(
                  decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: Colors.white.withOpacity(0.08))),
                  ),
                  child: Column(
                    children: [
                      // User tile
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: collapsed ? 8 : 16,
                          vertical: 12,
                        ),
                        child: _SidebarUserTile(
                          name: user?.name ?? 'User',
                          email: user?.email ?? '',
                          role: user?.role ?? 'user',
                          collapsed: collapsed,
                        ),
                      ),
                      // Collapse toggle
                      Padding(
                        padding: EdgeInsets.only(
                          left: collapsed ? 0 : 16,
                          right: collapsed ? 0 : 16,
                          bottom: 12,
                        ),
                        child: InkWell(
                          onTap: onToggleCollapse,
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            height: 36,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: collapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
                              children: [
                                if (!collapsed) const SizedBox(width: 12),
                                Icon(
                                  collapsed ? Icons.chevron_right_rounded : Icons.chevron_left_rounded,
                                  color: const Color(0xFF94A3B8),
                                  size: 20,
                                ),
                                if (!collapsed) ...[
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Ciutkan sidebar',
                                    style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Main content area ────────────────────────────────────────────
          Expanded(
            child: Column(
              children: [
                // Premium top bar
                Container(
                  height: 68,
                  decoration: BoxDecoration(
                    color: c.surface,
                    border: Border(bottom: BorderSide(color: c.border.withOpacity(0.6))),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(c.isDark ? 0.15 : 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Row(
                    children: [
                      // Breadcrumb / page title area
                      Text(
                        _getPageTitle(selectedIndex, role),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: c.textPrimary,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const Spacer(),
                      // Notification bell
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: c.background,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: c.border),
                        ),
                        child: Icon(Icons.notifications_outlined, color: c.textSecondary, size: 20),
                      ),
                      const SizedBox(width: 10),
                      // Theme toggle
                      Consumer<ThemeProvider>(
                        builder: (context, themeProvider, _) {
                          return Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: c.background,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: c.border),
                            ),
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              icon: Icon(
                                themeProvider.isDarkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                                color: c.textSecondary,
                                size: 19,
                              ),
                              onPressed: () => themeProvider.toggleTheme(!themeProvider.isDarkMode),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 14),
                      // User avatar + menu
                      PopupMenuButton(
                        offset: const Offset(0, 48),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        color: c.surface,
                        elevation: 8,
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 17,
                              backgroundColor: const Color(0xFF1D4ED8),
                              child: Text(
                                user?.name.isNotEmpty == true ? user!.name[0].toUpperCase() : '?',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user?.name ?? 'User',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: c.textPrimary),
                                ),
                                Text(
                                  (user?.role ?? '').toUpperCase(),
                                  style: const TextStyle(fontSize: 10, color: Color(0xFF3B82F6), fontWeight: FontWeight.bold, letterSpacing: 0.5),
                                ),
                              ],
                            ),
                            const SizedBox(width: 6),
                            Icon(Icons.keyboard_arrow_down, color: c.textMuted, size: 18),
                          ],
                        ),
                        itemBuilder: (ctx) => [
                          PopupMenuItem(
                            child: Row(children: [Icon(Icons.logout_rounded, size: 18, color: Colors.red.shade400), const SizedBox(width: 10), const Text('Keluar')]),
                            onTap: () => context.read<AuthProvider>().logout(),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Page content
                Expanded(child: child),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getPageTitle(int index, String role) {
    final items = getNavItemsForRole(role);
    if (index >= 0 && index < items.length) return items[index].label;
    return 'Dashboard';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  TABLET LAYOUT (600-899px) — drawer + AppBar
// ─────────────────────────────────────────────────────────────────────────────
class _TabletLayout extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onNavSelected;
  final String role;
  final Widget child;

  const _TabletLayout({
    required this.selectedIndex,
    required this.onNavSelected,
    required this.role,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final navItems = getNavItemsForRole(role);
    final user = context.watch<AuthProvider>().user;

    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        backgroundColor: c.surface,
        elevation: 0,
        title: Text('SBM ITB', style: TextStyle(color: c.textPrimary, fontWeight: FontWeight.bold)),
        iconTheme: IconThemeData(color: c.textPrimary),
        actions: [
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, _) => IconButton(
              icon: Icon(themeProvider.isDarkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded, color: c.textSecondary),
              onPressed: () => themeProvider.toggleTheme(!themeProvider.isDarkMode),
            ),
          ),
        ],
      ),
      drawer: Drawer(
        backgroundColor: const Color(0xFF0F2240),
        child: Column(
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Color(0xFF0A1929)),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: const Color(0xFF1D4ED8),
                    child: Text(user?.name.isNotEmpty == true ? user!.name[0].toUpperCase() : '?',
                        style: const TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 10),
                  Text(user?.name ?? 'User', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 2),
                  Text((user?.role ?? '').toUpperCase(), style: const TextStyle(color: Color(0xFF3B82F6), fontSize: 11, letterSpacing: 0.5)),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: navItems.length,
                itemBuilder: (ctx, i) {
                  final item = navItems[i];
                  final selected = i == selectedIndex;
                  return ListTile(
                    leading: Icon(selected ? item.iconActive : item.icon, color: selected ? const Color(0xFF3B82F6) : const Color(0xFF94A3B8)),
                    title: Text(item.label, style: TextStyle(color: selected ? const Color(0xFF3B82F6) : Colors.white, fontWeight: selected ? FontWeight.bold : FontWeight.normal)),
                    onTap: () { Navigator.pop(context); onNavSelected(i); },
                  );
                },
              ),
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Color(0xFF94A3B8)),
              title: const Text('Keluar', style: TextStyle(color: Colors.white)),
              onTap: () => context.read<AuthProvider>().logout(),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
      body: child,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  MOBILE LAYOUT (<600px) — bottom navigation bar
// ─────────────────────────────────────────────────────────────────────────────
class _MobileLayout extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onNavSelected;
  final String role;
  final Widget child;

  const _MobileLayout({
    required this.selectedIndex,
    required this.onNavSelected,
    required this.role,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final navItems = getNavItemsForRole(role);

    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        backgroundColor: c.surface,
        elevation: 0,
        title: Text('SBM ITB', style: TextStyle(color: c.textPrimary, fontWeight: FontWeight.bold)),
        actions: [
          PopupMenuButton(
            itemBuilder: (ctx) => [
              PopupMenuItem(child: const Text('Keluar'), onTap: () => context.read<AuthProvider>().logout()),
            ],
          ),
        ],
      ),
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedIndex,
        onTap: onNavSelected,
        selectedItemColor: c.primary,
        unselectedItemColor: c.textSecondary,
        backgroundColor: c.surface,
        type: BottomNavigationBarType.fixed,
        items: navItems.map((item) => BottomNavigationBarItem(
          icon: Icon(item.icon), activeIcon: Icon(item.iconActive), label: item.label,
        )).toList(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  SHARED WIDGETS
// ─────────────────────────────────────────────────────────────────────────────

class _SidebarNavTile extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final bool collapsed;
  final VoidCallback onTap;

  const _SidebarNavTile({
    required this.icon,
    required this.label,
    required this.selected,
    required this.collapsed,
    required this.onTap,
  });

  @override
  State<_SidebarNavTile> createState() => _SidebarNavTileState();
}

class _SidebarNavTileState extends State<_SidebarNavTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: widget.collapsed ? 10 : 12, vertical: 2),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: widget.selected
                ? const Color(0xFF1D4ED8).withOpacity(0.9)
                : _isHovered
                    ? Colors.white.withOpacity(0.07)
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onTap,
              borderRadius: BorderRadius.circular(10),
              splashColor: Colors.white.withOpacity(0.05),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: widget.collapsed ? 0 : 14,
                  vertical: 11,
                ),
                child: widget.collapsed
                    ? Center(
                        child: Icon(widget.icon,
                          color: widget.selected ? Colors.white : const Color(0xFF94A3B8),
                          size: 22),
                      )
                    : Row(
                        children: [
                          Icon(widget.icon,
                            color: widget.selected ? Colors.white : const Color(0xFF94A3B8),
                            size: 20),
                          const SizedBox(width: 12),
                          Text(
                            widget.label,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: widget.selected ? FontWeight.w600 : FontWeight.normal,
                              color: widget.selected ? Colors.white : const Color(0xFFCBD5E1),
                            ),
                          ),
                          if (widget.selected) ...[
                            const Spacer(),
                            Container(width: 6, height: 6,
                              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
                          ],
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SidebarUserTile extends StatelessWidget {
  final String name;
  final String email;
  final String role;
  final bool collapsed;

  const _SidebarUserTile({
    required this.name,
    required this.email,
    required this.role,
    required this.collapsed,
  });

  @override
  Widget build(BuildContext context) {
    if (collapsed) {
      return Center(
        child: CircleAvatar(
          radius: 17,
          backgroundColor: const Color(0xFF1D4ED8),
          child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 17,
            backgroundColor: const Color(0xFF1D4ED8),
            child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(role.toUpperCase(),
                  style: const TextStyle(fontSize: 10, color: Color(0xFF3B82F6), fontWeight: FontWeight.bold, letterSpacing: 0.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
