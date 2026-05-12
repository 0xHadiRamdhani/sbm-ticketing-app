# SBM ITB Ticketing App

SBM ITB Ticketing App adalah aplikasi pelaporan keluhan fasilitas, perangkat IT, dan operasional lainnya yang dirancang khusus untuk civitas akademika School of Business and Management (SBM) ITB. Aplikasi ini mempermudah pelaporan, pemantauan, dan penyelesaian masalah secara *real-time*.

## Arsitektur Alur Sistem

![Alur Sistem Ticketing SBM ITB](diagram/image.png)

> [!NOTE]
> Anda juga dapat melihat diagram interaktif *Actor Workflow* di file: [`diagram/actor_workflow.drawio`](diagram/actor_workflow.drawio)

## Screenshots

<p align="center">
  <img src="screenshots/screen_1.png" width="200" style="margin: 8px;"/>
  <img src="screenshots/screen_2.png" width="200" style="margin: 8px;"/>
  <img src="screenshots/screen_3.png" width="200" style="margin: 8px;"/>
  <img src="screenshots/screen_4.png" width="200" style="margin: 8px;"/>
  <br/>
  <img src="screenshots/screen_5.png" width="200" style="margin: 8px;"/>
  <img src="screenshots/screen_6.png" width="200" style="margin: 8px;"/>
  <img src="screenshots/screen_7.png" width="200" style="margin: 8px;"/>
  <img src="screenshots/screen_8.png" width="200" style="margin: 8px;"/>
</p>

## Teknologi & Library yang Digunakan

### 1. Library Utama (Dependencies)
Aplikasi ini memanfaatkan berbagai library populer dari ekosistem Flutter:
- **Firebase Suite**:
  - `firebase_auth`: Untuk manajemen sesi dan autentikasi pengguna.
  - `cloud_firestore`: Database NoSQL real-time untuk menyimpan data tiket dan pesan.
  - `firebase_storage`: Media storage untuk lampiran foto.
- **State Management**:
  - `provider`: Digunakan untuk manajemen state global (Auth, Tickets).
- **UI & UX**:
  - `shimmer`: Memberikan efek loading skeleton yang halus.
  - `intl_phone_field`: Input nomor telepon dengan validasi kode negara.
  - `cupertino_icons`: Ikon standar gaya iOS.
- **Utilitas & Layanan**:
  - `flutter_local_notifications`: Menangani notifikasi push lokal saat ada pembaruan tiket.
  - `image_picker`: Memungkinkan akses kamera dan galeri untuk unggah bukti.
  - `intl`: Memformat tanggal, waktu, dan mata uang secara konsisten.
  - `http`: Digunakan untuk integrasi API pihak ketiga (seperti ImgBB).
  - `url_launcher`: Membuka tautan eksternal atau melakukan panggilan telepon/video.

### 2. Algoritma & Logika Utama
- **Role-Based Access Control (RBAC)**: Implementasi logika pengalihan (*routing*) otomatis yang membedakan akses antara *Requester*, *Technician*, dan *Admin* berdasarkan metadata profil di Firestore.
- **Real-time Data Streaming**: Penggunaan algoritma *Stream-based synchronization* menggunakan `StreamBuilder` untuk memastikan daftar tiket dan pesan chat selalu sinkron tanpa perlu *refresh* manual.
- **State Comparison Notification**: Algoritma pembanding state dalam `StreamSubscription` yang mendeteksi perubahan spesifik pada *field* `status` atau `note` untuk memicu notifikasi lokal hanya saat ada pembaruan relevan.
- **Optimistic UI Update**: Memanfaatkan kapabilitas sinkronisasi *offline-first* dari Firestore untuk memberikan pengalaman antarmuka yang instan meskipun koneksi internet lambat.
- **Client-side Filtering & Search**: Logika penyaringan dinamis menggunakan metode `where` dan `toLowerCase` untuk melakukan pencarian tiket secara cepat di sisi klien.

## Fitur Utama

- **Sistem Autentikasi**: Login dan Pendaftaran aman yang terintegrasi dengan Firebase Authentication. Mendukung validasi domain email (`@itb.ac.id` / `@sbm-itb.ac.id`).
- **Akses Berbasis Peran (Role-Based Access)**:
  - **Pemohon (Mahasiswa/Staf)**: Dapat membuat tiket keluhan baru, dan memantau status penyelesaian tiket mereka (Open, In Progress, Resolved).
  - **Teknisi IT**: Memiliki dashboard khusus untuk melihat daftar tiket yang tersedia (*Open*), mengambil alih tiket untuk dikerjakan (*In Progress*), dan menandai tiket yang sudah diselesaikan (*Resolved*).
  - **Admin**: Akses menyeluruh untuk mengelola sistem dan melihat statistik.
- **Notifikasi Real-Time**: Pengguna menerima pemberitahuan langsung ketika ada pembaruan status tiket atau pesan baru menggunakan `flutter_local_notifications`.
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
├── main.dart                          # Titik masuk aplikasi & konfigurasi Tema Global
├── firebase_options.dart              # Konfigurasi otomatis dari FlutterFire
├── models/
│   ├── message_model.dart             # Model struktur data Pesan Chat
│   ├── ticket_model.dart              # Model struktur data Tiket Keluhan
│   └── user_model.dart                # Model struktur data Pengguna
├── providers/
│   ├── auth_provider.dart             # Mengatur state login/register/logout & autentikasi
│   └── ticket_provider.dart           # Mengatur state list dan filter data tiket
├── services/
│   ├── auth_service.dart              # Logika API Firebase Authentication
│   ├── chat_service.dart              # Logika Database Real-time Chat
│   ├── email_otp_service.dart         # Layanan otentikasi menggunakan OTP Email (Resend/SendGrid)
│   ├── notification_service.dart      # Konfigurasi `flutter_local_notifications`
│   └── ticket_service.dart            # Logika CRUD Firebase Firestore & ImgBB Upload
└── screens/
    ├── admin/                         # UI Khusus Peran Admin
    │   ├── admin_dashboard.dart       # Statistik jumlah tiket per status
    │   ├── admin_tickets_screen.dart  # Tabel daftar seluruh tiket & fitur filter
    │   └── user_management_screen.dart# Kelola peran (role) pengguna dan akun
    ├── auth/                          # UI Autentikasi
    │   ├── email_otp_screen.dart      # Layar Verifikasi OTP menggunakan Email
    │   ├── login_screen.dart          # Layar Login utama (Email & Password)
    │   └── phone_login_screen.dart    # Layar Login menggunakan Nomor Telepon
    ├── requester/                     # UI Khusus Pemohon (Mahasiswa/Staff)
    │   ├── create_ticket_screen.dart  # Form lapor keluhan & upload bukti gambar
    │   ├── requester_dashboard.dart   # Dashboard berisi daftar tiket milik pemohon
    │   └── requester_ticket_detail_screen.dart # Detail tiket, timeline status, dan tombol Chat
    ├── technician/                    # UI Khusus Teknisi
    │   ├── technician_dashboard.dart  # Dashboard tiket *Open* dan penugasan teknisi
    │   └── ticket_detail_screen.dart  # Detail tiket untuk teknisi mengupdate status & bukti perbaikan
    ├── shared/                        # UI Komponen yang Dibagikan
    │   └── ticket_card.dart           # Widget kartu tiket yang dinamis untuk dashboard
    ├── about_screen.dart              # Layar informasi aplikasi & kebijakan
    ├── chat_screen.dart               # Layar fitur komunikasi langsung Pemohon - Teknisi
    ├── dashboard_wrapper.dart         # Pengarah (router) otomatis berdasarkan Role ke Dashboard
    ├── help_center_screen.dart        # Layar FAQ dan Bantuan Pengguna
    └── settings_screen.dart           # Layar Pengaturan Profil & Notifikasi
```

## Catatan Rilis

- **Versi 1.0.0**: 
  - Penyempurnaan tampilan UI/UX global.
  - Implementasi Fitur *Settings* dan *About App*.
  - Perbaikan bug sinkronisasi notifikasi `desugar_jdk_libs` di Android.
  - Skema Role-Based Access yang telah stabil.

---
**© 2026 SBM ITB** - Dikembangkan untuk kemudahan operasional fasilitas.
