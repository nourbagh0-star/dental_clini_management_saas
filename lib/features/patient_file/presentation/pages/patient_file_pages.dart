import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/localization/generated/app_localizations.dart';
import '../../../../core/error/failure_message.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../clinic/presentation/clinic_cubit.dart';
import '../../../clinical_session/domain/clinical_session_models.dart';
import '../../../clinical_session/presentation/clinical_session_cubit.dart';
import '../../../patient/presentation/patient_cubit.dart';
import '../../domain/patient_file_models.dart';
import '../../domain/patient_file_validator.dart';
import '../patient_file_cubit.dart';

class PatientFilesPage extends StatefulWidget {
  const PatientFilesPage({required this.patientId, super.key});
  final String patientId;

  @override
  State<PatientFilesPage> createState() => _PatientFilesPageState();
}

class _PatientFilesPageState extends State<PatientFilesPage> {
  String? _loadedKey;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final clinicState = context.watch<ClinicCubit>().state;
    final clinic = clinicState.activeClinic;
    final roles = clinicState.activeMembership?.roles ?? const <String>{};
    final canRead = roles.any(
      (role) => role == 'owner' || role == 'dentist' || role == 'assistant',
    );
    final canUpload = roles.contains('dentist') || roles.contains('assistant');
    final canArchive = roles.contains('owner') || roles.contains('dentist');
    final patient = context
        .watch<PatientCubit>()
        .state
        .patients
        .where((item) => item.id == widget.patientId)
        .firstOrNull;
    if (!canRead) {
      return Scaffold(
        appBar: AppBar(title: Text(l.patientFilesTitle)),
        body: _Message(message: l.patientFilesRestricted),
      );
    }
    if (clinic == null || patient == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l.patientFilesTitle)),
        body: _Message(message: l.fileUnavailableMessage),
      );
    }
    final loadKey = '${clinic.id}:${widget.patientId}';
    if (_loadedKey != loadKey) {
      _loadedKey = loadKey;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<PatientFileCubit>().load(widget.patientId, clinic.id);
        context.read<ClinicalSessionCubit>().load(widget.patientId);
      });
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(l.patientFilesTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.go('/patients/${widget.patientId}');
            }
          },
        ),
        actions: [
          if (canUpload)
            IconButton(
              tooltip: l.uploadFileLabel,
              onPressed: () => _pickAndUpload(context),
              icon: const Icon(Icons.upload_file_outlined),
            ),
        ],
      ),
      floatingActionButton: canUpload
          ? FloatingActionButton.extended(
              onPressed: () => _pickAndUpload(context),
              icon: const Icon(Icons.upload_file_outlined),
              label: Text(l.uploadFileLabel),
            )
          : null,
      body: BlocBuilder<PatientFileCubit, PatientFileState>(
        builder: (context, state) {
          final list = _FileList(
            state: state,
            canUpload: canUpload,
            onUpload: () => _pickAndUpload(context),
          );
          final detail = state.selectedFile == null
              ? _Message(message: l.noPatientFilesMessage)
              : _FileDetail(
                  file: state.selectedFile!,
                  canArchive: canArchive,
                  canUpload: canUpload,
                  mutating: state.mutating,
                  onOpen: () => _open(context, state.selectedFile!),
                  onArchive: () => _archive(context, state.selectedFile!),
                  onRestore: () => context.read<PatientFileCubit>().restore(
                    state.selectedFile!.id,
                  ),
                  onReplace: () =>
                      _pickAndUpload(context, replaces: state.selectedFile!),
                );
          return Column(
            children: [
              if (state.uploading)
                _UploadProgress(
                  state: state,
                  onCancel: () =>
                      context.read<PatientFileCubit>().cancelUpload(),
                ),
              if (state.failure != null)
                _ErrorBanner(
                  message: failureMessage(state.failure!, l),
                  onRetry: () => context.read<PatientFileCubit>().load(
                    widget.patientId,
                    clinic.id,
                  ),
                ),
              if (state.issue != null)
                _ErrorBanner(
                  message: _issueMessage(l, state.issue!),
                  onRetry: () => context.read<PatientFileCubit>().load(
                    widget.patientId,
                    clinic.id,
                  ),
                ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) => constraints.maxWidth >= 900
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            SizedBox(width: 380, child: list),
                            const VerticalDivider(width: 1),
                            Expanded(child: detail),
                          ],
                        )
                      : ListView(
                          padding: const EdgeInsets.only(bottom: 96),
                          children: [
                            list,
                            if (state.selectedFile != null) detail,
                          ],
                        ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _pickAndUpload(
    BuildContext context, {
    PatientFile? replaces,
  }) async {
    final l = AppLocalizations.of(context);
    try {
      final picked = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: const ['jpg', 'jpeg', 'png', 'pdf'],
      );
      if (!context.mounted || picked == null) return;
      final bytes = await picked.readAsBytes();
      final selected = PatientFileValidator.validate(
        name: picked.name,
        bytes: Uint8List.fromList(bytes),
      );
      if (!context.mounted) return;
      final submitted = await showSettledDialog<_UploadDetails>(
        context: context,
        barrierDismissible: false,
        builder: (_) => _UploadDialog(
          file: selected,
          sessions: context.read<ClinicalSessionCubit>().state.sessions,
          appointments: context
              .read<ClinicalSessionCubit>()
              .state
              .eligibleAppointments,
          replaces: replaces,
        ),
      );
      if (!context.mounted || submitted == null) return;
      await context.read<PatientFileCubit>().upload(
        PatientFileDraft(
          patientId: widget.patientId,
          category: submitted.category,
          description: submitted.description,
          appointmentId: submitted.appointmentId,
          clinicalSessionId: submitted.sessionId,
          replacesFileId: replaces?.id,
        ),
        selected,
      );
    } on PatientFileSelectionException {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l.fileSelectionInvalid)));
      }
    }
  }

  Future<void> _open(BuildContext context, PatientFile file) async {
    final access = await context.read<PatientFileCubit>().readAccess(
      file.id,
      preview: file.isImage,
    );
    if (!context.mounted || access == null) return;
    if (file.isImage) {
      await showSettledDialog<void>(
        context: context,
        builder: (_) => Dialog.fullscreen(
          child: Scaffold(
            appBar: AppBar(
              title: Text(file.originalFilename),
              leading: CloseButton(onPressed: () => Navigator.pop(context)),
            ),
            body: InteractiveViewer(
              minScale: 0.5,
              maxScale: 5,
              child: Center(
                child: Image.network(
                  access.url.toString(),
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => _Message(
                    message: AppLocalizations.of(
                      context,
                    ).fileUnavailableMessage,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    } else {
      final opened = await launchUrl(
        access.url,
        mode: LaunchMode.externalApplication,
        webOnlyWindowName: '_blank',
      );
      if (!opened && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).fileUnavailableMessage),
          ),
        );
      }
    }
  }

  Future<void> _archive(BuildContext context, PatientFile file) async {
    final l = AppLocalizations.of(context);
    final controller = TextEditingController();
    final reason = await showSettledDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l.archiveFileLabel),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l.archiveFileWarning),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLength: 1000,
              minLines: 2,
              maxLines: 4,
              decoration: InputDecoration(labelText: l.reasonLabel),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l.cancelLabel),
          ),
          FilledButton(
            onPressed: () {
              final value = controller.text.trim();
              if (value.isNotEmpty) Navigator.pop(dialogContext, value);
            },
            child: Text(l.archiveFileLabel),
          ),
        ],
      ),
    );
    controller.dispose();
    if (reason != null && context.mounted) {
      await context.read<PatientFileCubit>().archive(file.id, reason);
    }
  }
}

class _FileList extends StatelessWidget {
  const _FileList({
    required this.state,
    required this.canUpload,
    required this.onUpload,
  });
  final PatientFileState state;
  final bool canUpload;
  final VoidCallback onUpload;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DropdownButtonFormField<PatientFileCategory?>(
            isExpanded: true,
            initialValue: state.category,
            decoration: InputDecoration(labelText: l.fileCategoryLabel),
            items: [
              DropdownMenuItem(
                value: null,
                child: Text(l.allFileCategoriesLabel),
              ),
              for (final value in PatientFileCategory.values)
                DropdownMenuItem(
                  value: value,
                  child: Text(_categoryLabel(l, value)),
                ),
            ],
            onChanged: state.uploading
                ? null
                : (value) => context.read<PatientFileCubit>().setFilters(
                    includeArchived: state.includeArchived,
                    category: value,
                    clearCategory: value == null,
                  ),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l.includeArchivedFilesLabel),
            value: state.includeArchived,
            onChanged: state.uploading
                ? null
                : (value) => context.read<PatientFileCubit>().setFilters(
                    includeArchived: value,
                    category: state.category,
                  ),
          ),
          if (state.status == PatientFileLoadStatus.loading)
            const LinearProgressIndicator(),
          if (state.status == PatientFileLoadStatus.ready &&
              state.files.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                children: [
                  Text(l.noPatientFilesMessage),
                  if (canUpload) ...[
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: onUpload,
                      icon: const Icon(Icons.upload_file_outlined),
                      label: Text(l.uploadFileLabel),
                    ),
                  ],
                ],
              ),
            ),
          for (final file in state.files)
            Card(
              child: ListTile(
                selected: file.id == state.selectedFileId,
                onTap: () => context.read<PatientFileCubit>().select(file.id),
                leading: Icon(
                  file.isImage
                      ? Icons.image_outlined
                      : Icons.picture_as_pdf_outlined,
                ),
                title: Text(
                  file.originalFilename,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  '${_categoryLabel(l, file.category)} · ${_formatSize(context, file.sizeBytes)}',
                ),
                trailing: file.isArchived
                    ? Tooltip(
                        message: l.archivedFileLabel,
                        child: const Icon(Icons.archive_outlined),
                      )
                    : null,
              ),
            ),
          if (state.hasMore)
            TextButton(
              onPressed: state.loadingMore
                  ? null
                  : () => context.read<PatientFileCubit>().loadMore(),
              child: Text(l.loadMoreLabel),
            ),
        ],
      ),
    );
  }
}

class _FileDetail extends StatelessWidget {
  const _FileDetail({
    required this.file,
    required this.canArchive,
    required this.canUpload,
    required this.mutating,
    required this.onOpen,
    required this.onArchive,
    required this.onRestore,
    required this.onReplace,
  });
  final PatientFile file;
  final bool canArchive;
  final bool canUpload;
  final bool mutating;
  final VoidCallback onOpen;
  final VoidCallback onArchive;
  final VoidCallback onRestore;
  final VoidCallback onReplace;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      file.originalFilename,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  if (file.isArchived) Chip(label: Text(l.archivedFileLabel)),
                ],
              ),
              const SizedBox(height: 16),
              _DetailRow(l.fileCategoryLabel, _categoryLabel(l, file.category)),
              _DetailRow(l.fileSizeLabel, _formatSize(context, file.sizeBytes)),
              _DetailRow(
                l.uploadedAtLabel,
                DateFormat.yMMMd(
                  locale,
                ).add_jm().format(file.availableAt.toLocal()),
              ),
              if (file.description != null)
                _DetailRow(l.fileDescriptionLabel, file.description!),
              if (file.appointmentId != null || file.clinicalSessionId != null)
                _DetailRow(l.fileLinkedVisitLabel, l.visitsTitle),
              if (file.archiveReason != null)
                _DetailRow(l.reasonLabel, file.archiveReason!),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: mutating ? null : onOpen,
                icon: Icon(
                  file.isImage ? Icons.visibility_outlined : Icons.open_in_new,
                ),
                label: Text(file.isImage ? l.openFileLabel : l.openPdfLabel),
              ),
              if (canUpload && !file.isArchived) ...[
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: mutating ? null : onReplace,
                  icon: const Icon(Icons.upload_file_outlined),
                  label: Text(l.uploadReplacementLabel),
                ),
              ],
              if (canArchive) ...[
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: mutating
                      ? null
                      : (file.isArchived ? onRestore : onArchive),
                  icon: Icon(
                    file.isArchived
                        ? Icons.unarchive_outlined
                        : Icons.archive_outlined,
                  ),
                  label: Text(
                    file.isArchived ? l.restoreFileLabel : l.archiveFileLabel,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _UploadDetails {
  const _UploadDetails({
    required this.category,
    this.description,
    this.appointmentId,
    this.sessionId,
  });
  final PatientFileCategory category;
  final String? description;
  final String? appointmentId;
  final String? sessionId;
}

class _UploadDialog extends StatefulWidget {
  const _UploadDialog({
    required this.file,
    required this.sessions,
    required this.appointments,
    this.replaces,
  });
  final SelectedPatientFile file;
  final List<ClinicalSession> sessions;
  final List<EligibleSessionAppointment> appointments;
  final PatientFile? replaces;

  @override
  State<_UploadDialog> createState() => _UploadDialogState();
}

class _UploadDialogState extends State<_UploadDialog> {
  final _description = TextEditingController();
  PatientFileCategory? _category;
  String? _link;

  @override
  void dispose() {
    _description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(
        widget.replaces == null ? l.uploadFileLabel : l.uploadReplacementLabel,
      ),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  widget.file.mimeType == 'application/pdf'
                      ? Icons.picture_as_pdf_outlined
                      : Icons.image_outlined,
                ),
                title: Text(widget.file.name),
                subtitle: Text(_formatSize(context, widget.file.sizeBytes)),
              ),
              Text(l.fileTypeHelp),
              const SizedBox(height: 16),
              DropdownButtonFormField<PatientFileCategory>(
                isExpanded: true,
                initialValue: _category,
                decoration: InputDecoration(labelText: l.fileCategoryLabel),
                items: PatientFileCategory.values
                    .map(
                      (value) => DropdownMenuItem(
                        value: value,
                        child: Text(_categoryLabel(l, value)),
                      ),
                    )
                    .toList(growable: false),
                onChanged: (value) => setState(() => _category = value),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _description,
                maxLength: 1000,
                maxLines: 3,
                decoration: InputDecoration(labelText: l.fileDescriptionLabel),
              ),
              if (widget.sessions.isNotEmpty || widget.appointments.isNotEmpty)
                DropdownButtonFormField<String?>(
                  isExpanded: true,
                  initialValue: _link,
                  decoration: InputDecoration(
                    labelText: l.fileLinkedVisitLabel,
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('—')),
                    for (final session in widget.sessions.where(
                      (item) =>
                          item.status != ClinicalSessionStatus.enteredInError,
                    ))
                      DropdownMenuItem(
                        value: 'session:${session.id}',
                        child: Text(
                          DateFormat.yMMMd(
                            Localizations.localeOf(context).toLanguageTag(),
                          ).format(session.sessionDate.toLocal()),
                        ),
                      ),
                    for (final appointment in widget.appointments.where(
                      (item) => !widget.sessions.any(
                        (session) => session.appointmentId == item.id,
                      ),
                    ))
                      DropdownMenuItem(
                        value: 'appointment:${appointment.id}',
                        child: Text(
                          '${l.appointmentSessionLabel} · ${DateFormat.yMMMd(Localizations.localeOf(context).toLanguageTag()).format(appointment.startsAt.toLocal())}',
                        ),
                      ),
                  ],
                  onChanged: (value) => setState(() => _link = value),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l.cancelLabel),
        ),
        FilledButton(
          onPressed: _category == null
              ? null
              : () {
                  final sessionId = _link?.startsWith('session:') == true
                      ? _link!.substring('session:'.length)
                      : null;
                  final session = widget.sessions
                      .where((item) => item.id == sessionId)
                      .firstOrNull;
                  final appointmentId =
                      _link?.startsWith('appointment:') == true
                      ? _link!.substring('appointment:'.length)
                      : session?.appointmentId;
                  Navigator.pop(
                    context,
                    _UploadDetails(
                      category: _category!,
                      description: _description.text.trim().isEmpty
                          ? null
                          : _description.text.trim(),
                      appointmentId: appointmentId,
                      sessionId: sessionId,
                    ),
                  );
                },
          child: Text(l.uploadFileLabel),
        ),
      ],
    );
  }
}

class _UploadProgress extends StatelessWidget {
  const _UploadProgress({required this.state, required this.onCancel});
  final PatientFileState state;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    state.uploadedBytes >= state.uploadTotalBytes &&
                            state.uploadTotalBytes > 0
                        ? l.validatingFileLabel
                        : l.uploadingFileLabel,
                  ),
                ),
                TextButton(
                  onPressed: onCancel,
                  child: Text(l.cancelUploadLabel),
                ),
              ],
            ),
            LinearProgressIndicator(value: state.uploadProgress),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 150, child: Text(label)),
        Expanded(child: SelectableText(value)),
      ],
    ),
  );
}

class _Message extends StatelessWidget {
  const _Message({required this.message});
  final String message;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(padding: const EdgeInsets.all(24), child: Text(message)),
  );
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => MaterialBanner(
    content: Text(message),
    actions: [
      TextButton(
        onPressed: onRetry,
        child: Text(AppLocalizations.of(context).retryLabel),
      ),
    ],
  );
}

String _categoryLabel(AppLocalizations l, PatientFileCategory category) =>
    switch (category) {
      PatientFileCategory.xRay => l.fileCategoryXray,
      PatientFileCategory.clinicalPhoto => l.fileCategoryClinicalPhoto,
      PatientFileCategory.consent => l.fileCategoryConsent,
      PatientFileCategory.referral => l.fileCategoryReferral,
      PatientFileCategory.laboratoryResult => l.fileCategoryLaboratory,
      PatientFileCategory.other => l.fileCategoryOther,
    };

String _formatSize(BuildContext context, int bytes) {
  final locale = Localizations.localeOf(context).toLanguageTag();
  final value = bytes >= 1024 * 1024 ? bytes / (1024 * 1024) : bytes / 1024;
  final unit = bytes >= 1024 * 1024 ? 'MB' : 'KB';
  return '${NumberFormat('0.#', locale).format(value)} $unit';
}

String _issueMessage(AppLocalizations l, PatientFileOperationIssue issue) =>
    switch (issue) {
      PatientFileOperationIssue.forbidden => l.authorizationFailure,
      PatientFileOperationIssue.unavailable ||
      PatientFileOperationIssue.uploadMissing => l.fileUnavailableMessage,
      PatientFileOperationIssue.invalidName ||
      PatientFileOperationIssue.typeNotAllowed ||
      PatientFileOperationIssue.tooLarge ||
      PatientFileOperationIssue.empty ||
      PatientFileOperationIssue.signatureMismatch => l.fileSelectionInvalid,
      PatientFileOperationIssue.patientArchived ||
      PatientFileOperationIssue.uploadExpired ||
      PatientFileOperationIssue.invalidState ||
      PatientFileOperationIssue.storageUnavailable ||
      PatientFileOperationIssue.invalidInput => l.fileActionFailedMessage,
    };
