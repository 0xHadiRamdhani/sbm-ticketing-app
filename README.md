# SBM ITB Ticketing App

SBM ITB Ticketing App adalah aplikasi pelaporan keluhan fasilitas, perangkat IT, dan operasional lainnya yang dirancang khusus untuk civitas akademika School of Business and Management (SBM) ITB. Aplikasi ini mempermudah pelaporan, pemantauan, dan penyelesaian masalah secara *real-time*.

## Fitur Utama

- **Sistem Autentikasi**: Login dan Pendaftaran aman yang terintegrasi dengan Firebase Authentication. Mendukung validasi domain email (`@itb.ac.id` / `@sbm-itb.ac.id`).
- **Akses Berbasis Peran (Role-Based Access)**:
  - **Pemohon (Mahasiswa/Staf)**: Dapat membuat tiket keluhan baru, dan memantau status penyelesaian tiket mereka (Open, In Progress, Resolved).
  - **Teknisi IT**: Memiliki dashboard khusus untuk melihat daftar tiket yang tersedia (*Open*), mengambil alih tiket untuk dikerjakan (*In Progress*), dan menandai tiket yang sudah diselesaikan (*Resolved*).
  - **Admin**: Akses menyeluruh untuk mengelola sistem dan melihat statistik.
- **Notifikasi Real-Time**: Teknisi menerima pemberitahuan langsung ketika ada tiket baru masuk menggunakan `flutter_local_notifications`.
- **Desain UI/UX Modern**: Antarmuka responsif dan bersih dengan elemen berdesain kekinian (sudut kartu melengkung dinamis, warna status badge, animasi transisi).
- **Pengaturan & Pusat Bantuan**: Integrasi menu pengaturan terpadu termasuk kebijakan privasi, pengelolaan notifikasi, dan informasi aplikasi.

## Teknologi yang Digunakan

Aplikasi ini dibangun menggunakan teknologi modern:
- **Framework**: [Flutter](https://flutter.dev) (Dart)
- **Backend & Database**: Firebase (Cloud Firestore untuk database NoSQL, Firebase Auth untuk login)
- **State Management**: Provider
- **Local Notifications**: `flutter_local_notifications`

## Persiapan dan Instalasi

Ikuti langkah-langkah di bawah ini untuk menjalankan aplikasi di komputer lokal Anda:

### 1. Prasyarat
- Flutter SDK (Versi 3.x ke atas)
- Dart SDK
- Android Studio / VS Code
- Akses ke Console Firebase (Opsional, jika ingin menggunakan backend sendiri)

### 2. Cara Menjalankan Aplikasi

1. Lakukan *clone* atau unduh *repository* ini.
2. Buka terminal/Command Prompt, lalu arahkan ke folder proyek:
   ```bash
   cd ticketing_app_sbm
   ```
3. Unduh semua dependensi paket Flutter:
   ```bash
   flutter pub get
   ```
4. Hubungkan aplikasi dengan konfigurasi Firebase:
   ```bash
   flutterfire configure
   ```
   *(Catatan: Anda akan diminta memilih proyek Firebase dan platform seperti Android/iOS)*
5. Jalankan aplikasi di emulator atau perangkat nyata:
   ```bash
   flutter run
   ```

## Struktur Proyek Utama

```
lib/
├── main.dart                   # Titik masuk aplikasi & konfigurasi Tema Global
├── firebase_options.dart       # Konfigurasi otomatis dari FlutterFire
├── models/
│   ├── ticket_model.dart       # Model struktur data Tiket
│   └── user_model.dart         # Model struktur data Pengguna
├── providers/
│   ├── auth_provider.dart      # Mengatur state login/register/logout
│   └── ticket_provider.dart    # Mengatur pengambilan dan update data tiket
├── screens/
│   ├── admin/                  # Dashboard dan fungsionalitas Admin
│   ├── auth/                   # Halaman Login dan Registrasi
│   ├── requester/              # Dashboard dan Form Pembuatan Tiket (Mahasiswa/Staf)
│   ├── technician/             # Dashboard Teknisi & Detail Tiket
│   ├── about_screen.dart       # Halaman Tentang Aplikasi
│   └── settings_screen.dart    # Halaman Pengaturan (Notifikasi, Profil)
└── services/
    ├── auth_service.dart       # Logika Firebase Authentication
    ├── notification_service.dart # Konfigurasi Local Notification
    └── ticket_service.dart     # Logika CRUD Firebase Firestore untuk Tiket
```

## Catatan Rilis

- **Versi 1.0.0**: 
  - Penyempurnaan tampilan UI/UX global.
  - Implementasi Fitur *Settings* dan *About App*.
  - Perbaikan bug sinkronisasi notifikasi `desugar_jdk_libs` di Android.
  - Skema Role-Based Access yang telah stabil.

---
**© 2026 SBM ITB** - Dikembangkan untuk kemudahan operasional fasilitas.
