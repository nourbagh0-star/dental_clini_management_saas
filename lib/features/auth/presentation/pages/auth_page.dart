import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/localization/generated/app_localizations.dart';
import '../../../../app/theme/appearance.dart';
import '../../../../app/theme/appearance_cubit.dart';
import '../../domain/auth_models.dart';
import '../../domain/auth_validation.dart';
import '../bloc/auth_bloc.dart';
import '../widgets/auth_appearance_actions.dart';
import '../widgets/auth_issue_message.dart';

enum AuthPageKind {
  login,
  register,
  verify,
  forgot,
  reset,
  locked,
  account,
  restoring,
  initialPassword,
}

class AuthPage extends StatefulWidget {
  const AuthPage(this.kind, {super.key});
  final AuthPageKind kind;
  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _secret = TextEditingController();
  final _confirm = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _email.dispose();
    _secret.dispose();
    _confirm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => BlocConsumer<AuthBloc, AuthViewState>(
    listenWhen: (a, b) =>
        a.stage != b.stage ||
        a.issue != b.issue ||
        (a.busy && !b.busy && b.issue == null),
    listener: (_, state) {
      final issue = state.issue;
      if (issue != null) {
        final messenger = ScaffoldMessenger.of(context);
        messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(
                authIssueMessage(issue, AppLocalizations.of(context)),
              ),
            ),
          );
        return;
      }
      _secret.clear();
      _confirm.clear();
    },
    builder: (context, state) {
      final l = AppLocalizations.of(context);
      final bloc = context.read<AuthBloc>();
      final kind = widget.kind;
      final title = switch (kind) {
        AuthPageKind.login => l.loginTitle,
        AuthPageKind.register => l.registerTitle,
        AuthPageKind.verify => l.verifyTitle,
        AuthPageKind.forgot => l.forgotTitle,
        AuthPageKind.reset => l.resetTitle,
        AuthPageKind.initialPassword => l.initialPasswordTitle,
        AuthPageKind.locked => l.lockedTitle,
        AuthPageKind.account => l.accountTitle,
        AuthPageKind.restoring =>
          state.stage == AuthStage.restorationFailed
              ? l.restoreFailedTitle
              : l.restoringTitle,
      };
      final needsEmail =
          kind == AuthPageKind.login ||
          kind == AuthPageKind.register ||
          kind == AuthPageKind.forgot;
      final awaitingRecovery =
          kind == AuthPageKind.reset &&
          state.stage != AuthStage.recoveryAuthorized;
      final newPassword =
          kind == AuthPageKind.initialPassword ||
          kind == AuthPageKind.register ||
          (kind == AuthPageKind.reset &&
              state.stage == AuthStage.recoveryAuthorized);
      final needsSecret =
          newPassword ||
          kind == AuthPageKind.login ||
          kind == AuthPageKind.locked;
      final action = switch (kind) {
        AuthPageKind.login => AuthAction.login,
        AuthPageKind.register => AuthAction.register,
        AuthPageKind.verify => AuthAction.resend,
        AuthPageKind.forgot => AuthAction.recover,
        AuthPageKind.initialPassword => AuthAction.changeInitialPassword,
        AuthPageKind.reset =>
          awaitingRecovery ? AuthAction.recover : AuthAction.resetPassword,
        AuthPageKind.locked => AuthAction.unlock,
        _ => AuthAction.restore,
      };
      final label = switch (kind) {
        AuthPageKind.login => l.signInLabel,
        AuthPageKind.register => l.registerLabel,
        AuthPageKind.verify => l.resendLinkLabel,
        AuthPageKind.forgot => l.sendResetLinkLabel,
        AuthPageKind.initialPassword => l.resetLabel,
        AuthPageKind.reset =>
          awaitingRecovery ? l.resendLinkLabel : l.resetLabel,
        AuthPageKind.locked => l.unlockLabel,
        _ => l.retryLabel,
      };
      void submit() {
        if (state.busy || !(_form.currentState?.validate() ?? false)) return;
        bloc.add(
          AuthRequested(
            action,
            AuthInput(
              email: awaitingRecovery ? state.email : _email.text,
              secret: _secret.text,
            ),
          ),
        );
      }

      return Scaffold(
        appBar: AppBar(
          title: Text(l.appTitle),
          actions: const [AuthAppearanceActions()],
        ),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              padding: EdgeInsets.all(constraints.maxWidth < 600 ? 16 : 32),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Form(
                        key: _form,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              l.demoLabel,
                              style: Theme.of(context).textTheme.labelLarge,
                            ),
                            const SizedBox(height: 16),
                            Semantics(
                              header: true,
                              child: Text(
                                title,
                                style: Theme.of(
                                  context,
                                ).textTheme.headlineSmall,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(l.demoNotice),
                            const SizedBox(height: 24),
                            if (state.issue != null) ...[
                              Semantics(
                                liveRegion: true,
                                child: Text(authIssueMessage(state.issue!, l)),
                              ),
                              const SizedBox(height: 16),
                            ],
                            BlocBuilder<AppearanceCubit, AppearanceState>(
                              builder: (_, appearance) =>
                                  appearance.storageFailed
                                  ? Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 16,
                                      ),
                                      child: Text(l.storageWarning),
                                    )
                                  : const SizedBox.shrink(),
                            ),
                            if (kind == AuthPageKind.restoring) ...[
                              if (state.busy ||
                                  state.stage == AuthStage.restoring)
                                const Center(
                                  child: CircularProgressIndicator(),
                                ),
                              if (state.stage == AuthStage.restorationFailed &&
                                  !state.busy) ...[
                                FilledButton(
                                  onPressed: submit,
                                  child: Text(l.retryLabel),
                                ),
                                TextButton(
                                  onPressed: () =>
                                      bloc.add(AuthLogoutRequested()),
                                  child: Text(l.switchAccountLabel),
                                ),
                              ],
                            ] else if (kind == AuthPageKind.account) ...[
                              Text(l.accountBody),
                              const SizedBox(height: 16),
                              FilledButton(
                                onPressed: () => bloc.add(AuthLockRequested()),
                                child: Text(l.lockLabel),
                              ),
                              TextButton(
                                onPressed: () =>
                                    bloc.add(AuthLogoutRequested()),
                                child: Text(l.logoutLabel),
                              ),
                            ] else ...[
                              if (kind == AuthPageKind.verify) ...[
                                Icon(
                                  Icons.mark_email_unread_outlined,
                                  size: 48,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                const SizedBox(height: 16),
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.surface,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: SelectableText(
                                    state.email,
                                    textDirection: TextDirection.ltr,
                                    textAlign: TextAlign.center,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleMedium,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(l.confirmationLinkSent),
                                const SizedBox(height: 24),
                              ],
                              if (kind == AuthPageKind.locked) ...[
                                Text(l.lockedBody),
                                const SizedBox(height: 16),
                              ],
                              if (awaitingRecovery) ...[
                                Text(state.email),
                                Text(l.recoveryLinkSent),
                                const SizedBox(height: 16),
                              ],
                              if (needsEmail) ...[
                                TextFormField(
                                  key: const ValueKey('auth-email'),
                                  controller: _email,
                                  enabled: !state.busy,
                                  keyboardType: TextInputType.emailAddress,
                                  autofillHints: const [AutofillHints.username],
                                  autocorrect: false,
                                  decoration: InputDecoration(
                                    labelText: l.emailLabel,
                                  ),
                                  validator: (value) =>
                                      AuthValidation.email(value ?? '')
                                      ? null
                                      : l.emailInvalid,
                                  textInputAction: needsSecret
                                      ? TextInputAction.next
                                      : TextInputAction.done,
                                  onFieldSubmitted: (_) {
                                    if (!needsSecret) submit();
                                  },
                                ),
                                const SizedBox(height: 16),
                              ],
                              if (newPassword) ...[
                                Text(l.passwordHelp),
                                const SizedBox(height: 12),
                              ],
                              if (needsSecret) ...[
                                TextFormField(
                                  key: const ValueKey('auth-password'),
                                  controller: _secret,
                                  enabled: !state.busy,
                                  obscureText: _obscure,
                                  keyboardType: TextInputType.visiblePassword,
                                  enableSuggestions: false,
                                  autocorrect: false,
                                  autofillHints: [
                                    newPassword
                                        ? AutofillHints.newPassword
                                        : AutofillHints.password,
                                  ],
                                  decoration: InputDecoration(
                                    labelText: l.passwordLabel,
                                    suffixIcon: IconButton(
                                      tooltip: _obscure
                                          ? l.showPassword
                                          : l.hidePassword,
                                      onPressed: () =>
                                          setState(() => _obscure = !_obscure),
                                      icon: Icon(
                                        _obscure
                                            ? Icons.visibility
                                            : Icons.visibility_off,
                                      ),
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return l.requiredField;
                                    }
                                    if (newPassword &&
                                        !AuthValidation.password(value)) {
                                      return l.passwordShort;
                                    }
                                    return null;
                                  },
                                  textInputAction: newPassword
                                      ? TextInputAction.next
                                      : TextInputAction.done,
                                  onFieldSubmitted: (_) {
                                    if (!newPassword) submit();
                                  },
                                ),
                                const SizedBox(height: 16),
                              ],
                              if (newPassword) ...[
                                TextFormField(
                                  key: const ValueKey('auth-confirm'),
                                  controller: _confirm,
                                  enabled: !state.busy,
                                  obscureText: _obscure,
                                  enableSuggestions: false,
                                  autocorrect: false,
                                  decoration: InputDecoration(
                                    labelText: l.confirmPasswordLabel,
                                  ),
                                  validator: (value) => value == _secret.text
                                      ? null
                                      : l.passwordMismatch,
                                  onFieldSubmitted: (_) => submit(),
                                ),
                                const SizedBox(height: 16),
                              ],
                              FilledButton(
                                key: const ValueKey('auth-submit'),
                                onPressed: state.busy ? null : submit,
                                child: state.busy
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Text(label),
                              ),
                              if (kind == AuthPageKind.login) ...[
                                TextButton(
                                  onPressed: state.busy
                                      ? null
                                      : () => context.go('/register'),
                                  child: Text(l.registerLabel),
                                ),
                                TextButton(
                                  onPressed: state.busy
                                      ? null
                                      : () => context.go('/forgot-password'),
                                  child: Text(l.forgotLabel),
                                ),
                              ] else if (kind == AuthPageKind.verify) ...[
                                TextButton(
                                  onPressed: state.busy
                                      ? null
                                      : () => bloc.add(AuthLogoutRequested()),
                                  child: Text(l.backLoginLabel),
                                ),
                                TextButton(
                                  onPressed: state.busy
                                      ? null
                                      : () => bloc.add(AuthLogoutRequested()),
                                  child: Text(l.changeEmailLabel),
                                ),
                              ] else if (kind == AuthPageKind.locked) ...[
                                TextButton(
                                  onPressed: state.busy
                                      ? null
                                      : () => bloc.add(AuthLogoutRequested()),
                                  child: Text(l.switchAccountLabel),
                                ),
                              ] else ...[
                                TextButton(
                                  onPressed: state.busy
                                      ? null
                                      : () {
                                          if (state.stage ==
                                              AuthStage.signedOut) {
                                            context.go('/login');
                                          } else {
                                            bloc.add(AuthLogoutRequested());
                                          }
                                        },
                                  child: Text(l.backLoginLabel),
                                ),
                              ],
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}
