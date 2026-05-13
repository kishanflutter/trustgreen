import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'breakpoints.dart';

/// Reference width used for fluid typography. Picked to fall between
/// the iPhone-style (390) and Android-style (360) reference widths
/// in §2.2 of the spec.
const double kReferenceWidth = 390;

/// Returns a [BuildContext]-derived helper exposing breakpoint, fluid
/// scale, and a max content column width.
class Responsive {
  Responsive._(this.size, this.textScaler);

  final Size size;
  final TextScaler textScaler;

  factory Responsive.of(BuildContext context) {
    final mq = MediaQuery.of(context);
    return Responsive._(mq.size, mq.textScaler);
  }

  Breakpoint get breakpoint => Breakpoints.of(size.width);

  bool get isCompact => breakpoint.isCompact;
  bool get isMediumOrUp => breakpoint.isMediumOrUp;
  bool get isExpanded => breakpoint.isExpanded;

  /// Scale a base typographic size *downwards* on narrow phones and
  /// hold it steady on wider devices. Capped so small phones never
  /// overflow and tablets never look toy-sized.
  double font(double base, {double minScale = 0.85, double maxScale = 1.1}) {
    final raw = base * (size.width / kReferenceWidth);
    final clamped = raw.clamp(base * minScale, base * maxScale);
    return clamped.toDouble();
  }

  /// Max width for the primary column (forms, CTAs). Returns a value
  /// the caller can hand to [ConstrainedBox] / [SizedBox].
  double primaryColumnWidth() =>
      math.min(size.width, Breakpoints.primaryColumn);

  double contentColumnWidth() =>
      math.min(size.width, Breakpoints.contentColumn);

  /// True if the user has scaled text 1.3× or more — used to switch
  /// to vertically stacked layouts where horizontal space tightens.
  bool get isLargeTextScale => textScaler.scale(14) >= 14 * 1.3;
}

/// Centers and width-caps [child] for the primary column on wide
/// screens. Pass-through on compact (width < 600).
class PrimaryColumn extends StatelessWidget {
  const PrimaryColumn({
    super.key,
    required this.child,
    this.maxWidth = Breakpoints.primaryColumn,
    this.padding,
  });

  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    Widget content = ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: child,
    );
    if (padding != null) content = Padding(padding: padding!, child: content);
    return Align(alignment: Alignment.topCenter, child: content);
  }
}

/// Same as [PrimaryColumn] but for slightly wider content blocks
/// (cards, lists).
class ContentColumn extends StatelessWidget {
  const ContentColumn({
    super.key,
    required this.child,
    this.maxWidth = Breakpoints.contentColumn,
    this.padding,
  });

  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    Widget content = ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: child,
    );
    if (padding != null) content = Padding(padding: padding!, child: content);
    return Align(alignment: Alignment.topCenter, child: content);
  }
}
