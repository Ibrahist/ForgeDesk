import 'package:flutter/material.dart';
import 'core/constants.dart';
import 'core/theme.dart';
import 'screens/home_screen.dart';
import 'services/forgedesk_bridge.dart';

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
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: ForgeTheme.darkTheme,
      home: HomeScreen(bridge: bridge),
    );
  }
}
