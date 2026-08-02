import 'package:flutter/material.dart';

/// baibars marka renkleri — CT110 datasheet kimliğinden.
///
/// Bu dosya markanın tek doğruluk kaynağıdır; ekranlarda doğrudan
/// hex değeri kullanmayın, buradaki sabitleri kullanın.
abstract final class BaibarsColors {
  /// baibars mavisi — birincil marka rengi.
  static const Color blue = Color(0xFF1F4788);

  /// Koyu yeşil — ikincil yüzeyler (datasheet kimliği).
  static const Color deepGreen = Color(0xFF1B4D3E);

  /// Lime vurgu — ilerleme, başarı ve öne çıkan öğeler.
  static const Color lime = Color(0xFFB5D334);

  // Trafik ışığı sağlık durumları:
  // yeşil = uçuşa hazır, sarı = kontrol yaklaşıyor, kırmızı = uçma, önce kontrol.
  static const Color statusReady = Color(0xFF2E7D32);
  static const Color statusDue = Color(0xFFF9A825);
  static const Color statusGrounded = Color(0xFFC62828);
}
