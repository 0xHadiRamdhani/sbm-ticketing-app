import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart' hide Border;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_notifications.dart';
import '../../services/audit_service.dart';
import '../shared/ticket_card.dart';

class ImportTicketsScreen extends StatefulWidget {
  const ImportTicketsScreen({Key? key}) : super(key: key);

  @override
  State<ImportTicketsScreen> createState() => _ImportTicketsScreenState();
}

class _ImportTicketsScreenState extends State<ImportTicketsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isImporting = false;
  String? _selectedFileName;
  List<Map<String, dynamic>> _previewData = [];
  int _successCount = 0;
  int _errorCount = 0;
  List<String> _errors = [];

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'xlsx', 'xls'],
      );

      if (result != null) {
        final file = File(result.files.single.path!);
        final fileName = result.files.single.name;
        final extension = result.files.single.extension?.toLowerCase();

        setState(() {
          _selectedFileName = fileName;
          _previewData = [];
          _errors = [];
          _successCount = 0;
          _errorCount = 0;
        });

        // Parse file based on extension
        if (extension == 'csv') {
          await _parseCSV(file);
        } else if (extension == 'xlsx' || extension == 'xls') {
          await _parseExcel(file);
        }
      }
    } catch (e) {
      if (!mounted) return;
      AppNotifications.showNotification(
        context,
        title: 'Error',
        message: 'Gagal membaca file: $e',
        isError: true,
      );
    }
  }

  Future<void> _parseCSV(File file) async {
    try {
      final input = file.readAsStringSync();
      final rows = const CsvToListConverter().convert(input);

      if (rows.isEmpty) {
        throw Exception('File CSV kosong');
      }

      // Expected header: Category, Priority, Location, Description, Status, Requester Email
      final headers = rows[0].map((e) => e.toString().trim()).toList();
      
      List<Map<String, dynamic>> data = [];
      for (int i = 1; i < rows.length; i++) {
        if (i > 10) break; // Preview max 10 rows
        
        final row = rows[i];
        Map<String, dynamic> ticket = {};
        for (int j = 0; j < headers.length && j < row.length; j++) {
          ticket[headers[j]] = row[j]?.toString() ?? '';
        }
        data.add(ticket);
      }

      setState(() => _previewData = data);
    } catch (e) {
      if (!mounted) return;
      AppNotifications.showNotification(
        context,
        title: 'Error',
        message: 'Gagal parse CSV: $e',
        isError: true,
      );
    }
  }

  Future<void> _parseExcel(File file) async {
    try {
      final bytes = file.readAsBytesSync();
      final excel = Excel.decodeBytes(bytes);

      if (excel.tables.isEmpty) {
        throw Exception('File Excel kosong');
      }

      final table = excel.tables[excel.tables.keys.first]!;
      
      if (table.rows.isEmpty) {
        throw Exception('Sheet Excel kosong');
      }

      // Get headers from first row
      final headers = table.rows[0]
          .map((cell) => cell?.value?.toString().trim() ?? '')
          .toList();

      List<Map<String, dynamic>> data = [];
      for (int i = 1; i < table.rows.length; i++) {
        if (i > 10) break; // Preview max 10 rows
        
        final row = table.rows[i];
        Map<String, dynamic> ticket = {};
        for (int j = 0; j < headers.length && j < row.length; j++) {
          ticket[headers[j]] = row[j]?.value?.toString() ?? '';
        }
        data.add(ticket);
      }

      setState(() => _previewData = data);
    } catch (e) {
      if (!mounted) return;
      AppNotifications.showNotification(
        context,
        title: 'Error',
        message: 'Gagal parse Excel: $e',
        isError: true,
      );
    }
  }

  Future<void> _importTickets() async {
    if (_selectedFileName == null) {
      AppNotifications.showNotification(
        context,
        title: 'Error',
        message: 'Pilih file terlebih dahulu',
        isError: true,
      );
      return;
    }

    final confirm = await AppNotifications.showConfirmDialog(
      context,
      title: 'Konfirmasi Import',
      message: 'Import tiket dari file $_selectedFileName?\n\nPastikan format file sesuai dengan template.',
      confirmLabel: 'Import',
      cancelLabel: 'Batal',
      isDestructive: false,
    );

    if (confirm != true) return;

    setState(() {
      _isImporting = true;
      _successCount = 0;
      _errorCount = 0;
      _errors = [];
    });

    try {
      // Parse full file again
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'xlsx', 'xls'],
      );

      if (result == null) return;

      final file = File(result.files.single.path!);
      final extension = result.files.single.extension?.toLowerCase();

      List<Map<String, dynamic>> allData = [];

      if (extension == 'csv') {
        final input = file.readAsStringSync();
        final rows = const CsvToListConverter().convert(input);
        final headers = rows[0].map((e) => e.toString().trim()).toList();
        
        for (int i = 1; i < rows.length; i++) {
          final row = rows[i];
          Map<String, dynamic> ticket = {};
          for (int j = 0; j < headers.length && j < row.length; j++) {
            ticket[headers[j]] = row[j]?.toString() ?? '';
          }
          allData.add(ticket);
        }
      } else {
        final bytes = file.readAsBytesSync();
        final excel = Excel.decodeBytes(bytes);
        final table = excel.tables[excel.tables.keys.first]!;
        final headers = table.rows[0]
            .map((cell) => cell?.value?.toString().trim() ?? '')
            .toList();
        
        for (int i = 1; i < table.rows.length; i++) {
          final row = table.rows[i];
          Map<String, dynamic> ticket = {};
          for (int j = 0; j < headers.length && j < row.length; j++) {
            ticket[headers[j]] = row[j]?.value?.toString() ?? '';
          }
          allData.add(ticket);
        }
      }

      // Import each ticket
      for (var data in allData) {
        try {
          await _importSingleTicket(data);
          setState(() => _successCount++);
        } catch (e) {
          setState(() {
            _errorCount++;
            _errors.add('Row ${allData.indexOf(data) + 2}: $e');
          });
        }
      }

      await AuditService().logAction(
        actionType: 'IMPORT_TICKETS',
        targetId: 'bulk',
        description: 'Import $_successCount tiket dari file $_selectedFileName',
      );

      if (!mounted) return;
      
      setState(() => _isImporting = false);

      AppNotifications.showNotification(
        context,
        title: 'Import Selesai',
        message: 'Berhasil: $_successCount, Gagal: $_errorCount',
        isError: _errorCount > 0,
      );
    } catch (e) {
      setState(() => _isImporting = false);
      
      if (!mounted) return;
      AppNotifications.showNotification(
        context,
        title: 'Error',
        message: 'Gagal import: $e',
        isError: true,
      );
    }
  }

  Future<void> _importSingleTicket(Map<String, dynamic> data) async {
    // Validate required fields
    final category = data['Category']?.toString().trim() ?? '';
    final priority = data['Priority']?.toString().trim() ?? '';
    final location = data['Location']?.toString().trim() ?? '';
    final description = data['Description']?.toString().trim() ?? '';
    final status = data['Status']?.toString().trim() ?? 'New';
    final requesterEmail = data['Requester Email']?.toString().trim() ?? '';

    if (category.isEmpty || description.isEmpty) {
      throw Exception('Category dan Description wajib diisi');
    }

    // Find requester by email
    String? requesterId;
    if (requesterEmail.isNotEmpty) {
      final userQuery = await _firestore
          .collection('users')
          .where('email', isEqualTo: requesterEmail)
          .limit(1)
          .get();
      
      if (userQuery.docs.isNotEmpty) {
        requesterId = userQuery.docs.first.id;
      }
    }

    // Create ticket
    final ticketRef = _firestore.collection('tickets').doc();
    final now = DateTime.now();

    await ticketRef.set({
      'ticket_id': ticketRef.id,
      'category': category,
      'priority': priority.isEmpty ? 'Medium' : priority,
      'location': location,
      'description': description,
      'status': status,
      'requester_id': requesterId ?? 'imported',
      'requester_name': requesterEmail.isNotEmpty ? requesterEmail : 'Imported User',
      'created_at': Timestamp.fromDate(now),
      'updated_at': Timestamp.fromDate(now),
      'target_resolution_at': Timestamp.fromDate(now.add(const Duration(hours: 1))),
      'escalation_level': 0,
      'imported': true,
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    
    return Scaffold(
      backgroundColor: c.background,
      appBar: buildSbmAppBar(
        showBackButton: true,
        onBackPressed: () => Navigator.pop(context),
        titleText: 'Import Tiket',
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: c.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: c.primary.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: c.primary, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Format File',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: c.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'File harus dalam format CSV atau XLSX dengan kolom berikut:\n\n'
                    '• Category (wajib)\n'
                    '• Priority (Low/Medium/High/Critical)\n'
                    '• Location\n'
                    '• Description (wajib)\n'
                    '• Status (New/Assigned/In Progress/dll)\n'
                    '• Requester Email',
                    style: TextStyle(fontSize: 12, color: c.textPrimary, height: 1.5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // File Picker Button
            Center(
              child: ElevatedButton.icon(
                onPressed: _isImporting ? null : _pickFile,
                icon: const Icon(Icons.file_upload_outlined),
                label: Text(_selectedFileName ?? 'Pilih File CSV / XLSX'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: c.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            
            if (_previewData.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text(
                'Preview Data (10 baris pertama)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: c.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: c.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: c.divider),
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(
                      c.primary.withOpacity(0.1),
                    ),
                    columns: _previewData.first.keys
                        .map((key) => DataColumn(
                              label: Text(
                                key,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: c.primary,
                                ),
                              ),
                            ))
                        .toList(),
                    rows: _previewData
                        .map((row) => DataRow(
                              cells: row.values
                                  .map((value) => DataCell(
                                        Text(
                                          value.toString(),
                                          style: TextStyle(color: c.textPrimary),
                                        ),
                                      ))
                                  .toList(),
                            ))
                        .toList(),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Import Button
              Center(
                child: ElevatedButton.icon(
                  onPressed: _isImporting ? null : _importTickets,
                  icon: _isImporting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.cloud_upload_outlined),
                  label: Text(_isImporting ? 'Importing...' : 'Import Semua Data'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
            
            if (_successCount > 0 || _errorCount > 0) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: c.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: c.divider),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hasil Import',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: c.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green, size: 20),
                        const SizedBox(width: 8),
                        Text('Berhasil: $_successCount', style: TextStyle(color: c.textPrimary)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.error, color: Colors.red, size: 20),
                        const SizedBox(width: 8),
                        Text('Gagal: $_errorCount', style: TextStyle(color: c.textPrimary)),
                      ],
                    ),
                    if (_errors.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      const Divider(),
                      const SizedBox(height: 8),
                      Text(
                        'Error Details:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: c.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ..._errors.take(5).map((error) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              '• $error',
                              style: TextStyle(fontSize: 12, color: Colors.red),
                            ),
                          )),
                      if (_errors.length > 5)
                        Text(
                          '... dan ${_errors.length - 5} error lainnya',
                          style: TextStyle(fontSize: 12, color: c.textMuted),
                        ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
