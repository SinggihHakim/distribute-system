# CONTEXT.md — Panduan untuk AI Assistant

> ⚠️ **WAJIB DIBACA SEBELUM GENERATE KODE APAPUN**
> File ini dibuat khusus untuk AI Assistant agar tidak salah arah saat membantu project ini.

---

## 1. Identitas Project

| Info         | Detail |
|---|---|
| **Nama App** | Kasir Pintar |
| **Package**  | `pakjoni_project` |
| **Stack**    | Flutter (Dart) + Supabase (PostgreSQL) |
| **Platform** | Android (utama), Web (secondary) |
| **Status**   | Active development — lihat `fase.md` untuk progress |

---

## 2. Dokumen Referensi

Selalu baca dokumen ini sebelum menjawab atau generate kode:

| File | Isi |
|---|---|
| `prd.md` | Product Requirements Document — fitur, alur, dan spesifikasi lengkap |
| `database.md` | Semua SQL schema & migration (v1.0.0–v1.3.0). **JANGAN buat table/function baru tanpa cek di sini dulu** |
| `fase.md` | Sprint plan & checklist per fase. Update status setelah selesai |
| `bug.md` | Catatan bug yang sedang/sudah ditangani |

---

## 3. Struktur Folder (Aktual)

```
lib/
├── main.dart                         ← Entry point, Supabase init, routing
├── core/
│   ├── config/
│   │   └── supabase_config.dart      ← ⚠️ LIHAT ATURAN ENV DI BAWAH
│   ├── theme/
│   │   ├── app_theme.dart
│   │   └── app_colors.dart
│   ├── utils/
│   │   ├── currency_formatter.dart
│   │   └── date_formatter.dart
│   └── widgets/
│       └── app_widgets.dart          ← AppButton, AppTextField, LoadingOverlay, dll
├── features/
│   ├── auth/
│   │   ├── data/auth_service.dart    ← signIn, signOut, registerStore, createDriver
│   │   └── presentation/            ← login_page, register_page, onboarding_page, shell_pages
│   ├── products/
│   │   ├── data/product_repository.dart
│   │   └── presentation/            ← products_page, stock_in_page
│   ├── distributions/
│   │   ├── data/distribution_repository.dart
│   │   └── presentation/            ← distributions_page, create_distribution_page, distribution_detail_page
│   ├── dashboard/
│   │   └── presentation/
│   └── reports/
│       └── presentation/
└── models/
    ├── user_model.dart
    ├── store_model.dart
    ├── product_model.dart
    ├── distribution_model.dart
    └── distribution_item_model.dart
```

---

## 4. ⚠️ ATURAN KRITIS — ENVIRONMENT & KONFIGURASI

### 4.1 Cara Supabase dikonfigurasi

Kredensial Supabase **TIDAK hardcoded** di source code. Menggunakan `String.fromEnvironment`:

```dart
// lib/core/config/supabase_config.dart
abstract class SupabaseConfig {
  static const String url = String.fromEnvironment('SUPABASE_URL');
  static const String anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  static void validate() { /* assert tidak kosong */ }
}
```

Nilai asli disimpan di file `.env` di root project (sudah ada, sudah di-gitignore).

### 4.2 Cara menjalankan app

```bash
# ✅ BENAR
flutter run --dart-define-from-file=.env
flutter build apk --dart-define-from-file=.env

# ❌ SALAH — akan crash (SUPABASE_URL kosong)
flutter run
```

- **VS Code:** Tekan F5 → otomatis pakai `.env` (sudah dikonfigurasi di `.vscode/launch.json`)
- **Android Studio:** Run lewat konfigurasi `main.dart` (sudah dikonfigurasi di `.idea/runConfigurations/main_dart.xml`)

### 4.3 JANGAN lakukan ini

- ❌ Jangan hardcode `SUPABASE_URL` atau `SUPABASE_ANON_KEY` di file Dart manapun
- ❌ Jangan tambahkan `defaultValue` ke `String.fromEnvironment` (ini menghilangkan keamanan .env)
- ❌ Jangan commit file `.env` ke git (sudah ada di `.gitignore`)
- ❌ Jangan buat file `.env.example` yang berisi key asli

---

## 5. ⚠️ ATURAN KRITIS — FILE TEST & DIAGNOSTIK

### JANGAN buat file berikut di dalam folder `lib/`:
- `lib/test_*.dart`
- `lib/debug_*.dart`
- `lib/diagnostic_*.dart`
- `lib/*.js`

File test yang benar ditulis di folder `test/` sesuai konvensi Flutter.

File diagnostik sementara (`.js`, script Node.js, dll.) letakkan di luar project atau hapus setelah selesai digunakan.

**Latar belakang:** AI sebelumnya membuat `lib/test_conn.dart`, `lib/test_insert.dart`, `lib/test_register.dart` yang mengotori project dan membingungkan IDE.

---

## 6. Database — Aturan Penting

### 6.1 Fungsi RPC yang tersedia di Supabase

| Function | Dipanggil dari | Keterangan |
|---|---|---|
| `register_store(p_auth_id, p_name, p_email, p_nama_toko, p_alamat?, p_telepon?, p_kota?)` | Flutter setelah `signUp` | Buat store + user admin secara atomik |
| `admin_create_driver(p_driver_auth_id, p_name, p_email, p_phone?)` | Flutter (admin login) | Buat akun driver, auto-link ke store admin |

### 6.2 Tabel yang tersedia

`stores`, `users`, `products`, `stock_in`, `distributions`, `distribution_items`

Semua tabel punya kolom `store_id` — data terisolasi per toko (multi-tenant).

### 6.3 RLS (Row Level Security) aktif

Semua tabel dilindungi RLS. Helper functions: `get_my_role()`, `get_my_store_id()`, `get_my_user_id()` — semua `SECURITY DEFINER` dan ditulis di PL/pgSQL (bukan SQL biasa, untuk mencegah inlining).

### 6.4 Jika ingin update schema

Tambahkan SQL baru di `database.md` dengan format versi baru (contoh: `## VERSI 1.4.0`), **jangan ubah SQL versi lama yang sudah ada**.

---

## 7. Design System

| Token | Value |
|---|---|
| Primary | `#1B6CA8` |
| Primary Dark | `#14508A` |
| Secondary | `#F59E0B` |
| Success | `#10B981` |
| Error | `#EF4444` |
| Background | `#F8FAFC` |
| Surface | `#FFFFFF` |
| Text Primary | `#1E293B` |
| Text Secondary | `#64748B` |

**Font:** Poppins via `google_fonts`

**Widget reusable:** Gunakan `AppButton`, `AppTextField`, `LoadingOverlay` dari `lib/core/widgets/app_widgets.dart`. Jangan buat widget baru jika fungsi yang sama sudah ada.

---

## 8. Routing

Menggunakan `MaterialApp` dengan named routes (bukan GoRouter — meski ada di pubspec, belum diimplementasi):

| Route | Widget | Akses |
|---|---|---|
| `/splash` | `_SplashRouter` | Public |
| `/onboarding` | `OnboardingPage` | Public |
| `/login` | `LoginPage` | Public |
| `/register` | `RegisterPage` | Public |
| `/admin` | `AdminShell` | Admin only |
| `/driver` | `DriverShell` | Driver only |

---

## 9. State & Auth Flow

- Tidak menggunakan Riverpod/Provider secara aktif (sudah ada di pubspec tapi belum diimplementasi di semua fitur)
- Auth state dikelola oleh `AuthService` + `Supabase.instance.client.auth`
- Session persistent otomatis oleh Supabase Flutter SDK
- Splash screen (`_SplashRouter`) cek session → redirect ke `/admin`, `/driver`, atau `/onboarding`

---

## 10. Konvensi Kode

- **Bahasa komentar:** Bahasa Indonesia
- **Nama variabel/fungsi:** camelCase (Dart standard)
- **Nama file:** snake_case
- **Error handling:** selalu `try-catch`, tampilkan pesan error yang ramah pengguna (bukan stack trace)
- **Loading state:** selalu ada indikator loading saat operasi async
- Tidak ada `print()` di production code — gunakan hanya untuk debugging sementara

---

## 11. Catatan Bug & Incident

### 2026-06-03 — Config Env Incident

AI sebelumnya mengubah `supabase_config.dart` dari hardcoded ke `String.fromEnvironment` **tanpa `defaultValue`**, menyebabkan semua fitur (register, login, produk, distribusi) crash karena Supabase diinisialisasi dengan URL kosong saat app dijalankan tanpa flag `--dart-define-from-file=.env`.

**Fix yang sudah diterapkan:** `SupabaseConfig.validate()` dipanggil di `main()` sebelum `Supabase.initialize()` untuk fail-fast dengan pesan error yang jelas.

**Pelajaran:** Jangan pernah mengubah cara konfigurasi Supabase tanpa memastikan semua cara run (VS Code, Android Studio, terminal) sudah dikonfigurasi dengan benar.
