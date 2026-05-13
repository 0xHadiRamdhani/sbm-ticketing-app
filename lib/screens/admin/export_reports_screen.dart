import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:excel/excel.dart' hide Border;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import '../shared/ticket_card.dart';
import '../../models/ticket_model.dart';

class ExportReportsScreen extends StatefulWidget {
  const ExportReportsScreen({Key? key}) : super(key: key);

  @override
  State<ExportReportsScreen> createState() => _ExportReportsScreenState();
}

class _ExportReportsScreenState extends State<ExportReportsScreen> {
  String _selectedFormat = 'Excel (.xlsx)';
  DateTimeRange? _selectedDateRange;
  bool _isWeeklyActive = true;
  bool _isMonthlyActive = false;

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
                      _buildScheduledItem(
                        'Laporan Mingguan', 
                        'Setiap Senin, 08:00 WIB', 
                        _isWeeklyActive,
                        (val) => setState(() {
                          _isWeeklyActive = val;
                          _showScheduledInfo('Laporan Mingguan');
                        })
                      ),
                      _buildScheduledItem(
                        'Ringkasan SLA Bulanan', 
                        'Tanggal 1, 00:00 WIB', 
                        _isMonthlyActive,
                        (val) => setState(() {
                          _isMonthlyActive = val;
                          _showScheduledInfo('Ringkasan SLA Bulanan');
                        })
                      ),
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

  Widget _buildScheduledItem(String title, String subtitle, bool isActive, ValueChanged<bool> onChanged) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC), 
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isActive ? const Color(0xFF1A3A5C).withOpacity(0.1) : Colors.transparent),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8), 
            decoration: BoxDecoration(
              color: isActive ? const Color(0xFF1A3A5C).withOpacity(0.1) : Colors.white, 
              shape: BoxShape.circle
            ), 
            child: Icon(Icons.mail_outline, size: 16, color: isActive ? const Color(0xFF1A3A5C) : const Color(0xFF94A3B8))
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start, 
            children: [
              Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isActive ? const Color(0xFF0F172A) : const Color(0xFF94A3B8))), 
              Text(subtitle, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)))
            ]
          ),
          const Spacer(),
          Switch.adaptive(
            value: isActive, 
            onChanged: onChanged, 
            activeColor: const Color(0xFF1A3A5C)
          ),
        ],
      ),
    );
  }

  void _showScheduledInfo(String type) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Fitur $type otomatis memerlukan Cloud Functions. Status berhasil diperbarui secara lokal.'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _handleExport() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Menyiapkan Laporan'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            CircularProgressIndicator(color: Color(0xFF1A3A5C)),
            SizedBox(height: 16),
            Text('Sedang mengambil dan memproses data tiket SBM ITB...', textAlign: TextAlign.center, style: TextStyle(fontSize: 13)),
          ],
        ),
      ),
    );

    try {
      // 1. Fetch Data
      Query query = FirebaseFirestore.instance.collection('tickets').orderBy('created_at', descending: true);
      
      if (_selectedDateRange != null) {
        // Use normalized dates for filtering
        DateTime start = DateTime(_selectedDateRange!.start.year, _selectedDateRange!.start.month, _selectedDateRange!.start.day);
        DateTime end = DateTime(_selectedDateRange!.end.year, _selectedDateRange!.end.month, _selectedDateRange!.end.day, 23, 59, 59);
        
        query = query.where('created_at', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
                     .where('created_at', isLessThanOrEqualTo: Timestamp.fromDate(end));
      }

      final snapshot = await query.get();
      final tickets = snapshot.docs.map((doc) => TicketModel.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();

      if (tickets.isEmpty) {
        if (!mounted) return;
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tidak ada data tiket untuk kriteria yang dipilih.')));
        return;
      }

      String filePath = '';
      String fileName = 'Laporan_Tiket_SBM_${DateFormat('yyyyMMdd').format(DateTime.now())}';

      if (_selectedFormat.contains('Excel')) {
        // 2. Generate Excel
        var excel = Excel.createExcel();
        Sheet sheetObject = excel['Laporan Tiket'];
        excel.delete('Sheet1'); // Remove default sheet

        // Header Style
        CellStyle headerStyle = CellStyle(
          bold: true,
          backgroundColorHex: ExcelColor.fromHexString('#F1F5F9'),
          fontFamily: getFontFamily(FontFamily.Arial),
        );

        // Header row
        List<String> headers = ['ID Tiket', 'Tanggal', 'Kategori', 'Prioritas', 'Status', 'Lokasi', 'Deskripsi'];
        for (var i = 0; i < headers.length; i++) {
          var cell = sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
          cell.value = TextCellValue(headers[i]);
          cell.cellStyle = headerStyle;
        }

        // Data rows
        for (var i = 0; i < tickets.length; i++) {
          var t = tickets[i];
          int rowIndex = i + 1;
          
          sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex)).value = TextCellValue(t.ticketId.substring(0, 8).toUpperCase());
          sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex)).value = TextCellValue(DateFormat('dd/MM/yyyy HH:mm').format(t.createdAt));
          sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex)).value = TextCellValue(t.category);
          sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIndex)).value = TextCellValue(t.priority);
          sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rowIndex)).value = TextCellValue(t.status);
          sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: rowIndex)).value = TextCellValue(t.location ?? '-');
          sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: rowIndex)).value = TextCellValue(t.description);
        }

        final directory = await getTemporaryDirectory();
        filePath = '${directory.path}/$fileName.xlsx';
        final bytes = excel.encode();
        if (bytes != null) {
          final file = File(filePath);
          await file.writeAsBytes(bytes);
        } else {
          throw Exception('Gagal mengencode file Excel');
        }

      } else if (_selectedFormat.contains('CSV')) {
        // 3. Generate CSV
        StringBuffer csvContent = StringBuffer();
        csvContent.writeln('ID Tiket,Tanggal,Kategori,Prioritas,Status,Lokasi,Deskripsi');
        
        for (var t in tickets) {
          String safeDesc = t.description.replaceAll('\n', ' ').replaceAll(',', ';').replaceAll('"', '""');
          csvContent.writeln('${t.ticketId.substring(0, 8)},${DateFormat('dd/MM/yyyy HH:mm').format(t.createdAt)},${t.category},${t.priority},${t.status},${t.location ?? "-"},"$safeDesc"');
        }

        final directory = await getTemporaryDirectory();
        filePath = '${directory.path}/$fileName.csv';
        final file = File(filePath);
        await file.writeAsString(csvContent.toString());
      } else {
        if (!mounted) return;
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Format PDF akan segera tersedia.')));
        return;
      }

      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog

      // 4. Share File
      await Share.shareXFiles([XFile(filePath)], text: 'Laporan Tiket SBM ITB');

    } catch (e, stack) {
      debugPrint('Export Error: $e');
      debugPrint(stack.toString());
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Gagal membuat laporan: $e'),
        backgroundColor: Colors.red.shade700,
      ));
    }
  }
}
