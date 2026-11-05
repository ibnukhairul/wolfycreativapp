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
| **Nama Aplikasi** | WolfyCreativ Mobile (Sistem Manajemen Agensi & Studio Kreatif) |
| **Versi Aplikasi** | v1.0.0 (Build 1) |
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
1. Memvalidasi bahwa aplikasi **WolfyCreativ Mobile** memenuhi seluruh kebutuhan bisnis agensi kreatif dalam mengelola pesanan (*orders*), data klien (*customers*), katalog layanan (*services*), serta pelaporan keuangan (*business & personal finance*).
2. Memastikan aplikasi memiliki antarmuka yang intuitif, navigasi yang stabil, serta validasi form yang mencegah kesalahan input pengguna (*human error*).
3. Menguji alur fungsional utama (*happy path*), skenario validasi, dan penanganan kondisi gagal (*negative testing*) sesuai kriteria penerimaan pengguna nyata.
4. Mendokumentasikan status kelulusan (*Pass/Fail*), hasil aktual, serta ringkasan temuan sebagai tolok ukur kesiapan rilis produksi.

---

## 3. Persona / Peran Pengguna (*User Personas*)

Untuk mencerminkan skenario riil di lapangan, pengujian melibatkan 3 persona pengguna:

### Persona 1: Ahmad Fauzi (Creative Director & Studio Owner)
* **Kebutuhan:** Memantau metrik performa bisnis harian, ringkasan pendapatan bulanan, status pesanan aktif, dan kesehatan finansial studio secara *real-time*.
* **Ekspektasi:** Dashboard informatif dengan statistik ringkas, perlindungan privasi pada angka omset, dan laporan keuangan terstruktur.

### Persona 2: Siti Rahma (Project Manager & Client Relations)
* **Kebutuhan:** Menerima brief klien, membuat invoice/pesanan baru, mengatur tenggat waktu (*deadline*), dan memperbarui status pengerjaan proyek dari *Pending* hingga *Selesai*.
* **Ekspektasi:** Input pesanan cepat dengan dropdown pelanggan/layanan, generator teks invoice otomatis untuk WhatsApp, serta kalender pengingat deadline.

### Persona 3: Budi Santoso (Freelance Specialist & Creative Staff)
* **Kebutuhan:** Mengakses daftar pekerjaan harian (*To Do Hari Ini*), mencatat pemasukan/pengeluaran pribadi secara terpisah dari studio, dan keamanan data via PIN/Biometrik.
* **Ekspektasi:** Tampilan responsif, alur pencatatan pengeluaran pribadi yang cepat, serta validasi kesalahan input yang jelas dan informatif.

---

## 4. Kriteria Penerimaan (*Acceptance Criteria*)

Aplikasi dinyatakan **LULUS (ACCEPTED)** apabila memenuhi kriteria berikut:
1. **Otentikasi Aman:** Sistem memverifikasi kredensial via Supabase Auth; kredensial salah ditolak dengan pesan yang informatif.
2. **Integritas Navigasi:** Seluruh tab pada *Bottom Navigation* (Dashboard, Pesanan, Klien, Kalender, Menu Lainnya) merespons transisi layar tanpa *crash* atau *blank page*.
3. **Akurasi Alur CRUD Pesanan:** Form pembuatan order berhasil menyimpan data dengan kalkulasi harga yang tepat dan otomatis masuk ke daftar order.
4. **Validasi Input Ketat:** Kolom wajib (seperti nama customer, layanan, nominal) dicek sebelum proses submit; menampilkan *error notification / snackbar* jika input tidak lengkap.
5. **Pemisahan Finansial:** Data keuangan bisnis dan keuangan pribadi tersimpan pada tabel terpisah, dengan proteksi keamanan tambahan (PIN/Biometrik) pada modul keuangan pribadi.
6. **Keterulangan Hasil (*Reproducibility*):** Pengujian manual dan otomasi (Maestro) memberikan hasil yang konsisten pada perangkat fisik/emulator.

---

## 5. Prasyarat Pengujian (*Preconditions*)

1. Perangkat Android terhubung dengan koneksi internet aktif untuk sinkronisasi Supabase.
2. Aplikasi WolfyCreativ Mobile terpasang (*installed*) pada perangkat pengujian.
3. Database Supabase dalam kondisi aktif dengan skema relasi: `customers`, `services`, `orders`, `transactions`, dan `personal_finances`.
4. Akun penguji terdaftar pada Supabase Auth dengan email uji `admin@wolfycreativ.com`.

---

## 6. Skenario Pengujian UAT Terperinci

Berikut adalah **7 skenario pengujian UAT** yang mencakup alur utama (*happy path*), validasi input, kondisi gagal (*negative testing*), serta hasil yang diharapkan:

### Skenario 1: Autentikasi Pengguna dengan Akun Valid (Alur Utama)
* **ID Kasus Uji:** `UAT-AUTH-001`
* **Modul:** Autentikasi
* **Persona:** Semua Pengguna
* **Prasyarat:** Aplikasi berada pada halaman login (`/login`).
* **Langkah Pengujian:**
  1. Buka aplikasi WolfyCreativ.
  2. Masukkan email terdaftar: `admin@wolfycreativ.com`.
  3. Masukkan password yang benar.
  4. Tekan tombol **"Masuk"**.
* **Hasil yang Diharapkan:** Sesi login tersimpan, sistem melakukan otentikasi ke Supabase, dan pengguna dialihkan ke halaman **Dashboard**.
* **Hasil Aktual:** Aplikasi berhasil memverifikasi kredensial, menampilkan notifikasi sukses, dan langsung membuka Dashboard dengan sapaan pengguna.
* **Status:** ✅ **LULUS (PASS)**

---

### Skenario 2: Autentikasi dengan Password Salah (Kondisi Gagal / Negative Test)
* **ID Kasus Uji:** `UAT-AUTH-002`
* **Modul:** Autentikasi
* **Persona:** Semua Pengguna
* **Prasyarat:** Berada pada halaman login.
* **Langkah Pengujian:**
  1. Masukkan email: `admin@wolfycreativ.com`.
  2. Masukkan password acak / salah: `passwordsalah123`.
  3. Tekan tombol **"Masuk"**.
* **Hasil yang Diharapkan:** Sistem menolak login, tidak ada sesi yang terbentuk, dan menampilkan pesan kesalahan kredensial tanpa membocorkan info sensitif.
* **Hasil Aktual:** Muncul pesan kesalahan *"Invalid login credentials"*, form tetap di halaman login, dan input password tetap aman.
* **Status:** ✅ **LULUS (PASS)**

---

### Skenario 3: Pemantauan Metrik Dashboard & Navigasi Antarmuka (Alur Utama)
* **ID Kasus Uji:** `UAT-DASH-001`
* **Modul:** Dashboard & Navigasi
* **Persona:** Ahmad Fauzi (Studio Owner)
* **Prasyarat:** Pengguna sudah login dan berada di Dashboard.
* **Langkah Pengujian:**
  1. Periksa kartu ringkasan hero (Sapaan pengguna & tanggal hari ini).
  2. Periksa 5 kartu metrik (Pesanan Baru, Proses, Selesai, Omset, Belum Lunas).
  3. Tekan ikon mata untuk menyembunyikan/menampilkan angka nominal omset.
  4. Lakukan gestur *Pull-to-Refresh* untuk memperbarui data.
* **Hasil yang Diharapkan:** Seluruh metrik tampil sinkron dengan database, nominal omset dapat disamarkan (*obscured*), dan data ter-refresh tanpa kendala.
* **Hasil Aktual:** Metrik terisi lengkap, fitur *obscure revenue* berfungsi menyamarkan nominal menjadi bintang, dan animasi refresh berjalan mulus.
* **Status:** ✅ **LULUS (PASS)**

---

### Skenario 4: Pembuatan Pesanan Baru / Order Baru (Alur Transaksi & CRUD)
* **ID Kasus Uji:** `UAT-ORD-001`
* **Modul:** Manajemen Pesanan
* **Persona:** Siti Rahma (Project Manager)
* **Prasyarat:** Berada di tab Pesanan (`/orders`).
* **Langkah Pengujian:**
  1. Tekan tombol FAB **"+ Order Baru"**.
  2. Pilih Customer dari modal pencarian (misal: "Budi Studio").
  3. Pilih Layanan (misal: "Desain Logo & Branding").
  4. Masukkan nominal harga pesanan: `Rp 1.500.000`.
  5. Tentukan tanggal deadline pengerjaan.
  6. Tekan tombol **"Buat Order"**.
* **Hasil yang Diharapkan:** Pesanan berhasil dibuat, data tersimpan ke Supabase, nomor invoice ter-generate otomatis, dan pesanan muncul di daftar teratas.
* **Hasil Aktual:** Pesanan tersimpan sempurna dengan status awal *Baru*, badge pembayaran *Belum Lunas*, dan daftar order langsung menampilkan data baru.
* **Status:** ✅ **LULUS (PASS)**

---

### Skenario 5: Validasi Kelengkapan Input Form Order (Validasi Input & Error Handling)
* **ID Kasus Uji:** `UAT-ORD-002`
* **Modul:** Form Pesanan
* **Persona:** Siti Rahma (Project Manager)
* **Prasyarat:** Berada di form pembuatan order baru (`/orders/new`).
* **Langkah Pengujian:**
  1. Buka form Order Baru.
  2. Biarkan pemilih Customer dan Layanan dalam keadaan kosong.
  3. Kosongkan kolom input harga.
  4. Langsung tekan tombol **"Buat Order"**.
* **Hasil yang Diharapkan:** Sistem menolak submit, memblokir pengiriman payload kosong, dan menampilkan pesan peringatan validasi: *"Silakan pilih customer terlebih dahulu"*.
* **Hasil Aktual:** Muncul Snackbar berwarna merah dengan pesan peringatan *"Silakan pilih customer terlebih dahulu"*. Form tidak ter-submit.
* **Status:** ✅ **LULUS (PASS)**

---

### Skenario 6: Pencarian dan Filter Daftar Pesanan (Pencarian & Penemuan Data)
* **ID Kasus Uji:** `UAT-ORD-003`
* **Modul:** Manajemen Pesanan
* **Persona:** Siti Rahma / Budi Santoso
* **Prasyarat:** Terdapat sejumlah pesanan pada tab Pesanan.
* **Langkah Pengujian:**
  1. Ketik nama klien atau kode invoice pada kolom pencarian di bagian atas.
  2. Pilih filter tab status (misal: "Proses" atau "Selesai").
  3. Tekan tombol filter sorting (Terbaru, Deadline Terdekat, Harga Tertinggi).
* **Hasil yang Diharapkan:** Daftar pesanan menyaring data secara dinamis sesuai kata kunci pencarian dan filter status terpilih.
* **Hasil Aktual:** Daftar order langsung memfilter data secara *real-time* sesuai input kata kunci dan status badge.
* **Status:** ✅ **LULUS (PASS)**

---

### Skenario 7: Manajemen Keuangan Pribadi dengan Proteksi Keamanan (Alur Khusus)
* **ID Kasus Uji:** `UAT-FIN-001`
* **Modul:** Keuangan Pribadi
* **Persona:** Budi Santoso (Staff / Freelancer)
* **Prasyarat:** Pengguna membuka menu *Lainnya* ➔ *Keuangan Pribadi*.
* **Langkah Pengujian:**
  1. Akses menu Keuangan Pribadi.
  2. Verifikasi dialog otentikasi biometrik / PIN pengaman.
  3. Masukkan PIN yang benar.
  4. Tambah catatan transaksi pengeluaran baru (Kategori: "Makan/Transportasi", Nominal: `50.000`).
  5. Tekan tombol simpan.
* **Hasil yang Diharapkan:** Akses modul terlindungi PIN/Biometrik; setelah terbuka, transaksi pengeluaran berhasil tersimpan dan memotong saldo ringkasan.
* **Hasil Aktual:** Layar terkunci sebelum PIN valid dimasukkan. Setelah lolos otentikasi, catatan pengeluaran tersimpan dan grafik alokasi budget terbarui.
* **Status:** ✅ **LULUS (PASS)**

---

## 7. Matriks Rekapitulasi Hasil Pengujian

| No | Kode Kasus Uji | Skenario | Kategori Pengujian | Prioritas | Hasil Pengujian |
|:--:|---|---|:---:|:---:|:---:|
| 1 | `UAT-AUTH-001` | Login dengan akun terdaftar | Alur Utama | High | **PASS** |
| 2 | `UAT-AUTH-002` | Login ditolak dengan password salah | Kondisi Gagal | High | **PASS** |
| 3 | `UAT-DASH-001` | Monitoring ringkasan metrik & samarkan omset | Alur Utama | High | **PASS** |
| 4 | `UAT-ORD-001` | Pembuatan order baru & generate invoice | Alur Utama / CRUD | High | **PASS** |
| 5 | `UAT-ORD-002` | Validasi form order jika field kosong | Validasi Input | High | **PASS** |
| 6 | `UAT-ORD-003` | Pencarian dan penyaringan data order | Fungsionalitas | Medium | **PASS** |
| 7 | `UAT-FIN-001` | Proteksi keamanan PIN & pencatatan cashflow | Alur Khusus | High | **PASS** |

**Statistik Kelulusan:**
* Total Skenario Diuji: **7 Skenario**
* Skenario Lulus (*Pass*): **7 (100%)**
* Skenario Gagal (*Fail*): **0 (0%)**
* Status Kelayakan: **SIAP RILIS (PRODUCTION READY)**

---

## 8. Ringkasan Temuan & Rekomendasi (*Findings & Recommendations*)

### Temuan Positif (*Strengths*):
1. **Performa Responsif:** Transisi antarmuka antar menu bottom navigation berjalan mulus pada refresh rate 60–120Hz tanpa *lag*.
2. **Kesesuaian Validasi:** Seluruh form input dilengkapi mekanisme pengaman ganda (validasi form lokal Flutter & aturan constraint Supabase).
3. **Privasi Pengguna:** Tersedianya fitur penyamaran nominal omset pada dashboard serta modul keuangan pribadi berproteksi biometrik/PIN memberikan rasa aman bagi pengguna.

### Rekomendasi Pengembangan Lanjutan (*Future Enhancements*):
1. **Offline Mode & Caching:** Menambahkan local database caching (Hive/Isar) agar aplikasi tetap dapat menampilkan data riwayat saat koneksi internet terputus sementara.
2. **Push Notification:** Mengintegrasikan notifikasi lokal atau Firebase Cloud Messaging untuk pengingat tenggat waktu (*deadline*) pesanan yang mendekati H-1.

---

## 9. Berita Acara Penerimaan (*Sign-off & Approval*)

Berdasarkan seluruh hasil pengujian User Acceptance Testing yang telah dilakukan, aplikasi **WolfyCreativ Mobile (v1.0.0)** dinyatakan telah memenuhi spesifikasi fungsionalitas, kriteria penerimaan pengguna, serta standar pengujian mata kuliah Mobile Testing.

| Peran | Nama | Tanda Tangan / Persetujuan | Tanggal |
|---|---|:---:|:---:|
| **QA / Penguji** | Ibnu Khairul | *Disetujui* | 05 November 2026 |
| **Dosen Pengampu** | Triyono M.Kom | *Menunggu Verifikasi* | - |

