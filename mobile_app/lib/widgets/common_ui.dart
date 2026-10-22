import 'package:flutter/material.dart';
import '../theme/savebite_theme.dart';

/// Shared building blocks used across the student and vendor flows so every
/// screen presents information the same professional way.
///
/// Everything here is presentation-only — it takes data and callbacks from the
/// calling screen and makes no network or navigation decisions of its own
/// (the CTA buttons simply call whatever the screen passes in).

/// A titled section with an accent icon and an optional trailing pill
/// ("20 live", "View all", etc.) — used above every content block.
class SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? trailing;
  final Color? iconColor;
  final Color? pillColor;
  final VoidCallback? onTrailingTap;

  const SectionHeader({
    super.key,
    required this.icon,
    required this.title,
    this.trailing,
    this.iconColor,
    this.pillColor,
    this.onTrailingTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: (iconColor ?? SaveBiteTheme.tealPrimary).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(icon, size: 19, color: iconColor ?? SaveBiteTheme.tealPrimary),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: SaveBiteTheme.title(size: 17),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 8),
          InkWell(
            onTap: onTrailingTap,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: (pillColor ?? SaveBiteTheme.tealPrimary).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                trailing!,
                style: SaveBiteTheme.body(
                  size: 12,
                  w: FontWeight.w700,
                  color: pillColor ?? SaveBiteTheme.tealPrimary,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// A soft pulsing rectangle that stands in for content while data loads —
/// used instead of a bare spinner so the layout never "jumps" when data
/// arrives. Deliberately dependency-free (no shimmer package).
class LoadingSkeleton extends StatefulWidget {
  final double height;
  final double? width;
  final BorderRadius? borderRadius;

  const LoadingSkeleton({
    super.key,
    required this.height,
    this.width,
    this.borderRadius,
  });

  @override
  State<LoadingSkeleton> createState() => _LoadingSkeletonState();
}

class _LoadingSkeletonState extends State<LoadingSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.45, end: 1.0).animate(
        CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
      ),
      child: Container(
        height: widget.height,
        width: widget.width,
        decoration: BoxDecoration(
          color: SaveBiteTheme.creamWarm,
          borderRadius: widget.borderRadius ?? BorderRadius.circular(SaveBiteTheme.radiusL),
        ),
      ),
    );
  }
}

/// A full deal-card-sized skeleton used while the Discover feed loads.
class DealCardSkeleton extends StatelessWidget {
  const DealCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: SaveBiteTheme.white,
        borderRadius: BorderRadius.circular(SaveBiteTheme.radiusL),
        border: Border.all(color: SaveBiteTheme.border.withValues(alpha: 0.5)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LoadingSkeleton(
            height: 148,
            borderRadius: BorderRadius.vertical(top: Radius.circular(SaveBiteTheme.radiusL)),
          ),
          Padding(
            padding: EdgeInsets.all(18),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      LoadingSkeleton(height: 12, width: 130, borderRadius: BorderRadius.all(Radius.circular(6))),
                      SizedBox(height: 8),
                      LoadingSkeleton(height: 16, width: 180, borderRadius: BorderRadius.all(Radius.circular(6))),
                      SizedBox(height: 8),
                      LoadingSkeleton(height: 12, width: 100, borderRadius: BorderRadius.all(Radius.circular(6))),
                    ],
                  ),
                ),
                SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    LoadingSkeleton(height: 12, width: 44, borderRadius: BorderRadius.all(Radius.circular(6))),
                    SizedBox(height: 8),
                    LoadingSkeleton(height: 22, width: 64, borderRadius: BorderRadius.all(Radius.circular(6))),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A single order-card-shaped skeleton for the Pickups screen.
class OrderCardSkeleton extends StatelessWidget {
  const OrderCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: SaveBiteTheme.white,
        borderRadius: BorderRadius.circular(SaveBiteTheme.radiusL),
        border: Border.all(color: SaveBiteTheme.tealPrimary.withValues(alpha: 0.2)),
      ),
      child: const Column(
        children: [
          LoadingSkeleton(
            height: 52,
            borderRadius: BorderRadius.vertical(top: Radius.circular(SaveBiteTheme.radiusL)),
          ),
          Padding(
            padding: EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      LoadingSkeleton(height: 18, width: 150, borderRadius: BorderRadius.all(Radius.circular(6))),
                      SizedBox(height: 10),
                      LoadingSkeleton(height: 12, width: 110, borderRadius: BorderRadius.all(Radius.circular(6))),
                      SizedBox(height: 14),
                      LoadingSkeleton(height: 42, borderRadius: BorderRadius.all(Radius.circular(12))),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Friendly empty state with an optional customer-facing CTA.
class AppEmptyState extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String? ctaLabel;
  final IconData? ctaIcon;
  final VoidCallback? onCta;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  const AppEmptyState({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.ctaLabel,
    this.ctaIcon,
    this.onCta,
    this.secondaryLabel,
    this.onSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 42, color: iconColor),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: SaveBiteTheme.display(size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: SaveBiteTheme.body(size: 13, color: SaveBiteTheme.textMuted),
            ),
            if (ctaLabel != null && onCta != null) ...[
              const SizedBox(height: 22),
              ElevatedButton.icon(
                onPressed: onCta,
                icon: Icon(ctaIcon ?? Icons.arrow_forward_rounded, size: 18),
                label: Text(ctaLabel!, style: const TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: SaveBiteTheme.tealPrimary,
                  foregroundColor: SaveBiteTheme.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(SaveBiteTheme.radiusM),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                ),
              ),
            ],
            if (secondaryLabel != null && onSecondary != null) ...[
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: onSecondary,
                style: OutlinedButton.styleFrom(
                  foregroundColor: SaveBiteTheme.tealPrimary,
                  side: const BorderSide(color: SaveBiteTheme.tealPrimary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(SaveBiteTheme.radiusM),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: Text(secondaryLabel!, style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Distinct failure state so a network problem never looks like an empty feed.
class AppErrorState extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback onRetry;

  const AppErrorState({
    super.key,
    required this.message,
    required this.onRetry,
    this.title = 'Couldn\'t load this right now',
  });

  @override
  Widget build(BuildContext context) {
    return AppEmptyState(
      icon: Icons.wifi_off_rounded,
      iconColor: SaveBiteTheme.warmAmber,
      title: title,
      subtitle: message,
      ctaLabel: 'Try again',
      ctaIcon: Icons.refresh_rounded,
      onCta: onRetry,
    );
  }
}

/// A compact horizontal flow indicator — “1 Reserved ✓ › 2 Pay › 3 Collect” —
/// so customers always know where they are in the rescue journey.
class FlowStepper extends StatelessWidget {
  final List<String> steps;
  final int currentStep;

  const FlowStepper({super.key, required this.steps, required this.currentStep});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: SaveBiteTheme.white,
        borderRadius: BorderRadius.circular(SaveBiteTheme.radiusL),
        border: Border.all(color: SaveBiteTheme.border.withValues(alpha: 0.6)),
      ),
      child: Row(
        children: List.generate(steps.length * 2 - 1, (i) {
          if (i.isOdd) {
            return Expanded(
              child: Container(
                height: 2,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                color: (i ~/ 2) < currentStep
                    ? SaveBiteTheme.tealPrimary
                    : SaveBiteTheme.border,
              ),
            );
          }
          final stepIndex = i ~/ 2;
          final done = stepIndex < currentStep;
          final active = stepIndex == currentStep;
          final color = done || active
              ? SaveBiteTheme.tealPrimary
              : SaveBiteTheme.textMuted.withValues(alpha: 0.55);
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: done || active ? SaveBiteTheme.tealPrimary : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(color: color, width: 2),
                ),
                child: Center(
                  child: done
                      ? const Icon(Icons.check_rounded,
                          size: 15, color: SaveBiteTheme.white)
                      : Text(
                          '${stepIndex + 1}',
                          style: SaveBiteTheme.body(
                            size: 11,
                            w: FontWeight.w800,
                            color: active ? SaveBiteTheme.white : color,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                steps[stepIndex],
                style: SaveBiteTheme.body(
                  size: 11,
                  w: done || active ? FontWeight.w800 : FontWeight.w600,
                  color: active ? SaveBiteTheme.charcoal : SaveBiteTheme.textMuted,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}
