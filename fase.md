# Sprint Plan — Kasir Pintar

> Project: `pakjoni_project` (Flutter + Supabase)
> Start: 2026-06-03
> Status saat ini: Flutter default project, belum ada kode custom

---

## 📊 Progress Overview

| Fase | Nama                         | Status        | Estimasi |
| ---- | ---------------------------- | ------------- | -------- |
| 0    | Setup & Fondasi              | ✅ Done       | 1 hari   |
| 1    | Auth & Navigation            | ✅ Done       | 2 hari   |
| 2    | Manajemen Produk & Stok      | ✅ Done       | 3 hari   |
| 3    | Sistem Distribusi            | ✅ Done       | 4 hari   |
| 4    | Dashboard & KPI              | ⏳ Pending    | 2 hari   |
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

- [x] Jalankan `flutter pub get`

---

### 0.2 Setup Supabase

- [ ] Buat project baru di [supabase.com](https://supabase.com)
- [ ] Jalankan SQL `v1.0.0` dari `database.md` di SQL Editor Supabase
- [ ] Salin `SUPABASE_URL` dan `SUPABASE_ANON_KEY`
- [ ] Buat file `.env` atau simpan di `lib/core/config/supabase_config.dart`

```dart
// lib/core/config/supabase_config.dart
class SupabaseConfig {
  static const String url = 'https://xxx.supabase.co';
  static const String anonKey = 'your-anon-key';
}
```

- [ ] Init Supabase di `main.dart`

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

- [ ] Buat semua folder di atas

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

- [ ] Buat `app_theme.dart`
- [ ] Buat `app_colors.dart`

---

## FASE 1 — Auth & Navigation

> Status: 🔄 In Progress — diperluas dengan fitur Register Toko
> Depends on: Fase 0 ✅

### Tujuan
Login & Register Admin (buat toko), redirect berdasarkan role, session persistent, Admin tambah Driver.

---

### 1.1 Model

- [x] Buat `UserModel` dari tabel `users`
- [ ] Buat `StoreModel` dari tabel `stores`

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

- [x] Buat `AuthService` dengan method:
  - [x] `signIn(email, password)` → Supabase Auth
  - [x] `signOut()`
  - [x] `getCurrentUser()` → fetch dari tabel `users` by `auth_id`
  - [ ] `signUp(email, password)` → Supabase Auth signup
  - [ ] `registerStore(authId, name, email, namaToko, ...)` → panggil DB function `register_store()`
  - [ ] `createDriver(name, email, password, phone?)` → panggil DB function `admin_create_driver()`

---

### 1.3 Halaman Onboarding

- [ ] Tampil logo + nama app
- [ ] Dua pilihan: **Masuk** dan **Daftar Toko**
- [ ] Animasi masuk yang smooth

---

### 1.4 Halaman Register Toko (Admin/Owner)

- [ ] Form: Nama Lengkap, Email, Password, Nama Toko
- [ ] Field opsional: Alamat Toko, Telepon Toko
- [ ] Validasi semua field wajib
- [ ] Password min 8 karakter + konfirmasi password
- [ ] Proses: `signUp()` → `register_store()` (DB function) → auto-login → Dashboard Admin
- [ ] Loading state + error handling

---

### 1.5 Halaman Login

- [x] Desain halaman login (logo, email, password, tombol login)
- [x] Validasi form (email format, password tidak kosong)
- [x] Tampilkan error message jika gagal
- [x] Loading state saat proses login
- [x] Redirect ke role yang sesuai setelah berhasil

---

### 1.6 Navigation

- [x] Route `/splash` → cek session → redirect
- [x] Route `/login` → LoginPage
- [x] Route `/admin` → AdminShell (4 tab)
- [x] Route `/driver` → DriverShell (2 tab)
- [ ] Tambah route `/register` → RegisterPage
- [ ] Admin tidak bisa akses route Driver dan sebaliknya

---

### 1.7 Bottom Navigation

- [x] `AdminShell` dengan 4 tab: Dashboard, Produk, Distribusi, Laporan
- [x] `DriverShell` dengan 2 tab: Dashboard, Distribusi

---

### Checklist Fase 1

- [x] Login berhasil dengan email & password
- [x] Admin redirect ke halaman Admin
- [x] Driver redirect ke halaman Driver
- [x] Session persistent (tidak perlu login ulang setelah close app)
- [x] Logout berfungsi
- [x] Driver tidak bisa akses halaman Admin
- [ ] Halaman onboarding (Masuk vs Daftar Toko)
- [ ] Register toko baru berhasil (form + DB function)
- [ ] Auto-login setelah register
- [ ] StoreModel dibuat

---

## FASE 2 — Manajemen Produk & Stok Gudang

> Status: ⏳ Pending
> Depends on: Fase 1 ✅

### Tujuan
Admin dapat mengelola produk dan input stok masuk gudang.

---

### 2.1 Model

- [ ] Buat `ProductModel` dari tabel `products`

---

### 2.2 Product Repository

- [ ] `getProducts()` → semua produk aktif + stok gudang
- [ ] `addProduct(data)` → tambah produk baru
- [ ] `updateProduct(id, data)` → edit produk
- [ ] `deactivateProduct(id)` → soft delete
- [ ] `addStockIn(data)` → input stok masuk

---

### 2.3 Halaman List Produk

- [ ] List semua produk dengan:
  - Nama, satuan, harga modal, harga jual, stok gudang
  - Badge merah jika stok < `stok_minimum`
- [ ] Search/filter produk
- [ ] Tombol tambah produk (FAB)
- [ ] Swipe to edit / tombol edit

---

### 2.4 Form Tambah/Edit Produk

- [ ] Input: nama, satuan, harga modal, harga jual, stok minimum
- [ ] Validasi semua field wajib diisi
- [ ] Harga harus > 0
- [ ] Harga jual harus >= harga modal (warning jika tidak)

---

### 2.5 Form Input Stok Masuk

- [ ] Pilih produk (dropdown / search)
- [ ] Input qty masuk
- [ ] Input harga modal saat ini (pre-filled dari harga produk)
- [ ] Keterangan (opsional)
- [ ] Konfirmasi sebelum submit
- [ ] Stok gudang terupdate otomatis

---

### Checklist Fase 2

- [ ] Admin bisa melihat list produk + stok gudang
- [ ] Admin bisa tambah produk baru
- [ ] Admin bisa edit harga produk
- [ ] Admin bisa nonaktifkan produk
- [ ] Admin bisa input stok masuk
- [ ] Stok gudang bertambah setelah stok masuk diinput
- [ ] Tampil warning jika stok menipis

---

## FASE 3 — Sistem Distribusi

> Status: ✅ Done — 2026-06-03
> Depends on: Fase 2 ✅

### Tujuan
Admin buat distribusi ke Driver, Driver input hasil penjualan, stok otomatis update.

---

### 3.1 Model

- [ ] Buat `DistributionModel` dari tabel `distributions`
- [ ] Buat `DistributionItemModel` dari tabel `distribution_items`

---

### 3.2 Distribution Repository

- [ ] `getDistributions()` → semua distribusi (Admin)
- [ ] `getMyDistributions()` → distribusi driver yg login
- [ ] `createDistribution(data)` → buat distribusi baru
- [ ] `addDistributionItems(items)` → tambah item distribusi
- [ ] `submitReturn(distributionId, items)` → input hasil retur Driver

---

### 3.3 Halaman List Distribusi (Admin)

- [ ] List semua distribusi dengan filter: Pending / Returned
- [ ] Per item: nama driver, tanggal, status, total produk
- [ ] Tombol buat distribusi baru (FAB)
- [ ] Tap untuk lihat detail distribusi

---

### 3.4 Form Buat Distribusi (Admin)

- [ ] Pilih driver (dropdown)
- [ ] Pilih tanggal distribusi
- [ ] Tambah item: pilih produk + input qty keluar
- [ ] Validasi: qty tidak melebihi stok gudang
- [ ] Preview ringkasan sebelum submit
- [ ] Konfirmasi submit → stok berkurang otomatis

---

### 3.5 Halaman Dashboard Driver

- [ ] Tampil distribusi aktif (status: PENDING)
- [ ] Tombol "Input Hasil" pada distribusi aktif
- [ ] Riwayat distribusi selesai

---

### 3.6 Form Input Hasil Driver

- [ ] List produk yang dibawa
- [ ] Per produk: input `qty_terjual` dan `qty_kembali`
- [ ] Validasi: qty_terjual + qty_kembali = qty_keluar
- [ ] Preview kalkulasi otomatis (omzet, laba)
- [ ] Submit → status jadi RETURNED, stok kembali bertambah

---

### Checklist Fase 3

- [x] Admin bisa membuat distribusi ke driver
- [x] Stok gudang berkurang saat distribusi dibuat
- [x] Driver melihat distribusi aktifnya
- [x] Driver bisa input qty terjual + retur
- [x] Validasi: terjual + kembali = keluar
- [x] Stok gudang bertambah sesuai qty kembali
- [x] Status distribusi berubah menjadi RETURNED

---

## FASE 4 — Dashboard Admin & KPI

> Status: ⏳ Pending
> Depends on: Fase 3 ✅

### Tujuan
Admin dapat melihat ringkasan bisnis hari ini dan tren penjualan.

---

### 4.1 KPI Cards

- [ ] Total Omzet Hari Ini
- [ ] Total Laba Hari Ini
- [ ] Distribusi Aktif (PENDING)
- [ ] Jumlah Produk Stok Menipis

---

### 4.2 Grafik Omzet 7 Hari (fl_chart)

- [ ] Bar chart atau line chart
- [ ] Sumbu X: tanggal, Sumbu Y: omzet (Rp)
- [ ] Tap bar untuk lihat detail hari itu

---

### 4.3 Top 5 Produk Terlaris

- [ ] List produk berdasarkan qty_terjual bulan ini
- [ ] Tampilkan progress bar relatif terhadap produk #1

---

### 4.4 Peringatan Stok Menipis

- [ ] List produk dengan stok < stok_minimum
- [ ] Tombol shortcut ke form input stok masuk

---

### Checklist Fase 4

- [ ] KPI hari ini tampil akurat
- [ ] Grafik omzet 7 hari berfungsi
- [ ] Top 5 produk terlaris bulan ini tampil
- [ ] Peringatan stok menipis tampil

---

## FASE 5 — Export Laporan Excel

> Status: ⏳ Pending
> Depends on: Fase 4 ✅

### Tujuan
Admin dapat mengunduh berbagai jenis laporan dalam format `.xlsx`.

---

### 5.1 Report Service

- [ ] Query data untuk setiap jenis laporan dari Supabase
- [ ] `getHarianReport(date)`
- [ ] `getMingguanReport(weekStart, weekEnd)`
- [ ] `getBulananReport(month, year)`
- [ ] `getTahunanReport(year)`
- [ ] `getDistribusiDriverReport(range, driverId?)`
- [ ] `getPergerakanStokReport(range)`
- [ ] `getProdukTerlarisReport(range)`
- [ ] `getAnalisisDriverReport(range)`
- [ ] `getLabaRugiReport(range)`

---

### 5.2 Excel Generator Service

- [ ] Fungsi generate `.xlsx` per jenis laporan
- [ ] Sheet 1 selalu berisi Dashboard KPI
- [ ] Styling: header bold, currency format, border
- [ ] Generate nama file otomatis sesuai jenis laporan

---

### 5.3 File Manager

- [ ] Simpan file ke storage device (`path_provider`)
- [ ] Minta permission storage Android (`permission_handler`)
- [ ] Buka file langsung (`open_filex`)
- [ ] Share file (`share_plus`): WhatsApp, Email, Drive

---

### 5.4 Halaman Laporan (Admin)

- [ ] Pilih jenis laporan (dropdown / tab)
- [ ] Pilih filter (tanggal/minggu/bulan/tahun)
- [ ] Preview ringkasan data di layar sebelum export
- [ ] Tombol "Export Excel"
- [ ] Loading indicator saat generate
- [ ] Bottom sheet: Buka File / Share / Simpan ke Drive

---

### Checklist Fase 5

- [ ] Semua 9 jenis laporan berhasil generate `.xlsx`
- [ ] File dapat dibuka di Google Sheets / Excel
- [ ] File dapat dibagikan via WhatsApp
- [ ] File dapat dikirim via Email
- [ ] Nama file otomatis sesuai format di PRD
- [ ] Driver tidak bisa akses halaman laporan
- [ ] Waktu generate < 10 detik untuk 10.000 baris
- [ ] Kalkulasi omzet, modal, laba akurat

---

## 📝 Catatan Sprint

> Gunakan bagian ini untuk mencatat keputusan teknis, bug, atau perubahan scope.

### 2026-06-03
- Project dibuat, PRD & database schema selesai
- ✅ Fase 0 selesai: pubspec.yaml updated, folder structure dibuat, design system selesai, main.dart di-setup dengan Supabase init
- Package terinstall: supabase_flutter, flutter_riverpod, go_router, google_fonts, fl_chart, intl, excel, share_plus, path_provider, permission_handler, open_filex
- ⚠️ TODO: Isi `SupabaseConfig.url` dan `SupabaseConfig.anonKey` di `lib/core/config/supabase_config.dart`
- 🔄 Next: Fase 1 — Auth & Navigation

---

## 🔖 Legend Status

| Simbol | Arti              |
| ------ | ----------------- |
| ⏳      | Pending (belum mulai) |
| 🔄      | In Progress       |
| ✅      | Done              |
| ❌      | Blocked / Skip    |
