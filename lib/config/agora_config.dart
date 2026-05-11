// ==========================================================
// AGORA CONFIGURATION
// Daftar gratis di: https://console.agora.io
// Create Project → Testing Mode (tanpa token untuk development)
// ==========================================================

class AgoraConfig {
  // Ganti dengan App ID dari Agora Console kamu
  static const String appId = 'a14b876a2e3349eb8daf4baaa5dd878e';

  // Untuk production, gunakan token dari server.
  // Untuk testing/development, kosongkan string ini (null token).
  static const String? token = null;
}
