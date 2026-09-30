class MoneyFormat {
  static String symbol = '₹';

  /// 150000 -> "₹1,50,000" (Indian 2,2,3 grouping).
  static String rupee(num v, {bool withSymbol = true, bool showDecimals = false}) {
    final neg = v < 0;
    final abs = v.abs();
    final whole = abs.truncate();
    final grouped = _indianGroup(whole.toString());
    var result = grouped;
    if (showDecimals) {
      final decimals = ((abs - whole) * 100).round().toString().padLeft(2, '0');
      result = '$grouped.$decimals';
    }
    final sign = neg ? '-' : '';
    return '$sign${withSymbol ? symbol : ''}$result';
  }

  /// 150000 -> "₹1.5L", 12000000 -> "₹1.2Cr".
  static String compact(num v, {bool withSymbol = true}) {
    final neg = v < 0;
    final abs = v.abs();
    final sign = neg ? '-' : '';
    final s = withSymbol ? symbol : '';
    if (abs >= 10000000) {
      return '$sign$s${_trim(abs / 10000000)}Cr';
    } else if (abs >= 100000) {
      return '$sign$s${_trim(abs / 100000)}L';
    } else if (abs >= 1000) {
      return '$sign$s${_trim(abs / 1000)}K';
    }
    return '$sign$s${abs.toStringAsFixed(0)}';
  }

  static String _trim(double v) {
    final s = v.toStringAsFixed(1);
    return s.endsWith('.0') ? s.substring(0, s.length - 2) : s;
  }

  /// Applies the Indian grouping pattern (last 3 digits, then groups of 2).
  static String _indianGroup(String digits) {
    if (digits.length <= 3) return digits;
    final last3 = digits.substring(digits.length - 3);
    var rest = digits.substring(0, digits.length - 3);
    final groups = <String>[];
    while (rest.length > 2) {
      groups.insert(0, rest.substring(rest.length - 2));
      rest = rest.substring(0, rest.length - 2);
    }
    if (rest.isNotEmpty) groups.insert(0, rest);
    return '${groups.join(',')},$last3';
  }
}
