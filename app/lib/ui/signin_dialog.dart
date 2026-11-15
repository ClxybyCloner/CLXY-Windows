import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/core_api.dart';
import '../core/core_controller.dart';
import '../core/models.dart';
import '../l10n/app_localizations.dart';
import 'widgets.dart';
import 'windows_parity_ui.dart';

/// Adds an account, or signs one in again: the core runs the sign-in and
/// the dialog shows whatever Mozilla asks for (codes, CAPTCHA, a link).
Future<void> showSignInDialog(
  BuildContext context,
  CoreController core, {
  String email = '',
  SignInState? started,
  VoidCallback? onBrowserRetry,
  bool accountSheet = false,
  bool firstRun = false,
  Future<void> Function()? onSignedIn,
}) => showDialog<void>(
  context: context,
  barrierDismissible: false,
  builder: (_) => _SignInDialog(
    core: core,
    email: email,
    started: started,
    onBrowserRetry: onBrowserRetry,
    accountSheet: accountSheet,
    firstRun: firstRun,
    onSignedIn: onSignedIn,
  ),
);

class _SignInDialog extends StatefulWidget {
  const _SignInDialog({
    required this.core,
    required this.email,
    this.started,
    this.onBrowserRetry,
    this.accountSheet = false,
    this.firstRun = false,
    this.onSignedIn,
  });

  final CoreController core;
  final String email;
  final SignInState? started;
  final VoidCallback? onBrowserRetry;
  final bool accountSheet;
  final bool firstRun;
  final Future<void> Function()? onSignedIn;

  @override
  State<_SignInDialog> createState() => _SignInDialogState();
}

class _SignInDialogState extends State<_SignInDialog> {
  late final _email = TextEditingController(text: widget.email);
  final _password = TextEditingController();
  final _answer = TextEditingController();
  final _form = GlobalKey<FormState>();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  SignInState? _state;
  String? _error;

  /// A sign-in started from the form whose password Mozilla has not
  /// accepted yet: the form stays (with the button busy) until it does,
  /// so a password manager is asked to save only a password that works.
  SignInState? _checking;

  /// A failure the person fixes in the form ([_formProblems]): its code
  /// and the core's text.
  String _formProblem = '';
  String _formProblemText = '';
  bool _sending = false;
  bool _showPassword = false;
  bool _completionPending = false;
  Timer? _poll;

  CoreApi? get _api => widget.core.api;

  @override
  void initState() {
    super.initState();
    if (widget.started != null) _follow(widget.started!);
  }

  @override
  void dispose() {
    _poll?.cancel();
    _email.dispose();
    _password.dispose();
    _answer.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  /// Failures of what was typed (a mistyped password or email): the form
  /// comes back with the fields as they were, to fix and send again.
  static const _formProblems = {
    SignInError.wrongPassword,
    SignInError.noAccount,
  };

  void _follow(SignInState s) {
    _poll?.cancel();
    final fromForm = _checking != null;
    _checking = null;
    if (!widget.accountSheet &&
        widget.onBrowserRetry == null &&
        s.step == SignInStep.failed &&
        _formProblems.contains(s.errorCode)) {
      _state = null;
      _formProblem = s.errorCode;
      _formProblemText = s.error;
      final wrongPassword = s.errorCode == SignInError.wrongPassword;
      final field = wrongPassword ? _password : _email;
      final focus = wrongPassword ? _passwordFocus : _emailFocus;
      field.selection = TextSelection.collapsed(offset: field.text.length);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) focus.requestFocus();
      });
      return;
    }
    if (fromForm) {
      if (s.passwordAccepted) {
        // The fields are still there: the phone's password manager (Android
        // autofill) may now offer to save them, or update a saved password.
        TextInput.finishAutofillContext();
      } else if (s.step == SignInStep.working) {
        _checking = s;
        _poll = Timer.periodic(const Duration(seconds: 1), (_) => _read());
        return;
      }
      // Otherwise Mozilla asks for something first (a CAPTCHA, an unblock
      // code) or the sign-in failed: nothing is offered for saving.
    }
    _state = s;
    if (s.finished) {
      if (s.step == SignInStep.done) {
        _password.clear();
        widget.core.refresh(accountsToo: true);
        if (widget.firstRun && !_completionPending) {
          _completionPending = true;
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            if (!mounted) return;
            await widget.onSignedIn?.call();
            if (mounted) Navigator.of(context).pop();
          });
        }
      }
      return;
    }
    _poll = Timer.periodic(const Duration(seconds: 1), (_) => _read());
  }

  Future<void> _read() async {
    final id = (_state ?? _checking)?.id;
    final api = _api;
    if (id == null || api == null) return;
    try {
      final next = await api.signInState(id);
      if (!mounted) return;
      // Keep a typed answer while the step stays the same.
      if (next.step != _state?.step) _answer.clear();
      setState(() => _follow(next));
    } on Exception {
      // The next tick retries; the core may be busy.
    }
  }

  Future<void> _send(Future<SignInState> Function(CoreApi api) call) async {
    final api = _api;
    if (api == null) return;
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      final next = await call(api);
      if (!mounted) return;
      setState(() => _follow(next));
    } on CoreApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } on CoreUnavailable catch (e) {
      if (mounted) {
        setState(
          () => _error = describeProblem(AppLocalizations.of(context), e),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _start() {
    if (!_form.currentState!.validate()) return;
    final email = _email.text.trim();
    final password = _password.text;
    _formProblem = '';
    _send((api) async {
      final started = await api.startSignIn(email, password);
      // Marks the sign-in as the form's, for _follow.
      _checking = started;
      return started;
    });
  }

  void _submitAnswer() {
    final value = _answer.text.trim();
    final id = _state?.id;
    if (value.isEmpty || id == null) return;
    _send((api) => api.answerSignIn(id, value));
  }

  Future<void> _close() async {
    final s = _state ?? _checking;
    if (s != null && !s.finished) {
      try {
        await _api?.cancelSignIn(s.id);
      } on Exception {
        // The core ends abandoned sign-ins itself.
      }
    }
    if (mounted) Navigator.of(context).pop();
  }

  void _restart() {
    final browserRetry = widget.onBrowserRetry;
    if (browserRetry != null) {
      Navigator.of(context).pop();
      browserRetry();
      return;
    }
    setState(() {
      _poll?.cancel();
      _state = null;
      _checking = null;
      _error = null;
      _formProblem = '';
      _answer.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = _state;
    if (widget.accountSheet) return _accountSheet(s);
    return PopScope(
      canPop: !widget.firstRun,
      child: Dialog.fullscreen(
        backgroundColor: Colors.transparent,
        child: Stack(
          fit: StackFit.expand,
          children: [
            const Positioned.fill(
              child: ClxyWindowsBackground(child: SizedBox.expand()),
            ),
            const Positioned(
              top: 8,
              left: 0,
              right: 0,
              height: 260,
              child: ClxyWindowsDottedWorld(dotAlpha: .36),
            ),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) => SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 20,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: (constraints.maxHeight - 40)
                          .clamp(0.0, double.infinity)
                          .toDouble(),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 16),
                        const Center(
                          child: ClxyWindowsBrand(logoSize: 42, labelSize: 22),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Sign In to CLXY',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            color: ClxyWindowsPalette.text,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -.3,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Center(
                          child: SizedBox(
                            width: 300,
                            child: Text(
                              'Enter your credentials for direct, automatic authentication.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                color: ClxyWindowsPalette.muted,
                                fontSize: 13,
                                height: 1.45,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Container(
                          width: double.infinity,
                          constraints: const BoxConstraints(maxWidth: 440),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Color(0xE60F172E), Color(0xF20A1023)],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: ClxyWindowsPalette.cyanBorder,
                            ),
                          ),
                          child: AnimatedSize(
                            duration: const Duration(milliseconds: 200),
                            alignment: Alignment.topCenter,
                            child:
                                s == null ||
                                    s.step == SignInStep.failed ||
                                    s.step == SignInStep.cancelled
                                ? _credentials()
                                : _progress(s),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (!widget.firstRun)
              Positioned(
                top: 4,
                right: 8,
                child: IconButton(
                  tooltip: 'Close',
                  onPressed: _close,
                  icon: const Icon(
                    Icons.close_rounded,
                    color: ClxyWindowsPalette.muted,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _accountSheet(SignInState? s) {
    final height = (MediaQuery.sizeOf(context).height - 48).clamp(0.0, 10000.0);
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 440, maxHeight: height),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0B1124),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: ClxyWindowsPalette.cyanBorder),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  s == null
                      ? 'Sign in to CLXY Account'
                      : s.email.isNotEmpty
                      ? s.email
                      : 'Signing in',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    color: ClxyWindowsPalette.text,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                if (s == null) ...[
                  const Text(
                    'Enter your username/email and password to authenticate automatically.',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      color: ClxyWindowsPalette.muted,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _accountCredentials(),
                ] else
                  _accountProgress(s),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _accountCredentials() {
    final busy = _sending || _checking != null;
    final problem =
        _error ??
        (_formProblem.isEmpty
            ? null
            : _problem(
                AppLocalizations.of(context),
                _formProblem,
                _formProblemText,
              ));
    return Form(
      key: _form,
      child: AutofillGroup(
        onDisposeAction: AutofillContextAction.cancel,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _email,
              focusNode: _emailFocus,
              autofocus: widget.email.isEmpty,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [
                AutofillHints.email,
                AutofillHints.username,
              ],
              textDirection: TextDirection.ltr,
              style: const TextStyle(
                fontFamily: 'Inter',
                color: ClxyWindowsPalette.text,
                fontSize: 13,
              ),
              decoration: _accountDecoration(label: 'Username or Email'),
              validator: (value) => (value ?? '').trim().isEmpty
                  ? 'Enter your username or email.'
                  : null,
              onChanged: (_) => _dismissFormError(),
              onFieldSubmitted: (_) => _passwordFocus.requestFocus(),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _password,
              focusNode: _passwordFocus,
              autofocus: widget.email.isNotEmpty,
              obscureText: !_showPassword,
              enableSuggestions: false,
              autocorrect: false,
              autofillHints: const [AutofillHints.password],
              textDirection: TextDirection.ltr,
              style: const TextStyle(
                fontFamily: 'Inter',
                color: ClxyWindowsPalette.text,
                fontSize: 13,
              ),
              decoration: _accountDecoration(label: 'Password').copyWith(
                suffixIcon: IconButton(
                  tooltip: _showPassword ? 'Hide password' : 'Show password',
                  onPressed: () =>
                      setState(() => _showPassword = !_showPassword),
                  icon: Icon(
                    _showPassword
                        ? Icons.visibility_off_rounded
                        : Icons.visibility_rounded,
                    color: ClxyWindowsPalette.muted,
                    size: 20,
                  ),
                ),
              ),
              validator: (value) =>
                  (value ?? '').isEmpty ? 'Enter your password.' : null,
              onChanged: (_) => _dismissFormError(),
              onFieldSubmitted: (_) => _start(),
            ),
            if (problem != null) ...[
              const SizedBox(height: 10),
              _ErrorBox(problem),
            ],
            const SizedBox(height: 22),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _close,
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: ClxyWindowsPalette.muted),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: busy ? null : _start,
                  style: FilledButton.styleFrom(
                    backgroundColor: ClxyWindowsPalette.blueDeep,
                  ),
                  child: busy
                      ? const SizedBox.square(
                          dimension: 16,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Sign in'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _dismissFormError() {
    if (_error == null && _formProblem.isEmpty && _state == null) return;
    setState(() {
      _error = null;
      _formProblem = '';
      _formProblemText = '';
      if (_state?.finished == true) _state = null;
    });
  }

  Widget _accountProgress(SignInState s) {
    final l = AppLocalizations.of(context);
    final instruction = switch (s.step) {
      SignInStep.needEmailCode =>
        'Enter the verification code sent to ${s.email}.',
      SignInStep.needTotp =>
        'Enter the 6-digit code from your authenticator app.',
      SignInStep.needUnblockCode =>
        'Enter the authorization/unblock code sent to ${s.email}.',
      SignInStep.needCaptcha =>
        'Enter the characters shown in the CAPTCHA image.',
      SignInStep.needEmailLink =>
        'Open the verification link sent to ${s.email} to continue.',
      SignInStep.working =>
        s.message.isNotEmpty
            ? s.message
                  .replaceAll('Mozilla', 'CLXY')
                  .replaceAll('mozilla', 'CLXY')
            : 'Signing in with CLXY…',
      SignInStep.failed => _problem(l, s.errorCode, s.error),
      SignInStep.cancelled => 'Sign-in cancelled.',
      SignInStep.done => 'Account ready! Added to CLXY.',
      _ => s.message,
    };
    final inlineError =
        _error ??
        (s.step == SignInStep.failed ||
                s.step == SignInStep.cancelled ||
                s.error.isEmpty
            ? null
            : _problem(l, s.errorCode, s.error));
    if (s.step == SignInStep.done) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(
                Icons.check_circle_rounded,
                color: ClxyWindowsPalette.green,
                size: 28,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  instruction,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    color: ClxyWindowsPalette.text,
                    fontSize: 13.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: FilledButton(
              onPressed: _close,
              style: FilledButton.styleFrom(
                backgroundColor: ClxyWindowsPalette.blueDeep,
              ),
              child: const Text('Done'),
            ),
          ),
        ],
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (s.step == SignInStep.working || s.step == SignInStep.needEmailLink)
          Row(
            children: [
              const SizedBox.square(
                dimension: 20,
                child: CircularProgressIndicator(
                  color: ClxyWindowsPalette.cyan,
                  strokeWidth: 2.5,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  instruction,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    color: ClxyWindowsPalette.secondary,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          )
        else if (s.step == SignInStep.failed || s.step == SignInStep.cancelled)
          _ErrorBox(instruction)
        else
          Text(
            instruction,
            style: const TextStyle(
              fontFamily: 'Inter',
              color: ClxyWindowsPalette.secondary,
              fontSize: 13,
            ),
          ),
        if (s.step == SignInStep.needCaptcha && s.captcha.isNotEmpty) ...[
          const SizedBox(height: 10),
          _Captcha(dataUrl: s.captcha),
        ],
        if (s.needsAnswer) ...[
          const SizedBox(height: 10),
          TextField(
            key: ValueKey(s.step),
            controller: _answer,
            autofocus: true,
            autofillHints: s.step == SignInStep.needCaptcha
                ? null
                : const [AutofillHints.oneTimeCode],
            keyboardType:
                s.step == SignInStep.needEmailCode ||
                    s.step == SignInStep.needTotp
                ? TextInputType.number
                : TextInputType.text,
            inputFormatters:
                s.step == SignInStep.needEmailCode ||
                    s.step == SignInStep.needTotp
                ? const [_CodeDigits()]
                : null,
            textDirection: s.step == SignInStep.needCaptcha
                ? null
                : TextDirection.ltr,
            textAlign:
                s.step == SignInStep.needEmailCode ||
                    s.step == SignInStep.needTotp
                ? TextAlign.center
                : TextAlign.start,
            style: const TextStyle(
              fontFamily: 'Inter',
              color: ClxyWindowsPalette.text,
              fontSize: 13,
            ),
            decoration: _accountDecoration(label: 'Verification code'),
            onSubmitted: (_) => _submitAnswer(),
          ),
        ],
        if (inlineError != null &&
            s.step != SignInStep.failed &&
            s.step != SignInStep.cancelled) ...[
          const SizedBox(height: 8),
          _ErrorBox(inlineError),
        ],
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: _close,
              child: Text(
                s.finished ? 'Close' : 'Cancel',
                style: const TextStyle(color: ClxyWindowsPalette.muted),
              ),
            ),
            if (s.step == SignInStep.failed &&
                s.errorCode == SignInError.noPassword) ...[
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: () =>
                    openLink(context, firefoxAccountSetPasswordUrl),
                child: const Text('Set password'),
              ),
            ] else if (s.step == SignInStep.failed ||
                s.step == SignInStep.cancelled) ...[
              const SizedBox(width: 8),
              FilledButton(
                onPressed: _restart,
                style: FilledButton.styleFrom(
                  backgroundColor: ClxyWindowsPalette.blueDeep,
                ),
                child: const Text('Try again'),
              ),
            ] else if (s.needsAnswer) ...[
              const SizedBox(width: 8),
              FilledButton(
                onPressed: _sending ? null : _submitAnswer,
                style: FilledButton.styleFrom(
                  backgroundColor: ClxyWindowsPalette.blueDeep,
                ),
                child: const Text('Continue'),
              ),
            ],
          ],
        ),
      ],
    );
  }

  InputDecoration _accountDecoration({
    required String label,
  }) => InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(
      fontFamily: 'Inter',
      color: ClxyWindowsPalette.muted,
      fontSize: 12,
    ),
    filled: false,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(4),
      borderSide: const BorderSide(color: ClxyWindowsPalette.glassBorder),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(4),
      borderSide: const BorderSide(color: ClxyWindowsPalette.glassBorder),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(4),
      borderSide: const BorderSide(color: ClxyWindowsPalette.cyan, width: 1.2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(4),
      borderSide: const BorderSide(color: ClxyWindowsPalette.red),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(4),
      borderSide: const BorderSide(color: ClxyWindowsPalette.red, width: 1.2),
    ),
  );

  Widget _credentials() {
    final busy = _sending || _checking != null;
    final state = _state;
    final stateProblem = state?.step == SignInStep.failed
        ? _problem(AppLocalizations.of(context), state!.errorCode, state.error)
        : state?.step == SignInStep.cancelled
        ? 'Sign-in cancelled.'
        : null;
    final problem =
        _error ??
        (_formProblem.isEmpty
            ? stateProblem
            : _problem(
                AppLocalizations.of(context),
                _formProblem,
                _formProblemText,
              ));
    return Form(
      key: _form,
      child: AutofillGroup(
        onDisposeAction: AutofillContextAction.cancel,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _email,
              focusNode: _emailFocus,
              autofocus: widget.email.isEmpty,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [
                AutofillHints.email,
                AutofillHints.username,
              ],
              textDirection: TextDirection.ltr,
              style: const TextStyle(
                fontFamily: 'Inter',
                color: ClxyWindowsPalette.text,
                fontSize: 13,
              ),
              decoration: _loginDecoration(
                label: 'Username or Email',
                hint: 'name@example.com',
                icon: Icons.person_rounded,
              ),
              validator: (value) => (value ?? '').trim().isEmpty
                  ? 'Enter your username or email.'
                  : null,
              onChanged: (_) => _dismissFormError(),
              onFieldSubmitted: (_) => _passwordFocus.requestFocus(),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _password,
              focusNode: _passwordFocus,
              autofocus: widget.email.isNotEmpty,
              obscureText: !_showPassword,
              enableSuggestions: false,
              autocorrect: false,
              autofillHints: const [AutofillHints.password],
              textDirection: TextDirection.ltr,
              style: const TextStyle(
                fontFamily: 'Inter',
                color: ClxyWindowsPalette.text,
                fontSize: 13,
              ),
              decoration:
                  _loginDecoration(
                    label: 'Password',
                    hint: 'Enter password',
                    icon: Icons.lock_rounded,
                  ).copyWith(
                    suffixIcon: IconButton(
                      tooltip: _showPassword
                          ? 'Hide password'
                          : 'Show password',
                      onPressed: () =>
                          setState(() => _showPassword = !_showPassword),
                      icon: Icon(
                        _showPassword
                            ? Icons.visibility_off_rounded
                            : Icons.visibility_rounded,
                        color: ClxyWindowsPalette.muted,
                        size: 20,
                      ),
                    ),
                  ),
              validator: (value) =>
                  (value ?? '').isEmpty ? 'Enter your password.' : null,
              onChanged: (_) => _dismissFormError(),
              onFieldSubmitted: (_) => _start(),
            ),
            if (_error != null || problem != null) ...[
              const SizedBox(height: 12),
              _ErrorBox(_error ?? problem!),
            ],
            if (_formProblem == SignInError.noAccount) ...[
              const SizedBox(height: 8),
              Text(
                AppLocalizations.of(context).signInNoAccountHint,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  color: ClxyWindowsPalette.muted,
                  fontSize: 12,
                ),
              ),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: TextButton.icon(
                  onPressed: () => openLink(context, firefoxAccountSignUpUrl),
                  icon: const Icon(Icons.open_in_new_rounded, size: 17),
                  label: Text(AppLocalizations.of(context).createAccountButton),
                ),
              ),
            ],
            const SizedBox(height: 2),
            _LoginGradientButton(
              label: busy ? 'Authenticating…' : 'Sign In',
              busy: busy,
              onPressed: busy ? null : _start,
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _loginDecoration({
    required String label,
    required String hint,
    required IconData icon,
  }) => InputDecoration(
    labelText: label,
    hintText: hint,
    hintStyle: const TextStyle(
      fontFamily: 'Inter',
      color: ClxyWindowsPalette.dim,
      fontSize: 12,
    ),
    labelStyle: const TextStyle(
      fontFamily: 'Inter',
      color: ClxyWindowsPalette.muted,
      fontSize: 12,
    ),
    prefixIcon: Icon(icon, color: ClxyWindowsPalette.cyanText, size: 20),
    filled: true,
    fillColor: const Color(0x33131B33),
    contentPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 15),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: ClxyWindowsPalette.glassBorder),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: ClxyWindowsPalette.glassBorder),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: ClxyWindowsPalette.cyan, width: 1.2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: ClxyWindowsPalette.red),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: ClxyWindowsPalette.red, width: 1.2),
    ),
  );

  /// The instruction for a step in the app's language; the core's own
  /// message for steps the app does not know.
  String _instruction(AppLocalizations l, SignInState s) => switch (s.step) {
    SignInStep.needEmailCode => l.stepEmailCode(s.email),
    SignInStep.needTotp => l.stepTotp,
    SignInStep.needUnblockCode => l.stepUnblockCode(s.email),
    SignInStep.needCaptcha => l.stepCaptcha,
    SignInStep.needEmailLink => l.stepEmailLink(s.email),
    SignInStep.working => l.signingIn,
    SignInStep.failed => l.signInFailed,
    SignInStep.cancelled => l.signInCancelled,
    _ => s.message,
  };

  /// What went wrong, in the app's language; the core's own text for
  /// problems the app does not know.
  String _problem(AppLocalizations l, String code, String text) =>
      switch (code) {
        SignInError.noAccount => l.signInNoAccount,
        SignInError.wrongPassword => l.signInWrongPassword,
        SignInError.noPassword => l.signInNoPassword,
        SignInError.tooManyAttempts => l.signInTooManyAttempts,
        SignInError.unblockCodeRejected => l.signInUnblockRejected,
        SignInError.wrongCode => l.signInWrongCode,
        SignInError.wrongTotp => l.signInWrongTotp,
        SignInError.tooManyCodes => l.signInTooManyCodes,
        SignInError.timedOut => l.signInTimedOut,
        SignInError.network => l.signInNetwork,
        SignInError.tokenBlocked => l.browserSignInBlocked,
        SignInError.blocked when widget.onBrowserRetry != null =>
          l.browserSignInBlocked,
        _ => text,
      };

  Widget _progress(SignInState s) {
    final l = AppLocalizations.of(context);
    final instruction = _instruction(l, s);
    final failed =
        s.step == SignInStep.failed || s.step == SignInStep.cancelled;
    final noPassword = failed && s.errorCode == SignInError.noPassword;
    final numericCode =
        s.step == SignInStep.needEmailCode || s.step == SignInStep.needTotp;
    final error =
        _error ??
        (s.step == SignInStep.working || s.error.isEmpty
            ? null
            : _problem(l, s.errorCode, s.error));

    if (s.step == SignInStep.done) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(
                Icons.check_circle_rounded,
                color: ClxyWindowsPalette.green,
                size: 30,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Authenticated',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        color: ClxyWindowsPalette.text,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      s.email.isNotEmpty ? s.email : _email.text.trim(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        color: ClxyWindowsPalette.muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _LoginGradientButton(label: 'Done', onPressed: _close),
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          s.email.isNotEmpty ? s.email : _email.text.trim(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontFamily: 'Inter',
            color: ClxyWindowsPalette.cyanText,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        if (s.step == SignInStep.working || s.step == SignInStep.needEmailLink)
          Row(
            children: [
              const SizedBox.square(
                dimension: 22,
                child: CircularProgressIndicator(
                  color: ClxyWindowsPalette.cyan,
                  strokeWidth: 2.4,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  instruction.isNotEmpty
                      ? instruction
                      : 'Verifying credentials automatically…',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    color: ClxyWindowsPalette.text,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          )
        else if (instruction.isNotEmpty)
          Text(
            instruction,
            style: const TextStyle(
              fontFamily: 'Inter',
              color: ClxyWindowsPalette.secondary,
              fontSize: 13,
            ),
          ),
        if (s.step == SignInStep.needCaptcha && s.captcha.isNotEmpty) ...[
          const SizedBox(height: 12),
          _Captcha(dataUrl: s.captcha),
        ],
        if (s.needsAnswer) ...[
          const SizedBox(height: 14),
          TextField(
            key: ValueKey(s.step),
            controller: _answer,
            autofocus: true,
            autofillHints: s.step == SignInStep.needCaptcha
                ? null
                : const [AutofillHints.oneTimeCode],
            keyboardType: numericCode ? TextInputType.number : null,
            inputFormatters: numericCode ? const [_CodeDigits()] : null,
            textDirection: s.step == SignInStep.needCaptcha
                ? null
                : TextDirection.ltr,
            textAlign: numericCode ? TextAlign.center : TextAlign.start,
            style: numericCode
                ? const TextStyle(
                    fontFamily: 'Inter',
                    color: ClxyWindowsPalette.text,
                    fontSize: 20,
                    letterSpacing: 6,
                  )
                : const TextStyle(
                    fontFamily: 'Inter',
                    color: ClxyWindowsPalette.text,
                    fontSize: 13,
                  ),
            decoration: _loginDecoration(
              label: 'Verification code',
              hint: '',
              icon: Icons.lock_rounded,
            ),
            onSubmitted: (_) => _submitAnswer(),
          ),
        ],
        if (error != null && !failed) ...[
          const SizedBox(height: 10),
          _ErrorBox(error),
        ],
        if (failed && error != null) ...[
          const SizedBox(height: 10),
          _ErrorBox(error),
        ],
        const SizedBox(height: 8),
        Row(
          children: [
            TextButton(
              onPressed: _restart,
              child: const Text(
                'Change account',
                style: TextStyle(
                  fontFamily: 'Inter',
                  color: ClxyWindowsPalette.muted,
                  fontSize: 12.5,
                ),
              ),
            ),
            const Spacer(),
            if (s.needsAnswer)
              _LoginGradientButton(
                label: _sending ? 'Checking…' : 'Verify',
                busy: _sending,
                onPressed: _sending ? null : _submitAnswer,
                minWidth: 110,
              )
            else if (failed && noPassword)
              FilledButton.icon(
                onPressed: () =>
                    openLink(context, firefoxAccountSetPasswordUrl),
                icon: const Icon(Icons.open_in_new_rounded, size: 17),
                label: Text(l.setPasswordButton),
              )
            else if (failed)
              FilledButton(onPressed: _restart, child: Text(l.tryAgain)),
          ],
        ),
      ],
    );
  }
}

class _LoginGradientButton extends StatelessWidget {
  const _LoginGradientButton({
    required this.label,
    required this.onPressed,
    this.busy = false,
    this.minWidth = 0,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool busy;
  final double minWidth;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: minWidth > 0 ? minWidth : null,
    height: 50,
    child: Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(10),
        child: Ink(
          decoration: BoxDecoration(
            gradient: onPressed == null
                ? const LinearGradient(
                    colors: [ClxyWindowsPalette.blueDeep, Color(0xFF334155)],
                  )
                : const LinearGradient(
                    colors: [
                      ClxyWindowsPalette.cyan,
                      ClxyWindowsPalette.blue,
                      ClxyWindowsPalette.purple,
                    ],
                  ),
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Center(
            child: busy
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        label,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  )
                : Text(
                    label,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      color: Colors.white,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
      ),
    ),
  );
}

/// Keeps the digits of a typed or pasted code and drops everything else
/// (spaces, dashes, letters); Persian and Arabic-Indic digits, which a
/// Persian or Arabic keyboard types, become 0-9.
class _CodeDigits extends TextInputFormatter {
  const _CodeDigits();

  static String? _digit(int rune) {
    if (rune >= 0x30 && rune <= 0x39) return String.fromCharCode(rune);
    if (rune >= 0x6F0 && rune <= 0x6F9) return '${rune - 0x6F0}';
    if (rune >= 0x660 && rune <= 0x669) return '${rune - 0x660}';
    return null;
  }

  static String _digits(String text) =>
      text.runes.map(_digit).whereType<String>().join();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = _digits(newValue.text);
    if (text == newValue.text) return newValue;
    // The cursor stays after the same digits it followed.
    final end = newValue.selection.end.clamp(0, newValue.text.length);
    final cursor = _digits(newValue.text.substring(0, end)).length;
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: cursor),
    );
  }
}

class _Captcha extends StatelessWidget {
  const _Captcha({required this.dataUrl});

  final String dataUrl;

  @override
  Widget build(BuildContext context) {
    final comma = dataUrl.indexOf(',');
    try {
      final bytes = base64Decode(dataUrl.substring(comma + 1));
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.memory(bytes, height: 120, fit: BoxFit.contain),
      );
    } on FormatException {
      return _ErrorBox(AppLocalizations.of(context).captchaBroken);
    }
  }
}

class _ErrorBox extends StatelessWidget {
  const _ErrorBox(this.message);

  final String message;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: StatusColors.bad.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      message,
      style: Theme.of(context).textTheme.bodyMedium
          ?.copyWith(color: StatusColors.bad),
    ),
  );
}
