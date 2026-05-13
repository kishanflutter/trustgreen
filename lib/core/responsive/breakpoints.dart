/// Width-based breakpoints per §2.1 of the rebuild spec.
///
/// * compact   — width < 600   (most phones)
/// * medium    — 600 <= width < 900 (small tablets, large foldables)
/// * expanded  — width >= 900   (large tablets, desktops)
enum Breakpoint { compact, medium, expanded }

extension BreakpointX on Breakpoint {
  bool get isCompact => this == Breakpoint.compact;
  bool get isMediumOrUp => this != Breakpoint.compact;
  bool get isExpanded => this == Breakpoint.expanded;
}

class Breakpoints {
  Breakpoints._();

  static const double medium = 600;
  static const double expanded = 900;

  /// Max width for the *primary column* (forms, action stacks). Caps
  /// onboarding / wallet content around the reference design.
  static const double primaryColumn = 480;

  /// Max width for content blocks (cards, lists). Slightly wider than
  /// the primary column.
  static const double contentColumn = 560;

  static Breakpoint of(double width) {
    if (width >= expanded) return Breakpoint.expanded;
    if (width >= medium) return Breakpoint.medium;
    return Breakpoint.compact;
  }
}
