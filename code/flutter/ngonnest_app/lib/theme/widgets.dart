import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

// ========================================
// DESIGN SYSTEM COMPONENTS (US-2.6)
// ========================================

enum ButtonVariant { primary, secondary, danger, icon }

enum ButtonSize { small, medium, large }

class AppButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final ButtonVariant variant;
  final ButtonSize size;
  final bool disabled;
  final bool fullWidth;
  final IconData? icon;
  final String? text;

  const AppButton({
    super.key,
    required this.child,
    this.onPressed,
    this.variant = ButtonVariant.primary,
    this.size = ButtonSize.medium,
    this.disabled = false,
    this.fullWidth = false,
    this.icon,
    this.text,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    // Color schemes based on design system
    Color getBackgroundColor(ButtonVariant variant) {
      if (disabled) return theme.disabledColor;

      switch (variant) {
        case ButtonVariant.primary:
          return const Color(0xFF22C55E); // Green
        case ButtonVariant.secondary:
          return isDarkMode ? const Color(0xFF374151) : const Color(0xFFF3F4F6);
        case ButtonVariant.danger:
          return const Color(0xFFEF4444); // Red
        case ButtonVariant.icon:
          return Colors.transparent;
      }
    }

    Color getTextColor(ButtonVariant variant) {
      if (disabled) return theme.disabledColor;

      switch (variant) {
        case ButtonVariant.primary:
          return Colors.white;
        case ButtonVariant.secondary:
          return isDarkMode ? Colors.white : const Color(0xFF374151);
        case ButtonVariant.danger:
          return Colors.white;
        case ButtonVariant.icon:
          return const Color(0xFF6B7280);
      }
    }

    double getFontSize(ButtonSize size) {
      switch (size) {
        case ButtonSize.small:
          return 14;
        case ButtonSize.medium:
          return 16;
        case ButtonSize.large:
          return 18;
      }
    }

    EdgeInsetsGeometry getPadding(ButtonSize size, ButtonVariant variant) {
      if (variant == ButtonVariant.icon) {
        return const EdgeInsets.all(8);
      }

      switch (size) {
        case ButtonSize.small:
          return const EdgeInsets.symmetric(horizontal: 12, vertical: 8);
        case ButtonSize.medium:
          return const EdgeInsets.symmetric(horizontal: 20, vertical: 12);
        case ButtonSize.large:
          return const EdgeInsets.symmetric(horizontal: 24, vertical: 16);
      }
    }

    BorderRadius getBorderRadius(ButtonVariant variant) {
      return variant == ButtonVariant.icon
          ? BorderRadius.circular(8)
          : BorderRadius.circular(12);
    }

    Widget buttonContent = child;

    // If text and icon provided, create combined layout
    if (text != null && icon != null) {
      buttonContent = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: getFontSize(size) + 2),
          const SizedBox(width: 8),
          Text(text!, style: TextStyle(fontSize: getFontSize(size))),
        ],
      );
    } else if (text != null) {
      buttonContent = Text(
        text!,
        style: TextStyle(fontSize: getFontSize(size)),
      );
    } else if (icon != null) {
      buttonContent = Icon(icon, size: getFontSize(size) + 4);
    }

    return SizedBox(
      width: fullWidth ? double.infinity : null,
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: disabled ? null : onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: getPadding(size, variant),
          decoration: BoxDecoration(
            color: getBackgroundColor(variant),
            borderRadius: getBorderRadius(variant),
            border: variant == ButtonVariant.secondary
                ? Border.all(
                    color: isDarkMode
                        ? const Color(0xFF4B5563)
                        : const Color(0xFFE5E7EB),
                    width: 1,
                  )
                : null,
          ),
          child: DefaultTextStyle(
            style: TextStyle(
              color: getTextColor(variant),
              fontSize: getFontSize(size),
              fontWeight: FontWeight.w600,
            ),
            child: buttonContent,
          ),
        ),
      ),
    );
  }
}

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;
  final BorderRadiusGeometry? borderRadius;
  final BoxBorder? border;
  final List<BoxShadow>? boxShadow;
  final VoidCallback? onTap;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.backgroundColor,
    this.borderRadius,
    this.border,
    this.boxShadow,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    final defaultBackground = isDarkMode
        ? const Color(0xFF1F2937)
        : Colors.white;
    final defaultShadow = [
      BoxShadow(
        color: Colors.black.withValues(alpha: isDarkMode ? 0.2 : 0.1),
        blurRadius: 8,
        offset: const Offset(0, 4),
      ),
    ];

    final cardWidget = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor ?? defaultBackground,
        borderRadius: borderRadius ?? BorderRadius.circular(12),
        border:
            border ??
            (isDarkMode
                ? Border.all(color: const Color(0xFF374151), width: 1)
                : null),
        boxShadow: boxShadow ?? defaultShadow,
      ),
      child: child,
    );

    if (onTap != null) {
      return CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: onTap,
        child: cardWidget,
      );
    }

    return cardWidget;
  }
}

class Toast extends StatefulWidget {
  final String message;
  final ToastType type;
  final VoidCallback? onClose;
  final Duration? duration;

  const Toast({
    super.key,
    required this.message,
    this.type = ToastType.info,
    this.onClose,
    this.duration = const Duration(seconds: 3),
  });

  @override
  State<Toast> createState() => _ToastState();
}

enum ToastType { success, error, warning, info }

class _ToastState extends State<Toast> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, -1), end: Offset.zero).animate(
          CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
        );

    _animationController.forward();

    if (widget.duration != null) {
      Future.delayed(widget.duration!, () {
        if (mounted) {
          _dismiss();
        }
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _dismiss() {
    _animationController.reverse().then((_) {
      widget.onClose?.call();
    });
  }

  @override
  Widget build(BuildContext context) {
    Color getBackgroundColor() {
      switch (widget.type) {
        case ToastType.success:
          return const Color(0xFF22C55E);
        case ToastType.error:
          return const Color(0xFFEF4444);
        case ToastType.warning:
          return const Color(0xFFF59E0B);
        case ToastType.info:
          return const Color(0xFF3B82F6);
      }
    }

    IconData getIcon() {
      switch (widget.type) {
        case ToastType.success:
          return CupertinoIcons.checkmark_circle_fill;
        case ToastType.error:
          return CupertinoIcons.exclamationmark_triangle_fill;
        case ToastType.warning:
          return CupertinoIcons.exclamationmark_triangle;
        case ToastType.info:
          return CupertinoIcons.info_circle_fill;
      }
    }

    return Positioned(
      top: MediaQuery.of(context).padding.top + 16,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Material(
            color: Colors.transparent,
            child: AppCard(
              padding: const EdgeInsets.all(12),
              backgroundColor: getBackgroundColor(),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
              child: Row(
                children: [
                  Icon(getIcon(), color: Colors.white, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.message,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  if (widget.onClose != null)
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: _dismiss,
                      child: const Icon(
                        CupertinoIcons.xmark,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Overlay for showing toasts
class ToastOverlay extends StatefulWidget {
  final Widget child;
  final List<Toast> toasts;

  const ToastOverlay({super.key, required this.child, this.toasts = const []});

  @override
  State<ToastOverlay> createState() => _ToastOverlayState();
}

class _ToastOverlayState extends State<ToastOverlay> {
  List<Toast> _currentToasts = [];

  @override
  void didUpdateWidget(ToastOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.toasts != oldWidget.toasts) {
      setState(() {
        _currentToasts = widget.toasts;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_currentToasts.isNotEmpty)
          ..._currentToasts.map(
            (toast) => Positioned(
              key: ValueKey(toast.message + DateTime.now().toString()),
              top: 0,
              left: 0,
              right: 0,
              child: toast,
            ),
          ),
      ],
    );
  }
}

// Utility widget for category icons based on name
class CategoryIcon extends StatelessWidget {
  final String category;
  final double size;
  final Color? color;

  const CategoryIcon({
    super.key,
    required this.category,
    this.size = 24,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    IconData getCategoryIcon(String category) {
      switch (category.toLowerCase()) {
        case 'hygiene':
        case 'hygiène':
          return CupertinoIcons.drop_fill;
        case 'cleaning':
        case 'nettoyage':
          return CupertinoIcons.bubble_left_bubble_right_fill;
        case 'kitchen':
        case 'cuisine':
          return CupertinoIcons.wand_rays;
        case 'durable':
        case 'durables':
          return CupertinoIcons.tv_fill;
        default:
          return CupertinoIcons.cube_box;
      }
    }

    Color getCategoryColor(BuildContext context) {
      if (color != null) return color!;

      final isDark = Theme.of(context).brightness == Brightness.dark;
      switch (category.toLowerCase()) {
        case 'hygiene':
        case 'hygiène':
          return const Color(0xFF22C55E); // Green
        case 'cleaning':
        case 'nettoyage':
          return const Color(0xFF3B82F6); // Blue
        case 'kitchen':
        case 'cuisine':
          return const Color(0xFFF59E0B); // Amber
        case 'durable':
        case 'durables':
          return const Color(0xFF8B5CF6); // Purple
        default:
          return isDark ? Colors.white : const Color(0xFF6B7280);
      }
    }

    return Icon(
      getCategoryIcon(category),
      size: size,
      color: getCategoryColor(context),
    );
  }
}

// Progress bar widget for various uses
class AppProgressBar extends StatelessWidget {
  final double value; // 0.0 to 1.0
  final double? height;
  final Color? backgroundColor;
  final Color? progressColor;
  final BorderRadiusGeometry? borderRadius;

  const AppProgressBar({
    super.key,
    required this.value,
    this.height = 4,
    this.backgroundColor,
    this.progressColor,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bgColor =
        backgroundColor ??
        (isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB));
    final progColor = progressColor ?? const Color(0xFF22C55E);

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: borderRadius ?? BorderRadius.circular(height! / 2),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: value.clamp(0.0, 1.0),
        child: Container(
          decoration: BoxDecoration(
            color: progColor,
            borderRadius: borderRadius ?? BorderRadius.circular(height! / 2),
          ),
        ),
      ),
    );
  }
}
