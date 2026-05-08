import 'dart:math';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Konfigurasi EmailJS — ganti dengan kredensial Anda dari https://emailjs.com
/// 1. Daftar gratis di emailjs.com
/// 2. Buat Email Service (Gmail, Outlook, dsb.)
/// 3. Buat Email Template dengan variabel: {{to_email}}, {{to_name}}, {{otp_code}}
/// 4. Salin Service ID, Template ID, dan Public Key ke sini
class EmailJsConfig {
  static const String serviceId = 'service_0mjd15p';
  static const String templateId = 'template_0u1coe8';
  static const String publicKey = 'JM9xsOh7ktruv8cFJ';

  /// Private Key — diperlukan saat Strict Mode aktif di EmailJS.
  /// Dapatkan dari: Dashboard → Account → API Keys → Private Key
  /// JIKA tidak mau pakai Private Key → matikan Strict Mode:
  /// Dashboard → Account → Security → nonaktifkan "Strict Mode"
  static const String privateKey = 'J609f8QAjQzxaffDBZhSf'; // ← ganti ini
}

class EmailOtpService {
  static const String _apiUrl = 'https://api.emailjs.com/api/v1.0/email/send';

  /// Generate OTP 6 digit acak
  static String generateOtp() {
    final rng = Random.secure();
    return (rng.nextInt(900000) + 100000).toString();
  }

  /// Kirim OTP ke [email] dengan nama penerima [name].
  /// Mengembalikan OTP yang dikirim agar bisa diverifikasi di sisi client.
  /// Melempar [Exception] jika gagal.
  Future<String> sendOtp({required String email, required String name}) async {
    final otp = generateOtp();

    final payload = <String, dynamic>{
      'service_id': EmailJsConfig.serviceId,
      'template_id': EmailJsConfig.templateId,
      'user_id': EmailJsConfig.publicKey,
      'template_params': {'to_email': email, 'to_name': name, 'otp_code': otp},
      // Diperlukan saat Strict Mode aktif di EmailJS
      if (EmailJsConfig.privateKey.isNotEmpty &&
          EmailJsConfig.privateKey != 'J609f8QAjQzxaffDBZhSf')
        'accessToken': EmailJsConfig.privateKey,
    };

    debugPrint('📧 [EmailOTP] Mengirim ke: $email');
    debugPrint('📧 [EmailOTP] Payload: ${jsonEncode(payload)}');

    final response = await http.post(
      Uri.parse(_apiUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );

    debugPrint('📧 [EmailOTP] Status: ${response.statusCode}');
    debugPrint('📧 [EmailOTP] Body: ${response.body}');

    if (response.statusCode == 200) {
      debugPrint('📧 [EmailOTP] OTP berhasil dikirim: $otp');
      return otp;
    } else {
      throw Exception('[EmailJS ${response.statusCode}] ${response.body}');
    }
  }
}
