import 'package:flutter_test/flutter_test.dart';
import 'package:spendcraft/core/utils/money_format.dart';

void main() {
  setUp(() => MoneyFormat.symbol = '₹');

  group('MoneyFormat.rupee — Indian 2,2,3 grouping', () {
    test('small numbers have no separators', () {
      expect(MoneyFormat.rupee(0), '₹0');
      expect(MoneyFormat.rupee(999), '₹999');
    });

    test('thousands', () {
      expect(MoneyFormat.rupee(1000), '₹1,000');
      expect(MoneyFormat.rupee(12345), '₹12,345');
      expect(MoneyFormat.rupee(99999), '₹99,999');
    });

    test('lakhs', () {
      expect(MoneyFormat.rupee(100000), '₹1,00,000');
      expect(MoneyFormat.rupee(150000), '₹1,50,000');
      expect(MoneyFormat.rupee(1234567), '₹12,34,567');
    });

    test('crores', () {
      expect(MoneyFormat.rupee(10000000), '₹1,00,00,000');
      expect(MoneyFormat.rupee(12000000), '₹1,20,00,000');
      expect(MoneyFormat.rupee(123456789), '₹12,34,56,789');
    });

    test('negatives and decimals', () {
      expect(MoneyFormat.rupee(-150000), '-₹1,50,000');
      expect(MoneyFormat.rupee(1234.5, showDecimals: true), '₹1,234.50');
      expect(MoneyFormat.rupee(1234.56), '₹1,234');
    });

    test('custom symbol', () {
      MoneyFormat.symbol = '\$';
      expect(MoneyFormat.rupee(150000), '\$1,50,000');
      expect(MoneyFormat.rupee(150000, withSymbol: false), '1,50,000');
    });
  });

  group('MoneyFormat.compact', () {
    test('below 1K', () => expect(MoneyFormat.compact(950), '₹950'));
    test('thousands', () {
      expect(MoneyFormat.compact(1000), '₹1K');
      expect(MoneyFormat.compact(12500), '₹12.5K');
    });
    test('lakhs', () {
      expect(MoneyFormat.compact(150000), '₹1.5L');
      expect(MoneyFormat.compact(100000), '₹1L');
    });
    test('crores', () {
      expect(MoneyFormat.compact(12000000), '₹1.2Cr');
      expect(MoneyFormat.compact(10000000), '₹1Cr');
    });
    test('negative', () => expect(MoneyFormat.compact(-150000), '-₹1.5L'));
  });
}
