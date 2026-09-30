import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_skin.dart';

/// Custom numeric keypad for fast amount entry.
class AmountPad extends StatelessWidget {
  final ValueChanged<String> onKey; // digits, '.', 'del'
  const AmountPad({super.key, required this.onKey});

  static const _keys = [
    '1', '2', '3',
    '4', '5', '6',
    '7', '8', '9',
    '.', '0', 'del',
  ];

  @override
  Widget build(BuildContext context) {
    final skin = context.skin;
    final bg = skin.card;
    final fg = skin.text;
    final shape = RoundedRectangleBorder(
      borderRadius: skin.controlRadius,
      side: skin.controlBorder.a == 0 ? BorderSide.none : BorderSide(color: skin.cardBorder),
    );

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 1.9,
      ),
      itemCount: _keys.length,
      itemBuilder: (context, i) {
        final k = _keys[i];
        final isDel = k == 'del';
        return Material(
          color: bg,
          shape: shape,
          child: InkWell(
            customBorder: shape,
            onTap: () {
              HapticFeedback.lightImpact();
              onKey(k);
            },
            onLongPress: isDel
                ? () {
                    HapticFeedback.mediumImpact();
                    onKey('clear');
                  }
                : null,
            child: Center(
              child: isDel
                  ? Icon(Icons.backspace_outlined, color: fg, size: 22)
                  : Text(
                      k,
                      style: skin.amount(size: 22, color: fg, weight: FontWeight.w500),
                    ),
            ),
          ),
        );
      },
    );
  }
}
