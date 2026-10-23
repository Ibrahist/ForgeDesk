import 'package:flutter/material.dart';
import 'core/constants.dart';
import 'core/theme.dart';
import 'screens/home_screen.dart';
import 'services/forgedesk_bridge.dart';

final ValueNotifier<ThemeMode> themeModeNotifier = ValueNotifier(ThemeMode.dark);

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final bridge = ForgeDeskBridgeService();

  runApp(ForgeDeskApp(bridge: bridge));
}

class ForgeDeskApp extends StatelessWidget {
  final ForgeDeskBridgeService bridge;

  const ForgeDeskApp({
    super.key,
    required this.bridge,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeModeNotifier,
      builder: (context, currentMode, _) {
        return MaterialApp(
          title: AppConstants.appName,
          debugShowCheckedModeBanner: false,
          themeAnimationDuration: Duration.zero,
          theme: ForgeTheme.lightTheme,
          darkTheme: ForgeTheme.darkTheme,
          themeMode: currentMode,
          home: HomeScreen(
            bridge: bridge,
            isDarkMode: currentMode == ThemeMode.dark,
            onToggleTheme: () {
              themeModeNotifier.value = themeModeNotifier.value == ThemeMode.dark
                  ? ThemeMode.light
                  : ThemeMode.dark;
            },
          ),
        );
      },
    );
  }
}
