import 'dart:math' as math;
import '../../analysis/domain/analysis.dart';
import 'risk.dart';

enum PositionState { pending, open, partiallyClosed, closed }

class Fill {
  final String key, reason;
  final double quantity, price, pnl;
  final int time;
  const Fill(
    this.key,
    this.reason,
    this.quantity,
    this.price,
    this.pnl,
    this.time,
  );
  Map<String, dynamic> toJson() => {
    'key': key,
    'reason': reason,
    'quantity': quantity,
    'price': price,
    'pnl': pnl,
    'time': time,
  };
}

class Position {
  final String id, exchange, symbol;
  final Direction side;
  final double entry, initialQuantity, initialStop;
  final List<double> targets;
  final int openedAt;
  double remaining, stop, pnl;
  int targetIndex;
  int lastMarkTime;
  PositionState state;
  final Set<String> eventKeys;
  Position({
    required this.id,
    required this.exchange,
    required this.symbol,
    required this.side,
    required this.entry,
    required this.initialQuantity,
    required this.stop,
    required this.targets,
    required this.openedAt,
    double? initialStop,
    double? remaining,
    this.pnl = 0,
    this.targetIndex = 0,
    this.lastMarkTime = 0,
    this.state = PositionState.pending,
    Set<String>? eventKeys,
  }) : remaining = remaining ?? initialQuantity,
       initialStop = initialStop ?? stop,
       eventKeys = eventKeys ?? {};
  double get sign => side == Direction.long ? 1 : -1;
  bool get active =>
      state == PositionState.open || state == PositionState.partiallyClosed;
  double get reserved => active ? remaining * entry : 0;
  double get risk => active
      ? remaining * ((entry - stop) * sign).clamp(0, double.infinity) +
            remaining * entry * .002
      : 0;
  void open() {
    if (state != PositionState.pending) throw StateError('invalid_transition');
    state = PositionState.open;
    pnl = -initialQuantity * entry * RiskEngine.fee;
  }

  double unrealized(double mark) => active
      ? (mark - entry) * sign * remaining - remaining * mark * RiskEngine.fee
      : 0;
  Fill? closePart(
    String key,
    double quantity,
    double mark,
    int time, {
    String reason = 'manual',
  }) {
    if (!active || eventKeys.contains(key)) return null;
    if (!quantity.isFinite ||
        !mark.isFinite ||
        quantity <= 0 ||
        quantity > remaining + 1e-10 ||
        mark <= 0) {
      throw ArgumentError('invalid_close');
    }
    final q = math.min(quantity, remaining);
    final fillPrice = mark * (1 - sign * RiskEngine.slippage);
    final delta =
        (fillPrice - entry) * sign * q - fillPrice * q * RiskEngine.fee;
    remaining -= q;
    pnl += delta;
    eventKeys.add(key);
    if (remaining <= initialQuantity * 1e-9) {
      remaining = 0;
      state = PositionState.closed;
    } else {
      state = PositionState.partiallyClosed;
    }
    return Fill(key, reason, q, fillPrice, delta, time);
  }

  List<Fill> onPrice(double mark, int time) {
    if (!active || !mark.isFinite || mark <= 0) return [];
    if ((mark - stop) * sign <= 0) {
      final f = closePart('$id:SL', remaining, mark, time, reason: 'SL');
      return f == null ? [] : [f];
    }
    final fills = <Fill>[];
    while (active &&
        targetIndex < targets.length &&
        (mark - targets[targetIndex]) * sign >= 0) {
      final i = targetIndex;
      final q = i == targets.length - 1
          ? remaining
          : math.min(initialQuantity / 3, remaining);
      // Conservative target fill, never award a gap's entire price improvement.
      final f = closePart(
        '$id:TP${i + 1}',
        q,
        targets[i],
        time,
        reason: 'TP${i + 1}',
      );
      if (f != null) fills.add(f);
      targetIndex++;
      if (i == 0) stop = entry;
    }
    return fills;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'exchange': exchange,
    'symbol': symbol,
    'side': side.name,
    'entry': entry,
    'initialQuantity': initialQuantity,
    'initialStop': initialStop,
    'stop': stop,
    'remaining': remaining,
    'targets': targets,
    'openedAt': openedAt,
    'pnl': pnl,
    'targetIndex': targetIndex,
    'lastMarkTime': lastMarkTime,
    'state': state.name,
    'events': eventKeys.toList(),
  };
  factory Position.fromJson(Map<String, dynamic> m) => Position(
    id: m['id'],
    exchange: m['exchange'],
    symbol: m['symbol'],
    side: Direction.values.byName(m['side']),
    entry: (m['entry'] as num).toDouble(),
    initialQuantity: (m['initialQuantity'] as num).toDouble(),
    initialStop: (m['initialStop'] as num).toDouble(),
    stop: (m['stop'] as num).toDouble(),
    remaining: (m['remaining'] as num).toDouble(),
    targets: (m['targets'] as List).map((v) => (v as num).toDouble()).toList(),
    openedAt: m['openedAt'],
    pnl: (m['pnl'] as num).toDouble(),
    targetIndex: m['targetIndex'],
    lastMarkTime: m['lastMarkTime'] ?? 0,
    state: PositionState.values.byName(m['state']),
    eventKeys: Set<String>.from(m['events']),
  );
}
