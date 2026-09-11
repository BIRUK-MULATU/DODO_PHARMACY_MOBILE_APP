import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'dp_logo.dart';
import 'press_scale.dart';

enum DpButtonStyle { dark, yellow, outline, green }

/// The chunky pill button used everywhere in the design. Optionally carries the
/// DP mark on the left. Includes a press-scale and an idle shimmer.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.style = DpButtonStyle.dark,
    this.withLogo = false,
    this.trailingIcon,
    this.expand = true,
    this.height = 62,
  });

  final String label;
  final VoidCallback? onPressed;
  final DpButtonStyle style;
  final bool withLogo;
  final IconData? trailingIcon;
  final bool expand;
  final double height;

  @override
  Widget build(BuildContext context) {
    late Color bg;
    late Color fg;
    Border? border;
    switch (style) {
      case DpButtonStyle.dark:
        bg = AppColors.ink;
        fg = AppColors.yellow;
        break;
      case DpButtonStyle.yellow:
        bg = AppColors.yellow;
        fg = AppColors.ink;
        border = Border.all(color: AppColors.ink, width: 2);
        break;
      case DpButtonStyle.outline:
        bg = Colors.transparent;
        fg = AppColors.ink;
        border = Border.all(color: AppColors.ink, width: 2);
        break;
      case DpButtonStyle.green:
        bg = AppColors.success;
        fg = AppColors.yellow;
        break;
    }

    return PressScale(
      onTap: onPressed,
      enabled: onPressed != null,
      child: Opacity(
        opacity: onPressed == null ? 0.55 : 1,
        child: Container(
          height: height,
          width: expand ? double.infinity : null,
          padding: const EdgeInsets.symmetric(horizontal: 22),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(height / 2),
            border: border,
            boxShadow: [
              if (style != DpButtonStyle.outline)
                BoxShadow(
                  color: AppColors.ink.withValues(alpha: 0.18),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
            ],
          ),
          child: Row(
            mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (withLogo) ...[
                DpLogo(size: height * 0.5, color: fg),
                const SizedBox(width: 14),
              ],
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: fg,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (trailingIcon != null) ...[
                const SizedBox(width: 10),
                Icon(trailingIcon, color: fg, size: 22),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
