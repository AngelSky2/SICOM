import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_logo.dart';
import '../../../../shared/widgets/gradient_background.dart';
import '../controllers/splash_controller.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with SingleTickerProviderStateMixin {
  late final AnimationController _anim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..forward();

  late final Animation<double> _scale =
      CurvedAnimation(parent: _anim, curve: const Interval(0, 0.6, curve: Curves.elasticOut));
  late final Animation<double> _fade =
      CurvedAnimation(parent: _anim, curve: const Interval(0.35, 1, curve: Curves.easeOut));

  late final SplashController _controller = context.read<SplashController>();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onStatus);
    WidgetsBinding.instance.addPostFrameCallback((_) => _controller.start());
  }

  void _onStatus() {
    if (_controller.status == SplashStatus.ready && mounted) {
      Navigator.of(context).pushReplacementNamed(AppRoutes.home);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onStatus);
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              children: [
                const Spacer(flex: 3),
                ScaleTransition(scale: _scale, child: const AppLogo(size: 120)),
                const SizedBox(height: 28),
                FadeTransition(
                  opacity: _fade,
                  child: Column(
                    children: [
                      ShaderMask(
                        shaderCallback: AppColors.brandGradient.createShader,
                        child: Text(
                          AppConstants.appName,
                          style: theme.textTheme.displaySmall?.copyWith(color: Colors.white),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(AppConstants.appTagline, style: theme.textTheme.titleMedium?.copyWith(
                        color: AppColors.textSecondary,
                      )),
                    ],
                  ),
                ),
                const Spacer(flex: 3),
                Consumer<SplashController>(
                  builder: (_, c, _) => Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: c.progress),
                          duration: const Duration(milliseconds: 400),
                          builder: (_, v, _) => LinearProgressIndicator(
                            value: v,
                            minHeight: 6,
                            backgroundColor: AppColors.surfaceLight,
                            valueColor: const AlwaysStoppedAnimation(AppColors.secondary),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child: Text(c.message, key: ValueKey(c.message), style: theme.textTheme.bodyMedium),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                Text('Reconocimiento de señas con IA · v1.0.0',
                    style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
