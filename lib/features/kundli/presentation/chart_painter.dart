import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../domain/kundli.dart';
 
/// Renders a traditional North-Indian (diamond) Rasi chart.
/// Houses are fixed diamonds; the lagna sits in the top-centre house and signs
/// rotate accordingly. Planet abbreviations are placed in their houses.
class NorthChartPainter extends CustomPainter {
  NorthChartPainter(this.kundli);
  final Kundli kundli;
 
  static const _abbr = {
    Planet.sun: 'Su', Planet.moon: 'Mo', Planet.mars: 'Ma',
    Planet.mercury: 'Me', Planet.jupiter: 'Ju', Planet.venus: 'Ve',
    Planet.saturn: 'Sa', Planet.rahu: 'Ra', Planet.ketu: 'Ke',
  };
 
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final line = Paint()
      ..color = AppTheme.maroon
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke;
 
    // Outer square + the two diagonals + the inner diamond.
    final rect = Rect.fromLTWH(0, 0, w, h);
    canvas.drawRect(rect, line);
    canvas.drawLine(Offset(0, 0), Offset(w, h), line);
    canvas.drawLine(Offset(w, 0), Offset(0, h), line);
    final mid = [
      Offset(w / 2, 0),
      Offset(w, h / 2),
      Offset(w / 2, h),
      Offset(0, h / 2),
    ];
    final diamond = Path()
      ..moveTo(mid[0].dx, mid[0].dy)
      ..lineTo(mid[1].dx, mid[1].dy)
      ..lineTo(mid[2].dx, mid[2].dy)
      ..lineTo(mid[3].dx, mid[3].dy)
      ..close();
    canvas.drawPath(diamond, line);
 
    // Centre point of each of the 12 houses (house 1 at top centre).
    final cx = w / 2, cy = h / 2;
    final centres = <Offset>[
      Offset(cx, cy * 0.5), // 1
      Offset(cx * 0.5, cy * 0.45), // 2
      Offset(cx * 0.45, cy * 0.5), // 3
      Offset(cx * 0.5, cy), // 4
      Offset(cx * 0.45, cy * 1.5), // 5
      Offset(cx * 0.5, cy * 1.55), // 6
      Offset(cx, cy * 1.5), // 7
      Offset(cx * 1.5, cy * 1.55), // 8
      Offset(cx * 1.55, cy * 1.5), // 9
      Offset(cx * 1.5, cy), // 10
      Offset(cx * 1.55, cy * 0.5), // 11
      Offset(cx * 1.5, cy * 0.45), // 12
    ];
 
    for (var house = 1; house <= 12; house++) {
      final signIndex = (kundli.lagnaSign + house - 1) % 12;
      final centre = centres[house - 1];
 
      // Sign number (1..12 in Vedic North chart shows the rashi number).
      _text(
        canvas,
        '${signIndex + 1}',
        centre.translate(0, -16),
        const TextStyle(
          color: AppTheme.gold,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      );
 
      final occupants = kundli.inSign(signIndex);
      if (occupants.isNotEmpty) {
        final label = occupants
            .map((p) => '${_abbr[p.planet]}${p.retrograde ? "ᴿ" : ""}')
            .join(' ');
        _text(
          canvas,
          label,
          centre.translate(0, 4),
          const TextStyle(
            color: AppTheme.maroon,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        );
      }
    }
  }
 
  void _text(Canvas canvas, String s, Offset center, TextStyle style) {
    final tp = TextPainter(
      text: TextSpan(text: s, style: style),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout(maxWidth: 90);
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }
 
  @override
  bool shouldRepaint(NorthChartPainter old) => old.kundli != kundli;
}
