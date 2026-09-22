import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../app/localization/generated/app_localizations.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../clinic/presentation/clinic_cubit.dart';
import '../../domain/patient_file_models.dart';
import '../patient_file_cubit.dart';
import '../widgets/before_after_slider.dart';

/// Interactive Before & After comparison gallery page for dental clinical photos and X-rays.
class BeforeAfterGalleryPage extends StatefulWidget {
  const BeforeAfterGalleryPage({super.key, required this.patientId});

  final String patientId;

  @override
  State<BeforeAfterGalleryPage> createState() => _BeforeAfterGalleryPageState();
}

class _BeforeAfterGalleryPageState extends State<BeforeAfterGalleryPage> {
  PatientFile? _beforeFile;
  PatientFile? _afterFile;
  final Map<String, String> _urlCache = <String, String>{};
  bool _loadingUrls = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initData());
  }

  void _initData() {
    final clinicId = context.read<ClinicCubit>().state.activeClinicId;
    if (clinicId != null) {
      final fileState = context.read<PatientFileCubit>().state;
      if (fileState.patientId != widget.patientId ||
          fileState.status != PatientFileLoadStatus.ready) {
        context.read<PatientFileCubit>().load(widget.patientId, clinicId);
      } else {
        _autoSelectDefaultPhotos(fileState.files);
      }
    }
  }

  void _autoSelectDefaultPhotos(List<PatientFile> files) {
    if (_beforeFile != null && _afterFile != null) return;
    final imageFiles = files
        .where((f) => f.isImage && !f.isArchived)
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    if (imageFiles.length >= 2) {
      _beforeFile = imageFiles.first;
      _afterFile = imageFiles.last;
      _resolveUrls();
    } else if (imageFiles.length == 1) {
      _beforeFile = imageFiles.first;
      _resolveUrls();
    }
  }

  Future<void> _resolveUrls() async {
    if (!mounted) return;
    setState(() => _loadingUrls = true);

    final cubit = context.read<PatientFileCubit>();

    if (_beforeFile != null && !_urlCache.containsKey(_beforeFile!.id)) {
      final access = await cubit.readAccess(_beforeFile!.id, preview: true);
      if (access != null) {
        _urlCache[_beforeFile!.id] = access.url.toString();
      }
    }

    if (_afterFile != null && !_urlCache.containsKey(_afterFile!.id)) {
      final access = await cubit.readAccess(_afterFile!.id, preview: true);
      if (access != null) {
        _urlCache[_afterFile!.id] = access.url.toString();
      }
    }

    if (mounted) {
      setState(() => _loadingUrls = false);
    }
  }

  void _selectAsBefore(PatientFile file) {
    HapticFeedback.lightImpact();
    setState(() {
      _beforeFile = file;
      if (_afterFile?.id == file.id) {
        _afterFile = null;
      }
    });
    _resolveUrls();
  }

  void _selectAsAfter(PatientFile file) {
    HapticFeedback.lightImpact();
    setState(() {
      _afterFile = file;
      if (_beforeFile?.id == file.id) {
        _beforeFile = null;
      }
    });
    _resolveUrls();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();

    return Scaffold(
      appBar: AppBar(
        title: Text(l.beforeAfterGalleryTitle),
        leading: BackButton(
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/patients/${widget.patientId}');
            }
          },
        ),
      ),
      body: BlocConsumer<PatientFileCubit, PatientFileState>(
        listenWhen: (prev, curr) =>
            prev.status != curr.status &&
            curr.status == PatientFileLoadStatus.ready,
        listener: (context, state) {
          _autoSelectDefaultPhotos(state.files);
        },
        builder: (context, state) {
          if (state.status == PatientFileLoadStatus.loading &&
              state.files.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          final imageFiles = state.files
              .where((f) => f.isImage && !f.isArchived)
              .toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

          if (imageFiles.length < 2) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.large),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.photo_library_outlined,
                      size: 64,
                      color: theme.colorScheme.outline,
                    ),
                    const SizedBox(height: AppSpacing.medium),
                    Text(
                      l.selectPhotosToCompare,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.small),
                    Text(
                      l.noPatientFilesMessage,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.large),
                    FilledButton.icon(
                      onPressed: () {
                        context.go('/patients/${widget.patientId}/files');
                      },
                      icon: const Icon(Icons.upload_file_rounded),
                      label: Text(l.patientFilesTitle),
                    ),
                  ],
                ),
              ),
            );
          }

          final beforeUrl = _beforeFile != null ? _urlCache[_beforeFile!.id] : null;
          final afterUrl = _afterFile != null ? _urlCache[_afterFile!.id] : null;

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.medium),
            children: [
              // Comparison Slider Card
              if (beforeUrl != null && afterUrl != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    BeforeAfterSlider(
                      beforeImageUrl: beforeUrl,
                      afterImageUrl: afterUrl,
                      height: 380,
                    ),
                    const SizedBox(height: AppSpacing.small),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            '${l.beforeLabel}: ${_beforeFile!.originalFilename}',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.small),
                        Flexible(
                          child: Text(
                            '${l.afterLabel}: ${_afterFile!.originalFilename}',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                )
              else if (_loadingUrls)
                Container(
                  height: 300,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const CircularProgressIndicator(),
                )
              else
                Container(
                  height: 200,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                    ),
                  ),
                  padding: const EdgeInsets.all(AppSpacing.medium),
                  child: Text(
                    l.selectPhotosToCompare,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

              const SizedBox(height: AppSpacing.large),

              // Photo Picker Grid
              Text(
                l.patientFilesTitle,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.small),

              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 600;
                  final crossAxisCount = isWide ? 3 : 2;

                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: AppSpacing.small,
                      mainAxisSpacing: AppSpacing.small,
                      childAspectRatio: 0.85,
                    ),
                    itemCount: imageFiles.length,
                    itemBuilder: (context, index) {
                      final file = imageFiles[index];
                      final isBefore = _beforeFile?.id == file.id;
                      final isAfter = _afterFile?.id == file.id;
                      final dateStr = DateFormat.yMMMd(locale).format(file.createdAt);

                      return Card(
                        clipBehavior: Clip.antiAlias,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: isBefore
                                ? theme.colorScheme.secondary
                                : isAfter
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
                            width: (isBefore || isAfter) ? 2.5 : 1.0,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  if (_urlCache.containsKey(file.id))
                                    Image.network(
                                      _urlCache[file.id]!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, _, _) => const Icon(
                                        Icons.broken_image_outlined,
                                        size: 32,
                                      ),
                                    )
                                  else
                                    Container(
                                      color: theme.colorScheme.surfaceContainerHighest,
                                      child: const Center(
                                        child: Icon(Icons.image_outlined, size: 32),
                                      ),
                                    ),
                                  if (isBefore)
                                    Positioned(
                                      top: 6,
                                      left: 6,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withValues(alpha: 0.7),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          l.beforeLabel,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  if (isAfter)
                                    Positioned(
                                      top: 6,
                                      right: 6,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: theme.colorScheme.primary,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          l.afterLabel,
                                          style: TextStyle(
                                            color: theme.colorScheme.onPrimary,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(6),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    file.originalFilename,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.labelMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    dateStr,
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton(
                                          onPressed: () => _selectAsBefore(file),
                                          style: OutlinedButton.styleFrom(
                                            padding: EdgeInsets.zero,
                                            visualDensity: VisualDensity.compact,
                                            side: BorderSide(
                                              color: isBefore
                                                  ? theme.colorScheme.secondary
                                                  : theme.colorScheme.outlineVariant,
                                            ),
                                          ),
                                          child: Text(
                                            l.beforeLabel,
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: isBefore
                                                  ? FontWeight.bold
                                                  : FontWeight.normal,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: FilledButton(
                                          onPressed: () => _selectAsAfter(file),
                                          style: FilledButton.styleFrom(
                                            padding: EdgeInsets.zero,
                                            visualDensity: VisualDensity.compact,
                                            backgroundColor: isAfter
                                                ? theme.colorScheme.primary
                                                : theme.colorScheme.surfaceContainerHighest,
                                            foregroundColor: isAfter
                                                ? theme.colorScheme.onPrimary
                                                : theme.colorScheme.onSurfaceVariant,
                                          ),
                                          child: Text(
                                            l.afterLabel,
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: isAfter
                                                  ? FontWeight.bold
                                                  : FontWeight.normal,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
