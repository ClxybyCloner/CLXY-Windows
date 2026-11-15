import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_info.dart';
import 'app_settings.dart';
import 'core/android_core.dart';
import 'core/core_api.dart';
import 'core/core_controller.dart';
import 'core/updates.dart';
import 'core/core_process.dart';
import 'core/ports.dart';
import 'core/tun_service.dart';
import 'desktop/desktop_integration.dart';
import 'ui/app.dart';

/// The desktop app starts the core as its child process (`-app`) and stops
/// it on quit. Arguments: `--data-dir=<path>` (default: see
/// [CoreLocator.dataDir]) and `--core=<path>` (default:
/// [CoreProcess.executableFrom], `core\arman-vpn-core.exe` beside the app).
Future<void> main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isAndroid) return runAndroid();
  final dataDir = CoreLocator.dataDir(args);
  final settings = await AppSettings.load(dataDir);
  final process = CoreProcess(
    executable: CoreProcess.executableFrom(args),
    dataDir: dataDir,
  );
  final core = CoreController(
    process.connect,
    moveStoppedCore: (port) async {
      final listen = await CoreLocator.dashboardListen(dataDir);
      await CoreLocator.setDashboardListen(dataDir, withPort(listen, port));
      process.retryNow();
    },
    retryStoppedCore: () async => process.retryNow(),
    // The TUN mode's service, beside the core.
    tunService: Platform.isWindows || Platform.isLinux || Platform.isMacOS
        ? TunService.besideCore(process.executable)
        : null,
  )..start();
  // Back in front: the core tries again at once, not after a wait.
  AppLifecycleListener(
    onResume: core.retryNow,
    onShow: () => core.onScreen = true,
    onHide: () => core.onScreen = false,
  );
  final navigatorKey = GlobalKey<NavigatorState>();
  // Before the desktop's: a version installed at the start goes first. The
  // private smoke test can request a local-only fake update notice.
  final smokeUpdateArgs = args
      .where((arg) => arg.startsWith('--clxy-smoke-update-notice='))
      .toList(growable: false);
  final smokeUpdateActionPath = smokeUpdateArgs.isEmpty
      ? null
      : smokeUpdateArgs.first.substring(
          '--clxy-smoke-update-notice='.length,
        );
  Updates.start(
    core,
    settings,
    args: args,
    mockUpdateNotice:
        clxyPrivateTestBuild && smokeUpdateActionPath != null,
    mockActionPath: smokeUpdateActionPath,
  );
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    DesktopIntegration(
      core: core,
      settings: settings,
      process: process,
      navigatorKey: navigatorKey,
      // --hidden: a new version that its update started in the tray.
      startHidden: args.contains('--autostart') || args.contains('--hidden'),
      autostarted: args.contains('--autostart'),
      manageAutostart:
          !clxyPrivateTestBuild &&
          !args.any((a) => a.startsWith('--data-dir=')),
    ).start();
  }
  runApp(VpnApp(core: core, settings: settings, navigatorKey: navigatorKey));
}

/// Android: the core runs in this app's process, in a foreground service
/// that keeps the proxy up while the UI is closed.
Future<void> runAndroid() async {
  WidgetsFlutterBinding.ensureInitialized();
  AndroidCore.listenForHomeRequests();
  // Edge to edge: the home page's hero colors the status bar.
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
    ),
  );
  final dataDir = await AndroidCore.dataDir();
  final settings = await AppSettings.load(dataDir);
  await AndroidCore.loadMode();
  await AndroidCore.prepareFirstRunRouting(
    settings,
    systemCountry:
        WidgetsBinding.instance.platformDispatcher.locale.countryCode,
  );
  final core = CoreController(
    AndroidCore(dataDir).connect,
    turnOn: AndroidCore.setOn,
  )..start();
  AppLifecycleListener(
    onResume: core.retryNow,
    onShow: () => core.onScreen = true,
    onHide: () => core.onScreen = false,
  );
  if (!clxyPrivateTestBuild) Updates.start(core, settings);
  runApp(VpnApp(core: core, settings: settings));
}
