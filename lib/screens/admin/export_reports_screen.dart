import 'package:flutter/material.dart';
import '../shared/ticket_card.dart';

class ExportReportsScreen extends StatefulWidget {
  const ExportReportsScreen({Key? key}) : super(key: key);

  @override
  State<ExportReportsScreen> createState() => _ExportReportsScreenState();
}

class _ExportReportsScreenState extends State<ExportReportsScreen> {
  String _selectedFormat = 'Excel (.xlsx)';
  DateTimeRange? _selectedDateRange;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: buildSbmAppBar(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: Color(0xFF1A3A5C)),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Ekspor & Laporan',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1A3A5C)),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionCard(
                    'Konfigurasi Ekspor',
                    [
                      _buildLabel('Format File'),
                      _buildDropdown(['Excel (.xlsx)', 'CSV (.csv)', 'PDF Document (.pdf)'], _selectedFormat, (val) => setState(() => _selectedFormat = val!)),
                      const SizedBox(height: 20),
                      _buildLabel('Rentang Tanggal'),
                      _buildDateSelector(),
                      const SizedBox(height: 20),
                      _buildLabel('Kolom yang Disertakan'),
                      _buildColumnChips(),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildSectionCard(
                    'Laporan Terjadwal',
                    [
                      const Text(
                        'Dapatkan laporan otomatis yang dikirimkan ke email Anda setiap periode tertentu.',
                        style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                      ),
                      const SizedBox(height: 16),
                      _buildScheduledItem('Laporan Mingguan', 'Setiap Senin, 08:00 WIB', true),
                      _buildScheduledItem('Ringkasan SLA Bulanan', 'Tanggal 1, 00:00 WIB', false),
                    ],
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: _handleExport,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A3A5C),
                      minimumSize: const Size(double.infinity, 54),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Generate & Download Laporan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
          const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1, color: Color(0xFFF1F5F9))),
          ...children,
        ],
      ),
    );
  }

  Widget _buildLabel(String text) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF64748B))));

  Widget _buildDropdown(List<String> items, String current, ValueChanged<String?> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: current,
          isExpanded: true,
          onChanged: onChanged,
          items: items.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 14)))).toList(),
        ),
      ),
    );
  }

  Widget _buildDateSelector() {
    return InkWell(
      onTap: () async {
        final picked = await showDateRangePicker(context: context, firstDate: DateTime(2020), lastDate: DateTime.now());
        if (picked != null) setState(() => _selectedDateRange = picked);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_outlined, size: 18, color: Color(0xFF1A3A5C)),
            const SizedBox(width: 12),
            Text(
              _selectedDateRange == null ? 'Pilih Rentang Tanggal' : '${_selectedDateRange!.start.day}/${_selectedDateRange!.start.month} - ${_selectedDateRange!.end.day}/${_selectedDateRange!.end.month}',
              style: const TextStyle(fontSize: 14),
            ),
            const Spacer(),
            const Icon(Icons.keyboard_arrow_down, color: Color(0xFF64748B)),
          ],
        ),
      ),
    );
  }

  Widget _buildColumnChips() {
    return Wrap(
      spacing: 8,
      children: ['ID Tiket', 'Tgl Buat', 'Kategori', 'Prioritas', 'Status', 'Pelapor', 'Teknisi'].map((label) {
        return FilterChip(
          label: Text(label, style: const TextStyle(fontSize: 11)),
          selected: true,
          onSelected: (_) {},
          selectedColor: const Color(0xFF1A3A5C).withOpacity(0.1),
          checkmarkColor: const Color(0xFF1A3A5C),
          labelStyle: const TextStyle(color: Color(0xFF1A3A5C), fontWeight: FontWeight.bold),
          backgroundColor: const Color(0xFFF1F5F9),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        );
      }).toList(),
    );
  }

  Widget _buildScheduledItem(String title, String subtitle, bool isActive) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle), child: Icon(Icons.mail_outline, size: 16, color: Color(0xFF1A3A5C))),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)), Text(subtitle, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)))]),
          const Spacer(),
          Switch.adaptive(value: isActive, onChanged: (_) {}, activeColor: const Color(0xFF1A3A5C)),
        ],
      ),
    );
  }

  void _handleExport() {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Menyiapkan Laporan'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Sedang memproses data tiket SBM ITB...'),
          ],
        ),
      ),
    );
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Laporan $_selectedFormat berhasil dibuat dan diunduh.')));
    });
  }
}
