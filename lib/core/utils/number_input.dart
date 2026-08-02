/// Kullanıcının yazdığı sayıyı okur.
///
/// Türkçe klavyede ondalık ayracı virgül olduğu için hem "7,5" hem "7.5"
/// kabul edilir — çiftçi hangi tuşa bastığını düşünmek zorunda kalmasın.
double? parseDecimalInput(String? raw) {
  final text = raw?.trim().replaceAll(',', '.') ?? '';
  if (text.isEmpty) return null;
  final value = double.tryParse(text);
  if (value == null || value.isNaN || value.isInfinite) return null;
  return value;
}

/// Tam sayı okur (sorti adedi, dakika gibi bölünmeyen değerler için).
int? parseIntInput(String? raw) {
  final text = raw?.trim() ?? '';
  if (text.isEmpty) return null;
  return int.tryParse(text);
}
