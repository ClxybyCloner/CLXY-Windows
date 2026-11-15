import 'dart:async';

import 'package:flutter/material.dart';

import '../app_settings.dart';
import '../core/core_api.dart';
import '../core/core_controller.dart';
import '../core/models.dart';
import '../l10n/app_localizations.dart';
import 'format.dart';
import 'browser_signin.dart';
import 'widgets.dart';
import 'windows_parity_ui.dart';

/// The server list, one choice in one list: Recommended and Fastest, which
/// the app picks, then the locations with their real delay. A tap on a row
/// chooses it (`proxy.country`: empty for Mozilla's recommended location,
/// `fastest` for the lowest real delay, otherwise a country).
class ServersPage extends StatefulWidget {
  const ServersPage({
    super.key,
    required this.core,
    required this.settings,
    this.windowsAndroidStyle = false,
    this.onCloseToHome,
    this.onOpenRelay,
  });

  final CoreController core;
  final AppSettings settings;
  final bool windowsAndroidStyle;
  final VoidCallback? onCloseToHome;
  final VoidCallback? onOpenRelay;

  @override
  State<ServersPage> createState() => _ServersPageState();
}

/// How old measured delays are before the page measures them again when
/// it opens.
const _pingStale = Duration(minutes: 10);

class _ServersPageState extends State<ServersPage> {
  List<Location>? _locations;
  DateTime? _pingedAt;
  String _country = '';
  bool _testing = false;
  String _query = '';
  String? _loadError;

  /// The choice being saved ('' recommended, 'fastest', or a code).
  String? _busy;
  String? _summary;

  CoreController get _core => widget.core;

  /// No account yet: the delays cannot be measured (Mozilla's servers
  /// answer only an account's pass), so the page says to add one instead.
  bool get _noAccounts => _core.status?.totalAccounts == 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final list = await _core.call((api) => api.locations());
      final config = await _core.settings();
      if (!mounted) return;
      setState(() {
        _locations = list.locations;
        _pingedAt = list.pingedAt;
        _loadError = null;
        if (config['proxy'] case {'country': final String country}) {
          _country = country;
        }
      });
      // Delays measured a while ago, or never: measured again at once (the
      // core does it also while the proxy is off).
      final at = _pingedAt;
      if (!_noAccounts &&
          (at == null || DateTime.now().difference(at) > _pingStale)) {
        unawaited(_test());
      }
    } on CoreApiException catch (e) {
      if (mounted) {
        if (widget.windowsAndroidStyle) {
          setState(() => _loadError = e.message);
        } else {
          showError(context, e.message);
        }
      }
    } on CoreUnavailable {
      if (mounted && widget.windowsAndroidStyle) {
        setState(() => _loadError = 'The connection service is unavailable.');
      }
    }
  }

  Future<void> _choose(String country) async {
    if (_busy != null || _country.toLowerCase() == country.toLowerCase()) {
      return;
    }
    setState(() => _busy = country);
    final ok = await runShowingErrors(
      context,
      () => _core.setLocation(country),
    );
    if (!mounted) return;
    setState(() {
      _busy = null;
      if (ok) _country = country;
    });
  }

  Future<void> _test() async {
    final l = AppLocalizations.of(context);
    final codes = [
      for (final loc in _locations ?? const <Location>[]) loc.code,
    ];
    setState(() {
      _testing = true;
      _summary = null;
    });
    try {
      final result = await _core.call((api) => api.pingLocations(codes));
      final tested = {for (final loc in result.locations) loc.code: loc};
      if (!mounted) return;
      setState(() {
        _locations = [
          for (final loc in _locations ?? const <Location>[])
            tested[loc.code] ?? loc,
        ];
        _pingedAt = result.pingedAt ?? DateTime.now();
        final answered = result.locations.where((loc) => loc.answered).length;
        _summary = l.delaySummary(answered, result.locations.length);
      });
    } on CoreApiException {
      // The core's own words are for the log; the user gets what to do.
      if (mounted) showError(context, l.delayTestFailed);
    } on CoreUnavailable catch (e) {
      if (mounted) showError(context, describeProblem(l, e));
    } finally {
      if (mounted) setState(() => _testing = false);
    }
  }

  /// Every country, without Mozilla's recommended location (the choice
  /// above), fastest first, then by name in the app's language.
  List<Location> _countries(AppLocalizations l) {
    final list = [
      for (final loc in _locations ?? const <Location>[])
        if (!isRecommendedPlace(loc.code)) loc,
    ];
    list.sort((a, b) {
      final da = a.answered ? a.pingMs : 1 << 30;
      final db = b.answered ? b.pingMs : 1 << 30;
      if (da != db) return da.compareTo(db);
      return nameSortKey(
        l.localeName,
        locationName(l, a.code, a.name),
      ).compareTo(nameSortKey(l.localeName, locationName(l, b.code, b.name)));
    });
    return list;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.windowsAndroidStyle) return _buildWindowsAndroid(context);
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final chosen = _country.toLowerCase();
    final countries = _countries(l);
    final recommended = (_locations ?? const <Location>[])
        .where((loc) => isRecommendedPlace(loc.code))
        .firstOrNull;
    final delayLine =
        _summary ??
        (_pingedAt == null ? null : l.testedAgo(formatAgo(l, _pingedAt!)));
    final noAccounts = _noAccounts;
    return ListView(
      padding: pagePadding(context),
      children: [
        PageTitle(l.navServers),
        if (noAccounts) ...[
          NoAccountsPanel(
            onAdd: () => startAddAccount(context, _core, widget.settings),
          ),
          const SizedBox(height: 12),
        ],
        _SectionHeader(title: l.autoSection),
        _ChoiceCard(
          children: [
            _ChoiceRow(
              leading: const CountryFlag(code: 'REC', width: 36),
              title: l.modeRecommended,
              subtitle: l.modeRecommendedHint,
              delay: recommended == null
                  ? null
                  : _Delay(location: recommended, testing: _testing),
              selected: chosen == '',
              busy: _busy == '',
              onTap: () => _choose(''),
            ),
            _ChoiceRow(
              leading: const _IconTile(icon: Icons.bolt_rounded),
              title: l.modeFastest,
              subtitle: l.modeFastestHint,
              selected: chosen == 'fastest',
              busy: _busy == 'fastest',
              onTap: () => _choose('fastest'),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _SectionHeader(
          title: l.locationsSection,
          action: TextButton.icon(
            onPressed: !_testing && _locations != null && !noAccounts
                ? _test
                : null,
            icon: _testing
                ? const SizedBox.square(
                    dimension: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.speed_rounded, size: 18),
            label: Text(_testing ? l.testingDelay : l.testDelay),
          ),
        ),
        if (delayLine != null)
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(4, 0, 4, 8),
            child: Text(delayLine, style: muted),
          ),
        if (_locations == null)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (countries.isEmpty)
          Panel(child: Text(l.noServers, style: muted))
        else
          _ChoiceCard(
            children: [
              for (final loc in countries)
                _ChoiceRow(
                  leading: CountryFlag(code: loc.code, width: 36),
                  title: locationName(l, loc.code, loc.name),
                  subtitle: _subtitle(loc),
                  delay: _Delay(location: loc, testing: _testing),
                  selected: chosen == loc.code.toLowerCase(),
                  busy: _busy?.toLowerCase() == loc.code.toLowerCase(),
                  onTap: () => _choose(loc.code),
                ),
            ],
          ),
      ],
    );
  }

  bool _isActive(String country) {
    final status = _core.status;
    return status?.proxyOn == true &&
        status!.selection.toLowerCase() == country.toLowerCase();
  }

  Future<void> _selectOrDisconnect(String country) async {
    if (_busy != null) return;
    if (_isActive(country)) {
      setState(() => _busy = country);
      await runShowingErrors(context, () => _core.setOn(false));
      if (mounted) setState(() => _busy = null);
    } else {
      await _choose(country);
    }
  }

  Widget _buildWindowsAndroid(BuildContext context) {
    final l = AppLocalizations.of(context);
    final locations = _locations ?? const <Location>[];
    final recommended = locations
        .where((loc) => loc.recommended || isRecommendedPlace(loc.code))
        .firstOrNull;
    final query = _query.trim();
    final lowerQuery = query.toLowerCase();
    final recName = recommended == null || recommended.name.isEmpty
        ? 'Recommended'
        : locationName(l, recommended.code, recommended.name);
    final autoQueryMatches =
        query.isEmpty ||
        'clxy-auto.m1.fastly recommended auto fastest clxy-fast'.contains(
          lowerQuery,
        ) ||
        recName.toLowerCase().contains(lowerQuery);
    final measuredPings = [
      for (final loc in locations)
        if (!isRecommendedPlace(loc.code) && loc.pingMs > 0) loc.pingMs,
    ];
    final fastestPing = measuredPings.isEmpty
        ? 0
        : measuredPings.reduce((a, b) => a < b ? a : b);
    final global = locations
        .where((loc) => !isRecommendedPlace(loc.code))
        .where((loc) {
          if (lowerQuery.isEmpty) return true;
          final display = _serverTitle(l, loc, locations.indexOf(loc));
          return <String>[
            display,
            locationName(l, loc.code, loc.name),
            loc.city,
            loc.code,
            loc.server,
          ].any((value) => value.toLowerCase().contains(lowerQuery));
        })
        .toList(growable: false);
    final loading = _locations == null && _loadError == null;

    Widget autoCard({
      required String code,
      required String title,
      required String subtitle,
      required int ping,
    }) {
      final active = _isActive(code);
      return _WindowsAutoServerCard(
        icon: Icons.public_rounded,
        title: title,
        subtitle: subtitle,
        pingMs: ping,
        selected: active,
        busy: _busy == code,
        onTap: () => _selectOrDisconnect(code),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 10),
          child: Row(
            children: [
              const ClxyWindowsBrand(logoSize: 28, showLabel: false),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'All Server',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    color: ClxyWindowsPalette.text,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              SizedBox(
                height: 40,
                child: OutlinedButton.icon(
                  onPressed: !_testing && _locations != null ? _test : null,
                  icon: _testing
                      ? const SizedBox.square(
                          dimension: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 1.7,
                            color: ClxyWindowsPalette.cyan,
                          ),
                        )
                      : const Icon(Icons.speed_rounded, size: 15),
                  label: Text(_testing ? 'Pinging' : 'Ping'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: ClxyWindowsPalette.cyanText,
                    backgroundColor: ClxyWindowsPalette.card,
                    side: const BorderSide(
                      color: ClxyWindowsPalette.glassBorder,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    minimumSize: const Size(48, 40),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    textStyle: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              SizedBox(
                width: 40,
                height: 40,
                child: Material(
                  color: Colors.transparent,
                  shape: const CircleBorder(),
                  child: InkWell(
                    onTap:
                        widget.onCloseToHome ??
                        () => Navigator.of(context).maybePop(),
                    customBorder: const CircleBorder(),
                    child: const Icon(
                      Icons.close_rounded,
                      size: 20,
                      color: ClxyWindowsPalette.text,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: SizedBox(
            height: 46,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xE60F172E),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0x99334155)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: [
                  const Icon(
                    Icons.search_rounded,
                    color: ClxyWindowsPalette.muted,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      onChanged: (value) => setState(() => _query = value),
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        color: ClxyWindowsPalette.text,
                        fontSize: 12.5,
                      ),
                      cursorColor: ClxyWindowsPalette.cyan,
                      decoration: const InputDecoration.collapsed(
                        hintText: 'Search server here...',
                        hintStyle: TextStyle(
                          fontFamily: 'Inter',
                          color: ClxyWindowsPalette.dim,
                          fontSize: 12.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Expanded(
          child: loading
              ? const Center(
                  child: CircularProgressIndicator(
                    color: ClxyWindowsPalette.cyan,
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.only(bottom: 20),
                  children: [
                    if (autoQueryMatches) ...[
                      const _AndroidServerSectionLabel('Automatic server'),
                      const SizedBox(height: 10),
                      autoCard(
                        code: '',
                        title: 'CLXY-AUTO.M1.FASTLY · Recommended',
                        subtitle:
                            '${recommended != null && recommended.name.isNotEmpty ? locationName(l, recommended.code, recommended.name) : 'Auto Route'}${(recommended?.pingMs ?? 0) > 0 ? ' • ${recommended!.pingMs}ms' : ' • Auto'}',
                        ping: recommended?.pingMs ?? 0,
                      ),
                      const SizedBox(height: 10),
                      autoCard(
                        code: 'fastest',
                        title: 'CLXY-FAST.M1.FASTLY · Fastest Location',
                        subtitle:
                            'Lowest measured ping${fastestPing > 0 ? ' • ${fastestPing}ms' : ' • Auto'}',
                        ping: fastestPing,
                      ),
                    ],
                    if (global.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      _AndroidServerSectionLabel(
                        'Global servers (${global.length})',
                      ),
                      const SizedBox(height: 10),
                      for (final loc in global) ...[
                        _WindowsGlobalServerCard(
                          location: loc,
                          title: _serverTitle(l, loc, locations.indexOf(loc)),
                          subtitle: _serverSubtitle(l, loc),
                          selected: _isActive(loc.code),
                          busy: _busy?.toLowerCase() == loc.code.toLowerCase(),
                          onTap: () => _selectOrDisconnect(loc.code),
                        ),
                        const SizedBox(height: 10),
                      ],
                    ] else if (_loadError != null) ...[
                      _WindowsServerLoadError(
                        message: lowerQuery.isNotEmpty
                            ? 'No matching servers found'
                            : 'Could not load global servers yet. Retry or enable Shared Relay Pool if direct access is blocked.',
                        onRetry: _load,
                        onRelay: widget.onOpenRelay,
                        showActions: lowerQuery.isEmpty,
                      ),
                    ] else if (_locations != null) ...[
                      _WindowsServerEmpty(
                        message: lowerQuery.isNotEmpty
                            ? 'No matching servers found'
                            : 'No global servers found',
                      ),
                    ],
                  ],
                ),
        ),
      ],
    );
  }

  String _serverTitle(AppLocalizations l, Location loc, int index) {
    final hostDigits =
        loc.server.isNotEmpty && !RegExp(r'^\d').hasMatch(loc.server)
        ? RegExp(r'(\d{1,3})').firstMatch(loc.server)?.group(1)
        : null;
    final node = hostDigits ?? '${101 + index}';
    return 'CLXY$node.M1.FASTLY · ${locationName(l, loc.code, loc.name)}';
  }

  String _serverSubtitle(AppLocalizations l, Location loc) {
    final city = loc.city.isNotEmpty ? loc.city : loc.code.toUpperCase();
    if (loc.pingMs > 0) return '$city • ${loc.pingMs}ms';
    if (loc.pingError.isNotEmpty) return '$city • Timeout';
    return city;
  }

  /// A location's second line: its city when it says more than the
  /// country.
  String? _subtitle(Location loc) =>
      loc.city.isNotEmpty && loc.city != loc.name ? loc.city : null;
}

class _AndroidServerSectionLabel extends StatelessWidget {
  const _AndroidServerSectionLabel(this.title);
  final String title;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 2),
    child: Text(
      title,
      style: const TextStyle(
        fontFamily: 'Inter',
        color: ClxyWindowsPalette.muted,
        fontSize: 11.5,
      ),
    ),
  );
}

class _WindowsAutoServerCard extends StatelessWidget {
  const _WindowsAutoServerCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.pingMs,
    required this.selected,
    required this.busy,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final int pingMs;
  final bool selected;
  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: ClxyWindowsPalette.card,
    borderRadius: BorderRadius.circular(12),
    child: InkWell(
      onTap: busy ? null : onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        constraints: const BoxConstraints(minHeight: 58),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? ClxyWindowsPalette.cyanBorder
                : ClxyWindowsPalette.glassBorder,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    ClxyWindowsPalette.cyan,
                    ClxyWindowsPalette.blue,
                    ClxyWindowsPalette.purple,
                  ],
                ),
              ),
              child: Icon(icon, color: Colors.white, size: 19),
            ),
            const SizedBox(width: 12),
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
                      fontSize: 13.5,
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
                            fontSize: 10.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      _WindowsPingBars(pingMs: pingMs),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _WindowsConnectButton(
              label: selected ? 'Disconnect' : 'Connect',
              selected: selected,
              busy: busy,
              onTap: onTap,
            ),
          ],
        ),
      ),
    ),
  );
}

class _WindowsGlobalServerCard extends StatelessWidget {
  const _WindowsGlobalServerCard({
    required this.location,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.busy,
    required this.onTap,
  });

  final Location location;
  final String title;
  final String subtitle;
  final bool selected;
  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: ClxyWindowsPalette.card,
    borderRadius: BorderRadius.circular(12),
    child: InkWell(
      onTap: busy ? null : onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        constraints: const BoxConstraints(minHeight: 58),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? ClxyWindowsPalette.cyanBorder
                : ClxyWindowsPalette.glassBorder,
          ),
        ),
        child: Row(
          children: [
            ClxyWindowsCircularFlag(code: location.code, size: 34),
            const SizedBox(width: 12),
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
                      fontSize: 13.5,
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
                            fontSize: 10.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      _WindowsPingBars(
                        pingMs: location.answered ? location.pingMs : 0,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _WindowsConnectButton(
              label: selected ? 'Disconnect' : 'Connect',
              selected: selected,
              busy: busy,
              onTap: onTap,
            ),
          ],
        ),
      ),
    ),
  );
}

class _WindowsConnectButton extends StatelessWidget {
  const _WindowsConnectButton({
    required this.label,
    required this.selected,
    required this.busy,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 36,
    child: OutlinedButton(
      onPressed: busy ? null : onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: selected ? Colors.white : const Color(0xFF38BDF8),
        backgroundColor: selected
            ? ClxyWindowsPalette.red
            : const Color(0xBF0F172A),
        side: BorderSide(
          color: selected ? const Color(0x66FB7185) : const Color(0x4738BDF8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
        minimumSize: const Size(78, 36),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        textStyle: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 11.5,
          fontWeight: FontWeight.w500,
        ),
      ),
      child: busy
          ? const SizedBox.square(
              dimension: 14,
              child: CircularProgressIndicator(strokeWidth: 1.7),
            )
          : Text(label),
    ),
  );
}

class _WindowsPingBars extends StatelessWidget {
  const _WindowsPingBars({required this.pingMs});
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
    final color = pingMs <= 0 || pingMs < 400
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
                  color: i < active ? color : ClxyWindowsPalette.barInactive,
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

class _WindowsServerEmpty extends StatelessWidget {
  const _WindowsServerEmpty({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: ClxyWindowsPalette.card,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: ClxyWindowsPalette.glassBorder),
    ),
    child: Text(
      message,
      textAlign: TextAlign.center,
      style: const TextStyle(
        fontFamily: 'Inter',
        color: ClxyWindowsPalette.muted,
        fontSize: 11.5,
      ),
    ),
  );
}

class _WindowsServerLoadError extends StatelessWidget {
  const _WindowsServerLoadError({
    required this.message,
    required this.onRetry,
    required this.onRelay,
    this.showActions = true,
  });

  final String message;
  final VoidCallback onRetry;
  final VoidCallback? onRelay;
  final bool showActions;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: ClxyWindowsPalette.card,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: ClxyWindowsPalette.glassBorder),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          message,
          style: const TextStyle(
            fontFamily: 'Inter',
            color: ClxyWindowsPalette.muted,
            fontSize: 11.5,
          ),
        ),
        if (showActions) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              TextButton(onPressed: onRetry, child: const Text('Retry')),
              if (onRelay != null)
                TextButton(
                  onPressed: onRelay,
                  child: const Text('Relay settings'),
                ),
            ],
          ),
        ],
      ],
    ),
  );
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.action});

  final String title;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(4, 8, 0, 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ?action,
        ],
      ),
    );
  }
}

/// Rows of choices in one card, divided by thin lines.
class _ChoiceCard extends StatelessWidget {
  const _ChoiceCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Card(
    margin: EdgeInsets.zero,
    clipBehavior: Clip.antiAlias,
    child: Column(
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) const Divider(height: 1),
          children[i],
        ],
      ],
    ),
  );
}

/// An icon in the size of a flag, for a choice that is not a country.
class _IconTile extends StatelessWidget {
  const _IconTile({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: 36,
      height: 27,
      decoration: BoxDecoration(
        color: scheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Icon(icon, size: 20, color: scheme.onTertiaryContainer),
    );
  }
}

/// One choice: what it is, its delay, and a radio mark; a tap chooses it.
class _ChoiceRow extends StatelessWidget {
  const _ChoiceRow({
    required this.leading,
    required this.title,
    required this.selected,
    required this.busy,
    required this.onTap,
    this.subtitle,
    this.delay,
  });

  final Widget leading;
  final String title;
  final String? subtitle;
  final Widget? delay;
  final bool selected;
  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Material(
      color: selected
          ? scheme.primary.withValues(alpha: 0.08)
          : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(14, 12, 12, 12),
          child: Row(
            children: [
              leading,
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              if (delay != null) ...[const SizedBox(width: 10), delay!],
              const SizedBox(width: 6),
              SizedBox.square(
                dimension: 24,
                child: busy
                    ? const Padding(
                        padding: EdgeInsets.all(3),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        selected
                            ? Icons.radio_button_checked_rounded
                            : Icons.radio_button_unchecked_rounded,
                        color: selected ? scheme.primary : scheme.outline,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A location's real delay as a small badge in its color. While the delays
/// are measured, a small spinner instead of the last results, which may be
/// old (a measurement while offline answers nothing). A location that did
/// not answer is grey, not red: it says nothing is wrong with the app.
class _Delay extends StatelessWidget {
  const _Delay({required this.location, required this.testing});

  final Location location;
  final bool testing;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final loc = location;
    final (text, color) = testing
        ? ('', muted)
        : loc.answered
        ? (l.milliseconds(loc.pingMs), delayColor(loc.pingMs))
        : loc.pingError.isNotEmpty
        ? (l.noAnswer, muted)
        : ('—', muted);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: testing
          ? SizedBox.square(
              dimension: 12,
              child: CircularProgressIndicator(strokeWidth: 1.5, color: muted),
            )
          : Text(
              text,
              style: theme.textTheme.labelMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
    );
  }
}
