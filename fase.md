# Sprint Plan — Kasir Pintar

> Project: `pakjoni_project` (Flutter + Supabase)
> Start: 2026-06-03
> Status saat ini: Fase 0–4 selesai, Fase 5 belum dimulai

---

## 📊 Progress Overview

| Fase | Nama                         | Status        | Estimasi |
| ---- | ---------------------------- | ------------- | -------- |
| 0    | Setup & Fondasi              | ✅ Done       | 1 hari   |
| 1    | Auth & Navigation            | ✅ Done       | 2 hari   |
| 2    | Manajemen Produk & Stok      | ✅ Done       | 3 hari   |
| 3    | Sistem Distribusi            | ✅ Done       | 4 hari   |
| 4    | Dashboard & KPI              | ✅ Done       | 2 hari   |
| 5    | Export Laporan Excel         | ⏳ Pending    | 3 hari   |

**Total estimasi:** ~15 hari kerja

---

## FASE 0 — Setup & Fondasi ✅

> Status: ✅ Done — 2026-06-03

### Tujuan
Menyiapkan seluruh fondasi project: package, folder structure, Supabase, dan design system.

---

### 0.1 Update `pubspec.yaml`

Tambahkan semua package yang diperlukan:

```yaml
dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8

  # Backend
  supabase_flutter: ^2.5.0

  # State Management
  flutter_riverpod: ^2.5.1
  riverpod_annotation: ^2.3.5

  # Navigation
  go_router: ^14.0.0

  # UI & Utils
  intl: ^0.19.0
  fl_chart: ^0.69.0
  google_fonts: ^6.2.1

  # Export Excel
  excel: ^4.0.6
  share_plus: ^11.0.0
  path_provider: ^2.1.5
  permission_handler: ^12.0.1
  open_filex: ^4.5.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^6.0.0
  build_runner: ^2.4.9
  riverpod_generator: ^2.4.0
```

- ✅ Jalankan `flutter pub get`

---

### 0.2 Setup Supabase

- ✅ Buat project baru di [supabase.com](https://supabase.com)
- ✅ Jalankan SQL `v1.0.0` dari `database.md` di SQL Editor Supabase
- ✅ Salin `SUPABASE_URL` dan `SUPABASE_ANON_KEY`
- ✅ Buat file `.env` dan simpan di `lib/core/config/supabase_config.dart` (menggunakan `String.fromEnvironment`)

```dart
// lib/core/config/supabase_config.dart
abstract class SupabaseConfig {
  static const String url = String.fromEnvironment('SUPABASE_URL');
  static const String anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  static void validate() { /* assert tidak kosong */ }
}
```

- ✅ Init Supabase di `main.dart`

---

### 0.3 Struktur Folder

Buat struktur folder berikut di dalam `lib/`:

```
lib/
├── main.dart
├── app.dart                        ← MaterialApp + GoRouter
│
├── core/
│   ├── config/
│   │   └── supabase_config.dart
│   ├── theme/
│   │   ├── app_theme.dart          ← Color, Typography, ThemeData
│   │   └── app_colors.dart
│   ├── utils/
│   │   ├── currency_formatter.dart
│   │   └── date_formatter.dart
│   └── widgets/
│       ├── app_button.dart
│       ├── app_text_field.dart
│       └── loading_overlay.dart
│
├── features/
│   ├── auth/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   ├── products/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   ├── distributions/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   ├── dashboard/
│   │   └── presentation/
│   └── reports/
│       ├── data/
│       ├── domain/
│       └── presentation/
│
└── models/
    ├── user_model.dart
    ├── product_model.dart
    ├── distribution_model.dart
    └── distribution_item_model.dart
```

- ✅ Buat semua folder di atas

---

### 0.4 Design System

Tentukan palet warna dan typography sebelum mulai coding UI:

| Token         | Value              |
| ------------- | ------------------ |
| Primary       | `#1B6CA8` (biru)  |
| Secondary     | `#F59E0B` (kuning) |
| Success       | `#10B981`          |
| Error         | `#EF4444`          |
| Background    | `#F8FAFC`          |
| Surface       | `#FFFFFF`          |
| Text Primary  | `#1E293B`          |
| Text Secondary| `#64748B`          |

Font: **Poppins** (via google_fonts)

- ✅ Buat `app_theme.dart`
- ✅ Buat `app_colors.dart`

---

## FASE 1 — Auth & Navigation ✅

> Status: ✅ Done — 2026-06-05
> Depends on: Fase 0 ✅

### Tujuan
Login & Register Admin (buat toko), redirect berdasarkan role, session persistent, Admin tambah Driver.

---

### 1.1 Model

- ✅ Buat `UserModel` dari tabel `users`
- ✅ Buat `StoreModel` dari tabel `stores`

```dart
class UserModel {
  final String id;
  final String authId;
  final String name;
  final String email;
  final String? phone;
  final String role; // 'admin' | 'driver'
  final bool isActive;
  final String? storeId; // terhubung ke toko
}

class StoreModel {
  final String id;
  final String namaToko;
  final String? alamat;
  final String? telepon;
  final String? kota;
}
```

---

### 1.2 Auth Service

- ✅ Buat `AuthService` dengan method:
  - ✅ `signIn(email, password)` → Supabase Auth
  - ✅ `signOut()`
  - ✅ `getCurrentUser()` → fetch dari tabel `users` by `auth_id`
  - ✅ `signUp(email, password)` → Supabase Auth signup (terintegrasi di `registerStore`)
  - ✅ `registerStore(authId, name, email, namaToko, ...)` → panggil DB function `register_store()`
  - ✅ `createDriver(name, email, password, phone?)` → panggil DB function `admin_create_driver()`

---

### 1.3 Halaman Onboarding

- ✅ Tampil logo + nama app
- ✅ Dua pilihan: **Masuk** dan **Daftar Toko**
- ✅ Animasi masuk yang smooth (FadeTransition + SlideTransition)

---

### 1.4 Halaman Register Toko (Admin/Owner)

- ✅ Form: Nama Lengkap, Email, Password, Nama Toko
- ✅ Field opsional: Alamat Toko, Telepon Toko
- ✅ Validasi semua field wajib
- ✅ Password min 8 karakter + konfirmasi password
- ✅ Proses: `signUp()` → `register_store()` (DB function) → auto-login → Dashboard Admin
- ✅ Loading state + error handling

---

### 1.5 Halaman Login

- ✅ Desain halaman login (logo, email, password, tombol login)
- ✅ Validasi form (email format, password tidak kosong)
- ✅ Tampilkan error message jika gagal
- ✅ Loading state saat proses login
- ✅ Redirect ke role yang sesuai setelah berhasil

---

### 1.6 Navigation

- ✅ Route `/splash` → cek session → redirect
- ✅ Route `/login` → LoginPage
- ✅ Route `/admin` → AdminShell (5 tab: Dashboard, Produk, Distribusi, Laporan, Pengaturan)
- ✅ Route `/driver` → DriverShell (2 tab: Beranda, Distribusi)
- ✅ Tambah route `/register` → RegisterPage
- ✅ Tambah route `/onboarding` → OnboardingPage
- ✅ Admin tidak bisa akses route Driver dan sebaliknya (role check di splash)

---

### 1.7 Bottom Navigation

- ✅ `AdminShell` dengan 5 tab: Dashboard, Produk, Distribusi, Laporan, Pengaturan
- ✅ `DriverShell` dengan 2 tab: Beranda, Distribusi

---

### 1.8 Pengaturan (Bonus — tidak ada di plan awal)

- ✅ Halaman Settings Page dengan 2 tab: Profil Toko + Manajemen Driver
- ✅ Edit profil toko (nama, alamat, telepon, kota)
- ✅ List driver terdaftar
- ✅ Tambah driver baru via dialog form
- ✅ Detail driver + copy email/telepon

---

### Checklist Fase 1

- ✅ Login berhasil dengan email & password
- ✅ Admin redirect ke halaman Admin
- ✅ Driver redirect ke halaman Driver
- ✅ Session persistent (tidak perlu login ulang setelah close app)
- ✅ Logout berfungsi
- ✅ Driver tidak bisa akses halaman Admin
- ✅ Halaman onboarding (Masuk vs Daftar Toko)
- ✅ Register toko baru berhasil (form + DB function)
- ✅ Auto-login setelah register
- ✅ StoreModel dibuat
- ✅ Admin bisa tambah driver baru
- ✅ Admin bisa lihat dan kelola profil toko

---

## FASE 2 — Manajemen Produk & Stok Gudang ✅

> Status: ✅ Done — 2026-06-05
> Depends on: Fase 1 ✅

### Tujuan
Admin dapat mengelola produk dan input stok masuk gudang.

---

### 2.1 Model

- ✅ Buat `ProductModel` dari tabel `products`

---

### 2.2 Product Repository

- ✅ `getProducts()` → semua produk aktif + stok gudang (dengan filter store_id)
- ✅ `addProduct(data)` → tambah produk baru (termasuk stok awal + stock_in record)
- ✅ `updateProduct(id, data)` → edit produk
- ✅ `deactivateProduct(id)` → soft delete
- ✅ `activateProduct(id)` → aktifkan kembali produk
- ✅ `addStockIn(data)` → input stok masuk (+ auto update stok_gudang)
- ✅ `getStockInHistory(productId)` → riwayat stok masuk per produk

---

### 2.3 Halaman List Produk

- ✅ List semua produk dengan:
  - Nama, satuan, harga modal, harga jual, stok gudang
  - Badge merah jika stok < `stok_minimum`
- ✅ Search/filter produk
- ✅ Tombol tambah produk (FAB)
- ✅ Swipe to edit / tombol edit

---

### 2.4 Form Tambah/Edit Produk

- ✅ Input: nama, satuan, harga modal, harga jual, stok minimum
- ✅ Validasi semua field wajib diisi
- ✅ Harga harus > 0
- ✅ Harga jual harus >= harga modal (warning jika tidak)

---

### 2.5 Form Input Stok Masuk

- ✅ Pilih produk (dropdown / search)
- ✅ Input qty masuk
- ✅ Input harga modal saat ini (pre-filled dari harga produk)
- ✅ Keterangan (opsional)
- ✅ Konfirmasi sebelum submit
- ✅ Stok gudang terupdate otomatis

---

### Checklist Fase 2

- ✅ Admin bisa melihat list produk + stok gudang
- ✅ Admin bisa tambah produk baru
- ✅ Admin bisa edit harga produk
- ✅ Admin bisa nonaktifkan produk
- ✅ Admin bisa input stok masuk
- ✅ Stok gudang bertambah setelah stok masuk diinput
- ✅ Tampil warning jika stok menipis

---

## FASE 3 — Sistem Distribusi ✅

> Status: ✅ Done — 2026-06-05
> Depends on: Fase 2 ✅

### Tujuan
Admin buat distribusi ke Driver, Driver input hasil penjualan, stok otomatis update.

---

### 3.1 Model

- ✅ Buat `DistributionModel` dari tabel `distributions`
- ✅ Buat `DistributionItemModel` dari tabel `distribution_items`

---

### 3.2 Distribution Repository

- ✅ `getDistributions()` → semua distribusi (Admin) dengan join driver & admin name
- ✅ `getMyDistributions()` → distribusi driver yg login
- ✅ `createDistribution(data)` → buat distribusi baru (dengan validasi stok)
- ✅ `addDistributionItems(items)` → tambah item distribusi (terintegrasi di createDistribution)
- ✅ `completeDistribution(distributionId, items)` → input hasil retur Driver
- ✅ `getDrivers()` → list driver toko ini (untuk dropdown)
- ✅ `getDistributionById(id)` → detail satu distribusi

---

### 3.3 Halaman List Distribusi (Admin)

- ✅ List semua distribusi dengan filter: Pending / Returned
- ✅ Per item: nama driver, tanggal, status, total produk
- ✅ Tombol buat distribusi baru (FAB)
- ✅ Tap untuk lihat detail distribusi

---

### 3.4 Form Buat Distribusi (Admin)

- ✅ Pilih driver (dropdown)
- ✅ Pilih tanggal distribusi
- ✅ Tambah item: pilih produk + input qty keluar
- ✅ Validasi: qty tidak melebihi stok gudang
- ✅ Preview ringkasan sebelum submit
- ✅ Konfirmasi submit → stok berkurang otomatis

---

### 3.5 Halaman Dashboard Driver

- ✅ Tampil distribusi aktif (status: PENDING)
- ✅ Tombol "Input Hasil" pada distribusi aktif
- ✅ Riwayat distribusi selesai

---

### 3.6 Form Input Hasil Driver

- ✅ List produk yang dibawa
- ✅ Per produk: input `qty_terjual` dan `qty_kembali`
- ✅ Validasi: qty_terjual + qty_kembali = qty_keluar
- ✅ Preview kalkulasi otomatis (omzet, laba)
- ✅ Submit → status jadi RETURNED, stok kembali bertambah

---

### Checklist Fase 3

- ✅ Admin bisa membuat distribusi ke driver
- ✅ Stok gudang berkurang saat distribusi dibuat
- ✅ Driver melihat distribusi aktifnya
- ✅ Driver bisa input qty terjual + retur
- ✅ Validasi: terjual + kembali = keluar
- ✅ Stok gudang bertambah sesuai qty kembali
- ✅ Status distribusi berubah menjadi RETURNED

---

## FASE 4 — Dashboard Admin & KPI ✅

> Status: ✅ Done — 2026-06-05
> Depends on: Fase 3 ✅

### Tujuan
Admin dapat melihat ringkasan bisnis hari ini dan tren penjualan.

---

### 4.1 KPI Cards

- ✅ Total Omzet Hari Ini
- ✅ Total Laba Hari Ini
- ✅ Distribusi Aktif (PENDING)
- ✅ Jumlah Produk Stok Menipis

---

### 4.2 Grafik Omzet 7 Hari (fl_chart)

- ✅ Bar chart atau line chart
- ✅ Sumbu X: tanggal, Sumbu Y: omzet (Rp)
- ✅ Tap bar untuk lihat detail hari itu

---

### 4.3 Top 5 Produk Terlaris

- ✅ List produk berdasarkan qty_terjual bulan ini
- ✅ Tampilkan progress bar relatif terhadap produk #1

---

### 4.4 Peringatan Stok Menipis

- ✅ List produk dengan stok < stok_minimum
- ✅ Tombol shortcut ke form input stok masuk

---

### 4.5 Dashboard Driver (Bonus)

- ✅ Sambutan nama driver + nama toko
- ✅ Jumlah distribusi pending
- ✅ Riwayat 5 distribusi terakhir yang selesai + omzet
- ✅ Quick action ke halaman distribusi

---

### Checklist Fase 4

- ✅ KPI hari ini tampil akurat
- ✅ Grafik omzet 7 hari berfungsi
- ✅ Top 5 produk terlaris bulan ini tampil
- ✅ Peringatan stok menipis tampil
- ✅ Driver dashboard fungsional

---

## FASE 5 — Export Laporan Excel

> Status: ⏳ Pending
> Depends on: Fase 4 ✅

### Tujuan
Admin dapat mengunduh berbagai jenis laporan dalam format `.xlsx`.

---

### 5.1 Report Service

- ⏳ Query data untuk setiap jenis laporan dari Supabase
- ⏳ `getHarianReport(date)`
- ⏳ `getMingguanReport(weekStart, weekEnd)`
- ⏳ `getBulananReport(month, year)`
- ⏳ `getTahunanReport(year)`
- ⏳ `getDistribusiDriverReport(range, driverId?)`
- ⏳ `getPergerakanStokReport(range)`
- ⏳ `getProdukTerlarisReport(range)`
- ⏳ `getAnalisisDriverReport(range)`
- ⏳ `getLabaRugiReport(range)`

---

### 5.2 Excel Generator Service

- ⏳ Fungsi generate `.xlsx` per jenis laporan
- ⏳ Sheet 1 selalu berisi Dashboard KPI
- ⏳ Styling: header bold, currency format, border
- ⏳ Generate nama file otomatis sesuai jenis laporan

---

### 5.3 File Manager

- ⏳ Simpan file ke storage device (`path_provider`)
- ⏳ Minta permission storage Android (`permission_handler`)
- ⏳ Buka file langsung (`open_filex`)
- ⏳ Share file (`share_plus`): WhatsApp, Email, Drive

---

### 5.4 Halaman Laporan (Admin)

- ⏳ Pilih jenis laporan (dropdown / tab)
- ⏳ Pilih filter (tanggal/minggu/bulan/tahun)
- ⏳ Preview ringkasan data di layar sebelum export
- ⏳ Tombol "Export Excel"
- ⏳ Loading indicator saat generate
- ⏳ Bottom sheet: Buka File / Share / Simpan ke Drive

---

### Checklist Fase 5

- ⏳ Semua 9 jenis laporan berhasil generate `.xlsx`
- ⏳ File dapat dibuka di Google Sheets / Excel
- ⏳ File dapat dibagikan via WhatsApp
- ⏳ File dapat dikirim via Email
- ⏳ Nama file otomatis sesuai format di PRD
- ⏳ Driver tidak bisa akses halaman laporan
- ⏳ Waktu generate < 10 detik untuk 10.000 baris
- ⏳ Kalkulasi omzet, modal, laba akurat

---

## 📝 Catatan Sprint

> Gunakan bagian ini untuk mencatat keputusan teknis, bug, atau perubahan scope.

### 2026-06-03
- Project dibuat, PRD & database schema selesai
- ✅ Fase 0 selesai: pubspec.yaml updated, folder structure dibuat, design system selesai, main.dart di-setup dengan Supabase init
- Package terinstall: supabase_flutter, flutter_riverpod, go_router, google_fonts, fl_chart, intl, excel, share_plus, path_provider, permission_handler, open_filex
- ⚠️ TODO: Isi `SupabaseConfig.url` dan `SupabaseConfig.anonKey` di `lib/core/config/supabase_config.dart`
- 🔄 Next: Fase 1 — Auth & Navigation

### 2026-06-05 — Audit & Update fase.md
- 🔍 **Audit lengkap codebase** dilakukan untuk mencocokkan status fase.md dengan implementasi aktual
- ✅ **Fase 1 selesai** — Semua fitur auth sudah diimplementasi:
  - `auth_service.dart`: signIn, signOut, getCurrentUser, registerStore, createDriver, getCurrentStore, updateStore
  - `onboarding_page.dart`: logo + animasi + 2 tombol (Masuk / Daftar Toko)
  - `register_page.dart`: form lengkap + validasi + auto-login
  - `login_page.dart`: form + validasi + error handling + loading
  - `shell_pages.dart`: AdminShell (5 tab) + DriverShell (2 tab)
  - `settings_page.dart`: profil toko + manajemen driver (CRUD)
  - Models: `user_model.dart`, `store_model.dart`
- ✅ **Fase 2 selesai** — Semua fitur produk & stok sudah diimplementasi:
  - `product_repository.dart`: getProducts, addProduct, updateProduct, deactivateProduct, activateProduct, addStockIn, getStockInHistory
  - `products_page.dart`: list + search + badge stok rendah
  - `product_form_page.dart`: tambah/edit produk + validasi
  - `stock_in_page.dart`: input stok masuk + konfirmasi
  - Model: `product_model.dart`
- ✅ **Fase 3 selesai** — Semua fitur distribusi sudah diimplementasi:
  - `distribution_repository.dart`: CRUD distribusi + completeDistribution + getDrivers
  - `distributions_page.dart`: list distribusi admin + filter status
  - `create_distribution_page.dart`: form buat distribusi + validasi stok
  - `distribution_detail_page.dart`: detail + input hasil (driver)
  - `driver_distributions_page.dart`: list distribusi driver
  - Models: `distribution_model.dart`, `distribution_item_model.dart`
- ✅ **Fase 4 selesai** — Dashboard & KPI sudah diimplementasi:
  - `dashboard_repository.dart`: getDailyKPI, getActivePendingCount, getLowStockProducts, getWeeklyRevenue, getTopProducts, getMyPendingCount, getMyRecentCompleted
  - `admin_dashboard_page.dart`: 4 KPI cards + grafik omzet 7 hari + top 5 produk + stok menipis
  - `driver_dashboard_page.dart`: sambutan + distribusi pending + riwayat selesai
- ⏳ **Fase 5 belum dimulai** — Tab Laporan masih placeholder, belum ada file di features/reports/

---

## 🔖 Legend Status

| Simbol | Arti              |
| ------ | ----------------- |
| ⏳      | Pending (belum mulai) |
| 🔄      | In Progress       |
| ✅      | Done              |
| ❌      | Blocked / Skip    |
