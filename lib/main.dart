import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import 'screens/home_shell.dart';
import 'screens/onboarding_screen.dart';
import 'state/app_state.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Orientation: iPhone is portrait-only, iPad rotates freely (see Info.plist).
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
  final state = await AppState.load();
  runApp(AppScope(notifier: state, child: const OlympusApp()));
}

class OlympusApp extends StatelessWidget {
  const OlympusApp({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final pal = app.palette;
    return CupertinoApp(
      title: 'Solmora',
      debugShowCheckedModeBanner: false,
      theme: CupertinoThemeData(
        brightness: Brightness.dark,
        primaryColor: pal.primary,
        scaffoldBackgroundColor: Olymp.bg,
        barBackgroundColor: Olymp.bar,
        textTheme: CupertinoTextThemeData(
          primaryColor: pal.primary,
          textStyle: const TextStyle(fontSize: 17, letterSpacing: -0.4, color: Olymp.textPrimary),
          navLargeTitleTextStyle: OT.display(34),
          navTitleTextStyle: OT.headline,
        ),
      ),
      home: AnimatedSwitcher(
        duration: const Duration(milliseconds: 450),
        child: app.side == null
            ? const OnboardingScreen(key: ValueKey('onboarding'))
            : const HomeShell(key: ValueKey('home')),
      ),
    );
  }
}
