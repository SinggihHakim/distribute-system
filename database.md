# Database PRD - Kasir Pintar (Supabase / PostgreSQL)

> Dokumen ini berisi semua SQL migration untuk project Kasir Pintar.
> Setiap update schema ditambahkan di bawah sebagai versi baru.
> Jalankan secara berurutan di Supabase SQL Editor.

---

## ✅ VERSI 1.0.0 — Initial Schema

> Tanggal: 2026-06-03
> Deskripsi: Setup awal seluruh tabel utama aplikasi Kasir Pintar

```sql
-- ============================================================
-- KASIR PINTAR - Initial Database Schema v1.0.0
-- Supabase / PostgreSQL
-- Tanggal: 2026-06-03
-- ============================================================

-- ============================================================
-- 1. EXTENSION
-- ============================================================
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================================
-- 2. ENUM TYPES
-- ============================================================

-- Role pengguna
CREATE TYPE user_role AS ENUM ('admin', 'driver');

-- Status distribusi
CREATE TYPE distribution_status AS ENUM ('pending', 'returned');

-- ============================================================
-- 3. TABEL USERS
-- Menyimpan data admin dan driver
-- ============================================================
CREATE TABLE users (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  auth_id     UUID UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE,
  name        VARCHAR(100) NOT NULL,
  email       VARCHAR(150) UNIQUE NOT NULL,
  phone       VARCHAR(20),
  role        user_role NOT NULL DEFAULT 'driver',
  is_active   BOOLEAN NOT NULL DEFAULT TRUE,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE users IS 'Data pengguna aplikasi (Admin & Driver)';

-- ============================================================
-- 4. TABEL PRODUCTS
-- Menyimpan data produk dan stok gudang saat ini
-- ============================================================
CREATE TABLE products (
  id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name          VARCHAR(200) NOT NULL,
  satuan        VARCHAR(50) NOT NULL DEFAULT 'pcs',
  harga_modal   DECIMAL(15, 2) NOT NULL DEFAULT 0,
  harga_jual    DECIMAL(15, 2) NOT NULL DEFAULT 0,
  stok_gudang   INTEGER NOT NULL DEFAULT 0,
  stok_minimum  INTEGER NOT NULL DEFAULT 5,   -- threshold peringatan stok menipis
  is_active     BOOLEAN NOT NULL DEFAULT TRUE,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE products IS 'Data produk beserta stok gudang saat ini';
COMMENT ON COLUMN products.harga_modal IS 'Harga modal SAAT INI (bukan snapshot)';
COMMENT ON COLUMN products.harga_jual IS 'Harga jual SAAT INI (bukan snapshot)';
COMMENT ON COLUMN products.stok_gudang IS 'Stok tersedia di gudang saat ini';

-- ============================================================
-- 5. TABEL STOCK_IN
-- Riwayat stok masuk gudang (admin input)
-- ============================================================
CREATE TABLE stock_in (
  id                    UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  product_id            UUID NOT NULL REFERENCES products(id),
  admin_id              UUID NOT NULL REFERENCES users(id),
  qty                   INTEGER NOT NULL CHECK (qty > 0),
  harga_modal_snapshot  DECIMAL(15, 2) NOT NULL,  -- harga modal saat input
  subtotal_modal        DECIMAL(15, 2) GENERATED ALWAYS AS (qty * harga_modal_snapshot) STORED,
  keterangan            TEXT,
  tanggal               DATE NOT NULL DEFAULT CURRENT_DATE,
  created_at            TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE stock_in IS 'Riwayat stok masuk ke gudang';
COMMENT ON COLUMN stock_in.harga_modal_snapshot IS 'Snapshot harga modal saat stok diinput';

-- ============================================================
-- 6. TABEL DISTRIBUTIONS
-- Header distribusi (Admin → Driver)
-- ============================================================
CREATE TABLE distributions (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  driver_id       UUID NOT NULL REFERENCES users(id),
  admin_id        UUID NOT NULL REFERENCES users(id),
  tanggal_keluar  DATE NOT NULL DEFAULT CURRENT_DATE,
  tanggal_kembali DATE,
  status          distribution_status NOT NULL DEFAULT 'pending',
  catatan         TEXT,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE distributions IS 'Header distribusi barang ke driver';

-- ============================================================
-- 7. TABEL DISTRIBUTION_ITEMS
-- Detail produk per distribusi + snapshot harga
-- ============================================================
CREATE TABLE distribution_items (
  id                    UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  distribution_id       UUID NOT NULL REFERENCES distributions(id) ON DELETE CASCADE,
  product_id            UUID NOT NULL REFERENCES products(id),
  qty_keluar            INTEGER NOT NULL CHECK (qty_keluar > 0),
  qty_terjual           INTEGER CHECK (qty_terjual >= 0),
  qty_kembali           INTEGER CHECK (qty_kembali >= 0),
  harga_modal_snapshot  DECIMAL(15, 2) NOT NULL,  -- ⚠️ WAJIB: snapshot saat distribusi
  harga_jual_snapshot   DECIMAL(15, 2) NOT NULL,  -- ⚠️ WAJIB: snapshot saat distribusi
  subtotal_modal        DECIMAL(15, 2),            -- qty_terjual × harga_modal_snapshot
  subtotal_jual         DECIMAL(15, 2),            -- qty_terjual × harga_jual_snapshot
  subtotal_laba         DECIMAL(15, 2),            -- subtotal_jual - subtotal_modal
  created_at            TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at            TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE distribution_items IS 'Detail item per distribusi dengan snapshot harga';
COMMENT ON COLUMN distribution_items.harga_modal_snapshot IS 'Snapshot harga modal saat distribusi dibuat — tidak berubah meski harga produk diupdate';
COMMENT ON COLUMN distribution_items.harga_jual_snapshot IS 'Snapshot harga jual saat distribusi dibuat — tidak berubah meski harga produk diupdate';

-- ============================================================
-- 8. INDEXES
-- Optimasi query untuk laporan
-- ============================================================

-- Users
CREATE INDEX idx_users_role ON users(role);
CREATE INDEX idx_users_auth_id ON users(auth_id);

-- Products
CREATE INDEX idx_products_is_active ON products(is_active);

-- Stock In
CREATE INDEX idx_stock_in_product_id ON stock_in(product_id);
CREATE INDEX idx_stock_in_tanggal ON stock_in(tanggal);
CREATE INDEX idx_stock_in_admin_id ON stock_in(admin_id);

-- Distributions
CREATE INDEX idx_distributions_driver_id ON distributions(driver_id);
CREATE INDEX idx_distributions_status ON distributions(status);
CREATE INDEX idx_distributions_tanggal_keluar ON distributions(tanggal_keluar);

-- Distribution Items
CREATE INDEX idx_distribution_items_distribution_id ON distribution_items(distribution_id);
CREATE INDEX idx_distribution_items_product_id ON distribution_items(product_id);

-- ============================================================
-- 9. FUNCTIONS & TRIGGERS
-- ============================================================

-- Trigger: update kolom updated_at otomatis
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_users_updated_at
  BEFORE UPDATE ON users
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trg_products_updated_at
  BEFORE UPDATE ON products
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trg_distributions_updated_at
  BEFORE UPDATE ON distributions
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trg_distribution_items_updated_at
  BEFORE UPDATE ON distribution_items
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================================
-- 10. FUNCTION: Kurangi stok gudang saat distribusi dibuat
-- ============================================================
CREATE OR REPLACE FUNCTION reduce_stock_on_distribution()
RETURNS TRIGGER AS $$
BEGIN
  -- Validasi: stok cukup?
  IF (SELECT stok_gudang FROM products WHERE id = NEW.product_id) < NEW.qty_keluar THEN
    RAISE EXCEPTION 'Stok gudang tidak cukup untuk produk: %', NEW.product_id;
  END IF;

  -- Kurangi stok gudang
  UPDATE products
  SET stok_gudang = stok_gudang - NEW.qty_keluar
  WHERE id = NEW.product_id;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_reduce_stock_on_distribution
  AFTER INSERT ON distribution_items
  FOR EACH ROW EXECUTE FUNCTION reduce_stock_on_distribution();

-- ============================================================
-- 11. FUNCTION: Tambah stok gudang saat retur (barang kembali)
-- ============================================================
CREATE OR REPLACE FUNCTION restore_stock_on_return()
RETURNS TRIGGER AS $$
BEGIN
  -- Hanya jalankan saat qty_kembali diisi (dari NULL menjadi ada nilai)
  IF OLD.qty_kembali IS NULL AND NEW.qty_kembali IS NOT NULL THEN
    -- Validasi: qty_terjual + qty_kembali = qty_keluar
    IF NEW.qty_terjual + NEW.qty_kembali <> NEW.qty_keluar THEN
      RAISE EXCEPTION 'qty_terjual + qty_kembali harus sama dengan qty_keluar';
    END IF;

    -- Hitung subtotal
    NEW.subtotal_jual  := NEW.qty_terjual * NEW.harga_jual_snapshot;
    NEW.subtotal_modal := NEW.qty_terjual * NEW.harga_modal_snapshot;
    NEW.subtotal_laba  := NEW.subtotal_jual - NEW.subtotal_modal;

    -- Kembalikan stok gudang
    UPDATE products
    SET stok_gudang = stok_gudang + NEW.qty_kembali
    WHERE id = NEW.product_id;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_restore_stock_on_return
  BEFORE UPDATE ON distribution_items
  FOR EACH ROW EXECUTE FUNCTION restore_stock_on_return();

-- ============================================================
-- 12. ROW LEVEL SECURITY (RLS)
-- ============================================================

ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE products ENABLE ROW LEVEL SECURITY;
ALTER TABLE stock_in ENABLE ROW LEVEL SECURITY;
ALTER TABLE distributions ENABLE ROW LEVEL SECURITY;
ALTER TABLE distribution_items ENABLE ROW LEVEL SECURITY;

-- Helper function: ambil role dari tabel users
CREATE OR REPLACE FUNCTION get_my_role()
RETURNS user_role AS $$
  SELECT role FROM users WHERE auth_id = auth.uid();
$$ LANGUAGE sql SECURITY DEFINER;

-- Helper function: ambil id dari tabel users
CREATE OR REPLACE FUNCTION get_my_user_id()
RETURNS UUID AS $$
  SELECT id FROM users WHERE auth_id = auth.uid();
$$ LANGUAGE sql SECURITY DEFINER;

-- RLS: users
CREATE POLICY "Admin bisa lihat semua user"
  ON users FOR SELECT
  USING (get_my_role() = 'admin');

CREATE POLICY "Driver hanya bisa lihat dirinya sendiri"
  ON users FOR SELECT
  USING (auth_id = auth.uid());

CREATE POLICY "Admin bisa kelola semua user"
  ON users FOR ALL
  USING (get_my_role() = 'admin');

-- RLS: products
CREATE POLICY "Admin bisa kelola semua produk"
  ON products FOR ALL
  USING (get_my_role() = 'admin');

CREATE POLICY "Driver bisa lihat produk aktif"
  ON products FOR SELECT
  USING (get_my_role() = 'driver' AND is_active = TRUE);

-- RLS: stock_in
CREATE POLICY "Hanya admin yang bisa akses stock_in"
  ON stock_in FOR ALL
  USING (get_my_role() = 'admin');

-- RLS: distributions
CREATE POLICY "Admin bisa lihat & kelola semua distribusi"
  ON distributions FOR ALL
  USING (get_my_role() = 'admin');

CREATE POLICY "Driver hanya bisa lihat distribusi miliknya"
  ON distributions FOR SELECT
  USING (driver_id = get_my_user_id());

-- RLS: distribution_items
CREATE POLICY "Admin bisa kelola semua distribution_items"
  ON distribution_items FOR ALL
  USING (get_my_role() = 'admin');

CREATE POLICY "Driver bisa lihat & update items miliknya"
  ON distribution_items FOR SELECT
  USING (
    distribution_id IN (
      SELECT id FROM distributions WHERE driver_id = get_my_user_id()
    )
  );

CREATE POLICY "Driver bisa update items miliknya (input hasil)"
  ON distribution_items FOR UPDATE
  USING (
    distribution_id IN (
      SELECT id FROM distributions WHERE driver_id = get_my_user_id()
    )
  );

-- ============================================================
-- END OF v1.0.0
-- ============================================================
```

---

## 🔄 VERSI 1.x.x — Update Selanjutnya

> Tambahkan update SQL di bawah ini dengan format yang sama.
> Selalu sertakan versi, tanggal, dan deskripsi perubahan.

---

## VERSI 1.1.0 — Stores & Multi-Toko Support

> Tanggal: 2026-06-03
> Status: ⚠️ **JALANKAN DULU (urutan 1)**
> Deskripsi: Tabel `stores`, kolom `store_id` di semua tabel, function `get_my_store_id()`, update RLS per toko.

```sql
-- ============================================================
-- KASIR PINTAR - Migration v1.1.0
-- Stores & Multi-Toko Support
-- Tanggal: 2026-06-03
-- ============================================================

-- ============================================================
-- 1. TABEL STORES
-- ============================================================
CREATE TABLE stores (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nama_toko   VARCHAR(200) NOT NULL,
  alamat      TEXT,
  telepon     VARCHAR(20),
  kota        VARCHAR(100),
  is_active   BOOLEAN NOT NULL DEFAULT TRUE,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE stores IS 'Profil toko — tampil di header laporan Excel';

CREATE TRIGGER trg_stores_updated_at
  BEFORE UPDATE ON stores
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================================
-- 2. TAMBAH KOLOM store_id KE SEMUA TABEL
-- ============================================================
ALTER TABLE users        ADD COLUMN store_id UUID REFERENCES stores(id);
ALTER TABLE products     ADD COLUMN store_id UUID REFERENCES stores(id);
ALTER TABLE stock_in     ADD COLUMN store_id UUID REFERENCES stores(id);
ALTER TABLE distributions ADD COLUMN store_id UUID REFERENCES stores(id);

CREATE INDEX idx_users_store_id         ON users(store_id);
CREATE INDEX idx_products_store_id      ON products(store_id);
CREATE INDEX idx_stock_in_store_id      ON stock_in(store_id);
CREATE INDEX idx_distributions_store_id ON distributions(store_id);

-- ============================================================
-- 3. FUNCTION: get_my_store_id
-- ============================================================
CREATE OR REPLACE FUNCTION get_my_store_id()
RETURNS UUID AS $$
  SELECT store_id FROM users WHERE auth_id = auth.uid();
$$ LANGUAGE sql SECURITY DEFINER;

-- ============================================================
-- 4. RLS: stores
-- ============================================================
ALTER TABLE stores ENABLE ROW LEVEL SECURITY;

CREATE POLICY "User hanya bisa lihat toko miliknya"
  ON stores FOR SELECT
  USING (id = get_my_store_id());

CREATE POLICY "Admin bisa update toko miliknya"
  ON stores FOR UPDATE
  USING (id = get_my_store_id() AND get_my_role() = 'admin');

-- ============================================================
-- 5. UPDATE RLS products — filter by store_id
-- ============================================================
DROP POLICY IF EXISTS "Admin bisa kelola semua produk" ON products;
DROP POLICY IF EXISTS "Driver bisa lihat produk aktif" ON products;

CREATE POLICY "Admin bisa kelola produk toko sendiri"
  ON products FOR ALL
  USING (store_id = get_my_store_id() AND get_my_role() = 'admin');

CREATE POLICY "Driver bisa lihat produk aktif toko sendiri"
  ON products FOR SELECT
  USING (
    store_id = get_my_store_id()
    AND get_my_role() = 'driver'
    AND is_active = TRUE
  );

-- ============================================================
-- 6. UPDATE RLS distributions — filter by store_id
-- ============================================================
DROP POLICY IF EXISTS "Admin bisa lihat & kelola semua distribusi" ON distributions;
DROP POLICY IF EXISTS "Driver hanya bisa lihat distribusi miliknya" ON distributions;

CREATE POLICY "Admin bisa kelola distribusi toko sendiri"
  ON distributions FOR ALL
  USING (store_id = get_my_store_id() AND get_my_role() = 'admin');

CREATE POLICY "Driver hanya bisa lihat distribusi miliknya"
  ON distributions FOR SELECT
  USING (
    driver_id = get_my_user_id()
    AND store_id = get_my_store_id()
  );

-- ============================================================
-- END OF v1.1.0
-- ============================================================
```

---

## VERSI 1.2.0 — Fungsi Register Toko & Buat Driver

> Tanggal: 2026-06-03
> Status: ⚠️ **JALANKAN SETELAH v1.1.0 (urutan 2)**
> Deskripsi: Stored function untuk register toko baru (atomic) dan Admin membuat akun Driver.

```sql
-- ============================================================
-- KASIR PINTAR - Migration v1.2.0
-- Fungsi Register Toko & Buat Driver
-- Tanggal: 2026-06-03
-- ============================================================

-- ============================================================
-- 1. FUNCTION: register_store
-- Dipanggil Flutter setelah Supabase Auth signUp berhasil.
-- Membuat stores + users (admin) secara atomik.
-- ============================================================
CREATE OR REPLACE FUNCTION register_store(
  p_auth_id     UUID,
  p_name        TEXT,
  p_email       TEXT,
  p_nama_toko   TEXT,
  p_alamat      TEXT DEFAULT NULL,
  p_telepon     TEXT DEFAULT NULL,
  p_kota        TEXT DEFAULT NULL
)
RETURNS JSON AS $$
DECLARE
  v_store_id  UUID;
  v_user_id   UUID;
BEGIN
  INSERT INTO stores (nama_toko, alamat, telepon, kota)
  VALUES (p_nama_toko, p_alamat, p_telepon, p_kota)
  RETURNING id INTO v_store_id;

  INSERT INTO users (auth_id, name, email, role, store_id)
  VALUES (p_auth_id, p_name, p_email, 'admin', v_store_id)
  RETURNING id INTO v_user_id;

  RETURN json_build_object(
    'store_id',  v_store_id,
    'user_id',   v_user_id,
    'nama_toko', p_nama_toko,
    'role',      'admin'
  );

EXCEPTION WHEN OTHERS THEN
  RAISE EXCEPTION 'Gagal register toko: %', SQLERRM;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION register_store IS
  'Membuat store + user admin secara atomik setelah Supabase Auth signup.';

-- ============================================================
-- 2. FUNCTION: admin_create_driver
-- Admin membuat akun driver dari dalam app.
-- Driver otomatis terhubung ke store yang sama dengan Admin.
-- ============================================================
CREATE OR REPLACE FUNCTION admin_create_driver(
  p_driver_auth_id  UUID,
  p_name            TEXT,
  p_email           TEXT,
  p_phone           TEXT DEFAULT NULL
)
RETURNS JSON AS $$
DECLARE
  v_store_id  UUID;
  v_driver_id UUID;
BEGIN
  IF get_my_role() <> 'admin' THEN
    RAISE EXCEPTION 'Akses ditolak: hanya Admin yang dapat membuat Driver.';
  END IF;

  v_store_id := get_my_store_id();

  IF v_store_id IS NULL THEN
    RAISE EXCEPTION 'Admin tidak terhubung ke toko manapun.';
  END IF;

  INSERT INTO users (auth_id, name, email, phone, role, store_id)
  VALUES (p_driver_auth_id, p_name, p_email, p_phone, 'driver', v_store_id)
  RETURNING id INTO v_driver_id;

  RETURN json_build_object(
    'driver_id', v_driver_id,
    'name',      p_name,
    'email',     p_email,
    'store_id',  v_store_id,
    'role',      'driver'
  );

EXCEPTION WHEN OTHERS THEN
  RAISE EXCEPTION 'Gagal membuat driver: %', SQLERRM;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION admin_create_driver IS
  'Admin membuat akun driver yang otomatis terhubung ke store-nya.';

-- ============================================================
-- 3. GRANT
-- ============================================================
GRANT EXECUTE ON FUNCTION register_store TO authenticated;
GRANT EXECUTE ON FUNCTION admin_create_driver TO authenticated;

-- ============================================================
-- END OF v1.2.0
-- ============================================================
```

---

## VERSI 1.3.0 — Perbaikan Fungsi RLS (Mencegah SQL Inlining)

> Tanggal: 2026-06-03
> Status: ⚠️ **JALANKAN SETELAH v1.2.0 (urutan 3)**
> Deskripsi: Tulis ulang fungsi `get_my_role()`, `get_my_store_id()`, dan `get_my_user_id()` ke `plpgsql` agar tidak di-inline oleh query planner PostgreSQL (yang dapat merusak konteks SECURITY DEFINER dan menyebabkan error RLS).

```sql
-- ============================================================
-- KASIR PINTAR - Migration v1.3.0
-- Fix RLS Helper Functions (Prevent SQL Inlining)
-- Tanggal: 2026-06-03
-- ============================================================

-- Tulis ulang fungsi pembantu ke PL/pgSQL agar tidak di-inline oleh planner
-- Ini menjamin SECURITY DEFINER selalu aktif dan membypass RLS pada tabel users.

CREATE OR REPLACE FUNCTION get_my_role()
RETURNS user_role AS $$
DECLARE
  v_role user_role;
BEGIN
  SELECT role INTO v_role FROM users WHERE auth_id = auth.uid();
  RETURN v_role;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION get_my_store_id()
RETURNS UUID AS $$
DECLARE
  v_store_id UUID;
BEGIN
  SELECT store_id INTO v_store_id FROM users WHERE auth_id = auth.uid();
  RETURN v_store_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION get_my_user_id()
RETURNS UUID AS $$
DECLARE
  v_user_id UUID;
BEGIN
  SELECT id INTO v_user_id FROM users WHERE auth_id = auth.uid();
  RETURN v_user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```
