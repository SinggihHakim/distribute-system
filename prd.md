# PRD - Kasir Pintar (Sistem Distribusi & Laporan)

## 1. Informasi Umum

### Nama Aplikasi

Kasir Pintar

### Deskripsi

Aplikasi manajemen distribusi dan penjualan berbasis mobile (Flutter) dengan backend Supabase. Admin mengelola stok gudang, mendistribusikan barang ke Driver, Driver melaporkan hasil penjualan, dan Admin dapat mengekspor laporan bisnis dalam format Excel.

### Modul Utama

1. Autentikasi & Profil Toko (Register + Login)
2. Manajemen Produk & Stok Gudang
3. Sistem Distribusi
4. Input Hasil Penjualan Driver
5. Dashboard & Analitik
6. **Export Laporan Excel**
7. Settings Toko

### Target Pengguna

* **Admin/Owner** — Mendaftarkan toko, mengelola seluruh operasional bisnis
* **Driver** — Menerima distribusi dan melaporkan hasil jual (akun dibuat oleh Admin)

---

# 2. Alur Bisnis Utama

```
[Admin] Input Stok Masuk Gudang
            ↓
[Admin] Buat Distribusi → Pilih Driver + Produk + Qty
            ↓
[Driver] Keluar ke Lapangan (status: PENDING)
            ↓
[Driver] Input Hasil: Qty Terjual + Qty Kembali
            ↓
[Sistem] Hitung: Omzet, Modal, Laba, Stok Akhir
            ↓
[Admin] Lihat Dashboard & Export Laporan Excel
```

---

# 3. Hak Akses

## Admin / Owner

Admin dapat:

* Mendaftarkan toko baru (Register)
* Edit profil toko (nama, alamat, telepon)
* Menambah / mengedit / menonaktifkan produk
* Input stok masuk gudang
* Membuat distribusi untuk Driver
* Melihat semua distribusi (aktif & selesai)
* Melihat dashboard & laporan
* Export semua jenis laporan Excel
* **Membuat akun Driver** (driver tidak bisa daftar sendiri)
* Menonaktifkan / menangguhkan akun Driver

## Driver

Driver dapat:

* Login dengan akun yang dibuat oleh Admin
* Melihat distribusi yang ditugaskan kepadanya
* Input hasil penjualan (terjual + retur)
* Melihat riwayat distribusi pribadi

Driver **tidak dapat**:

* Mendaftar sendiri (akun harus dibuat Admin)
* Mengakses menu laporan
* Mengakses menu export Excel
* Melihat data driver lain
* Mengakses data stok gudang
* Mengakses profil toko

---

# 4. Modul 1 — Autentikasi & Profil Toko

## 4.1 Halaman Awal (Onboarding)

Ketika pertama kali membuka app:
* Tampil dua pilihan: **Masuk** dan **Daftar Toko**
* Driver tidak punya opsi daftar (hanya login)

---

## 4.2 Register Toko Baru (Admin/Owner)

### Form Registrasi

| Field        | Tipe    | Wajib | Keterangan                          |
| ------------ | ------- | ----- | ----------------------------------- |
| Nama Lengkap | Text    | ✅    | Nama pemilik / admin                |
| Email        | Email   | ✅    | Untuk login                         |
| Password     | Password| ✅    | Min. 8 karakter                     |
| Nama Toko    | Text    | ✅    | Tampil di header laporan Excel      |
| Alamat Toko  | Text    | ❌    | Opsional, bisa diisi nanti          |
| Telepon Toko | Phone   | ❌    | Opsional, bisa diisi nanti          |

### Proses Setelah Register

1. Supabase Auth membuat akun
2. Insert ke tabel `stores` (data toko)
3. Insert ke tabel `users` (role: admin, store_id)
4. Auto-login → redirect ke Dashboard Admin

---

## 4.3 Login

* Login dengan Email & Password via Supabase Auth
* Role-based redirect:
  * Admin → Dashboard Admin
  * Driver → Dashboard Driver
* Logout dengan konfirmasi dialog
* Session persistent (auto-login saat buka app)

### Validasi Login

* Email dan password wajib diisi
* Tampilkan pesan error jika gagal
* Role diambil dari tabel `users` setelah login

---

## 4.4 Admin Tambah Driver

Admin dapat membuat akun driver dari dalam app:

| Field        | Tipe    | Wajib |
| ------------ | ------- | ----- |
| Nama Driver  | Text    | ✅    |
| Email        | Email   | ✅    |
| Password     | Password| ✅    |
| Telepon      | Phone   | ❌    |

* Driver yang dibuat otomatis terhubung ke `store_id` yang sama dengan Admin
* Admin dapat menonaktifkan driver kapanpun
* Driver **tidak** mendapat opsi register mandiri

---

## 4.5 Profil Toko (Settings)

Admin dapat edit informasi toko kapanpun:
* Nama Toko
* Alamat Toko
* Telepon Toko
* Kota

Data ini digunakan sebagai header di setiap file Excel export:
```
══════════════════════════════════
  KASIR PINTAR — LAPORAN BISNIS
  Toko : Toko Berkah Jaya
  Alamat : Jl. Merdeka No. 5, Surabaya
  Periode : Juni 2026
══════════════════════════════════
```

---

# 5. Modul 2 — Manajemen Produk & Stok Gudang

### 5.1 Manajemen Produk

Admin dapat:

* Tambah produk baru (nama, satuan, harga modal, harga jual)
* Edit harga modal & harga jual (tidak mempengaruhi histori transaksi)
* Nonaktifkan produk (soft delete)
* Lihat stok gudang saat ini per produk

### 5.2 Input Stok Masuk Gudang

Admin dapat:

* Pilih produk
* Input qty masuk
* Input harga modal saat itu (snapshot otomatis tersimpan)
* Tambah keterangan (opsional)
* Sistem otomatis update `stok_gudang` di tabel produk

### Validasi

* Qty harus > 0
* Harga modal tidak boleh kosong
* Produk harus aktif

---

# 6. Modul 3 — Sistem Distribusi

### 6.1 Buat Distribusi

Admin dapat:

* Pilih Driver
* Pilih tanggal distribusi
* Tambah item: produk + qty keluar
* Sistem otomatis **snapshot harga modal & jual** saat distribusi dibuat
* Sistem otomatis **kurangi stok gudang**
* Status awal: `PENDING`

### Validasi

* Qty keluar tidak boleh melebihi stok gudang
* Minimal 1 item distribusi
* Driver harus aktif

### 6.2 Input Hasil Driver (Retur)

Driver / Admin dapat:

* Pilih distribusi aktif (status: PENDING)
* Per item: input `qty_terjual` dan `qty_kembali`
* Validasi: `qty_terjual + qty_kembali = qty_keluar`
* Sistem otomatis hitung:
  * `subtotal_modal = qty_terjual × harga_modal_snapshot`
  * `subtotal_jual = qty_terjual × harga_jual_snapshot`
  * `subtotal_laba = subtotal_jual - subtotal_modal`
* Stok gudang bertambah sejumlah `qty_kembali`
* Status distribusi berubah menjadi `RETURNED`

---

# 7. Modul 4 — Dashboard Admin

### KPI yang Ditampilkan

* Total Omzet Hari Ini
* Total Laba Hari Ini
* Distribusi Aktif (status PENDING)
* Stok Gudang Menipis (stok < threshold)
* Grafik Omzet 7 Hari Terakhir
* Top 5 Produk Terlaris

---

# 8. Modul 5 — Export Laporan Excel

## 8.1 Jenis Laporan

### Laporan Harian

**Filter:** Pilih tanggal

| Field          | Keterangan                     |
| -------------- | ------------------------------ |
| Tanggal        | Tanggal transaksi              |
| Nama Produk    | Nama produk                    |
| Barang Keluar  | Qty distribusi keluar          |
| Barang Kembali | Qty retur dari driver          |
| Barang Terjual | Qty yang berhasil terjual      |
| Harga Modal    | Snapshot harga modal           |
| Harga Jual     | Snapshot harga jual            |
| Omzet          | qty_terjual × harga_jual       |
| Modal Terjual  | qty_terjual × harga_modal      |
| Laba           | Omzet - Modal Terjual          |

**Ringkasan:** Total Omzet, Modal, Laba Harian

---

### Laporan Mingguan

**Filter:** Pilih minggu (week picker)

| Field   |
| ------- |
| Tanggal |
| Omzet   |
| Modal   |
| Laba    |

**Ringkasan:** Total Omzet, Modal, Laba, Produk Terlaris Mingguan

---

### Laporan Bulanan

**Filter:** Pilih bulan & tahun

| Field   |
| ------- |
| Tanggal |
| Omzet   |
| Modal   |
| Laba    |

**Ringkasan:** Total Omzet, Modal, Laba, Produk Terlaris, Driver Terbaik Bulanan

---

### Laporan Tahunan

**Filter:** Pilih tahun

| Field |
| ----- |
| Bulan |
| Omzet |
| Modal |
| Laba  |

**Ringkasan:** Total Omzet, Modal, Laba Tahunan

---

### Laporan Distribusi Driver

**Filter:** Pilih driver (opsional), rentang tanggal

| Field              |
| ------------------ |
| Nama Driver        |
| Tanggal Distribusi |
| Produk             |
| Barang Keluar      |
| Barang Kembali     |
| Barang Terjual     |
| Total Penjualan    |

**Ringkasan:** Total Distribusi, Total Penjualan per Driver

---

### Laporan Pergerakan Stok

**Filter:** Rentang tanggal, produk (opsional)

| Field      |
| ---------- |
| Tanggal    |
| Produk     |
| Stok Awal  |
| Stok Masuk |
| Distribusi |
| Retur      |
| Stok Akhir |

**Ringkasan:** Total Masuk, Total Keluar, Total Retur

---

### Laporan Produk Terlaris

**Filter:** Rentang tanggal

| Field         |
| ------------- |
| Nama Produk   |
| Total Terjual |
| Omzet         |
| Laba          |

**Ringkasan:** Top 10 Terlaris, Top 10 Paling Menguntungkan, Produk Slow Moving

---

### Laporan Analisis Driver

**Filter:** Rentang tanggal

| Field                |
| -------------------- |
| Nama Driver          |
| Total Barang Keluar  |
| Total Barang Kembali |
| Total Barang Terjual |
| Omzet                |
| Laba                 |

**Ranking:** Driver Terbaik, Driver Teraktif, Penjualan Tertinggi

---

### Laporan Laba Rugi

**Filter:** Pilih periode (bulan/tahun)

| Field         | Keterangan                       |
| ------------- | -------------------------------- |
| Periode       | Bulan/Tahun                      |
| Omzet         | Total penjualan                  |
| Modal Terjual | Total modal barang terjual       |
| Laba Kotor    | Omzet - Modal Terjual            |
| Retur         | Nilai barang kembali             |
| Laba Bersih   | Laba Kotor - kerugian retur      |

**Rumus:**
```
Laba Kotor  = Omzet - Modal Terjual
Laba Bersih = Laba Kotor - Kerugian Retur
Margin      = (Laba Bersih / Omzet) × 100%
```

---

## 8.2 Export Semua Laporan (1 File)

File Excel dengan 8 sheet:

| Sheet | Konten               |
| ----- | -------------------- |
| 1     | Dashboard KPI        |
| 2     | Ringkasan Penjualan  |
| 3     | Detail Penjualan     |
| 4     | Distribusi Driver    |
| 5     | Pergerakan Stok      |
| 6     | Produk Terlaris      |
| 7     | Analisis Driver      |
| 8     | Laba Rugi            |

---

## 8.3 Dashboard Sheet (Sheet 1)

Contoh tampilan sheet pertama:

```
Laporan Kasir Pintar
Periode: Juni 2026
Generated: 03-06-2026 14:00

Total Omzet     : Rp 15.000.000
Total Modal     : Rp  9.000.000
Total Laba      : Rp  6.000.000
Barang Keluar   : 1.500
Barang Kembali  :   120
Barang Terjual  : 1.380
Driver Aktif    : 8
Produk Aktif    : 150
```

---

## 8.4 Alur Export

```
Admin Login
    ↓
Menu Laporan
    ↓
Pilih Jenis Laporan
    ↓
Pilih Filter (periode / driver / produk)
    ↓
Klik "Export Excel"
    ↓
Sistem query Supabase
    ↓
Generate file .xlsx (package: excel)
    ↓
Simpan ke perangkat (path_provider)
    ↓
Tampilkan pilihan:
  ├── Buka File (open_filex)
  ├── Share WhatsApp
  ├── Kirim Email
  └── Simpan ke Google Drive
```

---

## 8.5 Nama File Otomatis

| Jenis           | Nama File                         |
| --------------- | --------------------------------- |
| Harian          | `Laporan_Harian_2026-06-03.xlsx`  |
| Mingguan        | `Laporan_Mingguan_2026_W23.xlsx`  |
| Bulanan         | `Laporan_Bulanan_Juni_2026.xlsx`  |
| Tahunan         | `Laporan_Tahunan_2026.xlsx`       |
| Semua Laporan   | `Laporan_Lengkap_Juni_2026.xlsx`  |

---

# 9. Kebutuhan Flutter (Package)

```yaml
dependencies:
  supabase_flutter: ^2.5.0     # Backend & Auth
  excel: ^4.0.6                 # Generate file Excel
  share_plus: ^11.0.0           # Share file
  path_provider: ^2.1.5         # Simpan ke perangkat
  permission_handler: ^12.0.1   # Izin storage Android
  open_filex: ^4.5.0            # Buka file langsung
  fl_chart: ^0.69.0             # Grafik dashboard
  riverpod: ^2.5.1              # State management
  intl: ^0.19.0                 # Format tanggal & angka
```

---

# 10. Non Functional Requirements

### Performa

* Maksimal 10.000 baris per export
* Waktu generate < 10 detik
* Query Supabase menggunakan index yang tepat

### Kompatibilitas

* Microsoft Excel
* Google Sheets
* LibreOffice Calc
* Android (target utama)

### Keamanan

* Hanya Admin dapat export laporan
* Driver tidak dapat mengakses endpoint laporan
* RLS (Row Level Security) aktif di Supabase
* Data difilter berdasarkan role pengguna

### Reliabilitas

* File tidak boleh corrupt
* Notifikasi gagal jika proses export bermasalah
* Retry otomatis jika koneksi terputus saat query

---

# 11. Acceptance Criteria

### Modul Distribusi

- [ ] Admin dapat input stok masuk gudang
- [ ] Admin dapat membuat distribusi ke driver
- [ ] Stok gudang berkurang otomatis saat distribusi dibuat
- [ ] Driver dapat input hasil penjualan (terjual + retur)
- [ ] Stok gudang bertambah otomatis saat retur masuk
- [ ] Harga snapshot tersimpan saat distribusi dibuat

### Modul Export Excel

- [ ] Admin dapat memilih jenis laporan
- [ ] Admin dapat memilih rentang tanggal
- [ ] Sistem menghasilkan file .xlsx yang valid
- [ ] File dapat dibuka di Excel / Google Sheets
- [ ] File dapat dibagikan via WhatsApp
- [ ] File dapat dikirim via Email
- [ ] File dapat disimpan ke Google Drive
- [ ] Driver tidak dapat mengakses fitur export
- [ ] Data laporan sesuai dengan database
- [ ] Perhitungan omzet, modal, dan laba akurat
- [ ] Export selesai dalam < 10 detik

---

# 12. Fase Pengembangan

| Fase | Fitur                                      | Status  |
| ---- | ------------------------------------------ | ------- |
| 1    | Setup Flutter + Supabase + Auth            | Pending |
| 2    | Manajemen Produk + Stok Gudang             | Pending |
| 3    | Sistem Distribusi (buat + retur)           | Pending |
| 4    | Dashboard Admin + KPI                      | Pending |
| 5    | Export Laporan Excel                       | Pending |
