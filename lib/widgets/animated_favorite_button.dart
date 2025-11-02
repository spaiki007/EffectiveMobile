import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class AnimatedFavoriteButton extends HookWidget {
  final bool isFavorite;
  final VoidCallback onPressed;
  final double size;
  final Color? activeColor;
  final Color? inactiveColor;

  const AnimatedFavoriteButton({
    super.key,
    required this.isFavorite,
    required this.onPressed,
    this.size = 30,
    this.activeColor,
    this.inactiveColor,
  });

  @override
  Widget build(BuildContext context) {
    final animationController = useAnimationController(
      duration: const Duration(milliseconds: 400),
    );

    final scaleAnimation = useAnimation(
      Tween<double>(begin: 1.0, end: 1.3).animate(
        CurvedAnimation(
          parent: animationController,
          curve: Curves.elasticOut,
        ),
      ),
    );

    final rotationAnimation = useAnimation(
      Tween<double>(begin: 0.0, end: 0.2).animate(
        CurvedAnimation(
          parent: animationController,
          curve: Curves.easeInOut,
        ),
      ),
    );

    // Запускаем анимацию при изменении состояния
    useEffect(() {
      if (isFavorite) {
        animationController.forward().then((_) {
          animationController.reverse();
        });
      }
      return null;
    }, [isFavorite]);

    return GestureDetector(
      onTap: onPressed,
      child: Transform.scale(
        scale: scaleAnimation,
        child: Transform.rotate(
          angle: rotationAnimation,
          child: Icon(
            isFavorite ? Icons.star : Icons.star_border,
            color: isFavorite
                ? (activeColor ?? Colors.amber)
                : (inactiveColor ?? Colors.grey),
            size: size,
          ),
        ),
      ),
    );
  }
}
