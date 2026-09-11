import 'package:flutter/material.dart';

import '../data/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/screenshot_guard.dart';
import 'routes.dart';

class DodoPharmacyApp extends StatefulWidget {
  const DodoPharmacyApp({super.key});

  @override
  State<DodoPharmacyApp> createState() => _DodoPharmacyAppState();
}

class _DodoPharmacyAppState extends State<DodoPharmacyApp> {
  final AppState _state = AppState();
  final GlobalKey<NavigatorState> _navKey = GlobalKey<NavigatorState>();

  @override
  void dispose() {
    _state.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScreenshotGuard(
      navigatorKey: _navKey,
      child: AppStateScope(
        state: _state,
        child: MaterialApp(
          navigatorKey: _navKey,
          title: 'DODOMED',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          initialRoute: AppRoutes.splash,
          onGenerateRoute: AppRoutes.onGenerateRoute,
          builder: (context, child) {
            final mq = MediaQuery.of(context);

            // Keep the phone-first layouts intact whatever text-size the OS
            // requests — clamp the scale to a sane band.
            final scaled = mq.copyWith(
              textScaler: mq.textScaler.clamp(
                minScaleFactor: 0.9,
                maxScaleFactor: 1.2,
              ),
            );

            // On phones just apply the clamp.
            if (mq.size.width <= 520) {
              return MediaQuery(data: scaled, child: child!);
            }

            // On wide screens (web / tablet) frame the app in a phone-width
            // card so the layouts stay legible.
            const w = 430.0;
            return ColoredBox(
              color: const Color(0xFF111111),
              child: Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: SizedBox(
                    width: w,
                    height: mq.size.height,
                    child: MediaQuery(
                      data: scaled.copyWith(size: Size(w, mq.size.height)),
                      child: child!,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
