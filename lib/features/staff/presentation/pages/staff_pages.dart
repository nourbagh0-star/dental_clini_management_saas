import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/localization/generated/app_localizations.dart';
import '../../../../core/error/failure_message.dart';
import '../../../clinic/presentation/clinic_cubit.dart';
import '../../../auth/domain/auth_validation.dart';
import '../../domain/staff_models.dart';
import '../../domain/staff_validation.dart';
import '../staff_cubit.dart';

class StaffPage extends StatefulWidget {
  const StaffPage({super.key});
  @override
  State<StaffPage> createState() => _StaffPageState();
}

class _StaffPageState extends State<StaffPage> {
  String? _loadedClinic;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final clinic = context.watch<ClinicCubit>().state.activeMembership;
    if (clinic == null) {
      return _MessageCard(message: l.chooseClinicFirst);
    }
    if (!clinic.isOwner) {
      return _MessageCard(message: l.staffOwnerOnly);
    }
    if (_loadedClinic != clinic.clinic.id) {
      _loadedClinic = clinic.clinic.id;
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => context.read<StaffCubit>().load(clinic.clinic.id),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(l.staffTitle),
        leading: IconButton(
          tooltip: l.backLabel,
          onPressed: () => context.go('/clinic-gate'),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const ValueKey('staff-invite'),
        onPressed: () => _invite(context, clinic.clinic.id),
        icon: const Icon(Icons.person_add_alt_1),
        label: Text(l.createStaffAccountLabel),
      ),
      body: BlocBuilder<StaffCubit, StaffState>(
        builder: (context, state) => LayoutBuilder(
          builder: (context, constraints) => RefreshIndicator(
            onRefresh: () => context.read<StaffCubit>().load(clinic.clinic.id),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  clinic.clinic.name,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(l.manageStaffDescription),
                const SizedBox(height: 20),
                if (state.status == StaffStatus.loading)
                  const LinearProgressIndicator(),
                if (state.failure != null)
                  _MessageCard(
                    message: failureMessage(
                      state.failure!,
                      AppLocalizations.of(context),
                    ),
                  ),
                if (state.issue != null)
                  _MessageCard(message: _issueText(state.issue!, l)),
                if (constraints.maxWidth >= 900)
                  Row(
                    key: const ValueKey('staff-desktop-columns'),
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _MembersCard(
                          members: state.members,
                          onEdit: (m) => _edit(context, m),
                          onToggle: (m) => _toggle(context, m),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _InvitationsCard(
                          invitations: state.invitations,
                          onResend: (i) => _resend(context, i),
                          onRevoke: (i) => _revoke(context, i),
                        ),
                      ),
                    ],
                  )
                else ...[
                  _MembersCard(
                    members: state.members,
                    onEdit: (m) => _edit(context, m),
                    onToggle: (m) => _toggle(context, m),
                  ),
                  const SizedBox(height: 16),
                  _InvitationsCard(
                    invitations: state.invitations,
                    onResend: (i) => _resend(context, i),
                    onRevoke: (i) => _revoke(context, i),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Uri? _origin() {
    try {
      return StaffValidation.appOrigin(Uri.base);
    } on Object {
      return null;
    }
  }

  Future<void> _invite(BuildContext context, String clinicId) async {
    final form = GlobalKey<FormState>();
    var staffDisplayName = '';
    var staffEmail = '';
    var temporaryPassword = '';
    var roles = <StaffRole>{StaffRole.assistant};
    final submitted = await showDialog<bool>(
      context: context,
      builder: (dialog) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          scrollable: true,
          title: Text(AppLocalizations.of(context).createStaffAccountLabel),
          content: Form(
            key: form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(AppLocalizations.of(context).createStaffAccountHelp),
                const SizedBox(height: 12),
                TextFormField(
                  key: const ValueKey('staff-display-name'),
                  textCapitalization: TextCapitalization.words,
                  onChanged: (value) => staffDisplayName = value,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context).nameLabel,
                    prefixIcon: const Icon(Icons.person_outline),
                  ),
                  validator: (value) {
                    final displayName = value?.trim() ?? '';
                    return displayName.length >= 2 && displayName.length <= 120
                        ? null
                        : AppLocalizations.of(context).validationFailure;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const ValueKey('staff-invite-email'),
                  keyboardType: TextInputType.emailAddress,
                  onChanged: (value) => staffEmail = value,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context).emailLabel,
                  ),
                  validator: (value) => AuthValidation.email(value ?? '')
                      ? null
                      : AppLocalizations.of(context).emailInvalid,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const ValueKey('staff-temporary-password'),
                  obscureText: true,
                  autocorrect: false,
                  enableSuggestions: false,
                  onChanged: (value) => temporaryPassword = value,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(
                      context,
                    ).temporaryPasswordLabel,
                  ),
                  validator: (value) =>
                      AuthValidation.password(value ?? '') &&
                          (value?.length ?? 0) <= 128
                      ? null
                      : AppLocalizations.of(context).passwordShort,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final role in StaffRole.values)
                      FilterChip(
                        label: Text(
                          _roleLabel(role, AppLocalizations.of(context)),
                        ),
                        selected: roles.contains(role),
                        onSelected: (selected) => setDialogState(() {
                          if (selected) {
                            roles.add(role);
                          } else {
                            roles.remove(role);
                          }
                        }),
                      ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppLocalizations.of(context).cancelLabel),
            ),
            FilledButton(
              onPressed: roles.isEmpty
                  ? null
                  : () {
                      if (form.currentState!.validate()) {
                        Navigator.pop(context, true);
                      }
                    },
              child: Text(AppLocalizations.of(context).createStaffAccountLabel),
            ),
          ],
        ),
      ),
    );
    if (submitted != true || !context.mounted) return;
    await _waitForOverlayDismissal();
    if (!context.mounted) return;
    final password = await _password(context);
    if (!context.mounted || password == null) return;
    await _waitForOverlayDismissal();
    if (!context.mounted) return;
    final created = await context.read<StaffCubit>().createAccount(
      clinicId: clinicId,
      displayName: staffDisplayName,
      email: staffEmail,
      roles: roles,
      temporaryPassword: temporaryPassword,
      ownerPassword: password,
    );
    temporaryPassword = '';
    if (created && context.mounted) {
      _notice(context, AppLocalizations.of(context).staffAccountCreated);
    }
  }

  Future<void> _edit(BuildContext context, StaffMember member) async {
    await _waitForOverlayDismissal();
    if (!context.mounted) return;
    final roles = Set<StaffRole>.of(member.roles);
    final changed = await showDialog<bool>(
      context: context,
      builder: (dialog) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          scrollable: true,
          title: Text(member.displayName),
          content: Wrap(
            spacing: 8,
            children: [
              for (final role in StaffRole.values)
                FilterChip(
                  label: Text(_roleLabel(role, AppLocalizations.of(context))),
                  selected: roles.contains(role),
                  onSelected: (selected) => setDialogState(() {
                    if (selected) {
                      roles.add(role);
                    } else {
                      roles.remove(role);
                    }
                  }),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppLocalizations.of(context).cancelLabel),
            ),
            FilledButton(
              onPressed: roles.isEmpty
                  ? null
                  : () => Navigator.pop(context, true),
              child: Text(AppLocalizations.of(context).saveRolesLabel),
            ),
          ],
        ),
      ),
    );
    if (changed != true || !context.mounted) return;
    await _waitForOverlayDismissal();
    if (!context.mounted) return;
    final password =
        (member.roles.contains(StaffRole.owner) ||
            roles.contains(StaffRole.owner))
        ? await _password(context)
        : null;
    if (!context.mounted ||
        ((member.roles.contains(StaffRole.owner) ||
                roles.contains(StaffRole.owner)) &&
            password == null)) {
      return;
    }
    await _waitForOverlayDismissal();
    if (!context.mounted) return;
    await context.read<StaffCubit>().replaceMemberRoles(
      memberId: member.id,
      roles: roles,
      ownerPassword: password,
    );
  }

  Future<void> _resend(BuildContext context, StaffInvitation invitation) async {
    await _waitForOverlayDismissal();
    if (!context.mounted) return;
    final origin = _origin();
    if (origin == null) {
      _notice(context, AppLocalizations.of(context).webInvitationOnly);
      return;
    }
    final password = invitation.roles.contains(StaffRole.owner)
        ? await _password(context)
        : null;
    if (!context.mounted ||
        (invitation.roles.contains(StaffRole.owner) && password == null)) {
      return;
    }
    if (password != null) {
      await _waitForOverlayDismissal();
      if (!context.mounted) return;
    }
    await context.read<StaffCubit>().resendInvitation(
      invitationId: invitation.id,
      appOrigin: origin,
      ownerPassword: password,
    );
  }

  Future<void> _toggle(BuildContext context, StaffMember member) async {
    await _waitForOverlayDismissal();
    if (!context.mounted) return;
    final l = AppLocalizations.of(context);
    final next = !member.isActive;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        scrollable: true,
        title: Text(
          next ? l.reactivateStaffQuestion : l.deactivateStaffQuestion,
        ),
        content: Text('${member.displayName}\n${member.email}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l.cancelLabel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(next ? l.reactivateLabel : l.deactivateLabel),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) {
      return;
    }
    await _waitForOverlayDismissal();
    if (!context.mounted) return;
    final password = !next ? await _password(context) : null;
    if (!context.mounted || (!next && password == null)) {
      return;
    }
    if (password != null) {
      await _waitForOverlayDismissal();
      if (!context.mounted) return;
    }
    await context.read<StaffCubit>().setMemberActive(
      memberId: member.id,
      isActive: next,
      ownerPassword: password,
    );
  }

  Future<void> _revoke(BuildContext context, StaffInvitation invitation) async {
    await _waitForOverlayDismissal();
    if (!context.mounted) return;
    final password = invitation.roles.contains(StaffRole.owner)
        ? await _password(context)
        : null;
    if (!context.mounted ||
        (invitation.roles.contains(StaffRole.owner) && password == null)) {
      return;
    }
    if (password != null) {
      await _waitForOverlayDismissal();
      if (!context.mounted) return;
    }
    await context.read<StaffCubit>().revokeInvitation(
      invitationId: invitation.id,
      ownerPassword: password,
    );
  }

  Future<String?> _password(BuildContext context) async {
    final l = AppLocalizations.of(context);
    var password = '';
    return showDialog<String>(
      context: context,
      builder: (dialog) => AlertDialog(
        scrollable: true,
        title: Text(l.confirmPasswordTitle),
        content: TextField(
          obscureText: true,
          autocorrect: false,
          enableSuggestions: false,
          onChanged: (value) => password = value,
          decoration: InputDecoration(labelText: l.passwordLabel),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l.cancelLabel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialog, password),
            child: Text(l.confirmLabel),
          ),
        ],
      ),
    );
  }

  Future<void> _waitForOverlayDismissal() =>
      Future<void>.delayed(kThemeAnimationDuration);

  void _notice(BuildContext context, String message) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(message)));
}

class InvitationAcceptPage extends StatelessWidget {
  const InvitationAcceptPage({required this.token, super.key});
  final String? token;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: BlocBuilder<StaffCubit, StaffState>(
                builder: (context, state) {
                  final l = AppLocalizations.of(context);
                  if (token == null) {
                    return Text(l.invalidInvitationLink);
                  }
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        l.joinClinicTitle,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 12),
                      Text(l.acceptInvitationHelp),
                      const SizedBox(height: 20),
                      if (state.failure != null)
                        Text(
                          failureMessage(
                            state.failure!,
                            AppLocalizations.of(context),
                          ),
                        ),
                      if (state.issue != null)
                        Text(_issueText(state.issue!, l)),
                      FilledButton(
                        onPressed: state.mutating
                            ? null
                            : () async {
                                final clinicId = await context
                                    .read<StaffCubit>()
                                    .acceptInvitation(token!);
                                if (clinicId != null && context.mounted) {
                                  await context.read<ClinicCubit>().load();
                                  if (context.mounted) {
                                    context.go('/clinic-gate');
                                  }
                                }
                              },
                        child: state.mutating
                            ? const CircularProgressIndicator()
                            : Text(l.acceptInvitationLabel),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _MembersCard extends StatelessWidget {
  const _MembersCard({
    required this.members,
    required this.onEdit,
    required this.onToggle,
  });
  final List<StaffMember> members;
  final ValueChanged<StaffMember> onEdit;
  final ValueChanged<StaffMember> onToggle;
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l.staffCountTitle(members.length),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            for (final member in members)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  child: Text(member.displayName[0].toUpperCase()),
                ),
                title: Text(member.displayName),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(member.email),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      children: [
                        for (final role in member.roles)
                          Chip(label: Text(_roleLabel(role, l))),
                        if (!member.isActive)
                          Chip(label: Text(l.inactiveLabel)),
                      ],
                    ),
                  ],
                ),
                trailing: MenuAnchor(
                  builder: (context, controller, _) => IconButton(
                    icon: const Icon(Icons.more_vert),
                    onPressed: () => controller.isOpen
                        ? controller.close()
                        : controller.open(),
                  ),
                  menuChildren: [
                    MenuItemButton(
                      onPressed: () => onEdit(member),
                      child: Text(l.editRolesLabel),
                    ),
                    MenuItemButton(
                      onPressed: () => onToggle(member),
                      child: Text(
                        member.isActive ? l.deactivateLabel : l.reactivateLabel,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _InvitationsCard extends StatelessWidget {
  const _InvitationsCard({
    required this.invitations,
    required this.onResend,
    required this.onRevoke,
  });
  final List<StaffInvitation> invitations;
  final ValueChanged<StaffInvitation> onResend;
  final ValueChanged<StaffInvitation> onRevoke;
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l.invitationCountTitle(invitations.length),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            for (final invitation in invitations)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(invitation.email),
                subtitle: Text(
                  '${_invitationStatusLabel(invitation.status, l)} · ${invitation.roles.map((role) => _roleLabel(role, l)).join(', ')}',
                ),
                trailing: invitation.status == StaffInvitationStatus.pending
                    ? MenuAnchor(
                        builder: (context, controller, _) => IconButton(
                          icon: const Icon(Icons.more_vert),
                          onPressed: () => controller.isOpen
                              ? controller.close()
                              : controller.open(),
                        ),
                        menuChildren: [
                          MenuItemButton(
                            onPressed: () => onResend(invitation),
                            child: Text(l.resendInvitationLabel),
                          ),
                          MenuItemButton(
                            onPressed: () => onRevoke(invitation),
                            child: Text(l.revokeInvitationLabel),
                          ),
                        ],
                      )
                    : null,
              ),
          ],
        ),
      ),
    );
  }
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({required this.message});
  final String message;
  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: Card(
        child: Padding(padding: const EdgeInsets.all(24), child: Text(message)),
      ),
    ),
  );
}

String _issueText(StaffOperationIssue issue, AppLocalizations l) =>
    switch (issue) {
      StaffOperationIssue.invalidInput => l.staffInvalidInputIssue,
      StaffOperationIssue.ownerReauthenticationRequired =>
        l.ownerPasswordRequiredIssue,
      StaffOperationIssue.invitationUnavailable => l.invitationUnavailableIssue,
      StaffOperationIssue.memberUnavailable => l.staffMemberUnavailableIssue,
      StaffOperationIssue.accountUnavailable => l.staffAccountUnavailable,
    };

String _roleLabel(StaffRole role, AppLocalizations l) => switch (role) {
  StaffRole.owner => l.roleOwner,
  StaffRole.dentist => l.roleDentist,
  StaffRole.assistant => l.roleAssistant,
  StaffRole.receptionist => l.roleReceptionist,
};

String _invitationStatusLabel(
  StaffInvitationStatus status,
  AppLocalizations l,
) => switch (status) {
  StaffInvitationStatus.pending => l.invitationPending,
  StaffInvitationStatus.accepted => l.invitationAccepted,
  StaffInvitationStatus.revoked => l.invitationRevoked,
  StaffInvitationStatus.expired => l.invitationExpired,
};
