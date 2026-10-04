# SmartFix — Mobile-Based Inventory & Supply Chain Management System with Blockchain Integrity (SHA-256)

[![Flutter Version](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart Version](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![Laravel Version](https://img.shields.io/badge/Laravel-11.x-FF2D20?logo=laravel&logoColor=white)](https://laravel.com)
[![License](https://img.shields.io/badge/License-Academic%20Project-0F766E)](#development-team)
[![Blockchain](https://img.shields.io/badge/Security-SHA--256%20Cryptographic%20Ledger-14B8A6)](#cryptographic-blockchain-verification)

> **Tugas Akhir — Pemrograman Aplikasi Mobile (Semester 5)**  
> An enterprise-grade, mobile-first inventory and supply chain traceability system designed for smartphone repair workshops, featuring token-based authentication and a tamper-proof cryptographic audit trail.

---

## 📌 Table of Contents
- [Project Overview](#-project-overview)
- [Key Features](#-key-features)
- [System Architecture](#-system-architecture)
- [Tech Stack](#-tech-stack)
- [Database & Blockchain Schema](#-database--blockchain-schema)
- [API Reference](#-api-reference)
- [Installation & Setup Guide](#-installation--setup-guide)
  - [Backend Setup (Laravel 11)](#1-backend-setup-laravel-11)
  - [Frontend Setup (Flutter)](#2-frontend-setup-flutter-mobile)
- [Screenshots & UI Walkthrough](#-screenshots--ui-walkthrough)
- [Development Team](#-development-team)

---

## 📖 Project Overview

In smartphone repair enterprises, managing high-value OEM spare parts (OLED displays, lithium-ion battery packs, micro-soldered motherboards) requires rigorous inventory control and proof of component authenticity. Counterfeit and gray-market replacement parts cause high device return rates and customer distrust.

**SmartFix** resolves this challenge by combining a responsive **Flutter** cross-platform mobile client with a **Laravel 11 REST API** backed by an on-chain **SHA-256 Cryptographic Blockchain Ledger**. Every part registered or moved within the supply chain computes an immutable cryptographic hash linked to the previous block, creating a verifiable chain of custody that cannot be altered retroactively without invalidating the entire ledger.

---

## 🚀 Key Features

### 1. Secure Authentication & Session Management
- **Laravel Sanctum Token Authentication**: Issues lightweight, cryptographically secure bearer tokens for stateful mobile API communication.
- **Biometric Authentication Integration**: Supports fingerprint and facial recognition login using device biometric hardware (`local_auth`).
- **Persistent Storage**: Sessions survive application restarts using encrypted local key-value persistence (`shared_preferences`).
- **Graceful Logout**: Securely revokes tokens from memory and local storage, clearing user sessions and returning safely to the login screen.

### 2. Real-Time Inventory Management
- **Debounced Live Search**: Real-time querying by component name or Serial/SKU with a 350ms debounce timer to prevent redundant API queries.
- **Horizontal Category Filtering**: Instant filtering across five hardware categories: `All`, `Display`, `Battery`, `Machine`, and `Accessories`.
- **Dynamic Stock Badges**: Real-time visual status tags (`In Stock`, `Low Stock`, `Out of Stock`) with dynamic inventory KPI counters.
- **Currency Localization**: Native Indonesian Rupiah (IDR) numerical formatting (e.g., `Rp 1.450.000`).
- **Pull-to-Refresh**: Seamless inventory synchronization with backend records via `RefreshIndicator`.

### 3. Cryptographic Blockchain Verification (SHA-256)
- **Immutable Block Linking**: Each registered part computes a hash combining:
  $$\text{Hash}_n = \text{SHA-256}(\text{Hash}_{n-1} \parallel \text{Serial} \parallel \text{Name} \parallel \text{Category} \parallel \text{Stock} \parallel \text{Price} \parallel \text{UserID} \parallel \text{Timestamp})$$
- **Ledger Chain Explorer**: Interactive timeline interface displaying block height, action types (`PART_REGISTERED`, `QUALITY_INSPECTION`, `STOCK_TRANSFER`), previous hashes, current hashes, and signing nodes.
- **One-Touch Chain Integrity Audit**: Mathematical traversal that validates ledger continuity and flags compromised or broken hash links.
- **Single Component Verifier**: Diagnostic tool allowing technicians to paste any QR signature, serial, or hash to confirm OEM authenticity.

### 4. Hardware Utilities & Field Tools Hub
- **AI Repair Assistant**: Interactive diagnostics helper for motherboard short-circuit analysis and schematic pinout guidance.
- **Currency & Timezone Converter**: Live multi-currency conversion (IDR, USD, EUR) and Indonesian service timezone synchronizer (WIB, WITA, WIT).
- **GPS Courier Tracking**: Live delivery dispatch map using `flutter_map` (OpenStreetMap) and `geolocator`.
- **Sensor Calibration Minigame**: Interactive hardware sensor diagnostic testing device accelerometer and gyroscope inputs.

### 5. Modern Industrial-Tech User Interface
- **Dark Charcoal Theme**: High-contrast, eye-friendly workshop palette (`#1E1E1E` background, `#262626` surface, `#14B8A6` teal accents).
- **Responsive Layout**: Designed for mobile form factors with null-safe, clean architecture patterns.

---

## 🏗 System Architecture

```text
┌─────────────────────────────────────────────────────────────┐
│                 SmartFix Mobile App (Flutter)               │
│  ┌─────────────────┐ ┌─────────────────┐ ┌───────────────┐  │
│  │   Auth / Bio    │ │ Inventory List  │ │ Tools Hub /   │  │
│  │   Credentials   │ │ & Search / FAB  │ │ Blockchain UI │  │
│  └────────┬────────┘ └────────┬────────┘ └───────┬───────┘  │
└───────────┼───────────────────┼──────────────────┼──────────┘
            │                   │                  │
            │ HTTP (JSON)       │ Bearer Token     │ SHA-256
            ▼                   ▼                  ▼
┌─────────────────────────────────────────────────────────────┐
│                 Laravel 11 REST API Engine                  │
│  ┌─────────────────┐ ┌─────────────────┐ ┌───────────────┐  │
│  │  Sanctum Auth   │ │ Inventory CRUD  │ │ Blockchain    │  │
│  │   Middleware    │ │   Controller    │ │ Hashing Logic │  │
│  └────────┬────────┘ └────────┬────────┘ └───────┬───────┘  │
└───────────┼───────────────────┼──────────────────┼──────────┘
            │                   │                  │
            ▼                   ▼                  ▼
┌─────────────────────────────────────────────────────────────┐
│                 Relational & Ledger Storage                 │
│  ┌──────────────┐     ┌──────────────┐    ┌──────────────┐  │
│  │    users     │     │    parts     │    │  blockchain  │  │
│  │    table     │     │    table     │    │  _logs table │  │
│  └──────────────┘     └──────────────┘    └──────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

---

## 💻 Tech Stack

### Frontend (Mobile)
- **Framework**: [Flutter](https://flutter.dev) (v3.13+ / 3.x)
- **Language**: [Dart](https://dart.dev) (v3.13+ null-safe)
- **Key Packages**:
  - `http: ^1.6.0` — REST API networking & Sanctum bearer header injection
  - `shared_preferences: ^2.5.3` — Session token & credential persistence
  - `local_auth: ^3.0.2` — Biometric authentication (fingerprint / Face ID)
  - `flutter_map: ^8.3.2` & `latlong2: ^0.10.1` — OpenStreetMap GPS logistics
  - `sensors_plus: ^7.1.1` — Accelerometer & gyroscope sensor diagnostics
  - `flutter_local_notifications: ^22.3.1` — Local offline push notifications

### Backend (REST API)
- **Framework**: [Laravel 11](https://laravel.com)
- **Language**: PHP 8.2 / 8.3
- **Authentication**: Laravel Sanctum (Personal Access Tokens)
- **Database**: MySQL 8.x / MariaDB (or SQLite for development)
- **Cryptography**: Native PHP `hash('sha256', ...)` with ISO-8601 deterministic serialization

### Development Tools
- **Environment**: Laragon / Apache / Nginx
- **API Testing**: Postman / Bruno / cURL
- **Version Control**: Git & GitHub

---

## 🗄 Database & Blockchain Schema

### 1. `users` Table
| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | BigInt | PK, Auto Increment | Unique user identifier |
| `name` | Varchar(255) | Not Null | Technician full name |
| `email` | Varchar(255) | Unique, Not Null | Technician login email |
| `password` | Varchar(255) | Not Null | Bcrypt encrypted password hash |
| `role` | Varchar(50) | Default: `'technician'` | System authorization role |
| `timestamps` | Timestamp | Nullable | Created & updated timestamps |

### 2. `parts` Table
| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | BigInt | PK, Auto Increment | Component identifier |
| `serial_number` | Varchar(255) | Unique, Not Null | Cryptographic hardware SKU |
| `name` | Varchar(255) | Not Null | Component commercial description |
| `category` | Varchar(100) | Not Null | `Display`, `Battery`, `Machine`, `Accessories` |
| `stock_quantity`| Integer | Min: 0, Not Null | Available stock in warehouse |
| `base_price_idr`| Decimal(14,2)| Min: 0, Not Null | Price in Indonesian Rupiah |
| `timestamps` | Timestamp | Nullable | Created & updated timestamps |

### 3. `blockchain_logs` Table
| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | BigInt | PK, Auto Increment | Block height index |
| `part_id` | BigInt | FK -> `parts.id` | Associated component record |
| `action` | Varchar(100) | Not Null | `PART_REGISTERED`, `STOCK_TRANSFER`, etc. |
| `previous_hash` | Char(64) | Not Null | SHA-256 hash of parent block |
| `current_hash`  | Char(64) | Not Null | SHA-256 cryptographic block signature |
| `user_id` | BigInt | FK -> `users.id` | Signing technician node ID |
| `timestamps` | Timestamp | Nullable | Deterministic ISO-8601 block timestamp |

---

## 📡 API Reference

All protected endpoints require the HTTP header:  
`Authorization: Bearer <sanctum_token>`

| Method | Endpoint | Access | Request Body | Description |
|---|---|---|---|---|
| `POST` | `/api/login` | Public | `{ "email": "...", "password": "..." }` | Authenticates technician & issues Sanctum token |
| `GET` | `/api/inventory` | Protected | Query params: `?search=...&category=...` | Fetches filtered inventory list |
| `POST` | `/api/inventory` | Protected | `{ "serial_number": "...", "name": "...", "category": "...", "stock_quantity": 10, "base_price_idr": 150000 }` | Adds new part, calculates SHA-256 block, returns `201 Created` |

---

## 🛠 Installation & Setup Guide

### Prerequisites
- [PHP](https://www.php.net/) >= 8.2 & [Composer](https://getcomposer.org/)
- [MySQL](https://www.mysql.com/) database server (via Laragon / XAMPP)
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (v3.13+)
- Physical Android/iOS device or Emulator

---

### 1. Backend Setup (Laravel 11)

1. **Clone repository & navigate to backend directory**:
   ```bash
   cd c:/laragon/www/smartfix-backend
   ```

2. **Install PHP dependencies**:
   ```bash
   composer install
   ```

3. **Configure Environment Variables**:
   ```bash
   cp .env.example .env
   php artisan key:generate
   ```
   Open `.env` and verify your database connection:
   ```env
   DB_CONNECTION=mysql
   DB_HOST=127.0.0.1
   DB_PORT=3306
   DB_DATABASE=smartfix_db
   DB_USERNAME=root
   DB_PASSWORD=
   ```

4. **Run Database Migrations**:
   ```bash
   php artisan migrate:fresh
   ```

5. **Seed Initial Technician User**:
   Run `php artisan tinker` and execute:
   ```php
   App\Models\User::create([
       'name' => 'Agustya Ezha Kurniawan',
       'email' => 'technician@smartfix.com',
       'password' => bcrypt('password123'),
       'role' => 'technician'
   ]);
   ```

6. **Start the Laravel Development Server**:
   ```bash
   php artisan serve --host=127.0.0.1 --port=8000
   ```
   > The API will be available at: `http://127.0.0.1:8000/api`

---

### 2. Frontend Setup (Flutter Mobile)

1. **Navigate to the Flutter project directory**:
   ```bash
   cd ta
   ```

2. **Install Flutter packages**:
   ```bash
   flutter pub get
   ```

3. **Network Configuration Note**:
   - If running on **Windows Desktop / Web**: Default `http://127.0.0.1:8000/api` in `lib/core/api_service.dart` works directly.
   - If running on **Android Emulator**: Change base URL in `lib/core/api_service.dart` to `http://10.0.2.2:8000/api`.
   - If running on a **Physical Device**: Change base URL to your computer's local Wi-Fi IP (e.g. `http://192.168.1.15:8000/api`).

4. **Run Static Analysis (Quality Check)**:
   ```bash
   flutter analyze
   ```

5. **Launch the Application**:
   ```bash
   flutter run
   ```

6. **Default Test Credentials**:
   - **Email**: `technician@smartfix.com`
   - **Password**: `password123`

---

## 📱 Screenshots & UI Walkthrough

| 1. Industrial-Tech Login | 2. Real-time Inventory Dashboard | 3. Add Part & Blockchain Proof |
|:---:|:---:|:---:|
| Email/password form with Sanctum authentication, visibility toggle, and biometric option | Category chips, debounced search bar, KPI cards, and SHA-256 verified badges | Structured form with SKU auto-generator and cryptographic hash dialog |

| 4. Ledger Chain Explorer | 5. Cryptographic Hash Verifier | 6. Technical Utilities Hub |
|:---:|:---:|:---:|
| Chronological block timeline with previous/current SHA-256 signatures | Single-part hash verifier against OEM root certificates | Central launcher for AI Assistant, Forex & Time, GPS, and sensor minigame |

---

## 👥 Development Team

This project was designed, developed, and documented for the **Tugas Akhir — Pemrograman Aplikasi Mobile (Semester 5)** by:

| Photo | Name | Student ID (NIM) | Role & Contribution |
|:---:|:---|:---:|:---|
| 👨‍💻 | **Hanggara Winasis** | `124240125` | • Flutter UI Architecture & State Management<br>• Technical Utilities & Sensor Integration<br>• System Documentation & QA Testing |
| 👨‍💻 | **Agustya Ezha Kurniawan** | `124240142` | • Laravel 11 Backend & REST API Architecture<br>• Sanctum Authentication & Database Migrations<br>• SHA-256 Blockchain Cryptographic Ledger Design |

---

<p align="center">
  <b>SmartFix Mobile</b> • Final Academic Project • 2026<br>
  Built with ❤️ using Flutter & Laravel
</p>
