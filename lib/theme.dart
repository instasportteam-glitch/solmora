import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/physics.dart';

import 'models.dart';

/// Base colors: the night of Olympus, gold, and a fiery call-to-action.
class Olymp {
  static const bg = Color(0xFF09080F);
  static const surface = Color(0x14FFFFFF);
  static const surfaceStrong = Color(0x24FFFFFF);
  static const stroke = Color(0x22FFFFFF);
  static const gold = Color(0xFFF1C25B);
  static const goldDeep = Color(0xFFB9822C);
  static const textPrimary = Color(0xFFF7F3EA);
  static const textSecondary = Color(0xB8F7F3EA);
  static const textTertiary = Color(0x73F7F3EA);
  static const success = Color(0xFF5EE38B);
  static const danger = Color(0xFFFF5A4E);
  static const bar = Color(0xB309080F);

  /// Orange-to-red gradient of the primary button.
  static const cta = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFF58A2C), Color(0xFFDD4A1F)],
  );

  static const goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFE29A), Color(0xFFF1C25B), Color(0xFFB9822C)],
  );

  /// Serif display face for large titles and numbers.
  static const serif = 'Georgia';
}

class GodPalette {
  final GodSide side;
  final Color primary;
  final Color deep;
  final Color glow;
  final String god;
  final String title;
  final String path;
  final String emoji;
  final String realm;

  const GodPalette._({
    required this.side,
    required this.primary,
    required this.deep,
    required this.glow,
    required this.god,
    required this.title,
    required this.path,
    required this.emoji,
    required this.realm,
  });

  static const zeus = GodPalette._(
    side: GodSide.zeus,
    primary: Color(0xFF5CC8FF),
    deep: Color(0xFF14306E),
    glow: Color(0xFFB8ECFF),
    god: 'Sol',
    title: 'God of Light',
    path: 'Easy path',
    emoji: '⚡',
    realm: 'the Sun',
  );

  static const hades = GodPalette._(
    side: GodSide.hades,
    primary: Color(0xFFFF8A2A),
    deep: Color(0xFF4A0F06),
    glow: Color(0xFFFFC56B),
    god: 'Mora',
    title: 'God of Darkness',
    path: 'Hard path',
    emoji: '🔥',
    realm: 'the Night',
  );

  static GodPalette of(GodSide s) => s == GodSide.zeus ? zeus : hades;

  LinearGradient get gradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [glow, primary, deep],
        stops: const [0, 0.45, 1],
      );
}

/// A spring in Apple's terms: damping ratio (1.0 = no overshoot) and response
/// (seconds to reach the target), converted to Flutter's mass/stiffness/damping.
SpringDescription appleSpring({double response = 0.35, double damping = 1.0}) {
  final k = math.pow(2 * math.pi / response, 2).toDouble();
  return SpringDescription(mass: 1, stiffness: k, damping: 2 * damping * math.sqrt(k));
}

/// Typography: negative tracking and tight leading for large text,
/// near-zero tracking for body copy.
class OT {
  static TextStyle display(double size, {Color color = Olymp.textPrimary, FontWeight weight = FontWeight.w700}) =>
      TextStyle(
        fontFamily: Olymp.serif,
        fontSize: size,
        fontWeight: weight,
        height: 1.05,
        letterSpacing: -0.02 * size,
        color: color,
      );

  static const title = TextStyle(
      fontSize: 20, fontWeight: FontWeight.w700, letterSpacing: -0.45, height: 1.2, color: Olymp.textPrimary);
  static const headline = TextStyle(
      fontSize: 17, fontWeight: FontWeight.w600, letterSpacing: -0.35, height: 1.25, color: Olymp.textPrimary);
  static const body = TextStyle(
      fontSize: 15, fontWeight: FontWeight.w400, letterSpacing: -0.15, height: 1.4, color: Olymp.textSecondary);
  static const subhead = TextStyle(
      fontSize: 14, fontWeight: FontWeight.w500, letterSpacing: -0.1, height: 1.3, color: Olymp.textSecondary);
  static const caption = TextStyle(
      fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.6, height: 1.2, color: Olymp.textTertiary);
}
