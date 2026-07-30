import 'package:flutter/material.dart';

/// Life OS's visual identity is "the astrolabe": a brass measuring
/// instrument held against a midnight sky — a nod to the historical Arabic
/// tradition of precision timekeeping and geometric instruments, which is
/// exactly what this app *is* (an instrument for measuring and organizing a
/// life). Warm brass + deep indigo, not another blue/purple SaaS gradient.
///
/// Six named colors, used consistently everywhere instead of scattering
/// hex literals through the codebase:
class AppColors {
  AppColors._();

  /// Deep night-sky indigo — the dark-mode canvas.
  static const Color midnight = Color(0xFF12172B);

  /// Aged brass — the signature accent (buttons, active states, the
  /// instrument "needle"). This is the seed for anything derived.
  static const Color brass = Color(0xFFC9A253);

  /// Lapis lazuli blue — secondary accent, historically the pigment used in
  /// illuminated manuscripts alongside brass instruments.
  static const Color lapis = Color(0xFF2A4374);

  /// Warm parchment — the light-mode canvas (never stark white).
  static const Color parchment = Color(0xFFFAF6EC);

  /// Warm near-black ink — light-mode text.
  static const Color ink = Color(0xFF1E2233);

  /// Warm ivory — dark-mode text. Deliberately not pure white, so it stays
  /// in the same warm family as brass/parchment instead of reading cold.
  static const Color ivory = Color(0xFFEDE7D9);

  /// Muted sage — success / completion states (goals hit, tasks done).
  static const Color sage = Color(0xFF6B9080);

  /// Warm terracotta — reserved for alarms, deletion, and errors only. Used
  /// sparingly and deliberately so it keeps its urgency.
  static const Color signal = Color(0xFFC0533E);

  // Priority accents (Tasks / Goals) — derived tints, not random colors.
  static const Color priorityLow = sage;
  static const Color priorityMedium = brass;
  static const Color priorityHigh = signal;

  // A small rotating palette offered when the user picks a note/alarm/goal
  // color tag — kept inside the same family so nothing clashes.
  static const List<Color> tagPalette = [
    brass,
    lapis,
    sage,
    signal,
    Color(0xFF7A5C9E), // muted amethyst
    Color(0xFF3E7C8C), // muted teal
    Color(0xFF9C6B47), // warm terracotta-brown
    Color(0xFF6B7280), // neutral slate
  ];
}
