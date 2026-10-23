import 'dart:math' as math;
import '../../market/domain/models.dart';

/// Aligned arrays; warmup is NaN, never fabricated zeros. Wilder smoothing.
class Indicators {
  static List<double> sma(List<double> a, int n) => List.generate(
    a.length,
    (i) => i < n - 1
        ? double.nan
        : a.sublist(i - n + 1, i + 1).reduce((a, b) => a + b) / n,
  );
  static List<double> smooth(List<double> a, int n, double alpha) {
    final out = List<double>.filled(a.length, double.nan);
    if (a.length < n) return out;
    out[n - 1] = a.take(n).reduce((a, b) => a + b) / n;
    for (var i = n; i < a.length; i++) {
      out[i] = alpha * a[i] + (1 - alpha) * out[i - 1];
    }
    return out;
  }

  static List<double> ema(List<double> a, int n) => smooth(a, n, 2 / (n + 1));
  static List<double> rsi(List<double> a, [int n = 14]) {
    final out = List<double>.filled(a.length, double.nan);
    if (a.length <= n) return out;
    final gains = <double>[], losses = <double>[];
    for (var i = 1; i < a.length; i++) {
      final d = a[i] - a[i - 1];
      gains.add(math.max(d, 0));
      losses.add(math.max(-d, 0));
    }
    final g = smooth(gains, n, 1 / n), l = smooth(losses, n, 1 / n);
    for (var i = n; i < a.length; i++) {
      out[i] = l[i - 1] == 0
          ? (g[i - 1] == 0 ? 50 : 100)
          : 100 - 100 / (1 + g[i - 1] / l[i - 1]);
    }
    return out;
  }

  static Map<String, List<double>> all(List<Candle> c) {
    final a = c.map((e) => e.close).toList(), count = c.length;
    final e12 = ema(a, 12),
        e26 = ema(a, 26),
        macd = List.generate(count, (i) => e12[i] - e26[i]);
    final sig = List<double>.filled(count, double.nan);
    if (count > 25) {
      final v = ema(macd.sublist(25), 9);
      for (var i = 25; i < count; i++) {
        sig[i] = v[i - 25];
      }
    }
    final tr = <double>[], plus = <double>[], minus = <double>[];
    for (var i = 0; i < count; i++) {
      tr.add(
        i == 0
            ? c[i].high - c[i].low
            : math.max(
                c[i].high - c[i].low,
                math.max(
                  (c[i].high - c[i - 1].close).abs(),
                  (c[i].low - c[i - 1].close).abs(),
                ),
              ),
      );
      final up = i == 0 ? 0.0 : c[i].high - c[i - 1].high,
          down = i == 0 ? 0.0 : c[i - 1].low - c[i].low;
      plus.add(up > down && up > 0 ? up : 0);
      minus.add(down > up && down > 0 ? down : 0);
    }
    final atr = smooth(tr, 14, 1 / 14),
        p = smooth(plus, 14, 1 / 14),
        m = smooth(minus, 14, 1 / 14);
    final dx = List.generate(
      count,
      (i) => i < 13
          ? double.nan
          : (p[i] + m[i] == 0
                ? 0.0
                : 100 * (p[i] - m[i]).abs() / (p[i] + m[i])),
    );
    final adx = List<double>.filled(count, double.nan);
    if (count > 13) {
      final v = smooth(dx.sublist(13), 14, 1 / 14);
      for (var i = 13; i < count; i++) {
        adx[i] = v[i - 13];
      }
    }
    final mid = sma(a, 20),
        upper = <double>[],
        lower = <double>[],
        vwap = <double>[],
        stoch = <double>[];
    double pv = 0, vol = 0;
    int day = -1;
    for (var i = 0; i < count; i++) {
      if (i < 19) {
        upper.add(double.nan);
        lower.add(double.nan);
      } else {
        final sd = math.sqrt(
          a
                  .sublist(i - 19, i + 1)
                  .map((v) => math.pow(v - mid[i], 2))
                  .reduce((a, b) => a + b) /
              20,
        );
        upper.add(mid[i] + 2 * sd);
        lower.add(mid[i] - 2 * sd);
      }
      final d = c[i].time ~/ 86400000;
      if (d != day) {
        day = d;
        pv = 0;
        vol = 0;
      }
      pv += (c[i].high + c[i].low + c[i].close) / 3 * c[i].volume;
      vol += c[i].volume;
      vwap.add(vol > 0 ? pv / vol : double.nan);
      if (i < 13) {
        stoch.add(double.nan);
      } else {
        final w = c.sublist(i - 13, i + 1),
            h = w.map((v) => v.high).reduce(math.max),
            l = w.map((v) => v.low).reduce(math.min);
        stoch.add(h == l ? 50 : 100 * (a[i] - l) / (h - l));
      }
    }
    final stochD = List<double>.filled(count, double.nan);
    if (count > 13) {
      final s = sma(stoch.sublist(13), 3);
      for (var i = 13; i < count; i++) {
        stochD[i] = s[i - 13];
      }
    }
    return {
      'EMA 20': ema(a, 20),
      'EMA 50': ema(a, 50),
      'SMA 20': mid,
      'RSI': rsi(a),
      'MACD': macd,
      'MACD signal': sig,
      'ATR': atr,
      'BB upper': upper,
      'BB lower': lower,
      'ADX': adx,
      'VWAP': vwap,
      'Stoch K': stoch,
      'Stoch D': stochD,
    };
  }
}
