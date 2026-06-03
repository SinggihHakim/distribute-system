# Kasir Pintar

Aplikasi manajemen distribusi dan laporan penjualan untuk toko.\
Dibangun dengan **Flutter + Supabase**.

> **Untuk AI Assistant:** Baca `CONTEXT.md` terlebih dahulu sebelum mengerjakan apapun di project ini.

---

## Tech Stack

- **Frontend:** Flutter (Dart)
- **Backend & Auth:** Supabase (PostgreSQL + RLS)
- **Platform:** Android (utama), Web

## Cara Menjalankan

```bash
# Wajib pakai flag ini — kredensial Supabase ada di .env
flutter run --dart-define-from-file=.env

# Build APK
flutter build apk --dart-define-from-file=.env
```

> Di **VS Code**: cukup tekan **F5** (sudah dikonfigurasi otomatis).

## Dokumen Project

| File | Isi |
|---|---|
| `CONTEXT.md` | **Panduan untuk AI** — baca ini dulu |
| `prd.md` | Product Requirements Document |
| `database.md` | Schema database & SQL migrations |
| `fase.md` | Sprint plan & progress per fase |
| `bug.md` | Catatan bug |
