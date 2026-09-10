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
            // On very wide screens (web / tablet) frame the app in a
            // phone-width column so the phone-first layouts stay legible.
            final mq = MediaQuery.of(context);
            if (mq.size.width <= 520) return child!;
            const w = 420.0;
            return ColoredBox(
              color: const Color(0xFF111111),
              child: Center(
                child: SizedBox(
                  width: w,
                  height: mq.size.height,
                  child: MediaQuery(
                    data: mq.copyWith(size: Size(w, mq.size.height)),
                    child: child!,
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
