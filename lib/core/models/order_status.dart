import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

enum OrderStatus {
  baru('baru', 'Baru', AppColors.statusBaru),
  proses('proses', 'Proses', AppColors.statusProses),
  preview('preview', 'Preview', AppColors.statusPreview),
  revisi('revisi', 'Revisi', AppColors.statusRevisi),
  settingFile('setting_file', 'Setting File', AppColors.statusSettingFile),
  selesai('selesai', 'Selesai', AppColors.statusSelesai),
  batal('batal', 'Batal', AppColors.statusBatal);

  final String value;
  final String label;
  final Color color;

  const OrderStatus(this.value, this.label, this.color);

  static OrderStatus fromString(String? val) {
    if (val == null) return OrderStatus.baru;
    return OrderStatus.values.firstWhere(
      (e) => e.value == val,
      orElse: () => OrderStatus.baru,
    );
  }
}
