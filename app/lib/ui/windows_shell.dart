import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

import '../app_settings.dart';
import '../core/core_controller.dart';
import 'browser_signin.dart';
import 'logs_page.dart';
import 'servers_page.dart';
import 'settings_page.dart';
import 'windows_parity_ui.dart';

/// The fixed portrait Windows presentation, following the Android CLXY
/// Home, All Server, Profile, and sign-in visual language.
class WindowsShell extends StatefulWidget {
  const WindowsShell({super.key, required this.core, required this.settings});

  final CoreController core;
  final AppSettings settings;

  @override
  State<WindowsShell> createState() => _WindowsShellState();
}

class _WindowsShellState extends State<WindowsShell> {
  int _tab = 0;
  Timer? _clock;
  DateTime _now = DateTime.now();
  String _deviceIp = '';

  @override
  void initState() {
    super.initState();
    _clock = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
    _readDeviceIp();
  }

  Future<void> _readDeviceIp() async {
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLoopback: false,
      );
      final addresses = <String>[
        for (final interface in interfaces)
          for (final address in interface.addresses)
            if (!address.isLoopback && !address.isLinkLocal) address.address,
      ];
      if (mounted && addresses.isNotEmpty) {
        setState(() => _deviceIp = addresses.first);
      }
    } on SocketException {
      // The route card still identifies the local endpoint when unavailable.
    }
  }

  @override
  void dispose() {
    _clock?.cancel();
    super.dispose();
  }

  void _push(String title, Widget Function() page) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => ListenableBuilder(
          listenable: widget.core,
          builder: (context, _) => Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(title: Text(title)),
            body: ClxyWindowsBackground(
              child: SafeArea(
                top: false,
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 560),
                    child: page(),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _openRelaySettings() => _push(
    'Relay server',
    () => SettingsPage(
      core: widget.core,
      settings: widget.settings,
      section: SettingsSection.relay,
    ),
  );

  @override
  Widget build(BuildContext context) => Theme(
    data: clxyWindowsTheme(Theme.of(context)),
    child: ListenableBuilder(
      listenable: widget.core,
      builder: (context, _) {
        final core = widget.core;
        final status = core.status;
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: ClxyWindowsBackground(
            child: status == null
                ? const Center(
                    child: CircularProgressIndicator(
                      color: ClxyWindowsPalette.cyan,
                    ),
                  )
                : IndexedStack(
                    index: _tab,
                    children: [
                      ClxyWindowsHome(
                        core: core,
                        status: status,
                        now: _now,
                        showPublicIp: widget.settings.showPublicIp,
                        deviceIp: _deviceIp,
                        onServers: () => setState(() => _tab = 1),
                        onSignIn: () =>
                            startAddAccount(context, core, widget.settings),
                        onDiagnostics: () => _push(
                          'Logs',
                          () => LogsPage(core: core, settings: widget.settings),
                        ),
                      ),
                      ServersPage(
                        core: core,
                        settings: widget.settings,
                        windowsAndroidStyle: true,
                        onCloseToHome: () => setState(() => _tab = 0),
                        onOpenRelay: _openRelaySettings,
                      ),
                      ClxyWindowsProfile(
                        core: core,
                        settings: widget.settings,
                        push: _push,
                      ),
                    ],
                  ),
          ),
          bottomNavigationBar: ClxyWindowsBottomNav(
            selected: _tab,
            onSelected: (tab) => setState(() => _tab = tab),
          ),
        );
      },
    ),
  );
}
