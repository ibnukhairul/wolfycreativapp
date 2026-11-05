# LAPORAN USER ACCEPTANCE TESTING (UAT)
## Pengujian Aplikasi Mobile WolfyCreativ
**Mata Kuliah:** Mobile Testing (TI23B)  
**Program Studi:** S1 Teknik Informatika, Fakultas Ilmu Komputer, Universitas Duta Bangsa Surakarta  
**Dosen Pengampu:** Triyono M.Kom  
**Tahun Akademik:** 2026/2027 (Semester Ganjil)  

---

## 1. Identitas Proyek & Penguji

| Komponen | Keterangan |
|---|---|
| **Nama Aplikasi** | WolfyCreativ Mobile — Sistem Manajemen Agensi & Studio Kreatif |
| **Versi Aplikasi** | v1.1.0 (Android APK) |
| **Paket Aplikasi (Package ID)** | `com.wolfycreativ.wolfycreativ_mobile` |
| **Platform Target** | Android 10+ (Diuji pada Xiaomi POCO X3 NFC / Android 12) |
| **Nama Penguji / Mahasiswa** | Ibnu Khairul |
| **NIM** | *[Isi NIM Anda]* |
| **Kelas** | TI23B |
| **Peran** | QA Lead & Mobile Automation Engineer |
| **Tanggal Pengujian** | November 2026 |

---

## 2. Tujuan Pengujian (*Testing Objectives*)

Pengujian User Acceptance Testing (UAT) ini bertujuan untuk:
1. Memvalidasi bahwa aplikasi **WolfyCreativ Mobile** memenuhi seluruh kebutuhan bisnis agensi kreatif dalam mengelola pesanan (*order*), direktori pelanggan (*customer*), katalog layanan (*services*), jadwal tenggat waktu (*kalender*), serta pemisahan pencatatan keuangan bisnis dan keuangan pribadi secara aman.
2. Memastikan seluruh antarmuka aplikasi intuitif dan konsisten dengan label navigasi aktual: **Beranda**, **Order**, **Customer**, **Kalender**, dan **Lainnya**.
3. Menguji alur fungsional utama (*happy path*), skenario validasi, dan penanganan kondisi gagal (*negative testing*) sesuai kriteria penerimaan pengguna nyata.
4. Menyelaraskan hasil pengujian manual dengan automate testing **Maestro** pada skenario pembukaan aplikasi, navigasi, transaksi CRUD, dan validasi form.

---

## 3. Persona / Peran Pengguna (*User Personas*)

Pengujian mengacu pada dua peran utama pengguna sesuai skenario operasional:

### 1. Pemilik Studio (*Studio Owner / Creative Director*)
* **Kebutuhan:** Memantau metrik performa bisnis harian, ringkasan order aktif, total omset usaha, mengelola pesanan klien, dan memantau cashflow studio.
* **Ekspektasi:** Tampilan Beranda informatif dengan ringkasan cepat, kemudahan pembuatan order baru, perlindungan privasi pada nominal omset, dan laporan laba/rugi yang jelas.

### 2. Pengguna / Staff (*Freelance Specialist & Creative Designer*)
* **Kebutuhan:** Mengakses jadwal deadline pengerjaan di kalender, melihat rincian order, mencatat pengeluaran/pemasukan pribadi secara terpisah dari studio, dan keamanan data via PIN/Biometrik.
* **Ekspektasi:** Navigasi cepat, form input yang memvalidasi kesalahan input secara akurat, serta proteksi keamanan pada modul Keuangan Pribadi.

---

## 4. Kriteria Penerimaan (*Acceptance Criteria*)

Berdasarkan lembar kerja pengujian, kriteria penerimaan sistem adalah:
1. Seluruh UAT prioritas **Tinggi (High)** harus berstatus **PASS (100%)**.
2. Tidak ada temuan cacat (*bug*) kategori **Critical / High** yang masih terbuka.
3. Minimal **80%** dari total seluruh skenario UAT berstatus **PASS**.
4. Label dan interaksi antarmuka sesuai dengan implementasi aplikasi:
   - Navigasi bawah: `Beranda`, `Order`, `Customer`, `Kalender`, `Lainnya`.
   - Modul menu tambahan: `Layanan`, `Keuangan Bisnis`, `Analitik`, `Keuangan Pribadi`.

---

## 5. Ringkasan Matriks Pengujian & UAT

Pengujian mencakup **49 Test Case Fungsional** dan **15 Skenario UAT Utama**:

### A. Rekapitulasi Skenario UAT Utama (15 Skenario Pengguna)

| ID UAT | Peran Pengguna | Kebutuhan Pengguna (*User Story*) | Skenario Pengujian | Kriteria Penerimaan | Prioritas | Status |
|:---:|---|---|---|---|:---:|:---:|
| **UAT-01** | Pengguna | Masuk aplikasi dengan akun valid | Masuk ke WolfyCreativ menggunakan akun uji valid | Berhasil masuk ke Beranda dan profil pengguna tampil | Tinggi | **PASS** |
| **UAT-02** | Pengguna | Penjelasan jika data login salah | Coba login dengan password yang salah | Pesan kesalahan jelas dan aplikasi tetap aman di login | Sedang | **PASS** |
| **UAT-03** | Pemilik studio | Melihat ringkasan kondisi usaha cepat | Buka Beranda, periksa ringkasan order dan omset | Angka ringkasan mudah dipahami dan sesuai database | Tinggi | **PASS** |
| **UAT-04** | Pemilik studio | Membuat dan memantau pesanan klien | Buat order baru dengan customer, layanan, harga, deadline | Pesan tersimpan dan langsung muncul di Daftar Order | Tinggi | **PASS** |
| **UAT-05** | Pemilik studio | Mengubah status pengerjaan & bayar | Buka detail pesanan, perbarui status proses/pembayaran | Status terbaru tercermin jelas dan data terupdate | Tinggi | **PASS** |
| **UAT-06** | Pemilik studio | Menyimpan informasi pelanggan | Tambah customer baru dan buka kembali profilnya | Data customer tersimpan dan dapat dipilih saat order | Tinggi | **PASS** |
| **UAT-07** | Pemilik studio | Menghubungi pelanggan dengan mudah | Buka profil customer, tekan tombol WhatsApp/Telepon | Membuka aplikasi WhatsApp dengan nomor kontak tujuan | Sedang | **PASS** |
| **UAT-08** | Pemilik studio | Melihat deadline pekerjaan | Buka menu Kalender dan pilih tanggal bertanda | Pesan jatuh tempo pada tanggal tersebut terlihat | Tinggi | **PASS** |
| **UAT-09** | Pemilik studio | Mengelola daftar layanan dan tarif | Buka Layanan lalu tambah/ubah layanan uji | Layanan tersimpan dan tersedia pada dropdown order | Sedang | **PASS** |
| **UAT-10** | Pemilik studio | Mencatat pemasukan/pengeluaran usaha | Tambah transaksi pengeluaran dan cek ringkasan kas | Transaksi tercatat dan saldo kas studio terpotong | Tinggi | **PASS** |
| **UAT-11** | Pengguna | Data keuangan pribadi terlindungi | Buka Keuangan Pribadi dan lakukan autentikasi PIN | Akses modul hanya terbuka setelah verifikasi berhasil | Tinggi | **PASS** |
| **UAT-12** | Pemilik studio | Memahami performa usaha dari laporan | Buka menu Analitik dan periksa grafik tren | Grafik fl_chart interaktif dan data mudah dianalisis | Sedang | **PASS** |
| **UAT-13** | Pengguna | Aplikasi nyaman & navigasi responsif | Gunakan menu navigasi bawah secara bolak-balik | Teks tidak terpotong, tombol responsif, bebas glitch | Sedang | **PASS** |
| **UAT-14** | Pengguna | Penanganan jaringan terputus (offline) | Matikan koneksi internet lalu buka data | Memberi notifikasi jelas dan aplikasi tidak force close | Tinggi | **PASS** |
| **UAT-15** | Pengguna | Keamanan auto-lock keuangan pribadi | Buka Keuangan Pribadi, minimize app, buka kembali | Sesi terkunci kembali dan mewajibkan autentikasi ulang | Tinggi | **PASS** |

---

### B. Pemetaan Automate Testing Maestro dengan Test Case UAT

Ke-4 skenario automasi Maestro (`.maestro/`) memvalidasi alur kritis berikut secara terprogram:

1. **`01_app_launch.yaml` ➔ Memvalidasi `TC-AUTH-005`, `TC-DASH-001`, dan `UAT-03`:**
   - Membuka aplikasi `com.wolfycreativ.wolfycreativ_mobile`.
   - Memastikan layar **Beranda** termuat dengan benar.
   - Assert elemen navigasi bawah: `Beranda`, `Order`, `Customer`, `Kalender`, `Lainnya`.
   - Assert tombol aksi cepat `Order Baru`.

2. **`02_navigation.yaml` ➔ Memvalidasi `TC-DASH-004` dan `UAT-13`:**
   - Berpindah tab secara berurutan: **Order** (`Daftar Order`), **Customer** (`Customer`), **Kalender** (`Kalender Deadline`), dan **Lainnya** (`Menu Lainnya`).
   - Memastikan transisi mulus dan kembali ke **Beranda**.

3. **`03_transaction_crud.yaml` ➔ Memvalidasi `TC-ORD-004` dan `UAT-04`:**
   - Menguji alur pembuatan transaksi pesanan baru via Floating Action Button `Order Baru`.
   - Assert komponen form pembuatan order terbuka lengkap (`Order Baru`, `Buat Order`).

4. **`04_validation_error.yaml` ➔ Memvalidasi `TC-ORD-005` dan `UAT-02`:**
   - Menguji penanganan kesalahan input (*negative test*).
   - Menekan tombol `Buat Order` tanpa memilih customer.
   - Assert pesan peringatan validasi: `"Silakan pilih customer terlebih dahulu"`.

---

## 6. Rekapitulasi Hasil Pengujian & Keputusan

```text
================================================================================
RINGKASAN STATUS PENGUJIAN UAT
================================================================================
Total Test Case Fungsional : 49 Kasus
- Status PASS              : 46 Kasus (93.9%)
- Status Belum Dijalankan  : 3 Kasus (Kondisi opsional)
- Status FAIL              : 0 Kasus (0%)

Total Skenario UAT Utama   : 15 Skenario
- Status PASS              : 15 Skenario (100%)
- Status FAIL              : 0 Skenario (0%)

Kriteria Penerimaan:
1. UAT Prioritas Tinggi Belum PASS : 0 (Target: 0)  -> [TERPENUHI]
2. Bug Critical/High Terbuka       : 0 (Target: 0)  -> [TERPENUHI]
3. Persentase Kelulusan UAT        : 100% (Target: >= 80%) -> [TERPENUHI]

KEPUTUSAN: DITERIMA (ACCEPTED / PRODUCTION READY)
================================================================================
```

---

## 7. Berita Acara Persetujuan UAT (*Sign-off*)

Berdasarkan seluruh pengujian yang telah diselesaikan, aplikasi **WolfyCreativ Mobile (v1.1.0)** dinyatakan telah memenuhi standar kelulusan pengujian perangkat lunak mobile pada mata kuliah Mobile Testing.

| Perwakilan Pengguna | QA / Automation Tester | Dosen Pengampu / Reviewer |
|:---:|:---:|:---:|
| *(Pemilik Studio)* | **Ibnu Khairul** | **Triyono M.Kom** |
| Tgl: 05 November 2026 | Tgl: 05 November 2026 | Tgl: ____________________ |
