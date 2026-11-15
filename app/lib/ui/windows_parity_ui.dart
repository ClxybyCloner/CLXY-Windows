import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app_settings.dart';
import '../core/core_controller.dart';
import '../core/core_api.dart' show CoreUnavailable;
import '../core/models.dart';
import '../core/updates.dart';
import '../l10n/app_localizations.dart';
import 'accounts_page.dart' show accountReason;
import 'browser_signin.dart';
import 'connection_mode.dart';
import 'format.dart';
import 'logs_page.dart';
import 'settings_page.dart';
import 'widgets.dart';

/// Android CLXY color tokens, shared by the fixed-size Windows presentation.
abstract final class ClxyWindowsPalette {
  static const bgTop = Color(0xFF060916);
  static const bgMid = Color(0xFF090E22);
  static const bgBottom = Color(0xFF060A18);
  static const card = Color(0xC20F172E);
  static const routeCard = Color(0xC70C1328);
  static const nav = Color(0xE6080C1C);
  static const glassBorder = Color(0x2494A3B8);
  static const cyanBorder = Color(0x5200E5FF);
  static const cyan = Color(0xFF00E5FF);
  static const cyanText = Color(0xFF22D3EE);
  static const blue = Color(0xFF3B82F6);
  static const blueDeep = Color(0xFF2563EB);
  static const purple = Color(0xFF9333EA);
  static const pink = Color(0xFFC084FC);
  static const green = Color(0xFF10D9A0);
  static const amber = Color(0xFFFFB547);
  static const red = Color(0xFFF43F5E);
  static const text = Color(0xFFF8FAFC);
  static const secondary = Color(0xFFCBD5E1);
  static const muted = Color(0xFF94A3B8);
  static const dim = Color(0xFF64748B);
  static const timerDim = Color(0xFF475569);
  static const barInactive = Color(0xFF334155);
}

ThemeData clxyWindowsTheme(ThemeData base) {
  final scheme = base.colorScheme.copyWith(
    brightness: Brightness.dark,
    primary: ClxyWindowsPalette.cyanText,
    onPrimary: Colors.white,
    secondary: ClxyWindowsPalette.purple,
    onSecondary: Colors.white,
    surface: ClxyWindowsPalette.bgBottom,
    onSurface: ClxyWindowsPalette.text,
    onSurfaceVariant: ClxyWindowsPalette.muted,
    outline: const Color(0xFF334155),
    outlineVariant: ClxyWindowsPalette.glassBorder,
    error: ClxyWindowsPalette.red,
  );
  return base.copyWith(
    brightness: Brightness.dark,
    colorScheme: scheme,
    scaffoldBackgroundColor: ClxyWindowsPalette.bgBottom,
    canvasColor: ClxyWindowsPalette.bgBottom,
    cardTheme: CardThemeData(
      elevation: 0,
      color: ClxyWindowsPalette.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: ClxyWindowsPalette.glassBorder),
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: ClxyWindowsPalette.bgBottom,
      foregroundColor: ClxyWindowsPalette.text,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
    ),
    textTheme: base.textTheme.apply(
      fontFamily: 'Inter',
      bodyColor: ClxyWindowsPalette.text,
      displayColor: ClxyWindowsPalette.text,
    ),
  );
}

class ClxyWindowsBackground extends StatelessWidget {
  const ClxyWindowsBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          ClxyWindowsPalette.bgTop,
          ClxyWindowsPalette.bgMid,
          ClxyWindowsPalette.bgBottom,
        ],
      ),
    ),
    child: CustomPaint(painter: const _CosmicGlowPainter(), child: child),
  );
}

class _CosmicGlowPainter extends CustomPainter {
  const _CosmicGlowPainter();

  @override
  void paint(Canvas canvas, Size size) {
    void glow(Offset center, Color color, double radius) {
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..shader = RadialGradient(colors: [color, Colors.transparent])
              .createShader(Rect.fromCircle(center: center, radius: radius)),
      );
    }

    glow(
      Offset(size.width * .18, size.height * .20),
      ClxyWindowsPalette.cyan.withValues(alpha: .10),
      size.width * .65,
    );
    glow(
      Offset(size.width * .84, size.height * .26),
      ClxyWindowsPalette.purple.withValues(alpha: .13),
      size.width * .68,
    );
    glow(
      Offset(size.width * .50, size.height * .86),
      ClxyWindowsPalette.blue.withValues(alpha: .09),
      size.width * .72,
    );
  }

  @override
  bool shouldRepaint(covariant _CosmicGlowPainter oldDelegate) => false;
}

class ClxyWindowsBrand extends StatelessWidget {
  const ClxyWindowsBrand({
    super.key,
    this.logoSize = 28,
    this.labelSize = 15,
    this.showLabel = true,
    this.gap = 8,
  });

  final double logoSize;
  final double labelSize;
  final bool showLabel;
  final double gap;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      Image.asset(
        'assets/logo.png',
        width: logoSize,
        height: logoSize * .75,
        fit: BoxFit.contain,
        semanticLabel: 'CLXY logo',
      ),
      if (showLabel) ...[
        SizedBox(width: gap),
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [
              Color(0xFF00F0FF),
              Color(0xFF60A5FA),
              ClxyWindowsPalette.pink,
            ],
          ).createShader(bounds),
          blendMode: BlendMode.srcIn,
          child: Text(
            'ClXY',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: labelSize,
              fontWeight: FontWeight.w700,
              letterSpacing: .8,
              color: Colors.white,
            ),
          ),
        ),
      ],
    ],
  );
}

class ClxyWindowsDottedWorld extends StatelessWidget {
  const ClxyWindowsDottedWorld({super.key, this.dotAlpha = .44});

  final double dotAlpha;

  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: _DottedWorldPainter(dotAlpha: dotAlpha),
    child: const SizedBox.expand(),
  );
}

class _DottedWorldPainter extends CustomPainter {
  const _DottedWorldPainter({required this.dotAlpha});

  final double dotAlpha;

  bool _ellipse(
    double x,
    double y,
    double cx,
    double cy,
    double rx,
    double ry,
  ) {
    final dx = (x - cx) / rx;
    final dy = (y - cy) / ry;
    return dx * dx + dy * dy <= 1;
  }

  bool _land(double x, double y) {
    return _ellipse(x, y, .09, .21, .055, .055) ||
        _ellipse(x, y, .20, .28, .115, .125) ||
        _ellipse(x, y, .21, .43, .045, .065) ||
        _ellipse(x, y, .34, .13, .048, .055) ||
        _ellipse(x, y, .275, .59, .065, .095) ||
        _ellipse(x, y, .265, .74, .036, .120) ||
        _ellipse(x, y, .435, .25, .018, .030) ||
        _ellipse(x, y, .50, .27, .065, .075) ||
        _ellipse(x, y, .515, .175, .040, .048) ||
        _ellipse(x, y, .505, .465, .078, .095) ||
        _ellipse(x, y, .530, .625, .048, .125) ||
        _ellipse(x, y, .598, .665, .014, .045) ||
        _ellipse(x, y, .595, .395, .045, .058) ||
        _ellipse(x, y, .66, .215, .115, .095) ||
        _ellipse(x, y, .76, .32, .115, .120) ||
        _ellipse(x, y, .695, .455, .040, .075) ||
        _ellipse(x, y, .775, .475, .035, .065) ||
        _ellipse(x, y, .895, .305, .018, .055) ||
        _ellipse(x, y, .815, .575, .065, .025) ||
        _ellipse(x, y, .845, .725, .065, .088) ||
        _ellipse(x, y, .942, .810, .015, .042);
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final w = size.width;
    final h = size.height;
    final step = (w / 58).clamp(4.5, 7.0).toDouble();
    final radius = step * .24;
    final halo = Rect.fromCircle(
      center: Offset(w * .5, h * .48),
      radius: w * .46,
    );
    canvas.drawCircle(
      halo.center,
      halo.width / 2,
      Paint()
        ..shader = const RadialGradient(
          colors: [Color(0x223B82F6), Color(0x1F00E5FF), Colors.transparent],
        ).createShader(halo),
    );
    for (var y = step * .5; y < h; y += step) {
      for (var x = step * .5; x < w; x += step) {
        if (!_land(x / w, y / h)) continue;
        final nx = x / w;
        final color = nx < .36
            ? ClxyWindowsPalette.cyan
            : nx < .68
            ? const Color(0xFF60A5FA)
            : ClxyWindowsPalette.pink;
        canvas.drawCircle(
          Offset(x, y),
          radius,
          Paint()..color = color.withValues(alpha: dotAlpha),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DottedWorldPainter oldDelegate) =>
      dotAlpha != oldDelegate.dotAlpha;
}

class ClxyWindowsBottomNav extends StatelessWidget {
  const ClxyWindowsBottomNav({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final int selected;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: ClxyWindowsPalette.nav,
      border: Border.all(color: Color(0xFF1E293B), width: .5),
    ),
    padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _BottomNavItem(
          selected: selected == 0,
          icon: selected == 0 ? Icons.home_rounded : Icons.home_outlined,
          label: 'Home',
          onTap: () => onSelected(0),
        ),
        _BottomNavItem(
          selected: selected == 1,
          icon: selected == 1 ? Icons.public_rounded : Icons.public_outlined,
          label: 'All Server',
          onTap: () => onSelected(1),
        ),
        _BottomNavItem(
          selected: selected == 2,
          icon: selected == 2
              ? Icons.person_rounded
              : Icons.person_outline_rounded,
          label: 'Profile',
          onTap: () => onSelected(2),
        ),
      ],
    ),
  );
}

class _BottomNavItem extends StatelessWidget {
  const _BottomNavItem({
    required this.selected,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final bool selected;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? ClxyWindowsPalette.cyan : ClxyWindowsPalette.dim;
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            height: 52,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (selected) ...[
                  Container(
                    width: 26,
                    height: 2.5,
                    decoration: BoxDecoration(
                      color: ClxyWindowsPalette.cyan,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const SizedBox(height: 3),
                ],
                Icon(icon, size: 22, color: color),
                const SizedBox(height: 3),
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    color: color,
                    fontSize: 11,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ClxyWindowsHome extends StatelessWidget {
  const ClxyWindowsHome({
    super.key,
    required this.core,
    required this.status,
    required this.now,
    required this.showPublicIp,
    required this.deviceIp,
    required this.onServers,
    required this.onSignIn,
    required this.onDiagnostics,
  });

  final CoreController core;
  final CoreStatus status;
  final DateTime now;
  final bool showPublicIp;
  final String deviceIp;
  final VoidCallback onServers;
  final VoidCallback onSignIn;
  final VoidCallback onDiagnostics;

  bool get _connected {
    if (!status.proxyOn ||
        status.state.phase != Phase.running ||
        status.connectPending ||
        core.unavailable != null) {
      return false;
    }
    if ((status.systemProxySet || status.tunMode) && !status.computerUsesVpn) {
      return false;
    }
    return status.confirmedBy(core.lastTest);
  }

  bool get _connecting =>
      status.connectPending ||
      core.switchingProxy ||
      core.installingTun ||
      (status.proxyOn && status.state.phase == Phase.running && !_connected);

  String get _mode => connectionModeShown(status);

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final connected = _connected;
    final connecting = _connecting;
    final routeActive = connected || connecting;
    final failure =
        !status.proxyOn &&
        (status.connectFailure.isNotEmpty || status.state.phase == Phase.error);
    final modeName = switch (_mode) {
      'set' => 'System proxy',
      'tun' => 'TUN',
      _ => 'Proxy',
    };
    final statusColor = connected
        ? ClxyWindowsPalette.cyanText
        : connecting
        ? ClxyWindowsPalette.amber
        : failure
        ? ClxyWindowsPalette.red
        : ClxyWindowsPalette.dim;
    final shieldColor = connected
        ? ClxyWindowsPalette.cyan
        : connecting
        ? ClxyWindowsPalette.amber
        : failure
        ? ClxyWindowsPalette.red
        : ClxyWindowsPalette.timerDim;
    final statusLabel = core.unavailable != null
        ? 'Starting core ($modeName)'
        : connected
        ? 'Connection Secure • $modeName'
        : status.noNetwork && status.proxyOn
        ? 'No Network ($modeName)'
        : connecting
        ? 'Connecting… • $modeName'
        : failure
        ? 'Connection Failed ($modeName)'
        : 'Disconnected ($modeName)';
    final since = status.proxy?.startedAt ?? status.state.since;
    final elapsed = status.proxyOn && since != null
        ? now.difference(since)
        : Duration.zero;

    final selectedCode = status.selection.isNotEmpty ? status.selection : 'REC';
    final exitCode = status.exit?.countryCode.isNotEmpty == true
        ? status.exit!.countryCode
        : status.proxy?.countryCode.isNotEmpty == true
        ? status.proxy!.countryCode
        : selectedCode;
    final place = homeLocation(l, status, connected: routeActive);
    final exitName = _serverName(l, status, routeActive, place);
    final destinationName = locationName(
      l,
      exitCode,
      status.exit?.countryName.isNotEmpty == true
          ? status.exit!.countryName
          : status.proxy?.countryName.isNotEmpty == true
          ? status.proxy!.countryName
          : status.selectionName,
    );
    final localeCountry = WidgetsBinding
        .instance
        .platformDispatcher
        .locale
        .countryCode
        ?.toUpperCase();
    final originCode = localeCountry != null && localeCountry.length == 2
        ? localeCountry
        : 'US';
    final originName = countryName(l, originCode, originCode);
    final localIp = deviceIp.isEmpty ? 'Direct' : deviceIp;
    final originIp = !connected && status.exit?.ipv4.isNotEmpty == true
        ? status.exit!.ipv4
        : localIp;

    final exitAddress =
        connected && showPublicIp && status.exit?.ipv4.isNotEmpty == true
        ? status.exit!.ipv4
        : status.proxy?.listen.isNotEmpty == true && _mode != 'tun'
        ? status.proxy!.listen
        : status.proxy?.upstream.isNotEmpty == true
        ? status.proxy!.upstream
        : selectedCode == 'REC'
        ? 'Auto Route'
        : selectedCode;
    final currentTest = core.lastTest;
    final ping = currentTest != null && status.isCurrentTest(currentTest)
        ? currentTest.responseMs
        : 0;
    final pingLabel = ping > 0
        ? '${ping}ms'
        : connected
        ? 'Online'
        : 'Ready';
    final serverSubtitle = exitAddress.contains('.')
        ? 'IP $exitAddress • $pingLabel'
        : '$exitAddress • $pingLabel';
    final alert = _homeAlert(l, status, core.unavailable);

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxHeight < 680;
        final topPadding = constraints.maxHeight > 680
            ? ((constraints.maxHeight - 620) * .14).clamp(12.0, 28.0)
            : 8.0;
        final sectionGap = compact ? 6.0 : 10.0;
        final cardGap = compact ? 6.0 : 10.0;
        final timerSize = compact ? 36.0 : 42.0;
        final accounts = core.accounts?.accounts ?? const <Account>[];
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: topPadding),
              const Center(
                child: ClxyWindowsBrand(logoSize: 28, labelSize: 15),
              ),
              SizedBox(height: sectionGap),
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _WindowsShieldIcon(color: shieldColor),
                    const SizedBox(width: 7),
                    Flexible(
                      child: Text(
                        statusLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          color: statusColor,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Center(
                child: _HomeTimer(duration: elapsed, fontSize: timerSize),
              ),
              SizedBox(height: sectionGap),
              _HomeSpeedRow(
                download: status.proxyOn ? (status.traffic?.downRate ?? 0) : 0,
                upload: status.proxyOn ? (status.traffic?.upRate ?? 0) : 0,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: LayoutBuilder(
                    builder: (context, mapConstraints) {
                      final diameter = (mapConstraints.maxHeight / 1.5)
                          .clamp(72.0, 132.0)
                          .toDouble();
                      final mapHeight = math.min(
                        mapConstraints.maxHeight,
                        220.0,
                      );
                      return Center(
                        child: SizedBox(
                          width: mapConstraints.maxWidth,
                          height: mapHeight,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Positioned.fill(
                                child: ClxyWindowsDottedWorld(
                                  dotAlpha: routeActive ? .54 : .44,
                                ),
                              ),
                              _HomePowerButton(
                                connected: connected,
                                connecting: connecting,
                                diameter: diameter,
                                onPressed: () => runShowingErrors(
                                  context,
                                  () => core.setOn(!status.proxyOn),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 360),
                  child: _HomeRouteCard(
                    connected: routeActive,
                    originCode: originCode,
                    originName: originName,
                    originIp: originIp,
                    destinationCode: exitCode,
                    destinationName: destinationName,
                    destinationIp: exitAddress,
                  ),
                ),
              ),
              SizedBox(height: cardGap),
              _HomeUsageCard(
                accounts: accounts,
                activeAccount: status.activeAccount,
              ),
              if (alert != null) ...[
                SizedBox(height: cardGap),
                _HomeAlertCard(
                  message: alert.message,
                  failure: failure,
                  onTap: status.totalAccounts == 0 && !alert.diagnostic
                      ? onSignIn
                      : onDiagnostics,
                  action: status.totalAccounts == 0 && !alert.diagnostic
                      ? 'Sign in'
                      : 'Details',
                ),
              ],
              SizedBox(height: cardGap),
              _WindowsModeSelector(
                status: status,
                core: core,
                selected: _mode,
                onSelected: (mode) => chooseConnectionMode(context, core, mode),
              ),
              SizedBox(height: cardGap),
              _HomeServerCard(
                code: exitCode,
                title: exitName,
                subtitle: ltr(serverSubtitle),
                pingMs: ping,
                onTap: onServers,
              ),
              _WindowsUpdateNotice(core: core),
              SizedBox(height: compact ? 8 : 12),
            ],
          ),
        );
      },
    );
  }

  String _serverName(
    AppLocalizations l,
    CoreStatus status,
    bool routeActive,
    HomePlace place,
  ) {
    final city = routeActive
        ? (status.exit?.city ?? status.proxy?.cityName ?? '')
        : '';
    final base = place.name.isNotEmpty
        ? place.name
        : status.selectionName.isNotEmpty
        ? status.selectionName
        : l.modeRecommended;
    return city.isNotEmpty && !base.toLowerCase().contains(city.toLowerCase())
        ? '$base · $city'
        : base;
  }

  ({String message, bool diagnostic})? _homeAlert(
    AppLocalizations l,
    CoreStatus status,
    CoreUnavailable? unavailable,
  ) {
    if (unavailable != null) {
      return (
        message: 'Core offline: ${describeProblem(l, unavailable)}',
        diagnostic: false,
      );
    }
    if (status.connectFailure.isNotEmpty) {
      return (message: status.connectFailure, diagnostic: true);
    }
    if (status.state.phase == Phase.waiting && status.totalAccounts == 0) {
      return (message: 'Add a CLXY Account to connect', diagnostic: false);
    }
    if (status.state.phase == Phase.waiting) {
      return (
        message: stateText(l, status.state).isEmpty
            ? 'Waiting for connection'
            : stateText(l, status.state),
        diagnostic: true,
      );
    }
    if (status.state.phase == Phase.error) {
      return (
        message: stateText(l, status.state).isEmpty
            ? 'Connection needs attention'
            : stateText(l, status.state),
        diagnostic: true,
      );
    }
    if (status.exitMismatch != null) {
      return (
        message:
            'Public IP is in ${countryName(l, status.exitMismatch!.exitCountryCode, status.exitMismatch!.exitCountryName)} instead of ${countryName(l, status.exitMismatch!.chosenCountryCode, status.exitMismatch!.chosenCountryName)}',
        diagnostic: true,
      );
    }
    if (_mode != 'tun' && status.proxy?.listen.isNotEmpty == true) {
      return (
        message: 'SOCKS5 proxy listening on ${status.proxy!.listen}',
        diagnostic: false,
      );
    }
    return null;
  }
}

/// A one-click update action on Home, shown only when a newer version is known.
class _WindowsUpdateNotice extends StatelessWidget {
  const _WindowsUpdateNotice({required this.core});

  final CoreController core;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([
      Updates.available,
      Updates.failure,
      core,
    ]),
    builder: (context, _) {
      final release = Updates.available.value;
      if (release == null) return const SizedBox.shrink();

      final l = AppLocalizations.of(context);
      final update = core.status?.update;
      final mine = update?.version == release.version;
      final busy = mine && (update!.downloading || update.installing);
      final failure =
          Updates.failure.value ?? (mine && update!.failed ? update.error : null);
      final message = busy
          ? update.downloading
                ? l.updateDownloading(release.version)
                : l.updateInstalling(release.version)
          : failure != null
          ? l.updateFailed(release.version)
          : mine && update!.ready
          ? l.updateReady(release.version)
          : l.updateAvailable(release.version);

      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Container(
          padding: const EdgeInsetsDirectional.fromSTEB(14, 10, 12, 10),
          decoration: BoxDecoration(
            color: const Color(0xC20C1D32),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: ClxyWindowsPalette.cyanBorder),
          ),
          child: Row(
            children: [
              Icon(
                busy
                    ? Icons.downloading_rounded
                    : failure != null
                    ? Icons.error_outline_rounded
                    : Icons.system_update_rounded,
                color: failure != null
                    ? ClxyWindowsPalette.amber
                    : ClxyWindowsPalette.cyanText,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: busy && update.downloading
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            message,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: ClxyWindowsPalette.text,
                              fontFamily: 'Inter',
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          LinearProgressIndicator(
                            value: update.progress,
                            minHeight: 3,
                            backgroundColor: ClxyWindowsPalette.barInactive,
                            color: ClxyWindowsPalette.cyan,
                          ),
                        ],
                      )
                    : Text(
                        message,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: ClxyWindowsPalette.text,
                          fontFamily: 'Inter',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
              if (!busy) ...[
                const SizedBox(width: 10),
                OutlinedButton.icon(
                  autofocus: Updates.isSmokeUpdateNoticeActive,
                  onPressed: () => Updates.update(release),
                  icon: Icon(
                    failure == null
                        ? Icons.system_update_alt_rounded
                        : Icons.refresh_rounded,
                    size: 17,
                  ),
                  label: Text(failure == null ? l.updateNow : l.tryAgain),
                ),
              ],
            ],
          ),
        ),
      );
    },
  );
}

class _WindowsShieldIcon extends StatelessWidget {
  const _WindowsShieldIcon({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) => CustomPaint(
    size: const Size(14, 16),
    painter: _WindowsShieldPainter(color),
  );
}

class _WindowsShieldPainter extends CustomPainter {
  const _WindowsShieldPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final shield = Path()
      ..moveTo(w * .5, h * .03)
      ..lineTo(w * .11, h * .17)
      ..lineTo(w * .11, h * .46)
      ..cubicTo(w * .11, h * .69, w * .27, h * .91, w * .5, h * .97)
      ..cubicTo(w * .73, h * .91, w * .89, h * .69, w * .89, h * .46)
      ..lineTo(w * .89, h * .17)
      ..close();
    canvas.drawPath(shield, Paint()..color = color);
    final check = Path()
      ..moveTo(w * .34, h * .5)
      ..lineTo(w * .45, h * .61)
      ..lineTo(w * .68, h * .39);
    canvas.drawPath(
      check,
      Paint()
        ..color = ClxyWindowsPalette.bgBottom
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * .12
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant _WindowsShieldPainter oldDelegate) =>
      color != oldDelegate.color;
}

class _HomeTimer extends StatelessWidget {
  const _HomeTimer({required this.duration, required this.fontSize});

  final Duration duration;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return RichText(
      text: TextSpan(
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: fontSize,
          fontWeight: FontWeight.w400,
          letterSpacing: .5,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
        children: [
          TextSpan(
            text: '$hours:',
            style: const TextStyle(color: ClxyWindowsPalette.timerDim),
          ),
          TextSpan(
            text: '$minutes:$seconds',
            style: const TextStyle(color: ClxyWindowsPalette.text),
          ),
        ],
      ),
    );
  }
}

class _HomeSpeedRow extends StatelessWidget {
  const _HomeSpeedRow({required this.download, required this.upload});

  final int download;
  final int upload;

  String _mbps(int bytesPerSecond) =>
      (bytesPerSecond * 8 / 1000000).toStringAsFixed(1).replaceAll('.', ',');

  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 320),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _HomeSpeed(label: 'Download', value: _mbps(download)),
          Container(width: 1, height: 30, color: const Color(0x33293650)),
          _HomeSpeed(label: 'Upload', value: _mbps(upload)),
        ],
      ),
    ),
  );
}

class _HomeSpeed extends StatelessWidget {
  const _HomeSpeed({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      RichText(
        text: TextSpan(
          style: const TextStyle(fontFamily: 'Inter'),
          children: [
            TextSpan(
              text: value,
              style: const TextStyle(
                color: ClxyWindowsPalette.text,
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
              ),
            ),
            const TextSpan(
              text: ' Mbp/s',
              style: TextStyle(color: ClxyWindowsPalette.muted, fontSize: 14),
            ),
          ],
        ),
      ),
      Text(
        label,
        style: const TextStyle(
          fontFamily: 'Inter',
          color: ClxyWindowsPalette.dim,
          fontSize: 11,
        ),
      ),
    ],
  );
}

class _HomePowerButton extends StatefulWidget {
  const _HomePowerButton({
    required this.connected,
    required this.connecting,
    required this.diameter,
    required this.onPressed,
  });

  final bool connected;
  final bool connecting;
  final double diameter;
  final VoidCallback onPressed;

  @override
  State<_HomePowerButton> createState() => _HomePowerButtonState();
}

class _HomePowerButtonState extends State<_HomePowerButton>
    with TickerProviderStateMixin {
  late final AnimationController _pulse;
  late final AnimationController _breath;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );
    _breath = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );
    _syncAnimations();
  }

  @override
  void didUpdateWidget(covariant _HomePowerButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.connected != widget.connected ||
        oldWidget.connecting != widget.connecting) {
      _syncAnimations();
    }
  }

  void _syncAnimations() {
    if (widget.connected || widget.connecting) {
      _pulse.repeat();
      _breath.stop();
    } else {
      _pulse.stop();
      _breath.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    _breath.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: Listenable.merge([_pulse, _breath]),
    builder: (context, _) {
      final phase1 = _pulse.value;
      final phase2 = (phase1 + .5) % 1;
      final active = widget.connected || widget.connecting;
      final glowPrimary = widget.connected
          ? ClxyWindowsPalette.cyan
          : widget.connecting
          ? ClxyWindowsPalette.amber
          : ClxyWindowsPalette.blue.withValues(alpha: .5);
      final glowSecondary = widget.connected
          ? ClxyWindowsPalette.purple
          : widget.connecting
          ? ClxyWindowsPalette.blue
          : ClxyWindowsPalette.purple.withValues(alpha: .4);
      final start = widget.connected
          ? const Color(0xFF00F0FF)
          : widget.connecting
          ? ClxyWindowsPalette.amber
          : const Color(0xFF1E293B);
      final middle = widget.connected
          ? ClxyWindowsPalette.blueDeep
          : widget.connecting
          ? ClxyWindowsPalette.blue
          : const Color(0xFF0F172A);
      final end = widget.connected
          ? ClxyWindowsPalette.purple
          : widget.connecting
          ? ClxyWindowsPalette.purple
          : const Color(0xFF1E1B4B);
      final border = active ? const Color(0x99BAE6FD) : const Color(0x4794A3B8);
      final breathScale = .98 + _breath.value * .06;
      return Transform.scale(
        scale: _pressed ? .92 : 1,
        child: SizedBox.square(
          dimension: widget.diameter * 1.46,
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (active) ...[
                _PulsePowerRing(
                  diameter: widget.diameter,
                  phase: phase1,
                  primary: glowPrimary,
                  secondary: glowSecondary,
                ),
                _PulsePowerRing(
                  diameter: widget.diameter,
                  phase: phase2,
                  primary: glowPrimary,
                  secondary: glowSecondary,
                ),
              ] else
                Transform.scale(
                  scale: breathScale,
                  child: CustomPaint(
                    size: Size.square(widget.diameter * 1.08),
                    painter: const _IdlePowerRingPainter(),
                  ),
                ),
              GestureDetector(
                onTapDown: (_) => setState(() => _pressed = true),
                onTapUp: (_) {
                  setState(() => _pressed = false);
                  if (!(widget.connecting)) widget.onPressed();
                },
                onTapCancel: () => setState(() => _pressed = false),
                child: Container(
                  width: widget.diameter,
                  height: widget.diameter,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [start, middle, end],
                    ),
                    border: Border.all(color: border, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: widget.connected
                            ? ClxyWindowsPalette.cyan.withValues(alpha: .28)
                            : Colors.black.withValues(alpha: .36),
                        blurRadius: widget.connected ? 28 : 14,
                        spreadRadius: widget.connected ? 1 : 0,
                      ),
                      if (widget.connected)
                        BoxShadow(
                          color: ClxyWindowsPalette.purple.withValues(
                            alpha: .2,
                          ),
                          blurRadius: 28,
                        ),
                    ],
                  ),
                  child: Center(
                    child: widget.connecting
                        ? SizedBox.square(
                            dimension: widget.diameter * .33,
                            child: const CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 3,
                            ),
                          )
                        : Icon(
                            Icons.power_settings_new_rounded,
                            color: Colors.white,
                            size: widget.diameter * .35,
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _PulsePowerRing extends StatelessWidget {
  const _PulsePowerRing({
    required this.diameter,
    required this.phase,
    required this.primary,
    required this.secondary,
  });

  final double diameter;
  final double phase;
  final Color primary;
  final Color secondary;

  @override
  Widget build(BuildContext context) {
    final alpha = (1 - phase) * .52;
    return Transform.scale(
      scale: .96 + phase * .42,
      child: CustomPaint(
        size: Size.square(diameter),
        painter: _PowerPulseRingPainter(primary, secondary, alpha),
      ),
    );
  }
}

class _PowerPulseRingPainter extends CustomPainter {
  const _PowerPulseRingPainter(this.primary, this.secondary, this.alpha);

  final Color primary;
  final Color secondary;
  final double alpha;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide / 2;
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = RadialGradient(
          colors: [
            primary.withValues(alpha: alpha * .25),
            Colors.transparent,
          ],
        ).createShader(Rect.fromCircle(center: center, radius: radius)),
    );
    final border = Rect.fromCircle(center: center, radius: radius - 1);
    canvas.drawCircle(
      center,
      radius - 1,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..shader = LinearGradient(
          colors: [
            primary.withValues(alpha: alpha),
            secondary.withValues(alpha: alpha),
          ],
        ).createShader(border),
    );
  }

  @override
  bool shouldRepaint(covariant _PowerPulseRingPainter oldDelegate) =>
      primary != oldDelegate.primary ||
      secondary != oldDelegate.secondary ||
      alpha != oldDelegate.alpha;
}

class _IdlePowerRingPainter extends CustomPainter {
  const _IdlePowerRingPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      size.shortestSide / 2,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = ClxyWindowsPalette.cyan.withValues(alpha: .16),
    );
  }

  @override
  bool shouldRepaint(covariant _IdlePowerRingPainter oldDelegate) => false;
}

class _HomeRouteCard extends StatefulWidget {
  const _HomeRouteCard({
    required this.connected,
    required this.originCode,
    required this.originName,
    required this.originIp,
    required this.destinationCode,
    required this.destinationName,
    required this.destinationIp,
  });

  final bool connected;
  final String originCode;
  final String originName;
  final String originIp;
  final String destinationCode;
  final String destinationName;
  final String destinationIp;

  @override
  State<_HomeRouteCard> createState() => _HomeRouteCardState();
}

class _HomeRouteCardState extends State<_HomeRouteCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _flow;

  @override
  void initState() {
    super.initState();
    _flow = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1150),
    )..repeat();
  }

  @override
  void dispose() {
    _flow.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final border = widget.connected
        ? const Color(0x4D38BDF8)
        : const Color(0x2294A3B8);
    return Container(
      constraints: const BoxConstraints(minHeight: 44),
      decoration: BoxDecoration(
        color: ClxyWindowsPalette.routeCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: _HomeRouteNode(
              code: widget.originCode,
              name: widget.originName,
              ip: widget.originIp,
              connected: false,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: SizedBox(
              width: 54,
              height: 14,
              child: AnimatedBuilder(
                animation: _flow,
                builder: (context, _) => CustomPaint(
                  painter: _RouteArrowPainter(
                    connected: widget.connected,
                    phase: _flow.value,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: _HomeRouteNode(
              code: widget.destinationCode,
              name: widget.destinationName,
              ip: widget.destinationIp,
              connected: widget.connected,
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeRouteNode extends StatelessWidget {
  const _HomeRouteNode({
    required this.code,
    required this.name,
    required this.ip,
    required this.connected,
  });

  final String code;
  final String name;
  final String ip;
  final bool connected;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      ClxyWindowsCircularFlag(code: code, size: 24),
      const SizedBox(width: 7),
      Expanded(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Inter',
                color: ClxyWindowsPalette.text,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              ip,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Inter',
                color: connected
                    ? ClxyWindowsPalette.cyanText
                    : ClxyWindowsPalette.muted,
                fontSize: 9.5,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

class _RouteArrowPainter extends CustomPainter {
  const _RouteArrowPainter({required this.connected, required this.phase});

  final bool connected;
  final double phase;

  @override
  void paint(Canvas canvas, Size size) {
    final cy = size.height / 2;
    final start = 2.0;
    final end = size.width - 4;
    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    if (connected) {
      linePaint.shader = const LinearGradient(
        colors: [
          ClxyWindowsPalette.cyan,
          ClxyWindowsPalette.blue,
          Color(0xFFA855F7),
        ],
      ).createShader(Rect.fromLTWH(start, cy, end - start, 1));
    } else {
      linePaint.color = ClxyWindowsPalette.timerDim;
    }
    final shift = connected ? phase * 16 : 0.0;
    for (var x = start - shift; x < end; x += 16) {
      final from = math.max(start, x);
      final to = math.min(end, x + (connected ? 8 : 6));
      if (to > from) {
        canvas.drawLine(Offset(from, cy), Offset(to, cy), linePaint);
      }
    }
    if (connected) {
      final beadX = start + (end - start) * phase;
      canvas.drawCircle(
        Offset(beadX, cy),
        5,
        Paint()..color = ClxyWindowsPalette.cyan.withValues(alpha: .35),
      );
      canvas.drawCircle(Offset(beadX, cy), 2.2, Paint()..color = Colors.white);
    }
    final head = Path()
      ..moveTo(end - 5, cy - 4)
      ..lineTo(end, cy)
      ..lineTo(end - 5, cy + 4);
    canvas.drawPath(
      head,
      Paint()
        ..color = connected
            ? const Color(0xFFA855F7)
            : ClxyWindowsPalette.timerDim
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant _RouteArrowPainter oldDelegate) =>
      connected != oldDelegate.connected || phase != oldDelegate.phase;
}

class _HomeUsageCard extends StatelessWidget {
  const _HomeUsageCard({required this.accounts, required this.activeAccount});

  final List<Account> accounts;
  final Account? activeAccount;

  @override
  Widget build(BuildContext context) {
    Account? listedPrimary;
    for (final account in accounts) {
      if (account.active) {
        listedPrimary = account;
        break;
      }
    }
    listedPrimary ??= _firstWhere(
      accounts,
      (a) => a.enabled && a.usage != null,
    );
    listedPrimary ??= _firstWhere(accounts, (a) => a.enabled);
    listedPrimary ??= _firstWhere(accounts, (a) => a.usage != null);
    listedPrimary ??= accounts.isNotEmpty ? accounts.first : null;

    final active = activeAccount;
    final listed = listedPrimary;
    Account? resolved;
    if (active == null) {
      resolved = listed;
    } else if (listed == null) {
      resolved = active;
    } else if (active.id.isNotEmpty &&
        listed.id.isNotEmpty &&
        active.id != listed.id) {
      resolved = active;
    } else {
      final activeChecked =
          active.usage?.checkedAt?.millisecondsSinceEpoch ?? 0;
      final listedChecked =
          listed.usage?.checkedAt?.millisecondsSinceEpoch ?? 0;
      if (active.usage == null && listed.usage != null) {
        resolved = listed;
      } else if (listed.usage == null) {
        resolved = active;
      } else {
        resolved = listedChecked > activeChecked ? listed : active;
      }
    }

    final usage = resolved?.usage;
    final unlimited = usage?.unlimited == true;
    final finite = !unlimited && usage != null && usage.limitBytes > 0;
    final limit = finite ? usage.limitBytes : 0;
    final serverRemaining = finite
        ? usage.remainingBytes.clamp(0, limit).toInt()
        : 0;
    final usedBytes = finite ? (limit - serverRemaining).clamp(0, limit) : 0;
    final remainingBytes = finite ? (limit - usedBytes).clamp(0, limit) : 0;
    final usedPercent = finite && limit > 0
        ? ((usedBytes * 100) / limit).floor().clamp(0, 100)
        : 0;
    final hasAccount = resolved != null || accounts.isNotEmpty;

    final usedText = finite || unlimited
        ? formatBytes(usedBytes)
        : usedBytes > 0
        ? formatBytes(usedBytes)
        : '—';
    final usedSubtitle = !hasAccount
        ? 'No active account'
        : unlimited
        ? (resolved?.email.isNotEmpty == true
              ? resolved!.email
              : 'Unlimited account')
        : finite
        ? '${resolved?.email.isNotEmpty == true ? resolved!.email : 'Active account'} • $usedPercent% used'
        : 'Quota syncing…';
    final remainingText = unlimited
        ? '∞ Unlimited'
        : finite
        ? formatBytes(remainingBytes)
        : hasAccount
        ? 'Pending'
        : '—';
    final remainingSubtitle = unlimited
        ? 'Unlimited plan'
        : finite
        ? 'of ${formatBytes(limit)}'
        : hasAccount
        ? 'Tap Refresh in Profile'
        : 'Add account to track';

    return Container(
      decoration: BoxDecoration(
        color: ClxyWindowsPalette.routeCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ClxyWindowsPalette.glassBorder),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Account Data Used',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    color: ClxyWindowsPalette.dim,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  usedText,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    color: ClxyWindowsPalette.text,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  usedSubtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    color: ClxyWindowsPalette.muted,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          Container(width: 1, height: 34, color: const Color(0x2E94A3B8)),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'Remaining',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      color: ClxyWindowsPalette.dim,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    remainingText,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      color: ClxyWindowsPalette.cyanText,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    remainingSubtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      color: ClxyWindowsPalette.muted,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Account? _firstWhere(List<Account> accounts, bool Function(Account) test) {
    for (final account in accounts) {
      if (test(account)) return account;
    }
    return null;
  }
}

class _HomeAlertCard extends StatelessWidget {
  const _HomeAlertCard({
    required this.message,
    required this.action,
    required this.failure,
    required this.onTap,
  });

  final String message;
  final String action;
  final bool failure;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: const Color(0xD90F172E),
    borderRadius: BorderRadius.circular(10),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: failure
                ? ClxyWindowsPalette.red.withValues(alpha: .45)
                : ClxyWindowsPalette.amber.withValues(alpha: .40),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                message,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  color: ClxyWindowsPalette.secondary,
                  fontSize: 11,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              action,
              style: const TextStyle(
                fontFamily: 'Inter',
                color: ClxyWindowsPalette.cyanText,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _WindowsModeSelector extends StatelessWidget {
  const _WindowsModeSelector({
    required this.status,
    required this.core,
    required this.selected,
    required this.onSelected,
  });

  final CoreStatus status;
  final CoreController core;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final modes = <(String, String)>[
      ('clear', 'Proxy'),
      if (status.systemProxySupported) ('set', 'System proxy'),
      if (status.tunSupported) ('tun', 'TUN'),
    ];
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xD10C1328),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0x2994A3B8)),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          for (var i = 0; i < modes.length; i++) ...[
            if (i > 0) const SizedBox(width: 6),
            Expanded(
              child: GestureDetector(
                onTap:
                    core.switchingProxy ||
                        core.installingTun ||
                        modes[i].$1 == selected
                    ? null
                    : () => onSelected(modes[i].$1),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  constraints: const BoxConstraints(minHeight: 46),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    gradient: modes[i].$1 == selected
                        ? const LinearGradient(
                            colors: [
                              Color(0x3D00E5FF),
                              Color(0x4D3B82F6),
                              Color(0x4D9333EA),
                            ],
                          )
                        : null,
                    border: Border.all(
                      color: modes[i].$1 == selected
                          ? ClxyWindowsPalette.cyan.withValues(alpha: .62)
                          : Colors.transparent,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    modes[i].$2,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      color: modes[i].$1 == selected
                          ? Colors.white
                          : ClxyWindowsPalette.muted,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _HomeServerCard extends StatelessWidget {
  const _HomeServerCard({
    required this.code,
    required this.title,
    required this.subtitle,
    required this.pingMs,
    required this.onTap,
  });

  final String code;
  final String title;
  final String subtitle;
  final int pingMs;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: ClxyWindowsPalette.card,
    borderRadius: BorderRadius.circular(12),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        constraints: const BoxConstraints(minHeight: 60),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: ClxyWindowsPalette.glassBorder),
        ),
        child: Row(
          children: [
            ClxyWindowsCircularFlag(code: code, size: 34),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      color: ClxyWindowsPalette.text,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            color: ClxyWindowsPalette.muted,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      _ClxySignalBars(pingMs: pingMs),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.keyboard_arrow_right_rounded,
              size: 20,
              color: ClxyWindowsPalette.muted,
            ),
          ],
        ),
      ),
    ),
  );
}

class _ClxySignalBars extends StatelessWidget {
  const _ClxySignalBars({required this.pingMs});

  final int pingMs;

  @override
  Widget build(BuildContext context) {
    final active = pingMs <= 0
        ? 3
        : pingMs < 120
        ? 4
        : pingMs < 240
        ? 3
        : pingMs < 450
        ? 2
        : 1;
    final accent = pingMs <= 0 || pingMs < 400
        ? ClxyWindowsPalette.cyan
        : pingMs < 1000
        ? ClxyWindowsPalette.amber
        : ClxyWindowsPalette.red;
    const heights = [.3, .5, .75, 1.0];
    return SizedBox(
      width: 14,
      height: 10,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < heights.length; i++) ...[
            if (i > 0) const SizedBox(width: 1),
            Expanded(
              child: Container(
                height: 10 * heights[i],
                decoration: BoxDecoration(
                  color: i < active ? accent : ClxyWindowsPalette.barInactive,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class ClxyWindowsCircularFlag extends StatelessWidget {
  const ClxyWindowsCircularFlag({
    super.key,
    required this.code,
    this.size = 34,
  });

  final String code;
  final double size;

  @override
  Widget build(BuildContext context) => CustomPaint(
    size: Size.square(size),
    painter: _CircularFlagPainter(code.trim().toUpperCase()),
  );
}

class _CircularFlagPainter extends CustomPainter {
  _CircularFlagPainter(this.code);

  final String code;

  void _rect(
    Canvas c,
    Size s,
    Color color,
    double x,
    double y,
    double w,
    double h,
  ) {
    c.drawRect(
      Rect.fromLTWH(s.width * x, s.height * y, s.width * w, s.height * h),
      Paint()..color = color,
    );
  }

  void _circle(Canvas c, Size s, Color color, double x, double y, double r) {
    c.drawCircle(
      Offset(s.width * x, s.height * y),
      s.width * r,
      Paint()..color = color,
    );
  }

  void _horizontal(Canvas c, Size s, Color a, Color b, Color d) {
    _rect(c, s, a, 0, 0, 1, 1 / 3);
    _rect(c, s, b, 0, 1 / 3, 1, 1 / 3);
    _rect(c, s, d, 0, 2 / 3, 1, 1 / 3);
  }

  void _vertical(Canvas c, Size s, Color a, Color b, Color d) {
    _rect(c, s, a, 0, 0, 1 / 3, 1);
    _rect(c, s, b, 1 / 3, 0, 1 / 3, 1);
    _rect(c, s, d, 2 / 3, 0, 1 / 3, 1);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Offset.zero & size;
    canvas.save();
    canvas.clipPath(Path()..addOval(bounds));
    final white = Colors.white;
    switch (code) {
      case '':
      case 'REC':
      case 'AUTO':
        canvas.drawRect(
          bounds,
          Paint()
            ..shader = const LinearGradient(
              colors: [
                ClxyWindowsPalette.cyan,
                ClxyWindowsPalette.blue,
                ClxyWindowsPalette.purple,
              ],
            ).createShader(bounds),
        );
        canvas.drawCircle(
          bounds.center,
          size.width * .32,
          Paint()
            ..color = Colors.white.withValues(alpha: .25)
            ..style = PaintingStyle.stroke
            ..strokeWidth = size.width * .06,
        );
        _circle(canvas, size, white, .5, .5, .12);
      case 'DE':
        _horizontal(
          canvas,
          size,
          const Color(0xFF111111),
          const Color(0xFFDD0000),
          const Color(0xFFFFCE00),
        );
      case 'NL':
        _horizontal(
          canvas,
          size,
          const Color(0xFFAE1C28),
          white,
          const Color(0xFF21468B),
        );
      case 'JP':
        canvas.drawRect(bounds, Paint()..color = white);
        _circle(canvas, size, const Color(0xFFBC002D), .5, .5, .28);
      case 'US':
        for (var i = 0; i < 13; i++) {
          _rect(
            canvas,
            size,
            i.isEven ? const Color(0xFFB22234) : white,
            0,
            i / 13,
            1,
            1 / 13 + .005,
          );
        }
        _rect(canvas, size, const Color(0xFF3C3B6E), 0, 0, .46, .54);
        for (var row = 0; row < 3; row++) {
          for (var col = 0; col < 3; col++) {
            _circle(
              canvas,
              size,
              white,
              .10 + col * .13,
              .12 + row * .14,
              .028,
            );
          }
        }
      case 'SG':
        _rect(canvas, size, const Color(0xFFEF3340), 0, 0, 1, .5);
        _rect(canvas, size, white, 0, .5, 1, .5);
        _circle(canvas, size, white, .30, .26, .14);
        _circle(canvas, size, const Color(0xFFEF3340), .35, .26, .12);
      case 'GB':
        canvas.drawRect(bounds, Paint()..color = const Color(0xFF012169));
        canvas.drawLine(
          Offset.zero,
          Offset(size.width, size.height),
          Paint()
            ..color = white
            ..strokeWidth = size.width * .18,
        );
        canvas.drawLine(
          Offset(size.width, 0),
          Offset(0, size.height),
          Paint()
            ..color = white
            ..strokeWidth = size.width * .18,
        );
        canvas.drawLine(
          Offset.zero,
          Offset(size.width, size.height),
          Paint()
            ..color = const Color(0xFFC8102E)
            ..strokeWidth = size.width * .08,
        );
        canvas.drawLine(
          Offset(size.width, 0),
          Offset(0, size.height),
          Paint()
            ..color = const Color(0xFFC8102E)
            ..strokeWidth = size.width * .08,
        );
        _rect(canvas, size, white, .39, 0, .22, 1);
        _rect(canvas, size, white, 0, .39, 1, .22);
        _rect(canvas, size, const Color(0xFFC8102E), .43, 0, .14, 1);
        _rect(canvas, size, const Color(0xFFC8102E), 0, .43, 1, .14);
      case 'IR':
        _horizontal(
          canvas,
          size,
          const Color(0xFF239F40),
          white,
          const Color(0xFFDA0000),
        );
        _circle(canvas, size, const Color(0xFFDA0000), .5, .5, .08);
      case 'FR':
        _vertical(
          canvas,
          size,
          const Color(0xFF002654),
          white,
          const Color(0xFFED2939),
        );
      case 'IT':
        _vertical(
          canvas,
          size,
          const Color(0xFF009246),
          white,
          const Color(0xFFCE2B37),
        );
      case 'ES':
        _rect(canvas, size, const Color(0xFFAA151B), 0, 0, 1, .25);
        _rect(canvas, size, const Color(0xFFF1BF00), 0, .25, 1, .5);
        _rect(canvas, size, const Color(0xFFAA151B), 0, .75, 1, .25);
      case 'RU':
        _horizontal(
          canvas,
          size,
          white,
          const Color(0xFF0039A6),
          const Color(0xFFD52B1E),
        );
      case 'ID':
        _rect(canvas, size, const Color(0xFFFF0000), 0, 0, 1, .5);
        _rect(canvas, size, white, 0, .5, 1, .5);
      case 'CA':
        _rect(canvas, size, const Color(0xFFFF0000), 0, 0, .25, 1);
        _rect(canvas, size, white, .25, 0, .50, 1);
        _rect(canvas, size, const Color(0xFFFF0000), .75, 0, .25, 1);
        _circle(canvas, size, const Color(0xFFFF0000), .5, .5, .14);
      default:
        final hash = code.codeUnits.fold<int>(0, (a, b) => a + b);
        final c1 = HSLColor.fromAHSL(1, (hash * 7.0) % 360, .65, .42).toColor();
        final c2 = HSLColor.fromAHSL(
          1,
          (hash * 7.0 + 48) % 360,
          .72,
          .30,
        ).toColor();
        canvas.drawRect(
          bounds,
          Paint()
            ..shader = LinearGradient(colors: [c1, c2]).createShader(bounds),
        );
        for (var i = 0; i < 6; i++) {
          final angle = i * math.pi / 3;
          _circle(
            canvas,
            size,
            Colors.white.withValues(alpha: .22),
            .5 + math.cos(angle) * .24,
            .5 + math.sin(angle) * .24,
            .05,
          );
        }
    }
    canvas.restore();
    canvas.drawOval(
      bounds,
      Paint()
        ..color = Colors.white.withValues(alpha: .16)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(covariant _CircularFlagPainter oldDelegate) =>
      code != oldDelegate.code;
}

class ClxyWindowsProfile extends StatelessWidget {
  const ClxyWindowsProfile({
    super.key,
    required this.core,
    required this.settings,
    required this.push,
  });

  final CoreController core;
  final AppSettings settings;
  final void Function(String title, Widget Function() page) push;

  void _settings(String title, SettingsSection section) => push(
    title,
    () => SettingsPage(core: core, settings: settings, section: section),
  );

  @override
  Widget build(BuildContext context) {
    final accounts = core.accounts?.accounts ?? const <Account>[];
    final status = core.status;
    final version = status?.version.isNotEmpty == true
        ? status!.version
        : '1.0.18';
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 10, 24, 24),
      children: [
        Row(
          children: [
            const ClxyWindowsBrand(logoSize: 28, showLabel: false),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Profile',
                style: TextStyle(
                  fontFamily: 'Inter',
                  color: ClxyWindowsPalette.text,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              'Core v$version',
              style: const TextStyle(
                fontFamily: 'Inter',
                color: ClxyWindowsPalette.dim,
                fontSize: 11,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Text(
                'CLXY Accounts (${accounts.length})',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  color: ClxyWindowsPalette.muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            _AddAccountButton(
              onTap: () => startAddAccount(context, core, settings),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (accounts.isEmpty) ...[
          const _NoAccountsCard(),
          const SizedBox(height: 12),
        ] else
          for (var i = 0; i < accounts.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _ProfileAccountCard(
                core: core,
                settings: settings,
                account: accounts[i],
                index: i,
                count: accounts.length,
              ),
            ),
        const _ProfileSectionLabel('General', top: 4),
        const SizedBox(height: 12),
        _ProfileMenuCard(
          icon: Icons.tune_rounded,
          title: 'General',
          subtitle: 'Home IP badge, live notification speed, sign-in method & account switch %',
          onTap: () => _settings('General', SettingsSection.general),
        ),
        const SizedBox(height: 12),
        _ProfileMenuCard(
          icon: Icons.computer_rounded,
          title: 'Connection',
          subtitle: 'H2/H3 transport, IPv4/IPv6, pool size, max connections, pinned server & LAN listen',
          onTap: () => _settings('Connection', SettingsSection.connection),
        ),
        const SizedBox(height: 12),
        _ProfileMenuCard(
          icon: Icons.alt_route_rounded,
          title: 'Routing',
          subtitle: 'Regional direct presets, AdBlock, GeoSite/GeoIP updates & route tester',
          onTap: () => _settings('Routing', SettingsSection.routing),
        ),
        const SizedBox(height: 12),
        _ProfileMenuCard(
          icon: Icons.dns_rounded,
          title: 'DNS',
          subtitle: 'System, Cloudflare, Google, Quad9, custom DoH/DoT & live DNS check',
          onTap: () => _settings('DNS', SettingsSection.dns),
        ),
        const SizedBox(height: 12),
        _ProfileMenuCard(
          icon: Icons.shield_rounded,
          title: 'VPN settings',
          subtitle: 'Per-app split tunneling, interface MTU, QUIC forwarding & UDP notices',
          onTap: () => _settings('VPN settings', SettingsSection.tun),
        ),
        const SizedBox(height: 12),
        const _ProfileSectionLabel('If the service is blocked', top: 6),
        const SizedBox(height: 12),
        _ProfileMenuCard(
          icon: Icons.cloud_queue_rounded,
          title: 'Relay server',
          subtitle: 'Shared relay fallback, Personal Worker/PHP relay, ECH & control endpoint',
          onTap: () => _settings('Relay server', SettingsSection.relay),
        ),
        const SizedBox(height: 12),
        _ProfileMenuCard(
          icon: Icons.content_cut_rounded,
          title: 'TLS fragmentation',
          subtitle: 'ClientHello split modes: Off, 1st Byte, Split SNI, or 2 TLS Records',
          onTap: () => _settings('TLS fragmentation', SettingsSection.fragment),
        ),
        const SizedBox(height: 12),
        _ProfileMenuCard(
          icon: Icons.hub_rounded,
          title: 'Upstream proxy',
          subtitle: 'Chain connections through a local or remote SOCKS5 proxy',
          onTap: () =>
              _settings('Upstream proxy', SettingsSection.upstreamProxy),
        ),
        const SizedBox(height: 12),
        const _ProfileSectionLabel('App', top: 6),
        const SizedBox(height: 12),
        _ProfileMenuCard(
          icon: Icons.build_rounded,
          title: 'Advanced',
          subtitle: 'Dashboard API bind, detailed logging, retry/restart core & open-source licenses',
          onTap: () => _settings('Advanced', SettingsSection.advanced),
        ),
        const SizedBox(height: 12),
        _ProfileMenuCard(
          icon: Icons.receipt_long_rounded,
          title: 'Logs',
          subtitle: 'Live & total traffic, connection test, filtered core logs & socket table',
          onTap: () =>
              push('Logs', () => LogsPage(core: core, settings: settings)),
        ),
        const SizedBox(height: 4),
      ],
    );
  }
}

class _AddAccountButton extends StatelessWidget {
  const _AddAccountButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: ClxyWindowsPalette.card,
    borderRadius: BorderRadius.circular(8),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: ClxyWindowsPalette.cyanBorder),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add_rounded, size: 15, color: ClxyWindowsPalette.cyan),
            SizedBox(width: 5),
            Text(
              'Add Account',
              style: TextStyle(
                fontFamily: 'Inter',
                color: ClxyWindowsPalette.cyanText,
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _NoAccountsCard extends StatelessWidget {
  const _NoAccountsCard();

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    decoration: BoxDecoration(
      color: ClxyWindowsPalette.card,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: ClxyWindowsPalette.glassBorder),
    ),
    child: const Column(
      children: [
        Text(
          'No accounts configured',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Inter',
            color: ClxyWindowsPalette.text,
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 4),
        Text(
          'Add one or more CLXY Accounts for automatic failover and encrypted browsing.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Inter',
            color: ClxyWindowsPalette.muted,
            fontSize: 11.5,
          ),
        ),
      ],
    ),
  );
}

class _ProfileSectionLabel extends StatelessWidget {
  const _ProfileSectionLabel(this.text, {this.top = 0});

  final String text;
  final double top;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(top: top, bottom: 0),
    child: Text(
      text,
      style: const TextStyle(
        fontFamily: 'Inter',
        color: ClxyWindowsPalette.cyanText,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

class _ProfileMenuCard extends StatelessWidget {
  const _ProfileMenuCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: ClxyWindowsPalette.card,
    borderRadius: BorderRadius.circular(12),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        constraints: const BoxConstraints(minHeight: 60),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: ClxyWindowsPalette.glassBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: Color(0x382563EB),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 19, color: ClxyWindowsPalette.cyan),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      color: ClxyWindowsPalette.text,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      color: ClxyWindowsPalette.muted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 0),
            const Icon(
              Icons.keyboard_arrow_right_rounded,
              size: 20,
              color: ClxyWindowsPalette.muted,
            ),
          ],
        ),
      ),
    ),
  );
}

class _ProfileAccountCard extends StatelessWidget {
  const _ProfileAccountCard({
    required this.core,
    required this.settings,
    required this.account,
    required this.index,
    required this.count,
  });

  final CoreController core;
  final AppSettings settings;
  final Account account;
  final int index;
  final int count;

  Future<void> _remove(BuildContext context) async {
    final l = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.removeTitle),
        content: Text(l.removeBody(account.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: ClxyWindowsPalette.red,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l.remove),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      await runShowingErrors(context, () => core.remove(account));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final a = account;
    final usage = a.usage;
    final busy = core.busyAccounts.contains(a.id);
    final computedPercent = usage != null && usage.limitBytes > 0
        ? (usage.usedBytes * 100 / usage.limitBytes)
        : 0.0;
    final percent = (a.usedPercent > 0 ? a.usedPercent : computedPercent).clamp(
      0.0,
      100.0,
    );
    final fraction = usage != null && !usage.unlimited && usage.limitBytes > 0
        ? percent / 100
        : 0.0;
    final statusColor = switch (a.status) {
      AccountStatus.ready => ClxyWindowsPalette.green,
      AccountStatus.reauthRequired => ClxyWindowsPalette.red,
      AccountStatus.reserved => ClxyWindowsPalette.amber,
      _ => ClxyWindowsPalette.muted,
    };
    final statusLabel = a.status.toUpperCase();
    final reason = accountReason(l, a, core.status?.thresholdPercent ?? 95);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ClxyWindowsPalette.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: a.active
              ? ClxyWindowsPalette.cyanBorder
              : ClxyWindowsPalette.glassBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (a.active) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: ClxyWindowsPalette.cyan.withValues(
                                alpha: .16,
                              ),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Text(
                              'ACTIVE',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                color: ClxyWindowsPalette.cyanText,
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],
                        Text(
                          statusLabel,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            color: statusColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      a.email.isNotEmpty ? a.email : a.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        color: ClxyWindowsPalette.text,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (busy)
                const SizedBox.square(
                  dimension: 22,
                  child: CircularProgressIndicator(
                    color: ClxyWindowsPalette.cyan,
                    strokeWidth: 2,
                  ),
                )
              else
                Switch(
                  value: a.enabled,
                  onChanged: (value) => runShowingErrors(
                    context,
                    () => core.setEnabled(a, value),
                  ),
                  activeThumbColor: ClxyWindowsPalette.cyan,
                  activeTrackColor: ClxyWindowsPalette.cyan.withValues(
                    alpha: .35,
                  ),
                ),
            ],
          ),
          if (usage != null) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: usage.unlimited ? .15 : fraction,
                minHeight: 5,
                backgroundColor: ClxyWindowsPalette.barInactive,
                color: fraction > .9
                    ? ClxyWindowsPalette.red
                    : ClxyWindowsPalette.cyan,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              usage.unlimited
                  ? 'Unlimited quota'
                  : usage.limitBytes > 0
                  ? '${formatBytes(usage.usedBytes)} / ${formatBytes(usage.limitBytes)} (${(fraction * 100).toInt()}%)'
                  : 'Quota unknown until first use',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Inter',
                color: ClxyWindowsPalette.muted,
                fontSize: 10.5,
              ),
            ),
          ],
          if (reason != null && reason.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              reason,
              style: const TextStyle(
                fontFamily: 'Inter',
                color: ClxyWindowsPalette.amber,
                fontSize: 10.5,
              ),
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              if (!a.active && a.enabled)
                _AccountTextAction(
                  label: 'Use Now',
                  color: ClxyWindowsPalette.cyanText,
                  onTap: () =>
                      runShowingErrors(context, () => core.activate(a)),
                ),
              if (a.needsSignIn)
                _AccountTextAction(
                  label: 'Sign In',
                  color: ClxyWindowsPalette.amber,
                  onTap: () =>
                      startAddAccount(context, core, settings, email: a.email),
                ),
              const Spacer(),
              if (index > 0)
                _AccountIconAction(
                  icon: Icons.arrow_upward_rounded,
                  tooltip: 'Move Up',
                  onTap: busy
                      ? null
                      : () => runShowingErrors(context, () => core.move(a, -1)),
                ),
              if (index < count - 1)
                _AccountIconAction(
                  icon: Icons.arrow_downward_rounded,
                  tooltip: 'Move Down',
                  onTap: busy
                      ? null
                      : () => runShowingErrors(context, () => core.move(a, 1)),
                ),
              _AccountIconAction(
                icon: Icons.refresh_rounded,
                tooltip: 'Refresh Quota',
                tint: ClxyWindowsPalette.cyanText,
                onTap: busy
                    ? null
                    : () =>
                          runShowingErrors(context, () => core.refreshQuota(a)),
              ),
              _AccountIconAction(
                icon: Icons.delete_outline_rounded,
                tooltip: 'Remove Account',
                tint: ClxyWindowsPalette.red,
                onTap: busy ? null : () => _remove(context),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AccountTextAction extends StatelessWidget {
  const _AccountTextAction({
    required this.label,
    required this.color,
    required this.onTap,
  });

  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Inter',
            color: color,
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    ),
  );
}

class _AccountIconAction extends StatelessWidget {
  const _AccountIconAction({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.tint = ClxyWindowsPalette.muted,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;
  final Color tint;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 34,
    height: 34,
    child: IconButton(
      tooltip: tooltip,
      padding: EdgeInsets.zero,
      onPressed: onTap,
      icon: Icon(icon, size: 16, color: tint),
    ),
  );
}
