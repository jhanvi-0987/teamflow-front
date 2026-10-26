import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class AppButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isSecondary;
  final IconData? icon;
  final bool isCompact;
  final bool isDanger;

  const AppButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isSecondary = false,
    this.icon,
    this.isCompact = false,
    this.isDanger = false,
  });

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDisabled = widget.isLoading || widget.onPressed == null;

    if (widget.isSecondary) {
      return AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        ),
        child: GestureDetector(
          onTapDown: isDisabled ? null : (_) => _controller.forward(),
          onTapUp: isDisabled ? null : (_) => _controller.reverse(),
          onTapCancel: isDisabled ? null : () => _controller.reverse(),
          child: OutlinedButton(
            onPressed: isDisabled ? null : widget.onPressed,
            style: OutlinedButton.styleFrom(
              foregroundColor: widget.isDanger ? AppColors.error : AppColors.primary,
              side: BorderSide(
                color: widget.isDanger
                    ? AppColors.error.withValues(alpha: 0.4)
                    : AppColors.border,
                width: 1.5,
              ),
              minimumSize: widget.isCompact
                  ? const Size(0, 44)
                  : const Size.fromHeight(54),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: _buildChild(context),
          ),
        ),
      );
    }

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) => Transform.scale(
        scale: _scaleAnimation.value,
        child: child,
      ),
      child: GestureDetector(
        onTapDown: isDisabled ? null : (_) => _controller.forward(),
        onTapUp: isDisabled ? null : (_) => _controller.reverse(),
        onTapCancel: isDisabled ? null : () => _controller.reverse(),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            boxShadow: isDisabled ? null : AppColors.buttonShadow,
          ),
          child: ElevatedButton(
            onPressed: isDisabled ? null : widget.onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  widget.isDanger ? AppColors.error : AppColors.primary,
              minimumSize: widget.isCompact
                  ? const Size(0, 44)
                  : const Size.fromHeight(54),
            ),
            child: _buildChild(context),
          ),
        ),
      ),
    );
  }

  Widget _buildChild(BuildContext context) {
    if (widget.isLoading) {
      return SizedBox(
        height: 22,
        width: 22,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          valueColor: AlwaysStoppedAnimation<Color>(
            widget.isSecondary ? AppColors.primary : Colors.white,
          ),
        ),
      );
    }

    if (widget.icon != null) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(widget.icon, size: 18),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              widget.text,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      );
    }

    return Text(widget.text);
  }
}

/// Animated wrapper that rebuilds on animation value changes.
class AnimatedBuilder extends StatelessWidget {
  final Animation<double> animation;
  final Widget Function(BuildContext context, Widget? child) builder;
  final Widget? child;

  const AnimatedBuilder({
    super.key,
    required this.animation,
    required this.builder,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder2(
      animation: animation,
      builder: builder,
      child: child,
    );
  }
}

class AnimatedBuilder2 extends AnimatedWidget {
  final Widget Function(BuildContext context, Widget? child) builder;
  final Widget? child;

  const AnimatedBuilder2({
    super.key,
    required Animation<double> animation,
    required this.builder,
    this.child,
  }) : super(listenable: animation);

  @override
  Widget build(BuildContext context) {
    return builder(context, child);
  }
}
