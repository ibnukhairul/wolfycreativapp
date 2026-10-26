import openpyxl
from openpyxl.styles import Font, PatternFill, Alignment, Border, Side
from openpyxl.utils import get_column_letter
from openpyxl.worksheet.datavalidation import DataValidation

def create_uat_excel():
    wb = openpyxl.Workbook()
    
    # -------------------------------------------------------------
    # STYLES & PALETTES
    # -------------------------------------------------------------
    font_family = "Segoe UI"
    
    # Fonts
    title_font = Font(name=font_family, size=16, bold=True, color="1E293B")
    subtitle_font = Font(name=font_family, size=10, italic=True, color="64748B")
    section_font = Font(name=font_family, size=11, bold=True, color="FFFFFF")
    tbl_header_font = Font(name=font_family, size=10, bold=True, color="FFFFFF")
    bold_font = Font(name=font_family, size=10, bold=True, color="1E293B")
    regular_font = Font(name=font_family, size=9, color="334155")
    metric_num_font = Font(name=font_family, size=18, bold=True, color="0F172A")
    metric_label_font = Font(name=font_family, size=9, bold=True, color="64748B")
    
    # Fills
    primary_fill = PatternFill(start_color="1E293B", end_color="1E293B", fill_type="solid") # Dark Navy
    secondary_fill = PatternFill(start_color="334155", end_color="334155", fill_type="solid")
    header_blue_fill = PatternFill(start_color="2563EB", end_color="2563EB", fill_type="solid") # Blue
    accent_amber = PatternFill(start_color="F59E0B", end_color="F59E0B", fill_type="solid")
    light_blue_fill = PatternFill(start_color="F1F5F9", end_color="F1F5F9", fill_type="solid")
    zebra_fill = PatternFill(start_color="F8FAFC", end_color="F8FAFC", fill_type="solid")
    white_fill = PatternFill(start_color="FFFFFF", end_color="FFFFFF", fill_type="solid")
    
    # Status Fills & Fonts
    pass_fill = PatternFill(start_color="DCFCE7", end_color="DCFCE7", fill_type="solid")
    pass_font = Font(name=font_family, size=9, bold=True, color="166534")
    fail_fill = PatternFill(start_color="FEE2E2", end_color="FEE2E2", fill_type="solid")
    fail_font = Font(name=font_family, size=9, bold=True, color="991B1B")
    blocked_fill = PatternFill(start_color="FEF3C7", end_color="FEF3C7", fill_type="solid")
    blocked_font = Font(name=font_family, size=9, bold=True, color="92400E")
    untested_fill = PatternFill(start_color="F1F5F9", end_color="F1F5F9", fill_type="solid")
    untested_font = Font(name=font_family, size=9, bold=True, color="475569")
    
    # Borders
    thin_border_side = Side(border_style="thin", color="CBD5E1")
    thick_bottom_side = Side(border_style="medium", color="1E293B")
    card_border = Border(left=thin_border_side, right=thin_border_side, top=thin_border_side, bottom=thin_border_side)
    cell_border = Border(left=thin_border_side, right=thin_border_side, top=thin_border_side, bottom=thin_border_side)
    
    # Alignments
    align_center = Alignment(horizontal="center", vertical="center", wrap_text=True)
    align_left = Alignment(horizontal="left", vertical="center", wrap_text=True)
    align_right = Alignment(horizontal="right", vertical="center")
    align_header = Alignment(horizontal="center", vertical="center", wrap_text=True)
    
    # =============================================================
    # SHEET 1: RINGKASAN & PANDUAN (SUMMARY)
    # =============================================================
    ws1 = wb.active
    ws1.title = "Ringkasan UAT"
    ws1.views.sheetView[0].showGridLines = True
    
    # Title
    ws1.merge_cells("B2:I2")
    ws1["B2"] = "DOKUMEN USER ACCEPTANCE TESTING (UAT)"
    ws1["B2"].font = title_font
    
    ws1.merge_cells("B3:I3")
    ws1["B3"] = "Aplikasi Mobile WolfyCreativ — Sistem Manajemen Agensi & Studio Kreatif (Android APK)"
    ws1["B3"].font = subtitle_font
    
    # Project Info Box
    info_data = [
        ("Nama Proyek", "WolfyCreativ Mobile", "Versi Aplikasi", "v1.0.0 (Release Build)"),
        ("Tipe Distribusi", "Android Package (.apk) Universal", "Platform Target", "Android 10 - 15+"),
        ("Backend Service", "Supabase (PostgreSQL & Auth)", "Framework", "Flutter 3.47 / Dart 3.13"),
        ("Tanggal UAT", "26 Oktober 2026", "Status Pengujian", "Siap Diuji (Ready for UAT)"),
        ("Lead Developer", "Wolfy Development Team", "PIC Penguji (Tester)", "[Nama Penguji / Klien]"),
    ]
    
    ws1.merge_cells("B5:I5")
    ws1["B5"] = "INFORMASI PROYEK & LINGKUNGAN PENGUJIAN"
    ws1["B5"].font = section_font
    ws1["B5"].fill = primary_fill
    ws1["B5"].alignment = align_left
    
    start_r = 6
    for i, (k1, v1, k2, v2) in enumerate(info_data):
        r = start_r + i
        ws1[f"B{r}"] = k1
        ws1[f"B{r}"].font = bold_font
        ws1[f"B{r}"].fill = light_blue_fill
        ws1[f"B{r}"].border = cell_border
        
        ws1.merge_cells(f"C{r}:D{r}")
        ws1[f"C{r}"] = v1
        ws1[f"C{r}"].font = regular_font
        ws1[f"C{r}"].border = cell_border
        ws1[f"D{r}"].border = cell_border
        
        ws1[f"E{r}"] = k2
        ws1[f"E{r}"].font = bold_font
        ws1[f"E{r}"].fill = light_blue_fill
        ws1[f"E{r}"].border = cell_border
        
        ws1.merge_cells(f"F{r}:I{r}")
        ws1[f"F{r}"] = v2
        ws1[f"F{r}"].font = regular_font
        for col_l in ["F", "G", "H", "I"]:
            ws1[f"{col_l}{r}"].border = cell_border

    # Metrics Summary Cards
    ws1.merge_cells("B12:I12")
    ws1["B12"] = "RINGKASAN STATUS HASIL PENGUJIAN (REAL-TIME METRICS)"
    ws1["B12"].font = section_font
    ws1["B12"].fill = primary_fill
    ws1["B12"].alignment = align_left
    
    # 5 KPI Cards
    cards = [
        ("B", "C", "TOTAL TEST CASE", "=COUNTA('Daftar Test Cases'!A4:A53)", "1E293B", "F1F5F9"),
        ("D", "D", "PASS (LULUS)", '=COUNTIF(\'Daftar Test Cases\'!H4:H53, "Pass")', "166534", "DCFCE7"),
        ("E", "E", "FAIL (GAGAL)", '=COUNTIF(\'Daftar Test Cases\'!H4:H53, "Fail")', "991B1B", "FEE2E2"),
        ("F", "F", "BLOCKED", '=COUNTIF(\'Daftar Test Cases\'!H4:H53, "Blocked")', "92400E", "FEF3C7"),
        ("G", "G", "UNTESTED", '=COUNTIF(\'Daftar Test Cases\'!H4:H53, "Untested")', "475569", "F1F5F9"),
        ("H", "I", "PERSENTASE KELULUSAN", '=IF(B14>0, D14/B14, 0)', "1D4ED8", "DBEAFE"),
    ]
    
    for c_start, c_end, label, formula, text_c, bg_c in cards:
        if c_start != c_end:
            ws1.merge_cells(f"{c_start}13:{c_end}13")
            ws1.merge_cells(f"{c_start}14:{c_end}14")
        
        cell_lbl = ws1[f"{c_start}13"]
        cell_lbl.value = label
        cell_lbl.font = Font(name=font_family, size=8, bold=True, color="64748B")
        cell_lbl.alignment = align_center
        cell_lbl.fill = PatternFill(start_color=bg_c, end_color=bg_c, fill_type="solid")
        
        cell_val = ws1[f"{c_start}14"]
        cell_val.value = formula
        cell_val.font = Font(name=font_family, size=15, bold=True, color=text_c)
        cell_val.alignment = align_center
        cell_val.fill = PatternFill(start_color=bg_c, end_color=bg_c, fill_type="solid")
        if "IF" in formula:
            cell_val.number_format = "0.0%"
            
        # border
        col_range = [c_start] if c_start == c_end else [c_start, c_end]
        for c in col_range:
            ws1[f"{c}13"].border = cell_border
            ws1[f"{c}14"].border = cell_border

    # Instructions Table
    ws1.merge_cells("B16:I16")
    ws1["B16"] = "PANDUAN & ATURAN PENGISIAN FORM UAT"
    ws1["B16"].font = section_font
    ws1["B16"].fill = primary_fill
    ws1["B16"].alignment = align_left
    
    guidelines = [
        ("1", "Status Pengujian", "Pilih status pada kolom 'Status' di sheet 'Daftar Test Cases' menggunakan dropdown:"),
        ("", "  • Pass", "Fungsi berjalan persis sesuai hasil yang diharapkan tanpa kendala."),
        ("", "  • Fail", "Fungsi tidak berjalan sebagaimana mestinya, menghasilkan error, atau data salah."),
        ("", "  • Blocked", "Pengujian tidak dapat dilanjutkan karena terhalang bug sebelumnya / dependensi server."),
        ("", "  • Untested", "Skenario belum diuji sama sekali oleh tester."),
        ("2", "Pencatatan Masalah", "Jika status 'Fail' atau 'Blocked', catat temuan bug secara terperinci pada sheet 'Log Temuan Bug'."),
        ("3", "Perangkat Pengujian", "Lakukan pengujian langsung menggunakan file app-release.apk yang terinstall di HP fisik Android."),
        ("4", "Koneksi & Biometrik", "Pastikan koneksi internet aktif saat uji sinkronisasi data & siapkan sidik jari/PIN untuk fitur Personal Finance."),
    ]
    
    r_guide = 17
    for num, title, desc in guidelines:
        ws1[f"B{r_guide}"] = num
        ws1[f"B{r_guide}"].font = bold_font
        ws1[f"B{r_guide}"].alignment = align_center
        ws1[f"B{r_guide}"].border = cell_border
        
        ws1[f"C{r_guide}"] = title
        ws1[f"C{r_guide}"].font = bold_font if num != "" else regular_font
        ws1[f"C{r_guide}"].border = cell_border
        
        ws1.merge_cells(f"D{r_guide}:I{r_guide}")
        ws1[f"D{r_guide}"] = desc
        ws1[f"D{r_guide}"].font = regular_font
        for col_l in ["D", "E", "F", "G", "H", "I"]:
            ws1[f"{col_l}{r_guide}"].border = cell_border
        r_guide += 1

    # Sign-off box on summary sheet
    r_sign_start = r_guide + 1
    ws1.merge_cells(f"B{r_sign_start}:I{r_sign_start}")
    ws1[f"B{r_sign_start}"] = "PERSETUJUAN AKHIR (SIGN-OFF APPROVAL)"
    ws1[f"B{r_sign_start}"].font = section_font
    ws1[f"B{r_sign_start}"].fill = primary_fill
    ws1[f"B{r_sign_start}"].alignment = align_left
    
    headers_sign = ["Peran (Role)", "Nama Lengkap", "Organisasi / Jabatan", "Status Persetujuan", "Tanggal", "Tanda Tangan"]
    cols_sign = [("B", "C"), ("D", "D"), ("E", "E"), ("F", "F"), ("G", "G"), ("H", "I")]
    
    r_sh = r_sign_start + 1
    for (cs, ce), h_text in zip(cols_sign, headers_sign):
        if cs != ce:
            ws1.merge_cells(f"{cs}{r_sh}:{ce}{r_sh}")
        ws1[f"{cs}{r_sh}"] = h_text
        ws1[f"{cs}{r_sh}"].font = tbl_header_font
        ws1[f"{cs}{r_sh}"].fill = secondary_fill
        ws1[f"{cs}{r_sh}"].alignment = align_center
        col_list = [cs] if cs == ce else [cs, ce]
        for c in col_list:
            ws1[f"{c}{r_sh}"].border = cell_border
            
    roles_sign = [
        ("QA Lead / Tester", "[Nama Tester]", "Quality Assurance", "Accepted / Rejected", "____/____/2026", ""),
        ("Product Owner / Klien", "[Nama Klien]", "WolfyCreativ Management", "Accepted / Rejected", "____/____/2026", ""),
        ("Lead Developer", "Khairul & Team", "Mobile Engineering", "Accepted / Rejected", "____/____/2026", ""),
    ]
    
    for idx, (r_role, r_name, r_org, r_status, r_date, r_sig) in enumerate(roles_sign):
        curr_r = r_sh + 1 + idx
        vals = [(r_role, bold_font), (r_name, regular_font), (r_org, regular_font), (r_status, regular_font), (r_date, align_center), (r_sig, regular_font)]
        for (cs, ce), (val, f_style) in zip(cols_sign, vals):
            if cs != ce:
                ws1.merge_cells(f"{cs}{curr_r}:{ce}{curr_r}")
            ws1[f"{cs}{curr_r}"] = val
            if isinstance(f_style, Font):
                ws1[f"{cs}{curr_r}"].font = f_style
                ws1[f"{cs}{curr_r}"].alignment = align_left if cs in ["B", "D", "E"] else align_center
            else:
                ws1[f"{cs}{curr_r}"].font = regular_font
                ws1[f"{cs}{curr_r}"].alignment = f_style
            col_list = [cs] if cs == ce else [cs, ce]
            for c in col_list:
                ws1[f"{c}{curr_r}"].border = cell_border

    # Adjust widths for Sheet 1
    ws1.column_dimensions["A"].width = 3
    ws1.column_dimensions["B"].width = 16
    ws1.column_dimensions["C"].width = 24
    ws1.column_dimensions["D"].width = 24
    ws1.column_dimensions["E"].width = 24
    ws1.column_dimensions["F"].width = 16
    ws1.column_dimensions["G"].width = 16
    ws1.column_dimensions["H"].width = 16
    ws1.column_dimensions["I"].width = 18

    # =============================================================
    # SHEET 2: DAFTAR TEST CASES (TEST CASES)
    # =============================================================
    ws2 = wb.create_sheet(title="Daftar Test Cases")
    ws2.views.sheetView[0].showGridLines = True
    
    # Title
    ws2.merge_cells("A1:J1")
    ws2["A1"] = "SKENARIO DETAIL PENGUJIAN USER ACCEPTANCE TEST (UAT)"
    ws2["A1"].font = title_font
    
    ws2.merge_cells("A2:J2")
    ws2["A2"] = "Petunjuk: Ubah kolom 'Status' menjadi Pass, Fail, Blocked, atau Untested. Catat temuan pada kolom 'Catatan Tester'."
    ws2["A2"].font = subtitle_font
    
    headers_tc = [
        ("No", 6),
        ("ID Test Case", 15),
        ("Modul / Fitur", 18),
        ("Skenario Pengujian", 30),
        ("Langkah-Langkah Pengujian (Test Steps)", 38),
        ("Data Uji (Test Data)", 22),
        ("Hasil Yang Diharapkan (Expected Result)", 38),
        ("Status", 13),
        ("Tingkat Prioritas", 14),
        ("Catatan Tester / Bukti", 30),
    ]
    
    header_row = 3
    for col_idx, (h_title, h_width) in enumerate(headers_tc, start=1):
        cell = ws2.cell(row=header_row, column=col_idx, value=h_title)
        cell.font = tbl_header_font
        cell.fill = primary_fill
        cell.alignment = align_header
        cell.border = cell_border
        col_letter = get_column_letter(col_idx)
        ws2.column_dimensions[col_letter].width = h_width

    # Test cases data tailored for WolfyCreativ Mobile
    test_cases = [
        # MODUL 1: AUTENTIKASI & KEAMANAN
        ("UAT-AUTH-001", "Autentikasi", "Login berhasil dengan akun valid", 
         "1. Buka aplikasi\n2. Masukkan email & password terdaftar\n3. Tekan tombol 'Masuk'",
         "Email: admin@wolfycreativ.com\nPass: admin123",
         "Aplikasi memverifikasi data ke Supabase, menampilkan notifikasi sukses, dan otomatis masuk ke Dashboard.",
         "Untested", "High"),
         
        ("UAT-AUTH-002", "Autentikasi", "Login gagal dengan password salah", 
         "1. Masukkan email terdaftar\n2. Masukkan password salah\n3. Tekan 'Masuk'",
         "Email: admin@wolfycreativ.com\nPass: salah123",
         "Muncul pesan error pemberitahuan bahwa kombinasi email atau password salah. Tetap di halaman login.",
         "Untested", "High"),
         
        ("UAT-AUTH-003", "Autentikasi", "Validasi format email tidak valid", 
         "1. Masukkan teks tanpa format email (contoh: userbiasa)\n2. Isi sembarang password\n3. Tekan 'Masuk'",
         "Email: userbiasa\nPass: 123456",
         "Muncul pesan validasi 'Format email tidak valid' sebelum request dikirim.",
         "Untested", "Medium"),
         
        ("UAT-AUTH-004", "Autentikasi", "Validasi field kosong saat submit", 
         "1. Kosongkan field email dan password\n2. Tekan tombol 'Masuk'",
         "Field kosong",
         "Muncul peringatan bahwa email dan password wajib diisi.",
         "Untested", "Medium"),
         
        ("UAT-AUTH-005", "Autentikasi", "Auto-login (Sesi aktif)", 
         "1. Login sukses\n2. Tutup aplikasi (swipe close)\n3. Buka kembali aplikasi",
         "Sesi login tersimpan",
         "Aplikasi langsung membuka Dashboard tanpa meminta login ulang.",
         "Untested", "High"),
         
        ("UAT-AUTH-006", "Autentikasi", "Logout aplikasi", 
         "1. Dari halaman profil/pengaturan, tekan tombol 'Keluar'\n2. Konfirmasi logout",
         "Akun login",
         "Sesi dihapus dari cache lokal dan user dialihkan kembali ke Halaman Login.",
         "Untested", "High"),
         
        # MODUL 2: DASHBOARD & NAVIGASI
        ("UAT-DASH-001", "Dashboard", "Tampilan ringkasan metrik usaha", 
         "1. Buka halaman Dashboard\n2. Amati kartu ringkasan (Total Order, Omset, Order Aktif)",
         "Data tersimpan di Supabase",
         "Metrik menampilkan angka akurat sesuai rekap data database real-time.",
         "Untested", "High"),
         
        ("UAT-DASH-002", "Dashboard", "Daftar pesanan terbaru (Recent Orders)", 
         "1. Scroll pada bagian 'Pesanan Terbaru'\n2. Periksa kesesuaian data",
         "5 pesanan paling baru",
         "Menampilkan daftar order terbaru beserta status pengerjaannya.",
         "Untested", "Medium"),
         
        ("UAT-DASH-003", "Dashboard", "Aksi Cepat (Quick Actions)", 
         "1. Klik tombol quick action 'Order Baru'\n2. Coba juga shortcut Keuangan & Layanan",
         "Tombol shortcut",
         "Setiap shortcut membuka layar fitur yang bersangkutan dengan responsif.",
         "Untested", "Medium"),
         
        ("UAT-DASH-004", "Navigasi", "Bottom Navigation Bar", 
         "1. Tekan ikon 'Pesanan'\n2. Tekan ikon 'Pelanggan'\n3. Tekan 'Kalender'\n4. Tekan 'Dashboard'",
         "Ikon navigasi bawah",
         "Navigasi berpindah halaman secara instan tanpa glitch visual atau reload berat.",
         "Untested", "High"),
         
        # MODUL 3: MANAJEMEN PESANAN (ORDERS)
        ("UAT-ORD-001", "Pesanan", "Lihat daftar seluruh pesanan", 
         "1. Masuk ke menu 'Pesanan'\n2. Periksa daftar pesanan yang tampil",
         "Semua data order",
         "Daftar pesanan termuat dengan informasi nama klien, layanan, harga, dan status.",
         "Untested", "High"),
         
        ("UAT-ORD-002", "Pesanan", "Filter pesanan berdasarkan status", 
         "1. Tekan tab filter (Menunggu, Diproses, Selesai, Dibatalkan)",
         "Status pesanan",
         "Daftar pesanan hanya menampilkan order yang sesuai dengan filter yang aktif.",
         "Untested", "High"),
         
        ("UAT-ORD-003", "Pesanan", "Pencarian pesanan", 
         "1. Masukkan kata kunci nama pelanggan atau nomor pesanan pada kolom search",
         "Keyword: 'Wolfy' / Nama klien",
         "Hasil pencarian menyaring daftar pesanan secara instan.",
         "Untested", "Medium"),
         
        ("UAT-ORD-004", "Pesanan", "Tambah pesanan baru (Create Order)", 
         "1. Tekan tombol '+' atau 'Tambah Pesanan'\n2. Pilih Pelanggan\n3. Pilih Layanan\n4. Isi Harga & Deadline\n5. Tekan Simpan",
         "Pelanggan: Klien A\nLayanan: Desain Logo\nHarga: Rp 1.500.000",
         "Data pesanan baru berhasil tersimpan ke database dan langsung muncul di daftar pesanan.",
         "Untested", "High"),
         
        ("UAT-ORD-005", "Pesanan", "Validasi form pesanan baru", 
         "1. Buka form pesanan baru\n2. Kosongkan pelanggan atau layanan\n3. Tekan Simpan",
         "Form tidak lengkap",
         "Muncul pesan peringatan error bahwa field wajib harus diisi sebelum simpan.",
         "Untested", "Medium"),
         
        ("UAT-ORD-006", "Pesanan", "Lihat detail pesanan", 
         "1. Klik salah satu item pesanan pada daftar\n2. Periksa informasi detail",
         "ID Order terpilih",
         "Halaman detail menampilkan rincian komplit: Klien, paket jasa, catatan revisi, deadline, dan tagihan.",
         "Untested", "High"),
         
        ("UAT-ORD-007", "Pesanan", "Update status pengerjaan pesanan", 
         "1. Pada detail pesanan, ubah status dari 'Diproses' ke 'Review / Selesai'\n2. Konfirmasi",
         "Status baru: Selesai",
         "Status terupdate di database, warna badge berubah, dan tercermin di Dashboard.",
         "Untested", "High"),
         
        ("UAT-ORD-008", "Pesanan", "Update status pembayaran", 
         "1. Ubah status bayar pesanan (Belum Lunas -> Lunas)\n2. Masukkan nominal pembayaran",
         "Nominal pelunasan",
         "Status pembayaran terupdate dan otomatis tercatat pada pencatatan keuangan.",
         "Untested", "High"),
         
        ("UAT-ORD-009", "Pesanan", "Edit informasi pesanan", 
         "1. Tekan tombol Edit pada detail pesanan\n2. Ubah catatan atau tanggal deadline\n3. Simpan perubahan",
         "Data revisi",
         "Perubahan tersimpan sukses dan detail pesanan diperbarui.",
         "Untested", "Medium"),
         
        ("UAT-ORD-010", "Pesanan", "Bagikan ringkasan pesanan (Share)", 
         "1. Pada detail pesanan, tekan ikon 'Share'\n2. Pilih WhatsApp atau salin teks",
         "Data ringkasan order",
         "Muncul dialog pemilih aplikasi Android untuk mengirimkan invoice/rincian ke pelanggan.",
         "Untested", "Medium"),
         
        # MODUL 4: MANAJEMEN PELANGGAN (CUSTOMERS)
        ("UAT-CUST-001", "Pelanggan", "Menampilkan direktori pelanggan", 
         "1. Buka tab 'Pelanggan'\n2. Periksa list nama, instansi, dan kontak",
         "Daftar pelanggan",
         "Seluruh pelanggan tampil rapi dengan avatar/inisial, no HP, dan ringkasan order.",
         "Untested", "High"),
         
        ("UAT-CUST-002", "Pelanggan", "Pencarian pelanggan", 
         "1. Ketik nama pelanggan pada kotak search di atas",
         "Keyword nama pelanggan",
         "Daftar terfilter menampilkan pelanggan yang cocok dengan keyword.",
         "Untested", "Medium"),
         
        ("UAT-CUST-003", "Pelanggan", "Tambah pelanggan baru", 
         "1. Tekan ikon tambah (+)\n2. Isi Nama, No HP WhatsApp, Email, Alamat\n3. Simpan",
         "Nama: Budi Santoso\nWA: 081234567890",
         "Pelanggan baru tersimpan dan dapat langsung dipilih saat membuat pesanan baru.",
         "Untested", "High"),
         
        ("UAT-CUST-004", "Pelanggan", "Lihat riwayat pesanan pelanggan", 
         "1. Klik salah satu pelanggan\n2. Buka tab riwayat pesanan",
         "ID Pelanggan",
         "Menampilkan daftar seluruh pesanan masa lalu dan aktif dari pelanggan tersebut beserta total belanja.",
         "Untested", "Medium"),
         
        ("UAT-CUST-005", "Pelanggan", "Kontak langsung via WhatsApp / Telepon", 
         "1. Pada profil pelanggan, tekan tombol 'WhatsApp' atau 'Telepon'",
         "Nomor HP valid",
         "Aplikasi membuka otomatis WhatsApp atau dialer HP dengan nomor tujuan pelanggan.",
         "Untested", "High"),
         
        ("UAT-CUST-006", "Pelanggan", "Edit data pelanggan", 
         "1. Buka profil pelanggan\n2. Tekan Edit\n3. Perbarui no HP atau email\n4. Simpan",
         "Perubahan data kontak",
         "Data kontak pelanggan terupdate di database.",
         "Untested", "Medium"),
         
        # MODUL 5: KALENDER & TENGGAT WAKTU (CALENDAR)
        ("UAT-CAL-001", "Kalender", "Tampilan jadwal deadline bulanan", 
         "1. Buka menu 'Kalender'\n2. Periksa penanda titik/tanda pada tanggal-tanggal tertentu",
         "Bulan berjalan",
         "Kalender menampilkan tanggal dengan indikator visual untuk hari yang memiliki deadline pesanan.",
         "Untested", "High"),
         
        ("UAT-CAL-002", "Kalender", "Seleksi tanggal untuk melihat jadwal", 
         "1. Ketuk tanggal yang memiliki penanda deadline\n2. Amati daftar di bagian bawah kalender",
         "Tanggal bertanda",
         "Daftar di bawah kalender menampilkan pesanan yang jatuh tempo pada tanggal tersebut.",
         "Untested", "High"),
         
        ("UAT-CAL-003", "Kalender", "Navigasi ganti bulan", 
         "1. Tekan panah kiri/kanan untuk berpindah bulan",
         "Bulan sebelumnya / berikutnya",
         "Kalender berganti bulan dengan mulus dan memuat jadwal pada bulan terkait.",
         "Untested", "Medium"),
         
        ("UAT-CAL-004", "Kalender", "Klik jadwal untuk buka detail pesanan", 
         "1. Ketuk salah satu item pesanan dari daftar kalender",
         "Item deadline",
         "Aplikasi langsung mengarahkan user ke halaman Detail Pesanan yang dipilih.",
         "Untested", "Medium"),
         
        # MODUL 6: LAYANAN & PRICING (SERVICES)
        ("UAT-SRV-001", "Layanan", "Katalog layanan kreatif", 
         "1. Buka menu 'Layanan'\n2. Periksa daftar paket jasa (Desain, Video, Branding, dll.)",
         "Katalog layanan",
         "Daftar paket layanan termuat lengkap dengan estimasi harga dasar dan deskripsi.",
         "Untested", "High"),
         
        ("UAT-SRV-002", "Layanan", "Tambah paket layanan baru", 
         "1. Tekan 'Tambah Layanan'\n2. Isi Nama Layanan, Kategori, Harga Standar\n3. Simpan",
         "Layanan: Social Media Management\nHarga: Rp 2.000.000",
         "Layanan baru tersimpan dan otomatis tersedia pada dropdown pemilihan layanan order.",
         "Untested", "Medium"),
         
        ("UAT-SRV-003", "Layanan", "Edit harga & deskripsi layanan", 
         "1. Pilih salah satu layanan\n2. Ubah harga standar\n3. Simpan perubahan",
         "Harga diperbarui",
         "Informasi paket layanan terupdate tanpa mempengaruhi order yang telah berjalan.",
         "Untested", "Medium"),
         
        # MODUL 7: KEUANGAN BISNIS (BUSINESS FINANCE)
        ("UAT-FIN-001", "Keuangan Bisnis", "Ringkasan cashflow studio", 
         "1. Masuk ke menu 'Keuangan Bisnis'\n2. Amati Total Pemasukan, Total Pengeluaran, Saldo Kas",
         "Data transaksi bisnis",
         "Nilai saldo dan laba bersih dihitung secara otomatis dengan benar.",
         "Untested", "High"),
         
        ("UAT-FIN-002", "Keuangan Bisnis", "Filter rentang waktu laporan", 
         "1. Pilih filter: 'Bulan Ini', 'Bulan Lalu', atau 'Kustom'",
         "Filter tanggal",
         "Rekap angka dan daftar transaksi menyesuaikan dengan rentang waktu yang dipilih.",
         "Untested", "Medium"),
         
        ("UAT-FIN-003", "Keuangan Bisnis", "Catat pengeluaran operasional baru", 
         "1. Tekan 'Tambah Pengeluaran'\n2. Masukkan Judul, Kategori (Alat/Sewa/Gaji), Nominal, Bukti Struk\n3. Simpan",
         "Judul: Langganan Adobe CC\nNominal: Rp 800.000",
         "Pengeluaran baru tersimpan, saldo kas otomatis berkurang, dan muncul di daftar mutasi.",
         "Untested", "High"),
         
        ("UAT-FIN-004", "Keuangan Bisnis", "Catat pemasukan non-pesanan", 
         "1. Tekan 'Tambah Pemasukan'\n2. Masukkan sumber pendapatan tambahan & nominal\n3. Simpan",
         "Judul: Royalti Aset\nNominal: Rp 500.000",
         "Pemasukan tercatat dan saldo kas otomatis bertambah.",
         "Untested", "Medium"),
         
        # MODUL 8: KEUANGAN PRIBADI & BIOMETRIK (PERSONAL FINANCE)
        ("UAT-PFIN-001", "Keuangan Pribadi", "Autentikasi Biometrik (Fingerprint/Face Unlock)", 
         "1. Ketuk menu 'Keuangan Pribadi'\n2. Amati prompt pemindai biometrik HP yang muncul\n3. Tempelkan sidik jari yang terdaftar",
         "Sidik jari valid",
         "Sensor biometrik mengenali sidik jari dan langsung membuka layar Keuangan Pribadi tanpa crash.",
         "Untested", "High"),
         
        ("UAT-PFIN-002", "Keuangan Pribadi", "Fallback autentikasi via PIN 6 Digit", 
         "1. Pada prompt biometrik, tekan 'Batal' atau 'Gunakan PIN'\n2. Masukkan PIN 6 digit yang benar\n3. Konfirmasi",
         "PIN: 6 digit valid",
         "Aplikasi memverifikasi hash PIN dan berhasil memberikan akses ke layar Keuangan Pribadi.",
         "Untested", "High"),
         
        ("UAT-PFIN-003", "Keuangan Pribadi", "Validasi input PIN salah", 
         "1. Masukkan PIN 6 digit yang salah\n2. Tekan konfirmasi",
         "PIN: 000000 (salah)",
         "Muncul pesan 'PIN salah, silakan coba lagi'. Akses tetap terkunci.",
         "Untested", "Medium"),
         
        ("UAT-PFIN-004", "Keuangan Pribadi", "Manajemen dompet/rekening pribadi", 
         "1. Tekan 'Tambah Dompet/Akun'\n2. Masukkan nama (misal: BCA / Cash / Gopay) & Saldo Awal\n3. Simpan",
         "Nama: BCA Pribadi\nSaldo: Rp 5.000.000",
         "Dompet baru terbentuk dan total kekayaan pribadi otomatis terakumulasi.",
         "Untested", "High"),
         
        ("UAT-PFIN-005", "Keuangan Pribadi", "Pencatatan mutasi transaksi pribadi", 
         "1. Tekan (+)\n2. Pilih Tipe (Pengeluaran/Pemasukan)\n3. Pilih Kategori (Gaji, Jajan, Tagihan, Belanja)\n4. Masukkan nominal & Simpan",
         "Kategori: Jajan\nNominal: Rp 50.000",
         "Transaksi tercatat, saldo dompet terkait otomatis terpotong.",
         "Untested", "High"),
         
        ("UAT-PFIN-006", "Keuangan Pribadi", "Auto-lock saat aplikasi diminimize", 
         "1. Buka Keuangan Pribadi\n2. Tekan Home di HP\n3. Buka kembali aplikasi WolfyCreativ",
         "Status latar belakang",
         "Layar Keuangan Pribadi terkunci kembali dan mewajibkan autentikasi sidik jari/PIN ulang.",
         "Untested", "Medium"),
         
        # MODUL 9: ANALITIK & LAPORAN
        ("UAT-ANA-001", "Analitik", "Grafik statistik pendapatan", 
         "1. Masuk ke menu 'Analitik'\n2. Periksa grafik tren pendapatan bulanan",
         "Data historis penjualan",
         "Grafik garis / batang (fl_chart) terender dengan rapi, interaktif saat titik grafik disentuh.",
         "Untested", "High"),
         
        ("UAT-ANA-002", "Analitik", "Statistik layanan paling laris (Top Services)", 
         "1. Scroll ke bawah pada halaman analitik\n2. Amati peringkat paket layanan",
         "Data order selesai",
         "Menampilkan daftar persentase kontribusi omset dari masing-masing jenis layanan.",
         "Untested", "Medium"),
         
        # MODUL 10: PENGUJIAN NON-FUNGSIONAL & APK
        ("UAT-NFR-001", "Non-Fungsional", "Instalasi file APK di smartphone Android", 
         "1. Kirim file app-release.apk ke HP Android fisik\n2. Klik file dan jalankan instalasi",
         "File: app-release.apk (~57.5 MB)",
         "Aplikasi berhasil terpasang di HP tanpa pesan 'App not installed' atau signature corrupt.",
         "Untested", "High"),
         
        ("UAT-NFR-002", "Non-Fungsional", "Penanganan mode offline / jaringan terputus", 
         "1. Matikan WiFi & Data Seluler di HP\n2. Buka aplikasi atau lakukan aksi simpan",
         "Kondisi Offline",
         "Aplikasi tidak force close, menampilkan snackbar / dialog peringatan koneksi terputus.",
         "Untested", "High"),
         
        ("UAT-NFR-003", "Non-Fungsional", "Responsivitas keyboard & ukuran layar HP", 
         "1. Buka form input (Order Baru atau Transaksi)\n2. Ketuk input paling bawah",
         "Keyboard virtual muncul",
         "Form otomatis bergeser ke atas (adjustResize) sehingga kolom input tidak tertutup keyboard.",
         "Untested", "Medium"),
         
        ("UAT-NFR-004", "Non-Fungsional", "Stabilitas memori & tidak terjadi ANR / crash", 
         "1. Navigasi bolak-balik antara semua menu dengan cepat selama 2 menit",
         "Navigasi intensif",
         "Aplikasi tetap responsif, tidak freeze (ANR), dan tidak force close.",
         "Untested", "High"),
    ]
    
    # Write test cases to sheet 2
    row_start = 4
    for i, tc in enumerate(test_cases, start=1):
        r_num = row_start + i - 1
        tc_id, mod, scen, steps, data, exp, status, priority = tc
        
        ws2.cell(row=r_num, column=1, value=i).alignment = align_center
        ws2.cell(row=r_num, column=2, value=tc_id).alignment = align_center
        ws2.cell(row=r_num, column=3, value=mod).alignment = align_left
        ws2.cell(row=r_num, column=4, value=scen).alignment = align_left
        ws2.cell(row=r_num, column=5, value=steps).alignment = align_left
        ws2.cell(row=r_num, column=6, value=data).alignment = align_left
        ws2.cell(row=r_num, column=7, value=exp).alignment = align_left
        
        status_cell = ws2.cell(row=r_num, column=8, value=status)
        status_cell.alignment = align_center
        status_cell.font = untested_font
        status_cell.fill = untested_fill
        
        prio_cell = ws2.cell(row=r_num, column=9, value=priority)
        prio_cell.alignment = align_center
        prio_cell.font = bold_font
        
        note_cell = ws2.cell(row=r_num, column=10, value="")
        note_cell.alignment = align_left
        
        # Apply zebra styling
        bg = zebra_fill if i % 2 == 0 else white_fill
        for c in range(1, 11):
            cell = ws2.cell(row=r_num, column=c)
            cell.border = cell_border
            if c != 8: # keep status cell style
                cell.font = regular_font if c not in [1, 2, 9] else bold_font
                if c != 9:
                    cell.fill = bg

    # Data Validation Dropdown for Status column (H)
    dv = DataValidation(type="list", formula1='"Pass,Fail,Blocked,Untested"', allow_blank=True)
    dv.error ='Nilai status harus salah satu dari: Pass, Fail, Blocked, Untested'
    dv.errorTitle = 'Pilihan Tidak Valid'
    ws2.add_data_validation(dv)
    dv.add(f"H4:H{row_start + len(test_cases) - 1}")

    # =============================================================
    # SHEET 3: LOG TEMUAN BUG & DEFECT
    # =============================================================
    ws3 = wb.create_sheet(title="Log Temuan Bug")
    ws3.views.sheetView[0].showGridLines = True
    
    ws3.merge_cells("A1:I1")
    ws3["A1"] = "LOG PENCATATAN BUG & DEFECT PENGUJIAN"
    ws3["A1"].font = title_font
    
    ws3.merge_cells("A2:I2")
    ws3["A2"] = "Daftar masalah/kendala yang ditemukan selama pengujian UAT untuk ditindaklanjuti oleh developer."
    ws3["A2"].font = subtitle_font
    
    headers_bug = [
        ("No", 6),
        ("ID Bug", 14),
        ("ID Test Case", 15),
        ("Modul", 18),
        ("Deskripsi Masalah (Actual Result)", 38),
        ("Tingkat Keparahan (Severity)", 18),
        ("Status Bug", 14),
        ("Bukti / Tangkapan Layar", 25),
        ("Tindakan / Catatan Developer", 32),
    ]
    
    r_bh = 3
    for col_idx, (b_title, b_width) in enumerate(headers_bug, start=1):
        cell = ws3.cell(row=r_bh, column=col_idx, value=b_title)
        cell.font = tbl_header_font
        cell.fill = primary_fill
        cell.alignment = align_header
        cell.border = cell_border
        col_letter = get_column_letter(col_idx)
        ws3.column_dimensions[col_letter].width = b_width

    # Pre-filled 10 blank defect rows ready for entry
    for b_idx in range(1, 16):
        r_b = r_bh + b_idx
        ws3.cell(row=r_b, column=1, value=b_idx).alignment = align_center
        ws3.cell(row=r_b, column=2, value=f"BUG-0{b_idx:02d}").alignment = align_center
        ws3.cell(row=r_b, column=3, value="").alignment = align_center
        ws3.cell(row=r_b, column=4, value="").alignment = align_left
        ws3.cell(row=r_b, column=5, value="").alignment = align_left
        ws3.cell(row=r_b, column=6, value="Medium").alignment = align_center
        ws3.cell(row=r_b, column=7, value="Open").alignment = align_center
        ws3.cell(row=r_b, column=8, value="").alignment = align_left
        ws3.cell(row=r_b, column=9, value="").alignment = align_left
        
        bg_b = zebra_fill if b_idx % 2 == 0 else white_fill
        for c in range(1, 10):
            cell = ws3.cell(row=r_b, column=c)
            cell.border = cell_border
            cell.fill = bg_b
            cell.font = regular_font

    # Data Validation for Bug Severity & Status
    dv_sev = DataValidation(type="list", formula1='"Critical,Major,Medium,Minor,Trivial"', allow_blank=True)
    ws3.add_data_validation(dv_sev)
    dv_sev.add(f"F4:F{r_bh + 15}")
    
    dv_bstat = DataValidation(type="list", formula1='"Open,In Progress,Resolved,Closed,Rejected"', allow_blank=True)
    ws3.add_data_validation(dv_bstat)
    dv_bstat.add(f"G4:G{r_bh + 15}")

    # =============================================================
    # SHEET 4: BERITA ACARA UAT (SIGN-OFF CERTIFICATE)
    # =============================================================
    ws4 = wb.create_sheet(title="Berita Acara UAT")
    ws4.views.sheetView[0].showGridLines = True
    
    ws4.merge_cells("B2:G2")
    ws4["B2"] = "BERITA ACARA USER ACCEPTANCE TESTING (UAT)"
    ws4["B2"].font = title_font
    ws4["B2"].alignment = align_center
    
    ws4.merge_cells("B3:G3")
    ws4["B3"] = "PENGUJIAN PENERIMAAN APLIKASI WOLFYCREATIV MOBILE"
    ws4["B3"].font = Font(name=font_family, size=11, bold=True, color="475569")
    ws4["B3"].alignment = align_center
    
    ws4.merge_cells("B5:G5")
    ws4["B5"] = "Pada hari ini, .......................... tanggal .......... bulan ........................ tahun 2026, telah diselesaikan rangkaian pengujian User Acceptance Testing (UAT) untuk sistem aplikasi mobile dengan rincian sebagai berikut:"
    ws4["B5"].font = regular_font
    ws4["B5"].alignment = Alignment(wrap_text=True, vertical="top")
    ws4.row_dimensions[5].height = 35
    
    specs = [
        ("Nama Aplikasi", "WolfyCreativ Mobile"),
        ("Tipe Aplikasi", "Mobile Client (Android Release APK)"),
        ("Versi Rilis", "1.0.0+1"),
        ("Lingkungan Uji", "Perangkat Smartphone Android Fisik"),
        ("Basis Data / Server", "Supabase PostgreSQL Production"),
    ]
    
    r_sp = 7
    for k, v in specs:
        ws4[f"B{r_sp}"] = k
        ws4[f"B{r_sp}"].font = bold_font
        ws4[f"B{r_sp}"].fill = light_blue_fill
        ws4[f"B{r_sp}"].border = cell_border
        
        ws4.merge_cells(f"C{r_sp}:G{r_sp}")
        ws4[f"C{r_sp}"] = v
        ws4[f"C{r_sp}"].font = regular_font
        for c in ["C", "D", "E", "F", "G"]:
            ws4[f"{c}{r_sp}"].border = cell_border
        r_sp += 1
        
    ws4.merge_cells("B13:G13")
    ws4["B13"] = "KESIMPULAN HASIL PENGUJIAN:"
    ws4["B13"].font = section_font
    ws4["B13"].fill = primary_fill
    ws4["B13"].alignment = align_left
    
    ws4.merge_cells("B14:G14")
    ws4["B14"] = "[   ]  DITERIMA TANPA CATATAN (Dapat langsung dirilis / dipublikasikan)"
    ws4["B14"].font = bold_font
    
    ws4.merge_cells("B15:G15")
    ws4["B15"] = "[   ]  DITERIMA DENGAN CATATAN (Dapat dirilis setelah bug minor diselesaikan)"
    ws4["B15"].font = bold_font
    
    ws4.merge_cells("B16:G16")
    ws4["B16"] = "[   ]  DITOLAK (Memerlukan perbaikan menyeluruh pada fungsi kritikal)"
    ws4["B16"].font = bold_font
    
    ws4.merge_cells("B18:G18")
    ws4["B18"] = "Catatan Tambahan Stakeholder:"
    ws4["B18"].font = bold_font
    
    ws4.merge_cells("B19:G21")
    ws4["B19"] = "..............................................................................................................................................................................................................................................................................................................................................................................................................................................................................................................................................................................................................."
    ws4["B19"].font = regular_font
    ws4["B19"].alignment = Alignment(wrap_text=True, vertical="top")
    for r in range(19, 22):
        for c in ["B", "C", "D", "E", "F", "G"]:
            ws4[f"{c}{r}"].border = cell_border
            
    # Signature Box
    r_sig_final = 23
    ws4.merge_cells(f"B{r_sig_final}:D{r_sig_final}")
    ws4[f"B{r_sig_final}"] = "Pihak Penguji / Klien\n\n\n\n\n( .................................................... )\nProduct Owner / Klien"
    ws4[f"B{r_sig_final}"].font = bold_font
    ws4[f"B{r_sig_final}"].alignment = align_center
    ws4.row_dimensions[r_sig_final].height = 100
    for c in ["B", "C", "D"]:
        ws4[f"{c}{r_sig_final}"].border = cell_border
        
    ws4.merge_cells(f"E{r_sig_final}:G{r_sig_final}")
    ws4[f"E{r_sig_final}"] = "Pihak Pengembang (Developer)\n\n\n\n\n( .................................................... )\nLead Mobile Engineer"
    ws4[f"E{r_sig_final}"].font = bold_font
    ws4[f"E{r_sig_final}"].alignment = align_center
    for c in ["E", "F", "G"]:
        ws4[f"{c}{r_sig_final}"].border = cell_border

    ws4.column_dimensions["A"].width = 3
    ws4.column_dimensions["B"].width = 20
    ws4.column_dimensions["C"].width = 20
    ws4.column_dimensions["D"].width = 20
    ws4.column_dimensions["E"].width = 20
    ws4.column_dimensions["F"].width = 20
    ws4.column_dimensions["G"].width = 20

    # Save workbook
    output_path = r"d:\PROJECT_WEBSITE\wolfycreativ_mobile\UAT_Testing_WolfyCreativ_Mobile.xlsx"
    wb.save(output_path)
    print(f"Successfully generated UAT Excel file at: {output_path}")

if __name__ == "__main__":
    create_uat_excel()
