import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../domain/models.dart';
import '../../analysis/domain/indicators.dart';
import '../../../core/presentation/design.dart';

class CandleChart extends StatefulWidget {
  final List<Candle> candles;
  const CandleChart(this.candles, {super.key});
  @override
  State<CandleChart> createState() => _CandleChartState();
}

class _CandleChartState extends State<CandleChart> {
  int count = 45, offset = 0;
  double? cursor;
  double base = 45;
  @override
  Widget build(BuildContext context) {
    if (widget.candles.isEmpty) {
      return const SizedBox(height: 220, child: Center(child: Text('—')));
    }
    final end = math.max(
          1,
          widget.candles.length - offset.clamp(0, widget.candles.length - 1),
        ),
        start = math.max(0, end - count);
    final c = widget.candles.sublist(start, end);
    final ema = Indicators.ema(
      widget.candles.map((e) => e.close).toList(),
      20,
    ).sublist(start, end);
    final idx = cursor == null
        ? null
        : (cursor! * (c.length)).floor().clamp(0, c.length - 1);
    final item = idx == null ? c.last : c[idx];
    return Semantics(
      label:
          'Candlestick chart. Pinch to zoom, drag to pan, long press for OHLC.',
      child: Column(
        children: [
          Directionality(
            textDirection: TextDirection.ltr,
            child: Wrap(
              spacing: 12,
              children: [
                Text(
                  'O ${price(item.open)}',
                  style: const TextStyle(
                    fontFamily: 'Vazirmatn',
                    fontSize: 9,
                    color: muted,
                  ),
                ),
                Text(
                  'H ${price(item.high)}',
                  style: const TextStyle(
                    fontFamily: 'Vazirmatn',
                    fontSize: 9,
                    color: mint,
                  ),
                ),
                Text(
                  'L ${price(item.low)}',
                  style: const TextStyle(
                    fontFamily: 'Vazirmatn',
                    fontSize: 9,
                    color: red,
                  ),
                ),
                Text(
                  'C ${price(item.close)}',
                  style: const TextStyle(
                    fontFamily: 'Vazirmatn',
                    fontSize: 9,
                    color: muted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, box) => GestureDetector(
              onScaleStart: (_) {
                base = count.toDouble();
              },
              onScaleUpdate: (d) {
                setState(() {
                  if (d.scale != 1) {
                    count = (base / d.scale).round().clamp(15, 150);
                  } else {
                    offset = (offset - d.focalPointDelta.dx ~/ 4).clamp(
                      0,
                      math.max(0, widget.candles.length - count),
                    );
                  }
                });
              },
              onLongPressStart: (d) => setState(
                () => cursor = (d.localPosition.dx / (box.maxWidth - 62)).clamp(
                  0,
                  1,
                ),
              ),
              onLongPressMoveUpdate: (d) => setState(
                () => cursor = (d.localPosition.dx / (box.maxWidth - 62)).clamp(
                  0,
                  1,
                ),
              ),
              onLongPressEnd: (_) => setState(() => cursor = null),
              child: SizedBox(
                height: 235,
                width: double.infinity,
                child: CustomPaint(painter: _Painter(c, ema, idx)),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Directionality(
            textDirection: TextDirection.ltr,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _time(c.first.time),
                  style: const TextStyle(
                    fontFamily: 'Vazirmatn',
                    color: muted,
                    fontSize: 10,
                  ),
                ),
                const Text(
                  '— EMA 20   ▥ Volume',
                  style: TextStyle(
                    fontFamily: 'Vazirmatn',
                    color: blue,
                    fontSize: 10,
                  ),
                ),
                Text(
                  _time(c.last.time),
                  style: const TextStyle(
                    fontFamily: 'Vazirmatn',
                    color: muted,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _time(int t) {
    final d = DateTime.fromMillisecondsSinceEpoch(t, isUtc: true);
    return '${d.day}/${d.month} ${d.hour.toString().padLeft(2, '0')}:00';
  }
}

class _Painter extends CustomPainter {
  final List<Candle> c;
  final List<double> ema;
  final int? cursor;
  _Painter(this.c, this.ema, this.cursor);
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width - 62, h = size.height - 48;
    var lo = c.map((e) => e.low).reduce(math.min),
        hi = c.map((e) => e.high).reduce(math.max);
    final pad = math.max((hi - lo) * .12, hi * .001);
    lo -= pad;
    hi += pad;
    double y(double p) => h - (p - lo) / (hi - lo) * h;
    final paint = Paint()..strokeWidth = 1;
    for (var i = 0; i < 5; i++) {
      final yp = h * i / 4;
      paint.color = line.withValues(alpha: .8);
      canvas.drawLine(Offset(0, yp), Offset(w, yp), paint);
      final text = TextPainter(
        text: TextSpan(
          text: price(hi - (hi - lo) * i / 4),
          style: const TextStyle(
            fontFamily: 'Vazirmatn',
            color: muted,
            fontSize: 9,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: 60);
      text.paint(canvas, Offset(w + 7, yp - 5));
    }
    final step = w / c.length,
        maxV = math.max(1.0, c.map((e) => e.volume).reduce(math.max));
    final path = Path();
    bool begun = false;
    for (var i = 0; i < c.length; i++) {
      final e = c[i],
          x = (i + .5) * step,
          color = e.close >= e.open ? mint : red;
      paint.color = color;
      paint.strokeWidth = 1;
      canvas.drawLine(Offset(x, y(e.high)), Offset(x, y(e.low)), paint);
      canvas.drawRect(
        Rect.fromLTWH(
          x - step * .3,
          math.min(y(e.open), y(e.close)),
          math.max(1, step * .6),
          math.max(1, (y(e.open) - y(e.close)).abs()),
        ),
        paint,
      );
      paint.color = color.withValues(alpha: .25);
      canvas.drawRect(
        Rect.fromLTWH(
          x - step * .3,
          size.height - e.volume / maxV * 32,
          step * .6,
          e.volume / maxV * 32,
        ),
        paint,
      );
      if (ema[i].isFinite) {
        if (!begun) {
          path.moveTo(x, y(ema[i]));
          begun = true;
        } else {
          path.lineTo(x, y(ema[i]));
        }
      }
    }
    paint
      ..color = blue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    canvas.drawPath(path, paint);
    paint.style = PaintingStyle.fill;
    if (cursor != null) {
      final x = (cursor! + .5) * step;
      paint.color = Colors.white.withValues(alpha: .4);
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
      canvas.drawCircle(Offset(x, y(c[cursor!].close)), 3, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _Painter old) => true;
}
