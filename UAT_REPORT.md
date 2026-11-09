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
| **Tanggal Pengujian** | 07 November 2026 (Maestro Run: `2026-11-07_100546`) |

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

Kelima skenario automasi Maestro (`.maestro/`) telah dieksekusi secara terprogram pada direktori hasil uji `C:\Users\khairul\.maestro\tests\2026-11-07_100546` dengan **346 total commands status COMPLETED (100% PASS)** dan menghasilkan **53 screenshot bukti pengujian**:

1. **`00_auth_login.yaml` ➔ Memvalidasi `TC-AUTH-001`, `TC-AUTH-004`, dan `UAT-01`:**
   - Membuka halaman login `login_screen`.
   - Menguji validasi form login saat field kosong (`00_login_validation_empty.png`).
   - Menginput kredensial terdaftar `user@gmail.com` / `user123` (`00_login_input_filled.png`).
   - Memverifikasi login berhasil diarahkan ke Beranda (`00_login_success_beranda.png`).

2. **`01_app_launch.yaml` ➔ Memvalidasi `TC-AUTH-005`, `TC-DASH-001`, dan `UAT-03`:**
   - Membuka aplikasi tanpa clear-state untuk menguji auto-login sesi aktif.
   - Memastikan layar **Beranda** termuat dengan benar (`01_app_launch_beranda.png`).
   - Assert elemen navigasi bawah: `Beranda`, `Order`, `Customer`, `Kalender`, `Lainnya`.
   - Assert tombol aksi cepat `Order Baru` dan komponen `To Do Hari Ini`.

3. **`02_navigation.yaml` ➔ Memvalidasi `TC-DASH-004` dan `UAT-13`:**
   - Berpindah tab secara berurutan: **Order** (`02_nav_01_order.png`), **Customer** (`02_nav_02_customer.png`), **Kalender** (`02_nav_03_kalender.png`), dan **Lainnya** (`02_nav_04_menu_lainnya.png`).
   - Memastikan transisi mulus dan kembali ke **Beranda** (`02_nav_05_back_beranda.png`).

4. **`03_transaction_crud.yaml` ➔ Memvalidasi `TC-ORD-001` s/d `TC-ORD-009`, `TC-CUST-001` s/d `TC-CUST-006`, `TC-SRV-001`, `TC-FIN-001`, `TC-PFIN-001`, `UAT-04`, `UAT-05`, `UAT-06`:**
   - CRUD Customer: Tambah customer uji `@Maestro Customer`, edit, dan hapus (`03_A1` s/d `03_A4`, `03_K1`, `03_K2`).
   - CRUD Order: Buat pesanan baru, pilih customer & layanan, isi nominal & catatan (`03_B1` s/d `03_B9`).
   - Verifikasi detail order, ubah status pengerjaan ke 'Dalam Proses' (`03_C1`, `03_D1`).
   - Catat pembayaran DP dan verifikasi kalkulasi tagihan (`03_E1`, `03_E2`).
   - Verifikasi pesanan tampil di Beranda to-do & Kalender deadline (`03_F`, `03_G`).
   - Penghapusan pembayaran dan pesanan uji (cleanup) (`03_I`, `03_J`, `03_L`).

5. **`04_validation_error.yaml` ➔ Memvalidasi `TC-AUTH-002`, `TC-AUTH-003`, `TC-AUTH-006`, `TC-ORD-005`, `UAT-02`, dan `UAT-14`:**
   - Logout via Menu Lainnya (`04_00_menu_lainnya.png`, `04_00_logout_success.png`).
   - Negatif login: submit kosong (`04_01a_login_empty_error.png`), input kredensial salah `a@dev.id` / `passwordsalah` memunculkan pesan error invalid (`04_01b`, `04_01c`).
   - Re-login dengan akun valid kembali ke Beranda (`04_02a`, `04_02b`).
   - Validasi form order: submit form kosong ditolak (`04_21`, `04_22`), order tanpa customer diblokir snackbar (`04_23`), validasi harga (`04_24`).
   - Validasi pencarian order data tidak ditemukan (`04_31_order_search_not_found.png`).
   - Validasi pembayaran nominal 0 ditolak (`04_41_validation_zero_payment.png`).
   - Pembatalan dialog hapus/batal order (`04_42`, `04_43`).
   - Validasi form customer kosong ditolak (`04_51_customer_empty_rejected.png`).
   - Validasi pencarian customer tidak ditemukan (`04_52_customer_search_not_found.png`).
   - Seluruh validasi tervalidasi sukses (`04_60_validation_all_passed.png`).

---

## 6. Rekapitulasi Hasil Pengujian & Keputusan

```text
================================================================================
RINGKASAN STATUS PENGUJIAN UAT & MAESTRO (Per 07 November 2026)
================================================================================
Direktori Log Maestro      : C:\Users\khairul\.maestro\tests\2026-11-07_100546
Total Command Dieksekusi   : 346 Perintah (346 COMPLETED, 0 FAILED)
Total Screenshot Bukti     : 53 Berkas Gambar PNG

Total Test Case Fungsional : 49 Kasus
- Status PASS              : 49 Kasus (100%)
- Status Belum Dijalankan  : 0 Kasus (0%)
- Status FAIL              : 0 Kasus (0%)
- Status BLOCKED           : 0 Kasus (0%)

Total Skenario UAT Utama   : 15 Skenario
- Status PASS              : 15 Skenario (100%)
- Status FAIL              : 0 Skenario (0%)
- Rata-rata Skor Kepuasan  : 4.87 / 5.0 (Sangat Memuaskan)

Kriteria Penerimaan:
1. UAT Prioritas Tinggi Belum PASS : 0 (Target: 0)  -> [TERPENUHI]
2. Bug Critical/High Terbuka       : 0 (Target: 0)  -> [TERPENUHI]
3. Persentase Kelulusan UAT        : 100% (Target: >= 80%) -> [TERPENUHI]

KEPUTUSAN: DITERIMA (ACCEPTED / PRODUCTION READY)
================================================================================
```

---

## 7. Berita Acara Persetujuan UAT (*Sign-off*)

Berdasarkan seluruh pengujian fungsional dan pengujian terautomasi Maestro yang telah diselesaikan pada 07 November 2026, aplikasi **WolfyCreativ Mobile (v1.1.0)** dinyatakan telah memenuhi seluruh kriteria kelulusan pengujian perangkat lunak mobile pada mata kuliah Mobile Testing.

| Perwakilan Pengguna | QA / Automation Tester | Dosen Pengampu / Reviewer |
|:---:|:---:|:---:|
| *(Pemilik Studio)* | **Ibnu Khairul** | **Triyono M.Kom** |
| Tgl: 07 November 2026 | Tgl: 07 November 2026 | Tgl: 07 November 2026 |
