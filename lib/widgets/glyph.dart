import 'package:flutter/material.dart';

import '../models/enums.dart';
import 'modality_style.dart';

class Glyph extends StatelessWidget {
  final Modality modality;
  final double size;

  const Glyph({super.key, required this.modality, this.size = 18});

  @override
  Widget build(BuildContext context) {
    final style = modalityStyle(modality);
    return Container(
      width: size + 16,
      height: size + 16,
      decoration: BoxDecoration(color: style.tint, shape: BoxShape.circle),
      child: Icon(style.icon, size: size, color: style.color),
    );
  }
}
