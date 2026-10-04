# SmartFix — Sistem Manajemen Inventaris & Rantai Pasok Toko Servis Smartphone Berbasis Mobile dengan Integritas Blockchain (SHA-256)

[![Flutter Version](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart Version](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![Laravel Version](https://img.shields.io/badge/Laravel-11.x-FF2D20?logo=laravel&logoColor=white)](https://laravel.com)
[![Status Proyek](https://img.shields.io/badge/Status-Tugas%20Akhir-0F766E)](#tim-pengembang)
[![Keamanan](https://img.shields.io/badge/Keamanan-Buku%20Besar%20Kriptografi%20SHA--256-14B8A6)](#verifikasi-integritas-blockchain-sha-256)

> **Tugas Akhir — Pemrograman Aplikasi Mobile (Semester 5)**  
> Sistem manajemen inventaris dan pelacakan rantai pasok suku cadang smartphone berskala *enterprise-grade*, dilengkapi autentikasi berbasis token serta audit jejak kriptografi *immutable* anti-pemalsuan.

---

## 📌 Daftar Isi
- [Gambaran Umum Proyek](#-gambaran-umum-proyek)
- [Fitur Utama](#-fitur-utama)
- [Arsitektur Sistem](#-arsitektur-sistem)
- [Teknologi yang Digunakan (Tech Stack)](#-teknologi-yang-digunakan-tech-stack)
- [Skema Basis Data & Blockchain](#-skema-basis-data--blockchain)
- [Dokumentasi REST API](#-dokumentasi-rest-api)
- [Panduan Instalasi & Menjalankan Proyek](#-panduan-instalasi--menjalankan-proyek)
  - [Konfigurasi Backend (Laravel 11)](#1-konfigurasi-backend-laravel-11)
  - [Konfigurasi Frontend (Flutter Mobile)](#2-konfigurasi-frontend-flutter-mobile)
- [Tangkapan Layar Antarmuka (UI Walkthrough)](#-tangkapan-layar-antarmuka-ui-walkthrough)
- [Tim Pengembang](#-tim-pengembang)

---

## 📖 Gambaran Umum Proyek

Pada industri reparasi smartphone dan perangkat elektronik, pengelolaan stok suku cadang bernilai tinggi (seperti layar OLED original, baterai lithium-ion berkapasitas besar, dan *motherboard*) sering kali menghadapi kendala serius terkait suku cadang palsu, komponen bekas daur ulang (*recycled IC*), serta pencatatan stok manual yang rawan manipulasi. Hal ini berakibat pada tingginya angka pengembalian barang (*return rate*) dan hilangnya kepercayaan pelanggan.

**SmartFix** hadir memberikan solusi komprehensif dengan mengintegrasikan aplikasi mobile berbasis **Flutter** dan REST API modern **Laravel 11**, yang diperkuat oleh mekanisme **Buku Besar Kriptografi Blockchain SHA-256**. Setiap suku cadang yang didaftarkan ke sistem akan mengkalkulasi tanda tangan digital (*hash*) unik yang terikat secara matematis dengan blok sebelumnya. Dengan demikian, seluruh riwayat mutasi barang bersifat transparan, dapat diaudit, dan tidak dapat diubah secara sepihak (*tamper-proof*).

---

## 🚀 Fitur Utama

### 1. Autentikasi & Pengelolaan Sesi Aman
- **Laravel Sanctum Token Authentication**: Menerbitkan *plain-text bearer token* yang aman untuk mengamankan setiap transaksi data antara aplikasi mobile dan server backend.
- **Dukungan Biometrik (Fingerprint & Face ID)**: Kemudahan masuk ke sistem menggunakan pemindai sidik jari atau pengenalan wajah perangkat keras smartphone (`local_auth`).
- **Penyimpanan Sesi Persisten**: Sesi login teknisi tetap tersimpan aman di penyimpanan lokal perangkat (`shared_preferences`) sehingga tidak perlu login ulang saat aplikasi dibuka kembali.
- **Mekanisme Logout Aman**: Menghapus seluruh kredensial token baik dari memori aktif maupun *storage* lokal sebelum mengarahkan pengguna kembali ke halaman login.

### 2. Manajemen Inventaris Real-Time
- **Pencarian Cepat dengan Debounce**: Pencarian cerdas berdasarkan nama komponen atau nomor seri/SKU dengan jeda *debounce* 350ms guna menghemat *bandwidth* dan beban *database*.
- **Filter Kategori Horisontal**: Pengelompokan praktis dalam 5 kategori: `All`, `Display`, `Battery`, `Machine`, dan `Accessories`.
- **Lencana Status Stok Dinamis**: Indikator visual otomatis berdasarkan sisa kuantitas barang (`In Stock`, `Low Stock`, `Out of Stock`) yang terintegrasi dengan kartu ringkasan KPI di bagian atas layar.
- **Format Rupiah Standar (IDR)**: Penulisan harga nominal otomatis menggunakan pemisah ribuan standar Indonesia (contoh: `Rp 1.450.000`).
- **Fitur Tarik-untuk-Memperbarui (Pull-to-Refresh)**: Memperbarui daftar suku cadang langsung dari basis data server kapan saja.

### 3. Verifikasi Integritas Blockchain (SHA-256)
- **Keterikatan Blok Kriptografi**: Setiap penambahan suku cadang menghitung nilai *hash* menggunakan rumus deterministik:
  $$\text{Hash}_n = \text{SHA-256}(\text{Hash}_{n-1} \parallel \text{Serial} \parallel \text{Name} \parallel \text{Category} \parallel \text{Stock} \parallel \text{Price} \parallel \text{UserID} \parallel \text{Timestamp})$$
- **Penjelajah Rantai Blok (Ledger Chain Explorer)**: Tampilan visual berbasis *timeline* yang memperlihatkan tinggi blok (*height*), jenis aksi (`PART_REGISTERED`, `QUALITY_INSPECTION`, `STOCK_TRANSFER`), *previous hash*, *current hash*, serta node teknisi penandatangan.
- **Audit Mandiri Integritas Rantai**: Algoritma verifikasi menyeluruh untuk memastikan apakah seluruh blok saling terhubung tanpa ada manipulasi data.
- **Alat Verifikasi Komponen Mandiri**: Memungkinkan teknisi memasukkan kode hash atau nomor seri untuk mengonfirmasi keaslian komponen OEM di bengkel kerja.

### 4. Pusat Utilitas & Diagnostik Teknisi (Tools Hub)
- **AI Repair Assistant**: Asisten interaktif berbasis AI untuk diagnosa korsleting sirkuit *motherboard* dan panduan skematik jalur IC smartphone.
- **Konverter Mata Uang & Zona Waktu**: Kalkulator kurs valuta asing (IDR, USD, EUR) serta penyelarasan waktu operasional bengkel antarwilayah (WIB, WITA, WIT).
- **Pelacakan Kurir Logistik GPS**: Visualisasi peta pengiriman suku cadang menggunakan OpenStreetMap (`flutter_map`) dan GPS (`geolocator`).
- **Sensor Calibration Minigame**: Uji kalibrasi sensor perangkat keras (akselerometer dan giroskop) melalui *minigame* interaktif.

### 5. Desain Antarmuka Industrial-Tech
- **Tema Gelap Khusus Bengkel Reparasi**: Paduan warna kontras tinggi yang nyaman di mata (*dark charcoal* `#1E1E1E`, *slate surface* `#262626`, dan aksen *teal/cyan* `#14B8A6`).
- **Arsitektur Kode Bersih & Null-Safe**: Mengikuti pedoman tata kelola kode Dart terkini tanpa adanya *deprecation warnings*.

---

## 🏗 Arsitektur Sistem

```text
┌─────────────────────────────────────────────────────────────┐
│                 Aplikasi Mobile SmartFix (Flutter)          │
│  ┌─────────────────┐ ┌─────────────────┐ ┌───────────────┐  │
│  │ Autentikasi     │ │ Inventaris Real-│ │ Pusat Utilitas│  │
│  │ Sanctum & Bio   │ │ Time & Form FAB │ │ & Blockchain  │  │
│  └────────┬────────┘ └────────┬────────┘ └───────┬───────┘  │
└───────────┼───────────────────┼──────────────────┼──────────┘
            │                   │                  │
            │ HTTP (JSON)       │ Bearer Token     │ SHA-256
            ▼                   ▼                  ▼
┌─────────────────────────────────────────────────────────────┐
│                 Mesin REST API Backend (Laravel 11)         │
│  ┌─────────────────┐ ┌─────────────────┐ ┌───────────────┐  │
│  │ Middleware Auth │ │ Kontroler CRUD  │ │ Logika Hash   │  │
│  │ Sanctum Guard   │ │ Inventaris      │ │ Blockchain    │  │
│  └────────┬────────┘ └────────┬────────┘ └───────┬───────┘  │
└───────────┼───────────────────┼──────────────────┼──────────┘
            │                   │                  │
            ▼                   ▼                  ▼
┌─────────────────────────────────────────────────────────────┐
│                 Penyimpanan Relasional & Audit Log          │
│  ┌──────────────┐     ┌──────────────┐    ┌──────────────┐  │
│  │    Tabel     │     │    Tabel     │    │    Tabel     │  │
│  │    users     │     │    parts     │    │blockchain_log│  │
│  └──────────────┘     └──────────────┘    └──────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

---

## 💻 Teknologi yang Digunakan (Tech Stack)

### Frontend (Mobile App)
- **Framework**: [Flutter](https://flutter.dev) (v3.13+ / 3.x)
- **Bahasa Pemrograman**: [Dart](https://dart.dev) (v3.13+ Null-Safety)
- **Paket & Dependensi Utama**:
  - `http: ^1.6.0` — Komunikasi jaringan REST API & injeksi header otentikasi Sanctum.
  - `shared_preferences: ^2.5.3` — Penyimpanan persisten lokal untuk token dan sesi teknisi.
  - `local_auth: ^3.0.2` — Akses sensor biometrik (sidik jari & pengenalan wajah).
  - `flutter_map: ^8.3.2` & `latlong2: ^0.10.1` — Peta pelacakan GPS berbasis OpenStreetMap.
  - `sensors_plus: ^7.1.1` — Pembacaan sensor akselerometer & giroskop perangkat keras.
  - `flutter_local_notifications: ^22.3.1` — Notifikasi sistem lokal secara *offline*.

### Backend (REST API Engine)
- **Framework**: [Laravel 11](https://laravel.com)
- **Bahasa Pemrograman**: PHP 8.2 / 8.3
- **Otentikasi API**: Laravel Sanctum (Personal Access Tokens)
- **Basis Data**: MySQL 8.x / MariaDB (atau SQLite untuk kebutuhan pengujian)
- **Kriptografi**: Fungsi bawaan PHP `hash('sha256', ...)` dengan format serialisasi string ISO-8601.

### Alat Pengembangan & Lingkungan Kerja
- **Web Server & Stack**: Laragon / Apache / Nginx
- **Pengujian API**: Postman / Bruno / cURL
- **Version Control**: Git & GitHub

---

## 🗄 Skema Basis Data & Blockchain

### 1. Tabel `users`
| Kolom | Tipe Data | Aturan / Batasan | Deskripsi |
|---|---|---|---|
| `id` | BigInt | Primary Key, Auto Increment | Identifikasi unik pengguna |
| `name` | Varchar(255) | Not Null | Nama lengkap teknisi |
| `email` | Varchar(255) | Unique, Not Null | Alamat surel untuk login |
| `password` | Varchar(255) | Not Null | Hash kata sandi terenkripsi (Bcrypt) |
| `role` | Varchar(50) | Default: `'technician'` | Hak akses peran pengguna |
| `timestamps` | Timestamp | Nullable | Waktu pembuatan & pembaruan data |

### 2. Tabel `parts`
| Kolom | Tipe Data | Aturan / Batasan | Deskripsi |
|---|---|---|---|
| `id` | BigInt | Primary Key, Auto Increment | Identifikasi unik suku cadang |
| `serial_number` | Varchar(255) | Unique, Not Null | Nomor seri atau kode SKU komponen |
| `name` | Varchar(255) | Not Null | Nama komersial suku cadang |
| `category` | Varchar(100) | Not Null | Kategori (`Display`, `Battery`, dsb.) |
| `stock_quantity`| Integer | Min: 0, Not Null | Kuantitas unit suku cadang tersedia |
| `base_price_idr`| Decimal(14,2)| Min: 0, Not Null | Harga dasar dalam satuan Rupiah (IDR) |
| `timestamps` | Timestamp | Nullable | Waktu pembuatan & pembaruan data |

### 3. Tabel `blockchain_logs`
| Kolom | Tipe Data | Aturan / Batasan | Deskripsi |
|---|---|---|---|
| `id` | BigInt | Primary Key, Auto Increment | Indeks urutan blok (*block height*) |
| `part_id` | BigInt | Foreign Key -> `parts.id` | ID suku cadang yang dicatat |
| `action` | Varchar(100) | Not Null | Jenis aksi (`PART_REGISTERED`, dsb.) |
| `previous_hash` | Char(64) | Not Null | Hash SHA-256 dari blok induk pendahulu |
| `current_hash`  | Char(64) | Not Null | Tanda tangan hash SHA-256 blok ini |
| `user_id` | BigInt | Foreign Key -> `users.id` | Teknisi penandatangan transaksi |
| `timestamps` | Timestamp | Nullable | Stempel waktu ISO-8601 deterministik |

---

## 📡 Dokumentasi REST API

Seluruh *endpoint* berstatus **Protected** mewajibkan penyertaan HTTP Header:  
`Authorization: Bearer <sanctum_token>`

| Method | Endpoint | Akses | Parameter / Body | Deskripsi Singkat |
|---|---|---|---|---|
| `POST` | `/api/login` | Publik | `{ "email": "...", "password": "..." }` | Otentikasi teknisi & penerbitan token Sanctum |
| `GET` | `/api/inventory` | Terlindungi | Query: `?search=...&category=...` | Mengambil daftar inventaris dengan filter |
| `POST` | `/api/inventory` | Terlindungi | `{ "serial_number": "...", "name": "...", "category": "...", "stock_quantity": 10, "base_price_idr": 150000 }` | Menambah suku cadang, menghitung hash blok, mengembalikan status `201 Created` |

---

## 🛠 Panduan Instalasi & Menjalankan Proyek

### Kebutuhan Sistem (Prerequisites)
- [PHP](https://www.php.net/) versi 8.2 atau lebih tinggi & [Composer](https://getcomposer.org/)
- Database Server [MySQL](https://www.mysql.com/) (tersedia di Laragon / XAMPP)
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (versi 3.13 ke atas)
- Perangkat Android fisik dengan USB Debugging aktif atau Emulator Android

---

### 1. Konfigurasi Backend (Laravel 11)

1. **Buka terminal dan masuk ke direktori backend**:
   ```bash
   cd c:/laragon/www/smartfix-backend
   ```

2. **Pasang seluruh dependensi PHP via Composer**:
   ```bash
   composer install
   ```

3. **Atur Berkas Konfigurasi Lingkungan (`.env`)**:
   ```bash
   cp .env.example .env
   php artisan key:generate
   ```
   Buka berkas `.env` lalu sesuaikan kredensial basis data Anda:
   ```env
   DB_CONNECTION=mysql
   DB_HOST=127.0.0.1
   DB_PORT=3306
   DB_DATABASE=smartfix_db
   DB_USERNAME=root
   DB_PASSWORD=
   ```

4. **Jalankan Migrasi Skema Basis Data**:
   ```bash
   php artisan migrate:fresh
   ```

5. **Inisialisasi Akun Teknisi Pertama (Seeding)**:
   Buka `php artisan tinker` dan eksekusi perintah berikut:
   ```php
   App\Models\User::create([
       'name' => 'Agustya Ezha Kurniawan',
       'email' => 'technician@smartfix.com',
       'password' => bcrypt('password123'),
       'role' => 'technician'
   ]);
   ```

6. **Jalankan Server Lokal Laravel**:
   ```bash
   php artisan serve --host=127.0.0.1 --port=8000
   ```
   > Endpoint API siap diakses melalui: `http://127.0.0.1:8000/api`

---

### 2. Konfigurasi Frontend (Flutter Mobile)

1. **Masuk ke folder proyek Flutter**:
   ```bash
   cd ta
   ```

2. **Unduh seluruh paket dan dependensi Flutter**:
   ```bash
   flutter pub get
   ```

3. **Catatan Pengaturan Alamat Jaringan (IP Backend)**:
   - Jika dijalankan pada **Windows Desktop / Chrome Web**: Alamat default `http://127.0.0.1:8000/api` di `lib/core/api_service.dart` dapat langsung digunakan.
   - Jika dijalankan pada **Android Emulator**: Ubah basis URL pada `lib/core/api_service.dart` menjadi `http://10.0.2.2:8000/api`.
   - Jika dijalankan pada **Perangkat Smartphone Fisik**: Ubah basis URL ke alamat IP lokal laptop/PC Anda dalam jaringan Wi-Fi yang sama (contoh: `http://192.168.1.15:8000/api`).

4. **Lakukan Pengujian Kualitas Kode (Static Analysis)**:
   ```bash
   flutter analyze
   ```

5. **Jalankan Aplikasi ke Perangkat**:
   ```bash
   flutter run
   ```

6. **Kredensial Default untuk Pengujian**:
   - **Surel / Email**: `technician@smartfix.com`
   - **Kata Sandi**: `password123`

---

## 📱 Tangkapan Layar Antarmuka (UI Walkthrough)

| 1. Halaman Masuk (Login) | 2. Dasbor Inventaris Real-Time | 3. Tambah Suku Cadang & Bukti Hash |
|:---:|:---:|:---:|
| Formulir email & kata sandi dengan autentikasi Sanctum, sakelar visibilitas, dan opsi sidik jari | Chip kategori, bilah pencarian debounced, kartu metrik KPI, dan lencana verifikasi SHA-256 | Formulir terstruktur dengan pembuat SKU otomatis dan dialog bukti blok kriptografi |

| 4. Penjelajah Rantai Blok | 5. Verifikasi Keaslian Komponen | 6. Pusat Utilitas Teknisi |
|:---:|:---:|:---:|
| Tampilan kronologis blok transaksi dengan tanda tangan SHA-256 previous & current | Validasi tanda tangan QR/hash terhadap sertifikat root suku cadang resmi OEM | Peluncur terpadu untuk AI Asisten, valas & zona waktu, pelacakan GPS, dan minigame sensor |

---

## 👥 Tim Pengembang

Proyek ini dirancang, dibangun, dan didokumentasikan untuk memenuhi tugas mata kuliah **Tugas Akhir — Pemrograman Aplikasi Mobile (Semester 5)** oleh:

| Pasfoto | Nama Mahasiswa | Nomor Induk Mahasiswa (NIM) | Peran & Kontribusi |
|:---:|:---|:---:|:---|
| 👨‍💻 | **Hanggara Winasis** | `124240125` | • Perancangan Antarmuka Flutter & State Management<br>• Integrasi Pusat Utilitas & Sensor Perangkat Keras<br>• Dokumentasi Teknis Sistem & Pengujian Aplikasi |
| 👨‍💻 | **Agustya Ezha Kurniawan** | `124240142` | • Arsitektur Backend Laravel 11 & REST API Engine<br>• Autentikasi Laravel Sanctum & Migrasi Basis Data<br>• Perancangan Logika Buku Besar Kriptografi SHA-256 |

---

<p align="center">
  <b>SmartFix Mobile</b> • Proyek Akademik Tugas Akhir • 2026<br>
  Dikembangkan dengan penuh dedikasi menggunakan Flutter & Laravel
</p>
